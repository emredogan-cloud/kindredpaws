import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// KP-005 — the iOS privacy manifest is authored and wired. Apple rejects
/// submissions without `PrivacyInfo.xcprivacy` declaring required-reason API
/// usage; this pins the file, its honest posture (NO tracking), the
/// `shared_preferences`→UserDefaults reason the audit called out, and its
/// membership in the Xcode Resources phase (authored on Linux — the archive
/// validation itself is the founder's F-5 step).
void main() {
  group('ios/Runner/PrivacyInfo.xcprivacy (KP-005)', () {
    final manifest = File('ios/Runner/PrivacyInfo.xcprivacy');

    test('exists and declares the no-tracking posture', () {
      expect(manifest.existsSync(), isTrue);
      final s = manifest.readAsStringSync();
      expect(s, contains('<key>NSPrivacyTracking</key>'));
      // The value element that follows the key must be <false/>.
      final trackingIdx = s.indexOf('<key>NSPrivacyTracking</key>');
      final after = s.substring(trackingIdx, trackingIdx + 80);
      expect(after, contains('<false/>'));
      expect(s, contains('<key>NSPrivacyTrackingDomains</key>'));
      expect(s, isNot(contains('NSPrivacyCollectedDataTypeAdvertisingData')));
    });

    test('declares the required-reason APIs the app actually uses', () {
      final s = manifest.readAsStringSync();
      // shared_preferences → UserDefaults (the audit's named example).
      expect(s, contains('NSPrivacyAccessedAPICategoryUserDefaults'));
      expect(s, contains('CA92.1'));
      expect(s, contains('NSPrivacyAccessedAPICategoryFileTimestamp'));
      expect(s, contains('NSPrivacyAccessedAPICategorySystemBootTime'));
    });

    test('mirrors the data-safety SSOT (linked ids, no ad data)', () {
      final s = manifest.readAsStringSync();
      for (final t in [
        'NSPrivacyCollectedDataTypeUserID',
        'NSPrivacyCollectedDataTypeGameplayContent',
        'NSPrivacyCollectedDataTypePurchaseHistory',
        'NSPrivacyCollectedDataTypeProductInteraction',
        'NSPrivacyCollectedDataTypeCrashData',
        'NSPrivacyCollectedDataTypePerformanceData',
      ]) {
        expect(s, contains(t), reason: '$t missing from the manifest');
      }
    });

    test(
      'is a member of the Xcode Resources build phase (will be bundled)',
      () {
        final pbx = File(
          'ios/Runner.xcodeproj/project.pbxproj',
        ).readAsStringSync();
        expect(pbx, contains('PrivacyInfo.xcprivacy in Resources'));
        expect(
          RegExp('PrivacyInfo.xcprivacy').allMatches(pbx).length,
          greaterThanOrEqualTo(4), // build file, file ref, group, resources
        );
      },
    );
  });
}
