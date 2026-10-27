import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yanik_offline/engine/card_model.dart';
import 'package:yanik_offline/engine/offline_table_controller.dart';
import 'package:yanik_offline/l10n/app_localizations.dart';
import 'package:yanik_offline/screens/home_screen.dart';
import 'package:yanik_offline/screens/offline_table_screen.dart';
import 'package:yanik_offline/screens/rules_dialog.dart';
import 'package:yanik_offline/screens/settings_dialog.dart';
import 'package:yanik_offline/services/settings_service.dart';
import 'package:yanik_offline/services/sound_fx.dart';
import 'package:yanik_offline/widgets/round_summary_dialog.dart';
import 'package:yanik_offline/widgets/victory_celebration_overlay.dart';

Widget _buildLocalizedApp(Widget home) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}

CardModel _card(String id, String suit, int rank) {
  return CardModel(
    id: id,
    suit: suit,
    rank: rank,
    deckIndex: 0,
    isPhysicalJoker: false,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'yanik_offline_sound': false,
      'yanik_offline_vibration': false,
      'yanik_offline_language': 'en',
    });
    await SettingsService.instance.init();
    await SettingsService.instance.setLanguageCode('en');
    await SoundFx.init();
    OfflineTableController.instance.initMatch();
  });

  tearDown(() async {
    OfflineTableController.instance.stopGame();
    await SoundFx.dispose();
  });

  group('İngilizce Arayüz Küçük Ekran (320x568 dp) Taşma ve Görsel Okunabilirlik Testleri', () {
    testWidgets('1. HomeScreen İngilizce modda 320x568 dp ekranda taşma yapmaz', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildLocalizedApp(const HomeScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('PLAY'), findsOneWidget);
      expect(find.text('Assisted Mode'), findsOneWidget);
    });

    testWidgets('2. SettingsDialog İngilizce modda 320x568 dp ekranda taşma yapmaz', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildLocalizedApp(const Scaffold(body: SettingsDialog())));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Game Settings'), findsOneWidget);
      expect(find.text('SAVE & RETURN'), findsOneWidget);
    });

    testWidgets('3. RulesDialog İngilizce modda 320x568 dp ekranda taşma yapmaz', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildLocalizedApp(const Scaffold(body: RulesDialog())));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('How to Play (Rules)'), findsOneWidget);
      expect(find.text('GOT IT'), findsOneWidget);
    });

    testWidgets('4. OfflineTableScreen İngilizce modda 320x568 dp ekranda taşma yapmaz', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildLocalizedApp(const OfflineTableScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // Zynga 3D butonlarının metinleri
      expect(find.text('DECLARE\nFINISH'), findsWidgets);
      expect(find.text('AUTO\nSORT'), findsOneWidget);
    });

    testWidgets('5. RoundSummaryDialog İngilizce modda 320x568 dp ekranda taşma yapmaz', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockResults = [
        ShowdownPlayerResult(
          userId: 'human',
          username: 'Player',
          avatar: 'lion',
          seatIndex: 0,
          isFinisher: true,
          isFalseDeclarer: false,
          melds: [
            [_card('H7', 'H', 7), _card('H8', 'H', 8), _card('H9', 'H', 9)],
            [_card('S10', 'S', 10), _card('S11', 'S', 11), _card('S12', 'S', 12)],
          ],
          unmelded: [],
          roundPenalty: 0,
          previousScore: 10,
          newTotalScore: 10,
          burnedThisRound: false,
        ),
        ShowdownPlayerResult(
          userId: 'bot_1',
          username: 'Ahmet',
          avatar: 'king',
          seatIndex: 1,
          isFinisher: false,
          isFalseDeclarer: false,
          melds: [],
          unmelded: [_card('D10', 'D', 10), _card('C5', 'C', 5)],
          roundPenalty: 15,
          previousScore: 20,
          newTotalScore: 35,
          burnedThisRound: false,
        ),
      ];

      await tester.pumpWidget(
        _buildLocalizedApp(
          Scaffold(
            body: RoundSummaryDialog(
              results: mockResults,
              wildRank: 5,
              roundNumber: 2,
              winnerMessage: null,
              onPlayAgain: () {},
              onContinue: () {},
              onMainMenu: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('CONTINUE ➜'), findsOneWidget);
      expect(find.text('MELD 1'), findsOneWidget);
      expect(find.text('MELD 2'), findsOneWidget);
    });

    testWidgets('6. VictoryCelebrationOverlay İngilizce modda 320x568 dp ekranda taşma yapmaz', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(seconds: 2),
      );
      controller.value = 0.8;

      await tester.pumpWidget(
        _buildLocalizedApp(
          Scaffold(
            body: VictoryCelebrationOverlay(
              animation: controller,
              winnerName: 'Player',
              isHumanWinner: true,
              isGrandChampion: true,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('TABLE CHAMPION'), findsOneWidget);
      expect(find.text('Tap anywhere to skip'), findsOneWidget);

      controller.dispose();
    });
  });
}
