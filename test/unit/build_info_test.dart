import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/src/build_info.dart';

void main() {
  group('build_info (unit layer)', () {
    test('healthLabel reports environment OK', () {
      expect(healthLabel(), 'KindredPaws environment OK');
    });

    test('app identity constants are set', () {
      expect(kAppName, isNotEmpty);
      expect(kBuildChannel, 'walking-skeleton');
    });
  });
}
