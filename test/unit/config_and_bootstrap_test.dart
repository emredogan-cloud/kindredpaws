import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/core/bootstrap.dart';
import 'package:kindredpaws/core/kindred_terms.dart';
import 'package:kindredpaws/core/service_locator.dart';
import 'package:kindredpaws/services/analytics_service.dart';
import 'package:kindredpaws/services/auth_service.dart';
import 'package:kindredpaws/services/backend_service.dart';
import 'package:kindredpaws/services/remote_config_service.dart';
import 'package:kindredpaws/heartmind/heartmind_service.dart';

void main() {
  setUp(ServiceLocator.instance.reset);

  group('bootstrap wiring (offline-safe defaults)', () {
    test('registers all core services with mock/offline defaults', () {
      final config = bootstrap();
      expect(config.usingMockBackend, isTrue);
      expect(config.heartmindLiveChatEnabled, isFalse);

      final sl = ServiceLocator.instance;
      expect(sl.get<AuthService>(), isA<GuestAuthService>());
      expect(sl.get<BackendService>().isAuthoritative, isFalse);
      expect(sl.get<HeartmindService>(), isA<StubHeartmind>());
      expect(sl.get<AnalyticsService>(), isA<InMemoryAnalyticsService>());
      expect(sl.get<RemoteConfigService>(), isA<DefaultRemoteConfig>());
    });

    test('service locator throws for unregistered types', () {
      expect(
        () => ServiceLocator.instance.get<AuthService>(),
        throwsStateError,
      );
    });
  });

  group(
    'canonical remote-config defaults (GAMEPLAY_AND_PROGRESSION_BIBLE §5.8)',
    () {
      test(
        'no-death floor, bond thresholds, and gated live chat are correct',
        () {
          const rc = DefaultRemoteConfig();
          expect(rc.getDouble('meter.floor'), 15.0);
          expect(rc.getInt('bond.stage_soulmate'), 10000);
          expect(rc.getBool('heartmind.live_chat_enabled'), isFalse);
          expect(rc.getInt('notifications.daily_cap'), 2);
        },
      );

      test('overrides win over defaults', () {
        const rc = DefaultRemoteConfig({'meter.floor': 12.0});
        expect(rc.getDouble('meter.floor'), 12.0);
      });

      test('unknown key is rejected', () {
        expect(
          () => const DefaultRemoteConfig().getDouble('nope'),
          throwsArgumentError,
        );
      });
    },
  );

  group('canonical terminology mirrors the brief', () {
    test('locked names + bond/life stages match the SSOT', () {
      expect(KindredTerms.gameTitle, 'KindredPaws');
      expect(KindredTerms.donationCurrency, 'Compassion Coins');
      expect(KindredTerms.bondStages.first, 'Stranger');
      expect(KindredTerms.bondStages.last, 'Soulmate');
      expect(KindredTerms.lifeStages, ['Pup/Kit', 'Young One', 'Grown']);
    });
  });
}
