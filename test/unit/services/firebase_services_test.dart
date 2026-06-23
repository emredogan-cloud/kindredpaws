import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/core/bootstrap.dart';
import 'package:kindredpaws/core/service_locator.dart';
import 'package:kindredpaws/services/analytics_service.dart';
import 'package:kindredpaws/services/backend_service.dart';
import 'package:kindredpaws/services/firebase/firebase_services.dart';
import 'package:kindredpaws/services/firebase_provisioning.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P3-0 Firebase activation (fail-safe, gated)', () {
    setUp(ServiceLocator.instance.reset);

    test('not provisioned by default — the mock stack stands', () {
      expect(FirebaseProvisioning.isProvisioned, isFalse);
      bootstrap();
      // The default (CI/test/no-creds) build keeps the in-memory adapters.
      expect(
        ServiceLocator.instance.get<AnalyticsService>(),
        isA<InMemoryAnalyticsService>(),
      );
      expect(
        ServiceLocator.instance.get<BackendService>().isAuthoritative,
        isFalse,
      );
    });

    test(
      'initFirebase() degrades gracefully when unconfigured (never throws)',
      () async {
        // No native Firebase config in the test env → initializeApp throws →
        // initFirebase catches it and returns false (caller keeps the mocks).
        expect(await initFirebase(), isFalse);
      },
    );
  });
}
