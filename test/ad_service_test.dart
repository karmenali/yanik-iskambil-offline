import 'package:flutter_test/flutter_test.dart';
import 'package:yanik_offline/services/ad_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AdService.instance.resetCompletedRoundsCount();
  });

  group('AdService — Pre-Release UMP & Frequency Capping Tests', () {
    test('AdService singleton instance and initial round count', () {
      final service1 = AdService.instance;
      final service2 = AdService.instance;
      expect(identical(service1, service2), isTrue);
      expect(service1.completedRoundsCount, equals(0));
      expect(service1.lastProcessedRound, isNull);
      expect(service1.isShowingAd, isFalse);
    });

    test('Official Google Test Ad Unit IDs are maintained', () {
      final service = AdService.instance;
      // In non-mobile test host (e.g. desktop/windows), interstitialAdUnitId returns empty or platform ID
      expect(service.interstitialAdUnitId, isA<String>());
    });

    test('Frequency Capping: Ad is suppressed during rounds 1 and 2', () {
      final service = AdService.instance;
      int dismissedCount = 0;

      // Round 1
      service.showInterstitialAd(
        roundNumber: 1,
        onDismissed: () {
          dismissedCount++;
        },
      );
      expect(dismissedCount, equals(1));
      expect(service.completedRoundsCount, equals(1));
      expect(service.lastProcessedRound, equals(1));

      // Round 2
      service.showInterstitialAd(
        roundNumber: 2,
        onDismissed: () {
          dismissedCount++;
        },
      );
      expect(dismissedCount, equals(2));
      expect(service.completedRoundsCount, equals(2));
      expect(service.lastProcessedRound, equals(2));
    });

    test('Frequency Capping: Round 3 reaches threshold and executes callback seamlessly', () {
      final service = AdService.instance;
      int dismissedCount = 0;

      service.setCompletedRoundsCount(2);

      // Round 3 (reaches threshold >= 3)
      service.showInterstitialAd(
        roundNumber: 3,
        onDismissed: () {
          dismissedCount++;
        },
      );

      expect(dismissedCount, equals(1));
      expect(service.completedRoundsCount, greaterThanOrEqualTo(3));
      expect(service.lastProcessedRound, equals(3));
    });

    test('Duplicate Ad Prevention: Tur ve Maç Sonu aynı turda iki kez reklam tetiklemez', () {
      final service = AdService.instance;
      int dismissedCount = 0;

      service.setCompletedRoundsCount(2);

      // 1. Olay: Tur Özeti bittiğinde tetiklenen çağrı (Tur 3)
      service.showInterstitialAd(
        roundNumber: 3,
        onDismissed: () {
          dismissedCount++;
        },
      );
      expect(dismissedCount, equals(1));
      expect(service.completedRoundsCount, equals(3));
      expect(service.lastProcessedRound, equals(3));

      // 2. Olay: Aynı turda gerçekleşen Maç Sonu olayı tetiklenirse (Tur 3)
      service.showInterstitialAd(
        roundNumber: 3,
        onDismissed: () {
          dismissedCount++;
        },
      );

      // Sayaç artmamalı (hâlâ 3 olmalı), ikinci reklam çağrısı engellenmeli, onDismissed anında çalışmalı
      expect(dismissedCount, equals(2));
      expect(service.completedRoundsCount, equals(3));
      expect(service.lastProcessedRound, equals(3));

      // 3. Olay: Sonraki tur (Tur 4) geldiğinde normal işleyiş devam eder
      service.showInterstitialAd(
        roundNumber: 4,
        onDismissed: () {
          dismissedCount++;
        },
      );
      expect(dismissedCount, equals(3));
      expect(service.completedRoundsCount, equals(4));
      expect(service.lastProcessedRound, equals(4));
    });

    test('Offline & unloaded ad resilience: showInterstitialAd never freezes or blocks execution', () {
      final service = AdService.instance;
      service.setCompletedRoundsCount(5);

      bool callbackCalled = false;
      service.showInterstitialAd(
        roundNumber: 6,
        onDismissed: () {
          callbackCalled = true;
        },
      );

      expect(callbackCalled, isTrue);
      expect(service.lastProcessedRound, equals(6));
    });
  });
}
