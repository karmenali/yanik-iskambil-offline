import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yanik_offline/engine/card_model.dart';
import 'package:yanik_offline/engine/offline_table_controller.dart';
import 'package:yanik_offline/screens/home_screen.dart';
import 'package:yanik_offline/screens/offline_table_screen.dart';
import 'package:yanik_offline/screens/rules_dialog.dart';
import 'package:yanik_offline/screens/settings_dialog.dart';
import 'package:yanik_offline/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'yanik_offline_sound': false,
      'yanik_offline_vibration': false,
    });
    await SettingsService.instance.init();
    final ctrl = OfflineTableController.instance;
    ctrl.initMatch();
  });

  tearDown(() {
    OfflineTableController.instance.stopGame();
  });

  group('Accessibility: Touch Targets >= 48x48 dp', () {
    testWidgets('Top bar icon buttons have at least 48x48 dp touch target size',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: OfflineTableScreen(),
        ),
      );
      await tester.pump();

      // Back button touch target
      final backInkWell = find.ancestor(
        of: find.byIcon(Icons.arrow_back_ios_new_rounded),
        matching: find.byType(InkWell),
      );
      expect(backInkWell, findsOneWidget);
      final backSize = tester.getSize(backInkWell);
      expect(backSize.width, greaterThanOrEqualTo(48.0));
      expect(backSize.height, greaterThanOrEqualTo(48.0));

      // Settings button touch target
      final settingsInkWell = find.ancestor(
        of: find.byIcon(Icons.settings),
        matching: find.byType(InkWell),
      );
      expect(settingsInkWell, findsOneWidget);
      final settingsSize = tester.getSize(settingsInkWell);
      expect(settingsSize.width, greaterThanOrEqualTo(48.0));
      expect(settingsSize.height, greaterThanOrEqualTo(48.0));

      // 101 Scoreboard button touch target
      final scoreboardInkWell = find.ancestor(
        of: find.byIcon(Icons.leaderboard),
        matching: find.byType(InkWell),
      );
      expect(scoreboardInkWell, findsOneWidget);
      final scoreboardSize = tester.getSize(scoreboardInkWell);
      expect(scoreboardSize.width, greaterThanOrEqualTo(48.0));
      expect(scoreboardSize.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('Bottom 4 Zynga action buttons have at least 48 dp height',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: OfflineTableScreen(),
        ),
      );
      await tester.pump();

      final finishButton = find.textContaining('EL AÇ');
      expect(finishButton, findsOneWidget);

      final finishContainer = find.ancestor(
        of: finishButton,
        matching: find.byType(AnimatedContainer),
      );
      final size = tester.getSize(finishContainer);
      expect(size.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('Home screen header and dialog close icon buttons have >= 48x48 dp touch target',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pump();

      // Kurallar button
      final rulesBtn = find.widgetWithIcon(IconButton, Icons.menu_book_rounded);
      expect(rulesBtn, findsOneWidget);
      final rulesSize = tester.getSize(rulesBtn);
      expect(rulesSize.width, greaterThanOrEqualTo(48.0));
      expect(rulesSize.height, greaterThanOrEqualTo(48.0));

      // Ayarlar button
      final settingsBtn = find.widgetWithIcon(IconButton, Icons.settings);
      expect(settingsBtn, findsOneWidget);
      final settingsSize = tester.getSize(settingsBtn);
      expect(settingsSize.width, greaterThanOrEqualTo(48.0));
      expect(settingsSize.height, greaterThanOrEqualTo(48.0));

      // Settings dialog close button
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SettingsDialog()),
        ),
      );
      await tester.pump();
      final closeBtn = find.widgetWithIcon(IconButton, Icons.close);
      expect(closeBtn, findsOneWidget);
      final closeSize = tester.getSize(closeBtn);
      expect(closeSize.width, greaterThanOrEqualTo(48.0));
      expect(closeSize.height, greaterThanOrEqualTo(48.0));

      // Rules dialog close button
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: RulesDialog()),
        ),
      );
      await tester.pump();
      final rulesCloseBtn = find.widgetWithIcon(IconButton, Icons.close);
      expect(rulesCloseBtn, findsOneWidget);
      final rulesCloseSize = tester.getSize(rulesCloseBtn);
      expect(rulesCloseSize.width, greaterThanOrEqualTo(48.0));
      expect(rulesCloseSize.height, greaterThanOrEqualTo(48.0));
    });
  });

  group('Unassisted Mode False Finish Confirmation Dialog', () {
    testWidgets('Unassisted mode invalid finish shows warning dialog; cancel preserves game state',
        (WidgetTester tester) async {
      final ctrl = OfflineTableController.instance;
      await SettingsService.instance.setAssisted(false);
      ctrl.status = 'playing';
      ctrl.currentTurnSeat = 0;
      ctrl.hasDrawnThisTurn = true;

      // Incomplete/deadwood hand with 11 cards
      final hand = [
        const CardModel(id: 'c1', suit: 'H', rank: 2, deckIndex: 0, isPhysicalJoker: false),
        const CardModel(id: 'c2', suit: 'S', rank: 4, deckIndex: 0, isPhysicalJoker: false),
        const CardModel(id: 'c3', suit: 'D', rank: 6, deckIndex: 0, isPhysicalJoker: false),
        const CardModel(id: 'c4', suit: 'C', rank: 8, deckIndex: 0, isPhysicalJoker: false),
        const CardModel(id: 'c5', suit: 'H', rank: 10, deckIndex: 0, isPhysicalJoker: false),
        const CardModel(id: 'c6', suit: 'S', rank: 12, deckIndex: 0, isPhysicalJoker: false),
        const CardModel(id: 'c7', suit: 'D', rank: 1, deckIndex: 0, isPhysicalJoker: false),
        const CardModel(id: 'c8', suit: 'C', rank: 3, deckIndex: 0, isPhysicalJoker: false),
        const CardModel(id: 'c9', suit: 'H', rank: 5, deckIndex: 0, isPhysicalJoker: false),
        const CardModel(id: 'c10', suit: 'S', rank: 7, deckIndex: 0, isPhysicalJoker: false),
        const CardModel(id: 'c11', suit: 'D', rank: 9, deckIndex: 0, isPhysicalJoker: false),
      ];
      ctrl.players[0].hand = List.from(hand);
      ctrl.humanRows = [
        [hand[0], hand[1], hand[2], hand[3]],
        [hand[4], hand[5], hand[6], hand[7]],
        [hand[8], hand[9], hand[10]],
      ];
      ctrl.selectedCardId = 'c11';

      expect(ctrl.willHumanFinishCausePenalty(), isTrue);

      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: OfflineTableScreen(),
        ),
      );
      await tester.pump();

      // Tap EL AÇ BİTİR
      final finishBtn = find.textContaining('EL AÇ');
      await tester.tap(finishBtn);
      await tester.pumpAndSettle();

      // Confirmation dialog must appear with exact required text
      expect(
        find.text('Geçersiz el açarsanız 101 ceza alacaksınız. Devam etmek istiyor musunuz?'),
        findsOneWidget,
      );
      expect(find.text('Vazgeç'), findsOneWidget);
      expect(find.text('Devam Et'), findsOneWidget);

      // Tap "Vazgeç"
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();

      // Dialog dismissed
      expect(
        find.text('Geçersiz el açarsanız 101 ceza alacaksınız. Devam etmek istiyor musunuz?'),
        findsNothing,
      );

      // State is completely intact
      expect(ctrl.status, equals('playing'));
      expect(ctrl.players[0].hand.length, equals(11));
      expect(ctrl.players[0].totalScore, equals(0));
    });

    testWidgets('Unassisted mode invalid finish: confirming applies 101 penalty',
        (WidgetTester tester) async {
      final ctrl = OfflineTableController.instance;
      await SettingsService.instance.setAssisted(false);
      ctrl.status = 'playing';
      ctrl.currentTurnSeat = 0;
      ctrl.hasDrawnThisTurn = true;

      final hand = [
        const CardModel(id: 'c1', suit: 'H', rank: 2, deckIndex: 0, isPhysicalJoker: false),
        const CardModel(id: 'c2', suit: 'S', rank: 4, deckIndex: 0, isPhysicalJoker: false),
        const CardModel(id: 'c3', suit: 'D', rank: 6, deckIndex: 0, isPhysicalJoker: false),
        const CardModel(id: 'c4', suit: 'C', rank: 8, deckIndex: 0, isPhysicalJoker: false),
        const CardModel(id: 'c5', suit: 'H', rank: 10, deckIndex: 0, isPhysicalJoker: false),
        const CardModel(id: 'c6', suit: 'S', rank: 12, deckIndex: 0, isPhysicalJoker: false),
        const CardModel(id: 'c7', suit: 'D', rank: 1, deckIndex: 0, isPhysicalJoker: false),
        const CardModel(id: 'c8', suit: 'C', rank: 3, deckIndex: 0, isPhysicalJoker: false),
        const CardModel(id: 'c9', suit: 'H', rank: 5, deckIndex: 0, isPhysicalJoker: false),
        const CardModel(id: 'c10', suit: 'S', rank: 7, deckIndex: 0, isPhysicalJoker: false),
        const CardModel(id: 'c11', suit: 'D', rank: 9, deckIndex: 0, isPhysicalJoker: false),
      ];
      ctrl.players[0].hand = List.from(hand);
      ctrl.humanRows = [
        [hand[0], hand[1], hand[2], hand[3]],
        [hand[4], hand[5], hand[6], hand[7]],
        [hand[8], hand[9], hand[10]],
      ];
      ctrl.selectedCardId = 'c11';

      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: OfflineTableScreen(),
        ),
      );
      await tester.pump();

      // Tap EL AÇ BİTİR
      final finishBtn = find.textContaining('EL AÇ');
      await tester.tap(finishBtn);
      await tester.pumpAndSettle();

      // Confirm
      await tester.tap(find.text('Devam Et'));
      await tester.pumpAndSettle();

      // Round summary reached and false declarer received 101 penalty
      expect(ctrl.status, equals('round_summary'));
      expect(ctrl.lastFalseDeclarerSeat, equals(0));
      expect(ctrl.players[0].totalScore, equals(101));
      expect(ctrl.players[1].totalScore, equals(0));
      expect(ctrl.players[2].totalScore, equals(0));
      expect(ctrl.players[3].totalScore, equals(0));
    });

    testWidgets('Unassisted mode valid finish does NOT show warning dialog',
        (WidgetTester tester) async {
      final ctrl = OfflineTableController.instance;
      await SettingsService.instance.setAssisted(false);
      ctrl.status = 'playing';
      ctrl.currentTurnSeat = 0;
      ctrl.hasDrawnThisTurn = true;

      // Perfectly melded hand: 3 melds of (3 + 3 + 4) = 10 cards + 1 discard
      final row0 = [
        const CardModel(id: 'm1', suit: 'H', rank: 7, deckIndex: 0, isPhysicalJoker: false),
        const CardModel(id: 'm2', suit: 'H', rank: 8, deckIndex: 0, isPhysicalJoker: false),
        const CardModel(id: 'm3', suit: 'H', rank: 9, deckIndex: 0, isPhysicalJoker: false),
      ];
      final row1 = [
        const CardModel(id: 'm4', suit: 'D', rank: 5, deckIndex: 0, isPhysicalJoker: false),
        const CardModel(id: 'm5', suit: 'C', rank: 5, deckIndex: 0, isPhysicalJoker: false),
        const CardModel(id: 'm6', suit: 'S', rank: 5, deckIndex: 0, isPhysicalJoker: false),
      ];
      final row2 = [
        const CardModel(id: 'm7', suit: 'S', rank: 1, deckIndex: 0, isPhysicalJoker: false),
        const CardModel(id: 'm8', suit: 'S', rank: 2, deckIndex: 0, isPhysicalJoker: false),
        const CardModel(id: 'm9', suit: 'S', rank: 3, deckIndex: 0, isPhysicalJoker: false),
        const CardModel(id: 'm10', suit: 'S', rank: 4, deckIndex: 0, isPhysicalJoker: false),
        const CardModel(id: 'd1', suit: 'C', rank: 13, deckIndex: 0, isPhysicalJoker: false), // Discard
      ];

      ctrl.players[0].hand = [...row0, ...row1, ...row2];
      ctrl.humanRows = [List.from(row0), List.from(row1), List.from(row2)];
      ctrl.selectedCardId = 'd1';

      expect(ctrl.willHumanFinishCausePenalty(), isFalse);

      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: OfflineTableScreen(),
        ),
      );
      await tester.pump();

      // Tap EL AÇ BİTİR
      final finishBtn = find.textContaining('EL AÇ');
      await tester.tap(finishBtn);
      await tester.pumpAndSettle();

      // No confirmation dialog was shown
      expect(
        find.text('Geçersiz el açarsanız 101 ceza alacaksınız. Devam etmek istiyor musunuz?'),
        findsNothing,
      );
      // Valid finish applied directly
      expect(ctrl.status, equals('round_summary'));
      expect(ctrl.lastFinisherSeat, equals(0));
      expect(ctrl.lastFalseDeclarerSeat, isNull);
    });

    testWidgets('Assisted mode behavior is completely unchanged (no warning dialog)',
        (WidgetTester tester) async {
      final ctrl = OfflineTableController.instance;
      await SettingsService.instance.setAssisted(true);
      ctrl.status = 'playing';
      ctrl.currentTurnSeat = 0;
      ctrl.hasDrawnThisTurn = true;

      // 10 melded + 1 discard
      final row0 = [
        const CardModel(id: 'm1', suit: 'H', rank: 7, deckIndex: 0, isPhysicalJoker: false),
        const CardModel(id: 'm2', suit: 'H', rank: 8, deckIndex: 0, isPhysicalJoker: false),
        const CardModel(id: 'm3', suit: 'H', rank: 9, deckIndex: 0, isPhysicalJoker: false),
      ];
      final row1 = [
        const CardModel(id: 'm4', suit: 'D', rank: 5, deckIndex: 0, isPhysicalJoker: false),
        const CardModel(id: 'm5', suit: 'C', rank: 5, deckIndex: 0, isPhysicalJoker: false),
        const CardModel(id: 'm6', suit: 'S', rank: 5, deckIndex: 0, isPhysicalJoker: false),
      ];
      final row2 = [
        const CardModel(id: 'm7', suit: 'S', rank: 1, deckIndex: 0, isPhysicalJoker: false),
        const CardModel(id: 'm8', suit: 'S', rank: 2, deckIndex: 0, isPhysicalJoker: false),
        const CardModel(id: 'm9', suit: 'S', rank: 3, deckIndex: 0, isPhysicalJoker: false),
        const CardModel(id: 'm10', suit: 'S', rank: 4, deckIndex: 0, isPhysicalJoker: false),
        const CardModel(id: 'd1', suit: 'C', rank: 13, deckIndex: 0, isPhysicalJoker: false),
      ];

      ctrl.players[0].hand = [...row0, ...row1, ...row2];
      ctrl.humanRows = [List.from(row0), List.from(row1), List.from(row2)];
      ctrl.selectedCardId = 'd1';

      expect(ctrl.willHumanFinishCausePenalty(), isFalse);

      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: OfflineTableScreen(),
        ),
      );
      await tester.pump();

      // Tap EL AÇ BİTİR
      final finishBtn = find.textContaining('EL AÇ');
      await tester.tap(finishBtn);
      await tester.pumpAndSettle();

      // Direct finish with zero dialog
      expect(
        find.text('Geçersiz el açarsanız 101 ceza alacaksınız. Devam etmek istiyor musunuz?'),
        findsNothing,
      );
      expect(ctrl.status, equals('round_summary'));
      expect(ctrl.lastFinisherSeat, equals(0));
    });
  });
}
