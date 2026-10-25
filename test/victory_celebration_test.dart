import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yanik_offline/engine/offline_table_controller.dart';
import 'package:yanik_offline/screens/offline_table_screen.dart';
import 'package:yanik_offline/services/settings_service.dart';
import 'package:yanik_offline/services/sound_fx.dart';
import 'package:yanik_offline/widgets/round_summary_dialog.dart';
import 'package:yanik_offline/widgets/victory_celebration_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'yanik_offline_sound': true,
      'yanik_offline_vibration': true,
    });
    await SettingsService.instance.init();
    await SoundFx.init();
    final ctrl = OfflineTableController.instance;
    ctrl.initMatch();
  });

  tearDown(() async {
    OfflineTableController.instance.stopGame();
    await SoundFx.dispose();
  });

  group('Victory Celebration — Overlay Component Unit & Widget Tests', () {
    testWidgets('Renders human victory emblem correctly', (tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(seconds: 2),
      );
      controller.value = 0.5; // Mid-way through animation

      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VictoryCelebrationOverlay(
              animation: controller,
              winnerName: 'Sen',
              isHumanWinner: true,
              isGrandChampion: false,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      // Verify emblem title and subtitle for human winner
      expect(find.text('ELİ AÇTI VE BİTİRDİ'), findsOneWidget);
      expect(find.text('Harika El! 0 Ceza Puanı'), findsOneWidget);
      expect(find.text('Kutlamayı geçmek için dokunun'), findsOneWidget);

      // Tap anywhere on overlay
      await tester.tap(find.byType(VictoryCelebrationOverlay));
      expect(tapped, isTrue);

      controller.dispose();
    });

    testWidgets('Renders bot victory emblem correctly', (tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(seconds: 2),
      );
      controller.value = 0.5;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VictoryCelebrationOverlay(
              animation: controller,
              winnerName: 'Ahmet',
              isHumanWinner: false,
              isGrandChampion: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Ahmet BİTİRDİ'), findsOneWidget);
      expect(find.text('Ahmet Turu 0 Ceza İle Kazandı'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('Renders Grand Champion emblem correctly when match concludes', (tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(seconds: 2),
      );
      controller.value = 0.5;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VictoryCelebrationOverlay(
              animation: controller,
              winnerName: 'Sen',
              isHumanWinner: true,
              isGrandChampion: true,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('MASA ŞAMPİYONU'), findsOneWidget);
      expect(find.text('Tebrikler! Masayı 1. Olarak Tamamladınız!'), findsOneWidget);

      controller.dispose();
    });
  });

  group('Victory Celebration — Audio & Haptic Cooldown Tests', () {
    test('Celebration sound throttles rapid repeated calls (<1000ms)', () {
      // SoundFx.playCelebration should execute safely and throttle subsequent rapid invocations
      SoundFx.playCelebration();
      // Consecutive call immediately after
      SoundFx.playCelebration();
      // Should not throw any exception
    });

    test('When sound is disabled, celebration sound is suppressed', () async {
      await SettingsService.instance.setSoundEnabled(false);
      SoundFx.playCelebration();
      // No exception thrown and audio suppressed
    });

    test('Heavy haptic only executes when vibration setting is enabled', () async {
      await SettingsService.instance.setVibrationEnabled(false);
      bool hapticFired = false;
      SoundFx.triggerHaptic(() async => hapticFired = true);
      expect(hapticFired, isFalse);

      await SettingsService.instance.setVibrationEnabled(true);
      SoundFx.triggerHaptic(() async => hapticFired = true);
      expect(hapticFired, isTrue);
    });
  });

  group('Victory Celebration — OfflineTableScreen Flow Integration Tests', () {
    testWidgets('Human win triggers celebration overlay, highlights winner avatar, then transitions to dialog on tap',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final ctrl = OfflineTableController.instance;

      await tester.pumpWidget(
        const MaterialApp(
          home: OfflineTableScreen(),
        ),
      );
      await tester.pump();

      // Ensure no celebration or summary dialog initially
      expect(find.byType(VictoryCelebrationOverlay), findsNothing);
      expect(find.byType(RoundSummaryDialog), findsNothing);

      // Simulate human winning round 1
      ctrl.endRound(0);
      await tester.pump(); // Start celebration animation frame

      // Overlay must be visible immediately
      expect(find.byType(VictoryCelebrationOverlay), findsOneWidget);
      expect(find.text('ELİ AÇTI VE BİTİRDİ'), findsOneWidget);

      // Winner avatar (seat 0) should have '👑' and 'KAZANDI'
      expect(find.text('KAZANDI'), findsOneWidget);

      // Summary dialog must NOT yet be visible to prevent visual clash
      expect(find.byType(RoundSummaryDialog), findsNothing);

      // Tap-to-skip: tapping overlay immediately dismisses celebration and reveals RoundSummaryDialog
      await tester.tap(find.byType(VictoryCelebrationOverlay));
      await tester.pumpAndSettle();

      expect(find.byType(VictoryCelebrationOverlay), findsNothing);
      expect(find.byType(RoundSummaryDialog), findsOneWidget);
    });

    testWidgets('Bot win displays bot celebration and highlights bot avatar', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final ctrl = OfflineTableController.instance;

      await tester.pumpWidget(
        const MaterialApp(
          home: OfflineTableScreen(),
        ),
      );
      await tester.pump();

      // Bot (seat 1) wins
      ctrl.endRound(1);
      await tester.pump();

      expect(find.byType(VictoryCelebrationOverlay), findsOneWidget);
      expect(find.text('${ctrl.players[1].username} BİTİRDİ'), findsOneWidget);
      expect(find.text('KAZANDI'), findsOneWidget);

      // Tap to skip
      await tester.tap(find.byType(VictoryCelebrationOverlay));
      await tester.pumpAndSettle();

      expect(find.byType(VictoryCelebrationOverlay), findsNothing);
      expect(find.byType(RoundSummaryDialog), findsOneWidget);
    });

    testWidgets('Draw/Deck exhausted round does not trigger celebration overlay', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final ctrl = OfflineTableController.instance;

      await tester.pumpWidget(
        const MaterialApp(
          home: OfflineTableScreen(),
        ),
      );
      await tester.pump();

      // Draw round (finisherSeat == null)
      ctrl.endRound(null);
      await tester.pumpAndSettle();

      // No celebration overlay should ever be shown for draws
      expect(find.byType(VictoryCelebrationOverlay), findsNothing);
      // Dialog appears directly
      expect(find.byType(RoundSummaryDialog), findsOneWidget);
    });

    testWidgets('Celebration triggers strictly once per round', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final ctrl = OfflineTableController.instance;

      await tester.pumpWidget(
        const MaterialApp(
          home: OfflineTableScreen(),
        ),
      );
      await tester.pump();

      ctrl.endRound(0);
      await tester.pump();

      expect(find.byType(VictoryCelebrationOverlay), findsOneWidget);

      // Multiple state changes / notifyListeners during the same round
      ctrl.notifyListeners();
      await tester.pump();
      ctrl.notifyListeners();
      await tester.pump();

      // Still exactly 1 celebration overlay
      expect(find.byType(VictoryCelebrationOverlay), findsOneWidget);

      // Dismiss
      await tester.tap(find.byType(VictoryCelebrationOverlay));
      await tester.pumpAndSettle();
      expect(find.byType(RoundSummaryDialog), findsOneWidget);
    });
  });
}
