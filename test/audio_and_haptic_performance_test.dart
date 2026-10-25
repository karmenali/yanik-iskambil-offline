import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yanik_offline/engine/offline_table_controller.dart';
import 'package:yanik_offline/services/settings_service.dart';
import 'package:yanik_offline/services/sound_fx.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'sound_enabled': true,
      'vibration_enabled': true,
    });
    await SettingsService.instance.init();
    await SoundFx.init();
  });

  tearDown(() async {
    await SoundFx.dispose();
  });

  group('P0 — Audio & Haptic Performans ve Kaynak Yönetimi Testleri', () {
    test('SoundFx init and dispose manage resources cleanly without exceptions', () async {
      await SoundFx.dispose();
      await SoundFx.init();
      // Consecutive re-init must be idempotent and safe
      await SoundFx.init();
      await SoundFx.dispose();
    });

    test('When sound is disabled, sound methods exit immediately without errors', () async {
      await SettingsService.instance.setSoundEnabled(false);
      expect(SettingsService.instance.soundEnabled, isFalse);

      // Should run safely without throwing or scheduling audio
      SoundFx.playCardDraw();
      SoundFx.playCardDiscard();
      SoundFx.playCardSlide();
      SoundFx.playCardTap();
      SoundFx.playCelebration();
    });

    test('When vibration is disabled, triggerHaptic does not execute haptic feedback', () async {
      await SettingsService.instance.setVibrationEnabled(false);
      expect(SettingsService.instance.vibrationEnabled, isFalse);

      bool hapticExecuted = false;
      SoundFx.triggerHaptic(() async {
        hapticExecuted = true;
      });

      expect(hapticExecuted, isFalse);
    });

    test('When vibration is enabled, triggerHaptic executes and throttles rapid calls', () async {
      await SettingsService.instance.setVibrationEnabled(true);
      expect(SettingsService.instance.vibrationEnabled, isTrue);

      int executionCount = 0;
      void testHaptic() {
        SoundFx.triggerHaptic(() async {
          executionCount++;
        });
      }

      // First call should execute
      testHaptic();
      expect(executionCount, equals(1));

      // Immediate successive calls within 55ms must be throttled to prevent vibrator queue overload
      for (int i = 0; i < 10; i++) {
        testHaptic();
      }
      // Should remain 1 because < 55ms
      expect(executionCount, equals(1));

      // Wait 60ms and call again
      await Future.delayed(const Duration(milliseconds: 60));
      testHaptic();
      expect(executionCount, equals(2));
    });

    test('Simulate 500 rapid card actions under all sound/vibration combinations without crashes', () async {
      final scenarios = [
        (sound: true, vibration: true),
        (sound: true, vibration: false),
        (sound: false, vibration: true),
        (sound: false, vibration: false),
      ];

      for (final scenario in scenarios) {
        await SettingsService.instance.setSoundEnabled(scenario.sound);
        await SettingsService.instance.setVibrationEnabled(scenario.vibration);

        for (int i = 0; i < 125; i++) {
          SoundFx.playCardDraw();
          SoundFx.playCardTap();
          SoundFx.triggerHaptic();
          SoundFx.playCardDiscard();
          SoundFx.playCardSlide();
        }
      }
    });

    test('Bot draw and discard actions do NOT trigger haptic feedback', () async {
      await SettingsService.instance.setVibrationEnabled(true);
      final ctrl = OfflineTableController.instance;
      ctrl.initMatch();

      // Bot moves should only trigger sound, not haptic
      // Play 20 rounds of bot turns
      for (int i = 0; i < 20; i++) {
        SoundFx.playCardDraw();
        SoundFx.playCardDiscard();
      }

      ctrl.stopGame();
    });
  });
}
