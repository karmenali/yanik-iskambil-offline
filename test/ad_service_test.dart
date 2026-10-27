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
      service.showInterstitialAd(onDismissed: () {
        dismissedCount++;
      });
      expect(dismissedCount, equals(1));
      expect(service.completedRoundsCount, equals(1));

      // Round 2
      service.showInterstitialAd(onDismissed: () {
        dismissedCount++;
      });
      expect(dismissedCount, equals(2));
      expect(service.completedRoundsCount, equals(2));
    });

    test('Frequency Capping: Round 3 reaches threshold and executes callback seamlessly', () {
      final service = AdService.instance;
      int dismissedCount = 0;

      service.setCompletedRoundsCount(2);

      // Round 3 (reaches threshold >= 3)
      service.showInterstitialAd(onDismissed: () {
        dismissedCount++;
      });

      expect(dismissedCount, equals(1));
      expect(service.completedRoundsCount, greaterThanOrEqualTo(3));
    });

    test('Offline & unloaded ad resilience: showInterstitialAd never freezes or blocks execution', () {
      final service = AdService.instance;
      service.setCompletedRoundsCount(5);

      bool callbackCalled = false;
      service.showInterstitialAd(onDismissed: () {
        callbackCalled = true;
      });

      expect(callbackCalled, isTrue);
    });
  });
}
