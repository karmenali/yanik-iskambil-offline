import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yanik_offline/engine/card_model.dart';
import 'package:yanik_offline/engine/offline_table_controller.dart';
import 'package:yanik_offline/screens/offline_table_screen.dart';
import 'package:yanik_offline/services/settings_service.dart';
import 'package:yanik_offline/widgets/playing_card_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'yanik_offline_sound': false,
      'yanik_offline_vibration': false,
      'yanik_offline_assisted': false,
    });
    await SettingsService.instance.init();
    final ctrl = OfflineTableController.instance;
    ctrl.initMatch();
  });

  tearDown(() {
    OfflineTableController.instance.stopGame();
  });

  group('Section B: Discard Candidate Detection Unit Tests', () {
    test('Unassisted Mode: Exactly 1 valid discard candidate detected', () {
      final ctrl = OfflineTableController.instance;
      ctrl.status = 'playing';
      ctrl.currentTurnSeat = 0;
      ctrl.hasDrawnThisTurn = true;
      ctrl.wildRank = 2;

      // Melds:
      // Row 0: H7, H8, H9 (3)
      // Row 1: D5, C5, S5 (3)
      // Row 2: S1, S2, S3, S4 (4) + CK (1 extra discard)
      final row0 = [
        const CardModel(id: 'h7', suit: 'H', rank: 7, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'h8', suit: 'H', rank: 8, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'h9', suit: 'H', rank: 9, deckIndex: 1, isPhysicalJoker: false),
      ];
      final row1 = [
        const CardModel(id: 'd5', suit: 'D', rank: 5, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'c5', suit: 'C', rank: 5, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 's5', suit: 'S', rank: 5, deckIndex: 1, isPhysicalJoker: false),
      ];
      final row2 = [
        const CardModel(id: 's1', suit: 'S', rank: 1, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 's2', suit: 'S', rank: 2, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 's3', suit: 'S', rank: 3, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 's4', suit: 'S', rank: 4, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'ck', suit: 'C', rank: 13, deckIndex: 1, isPhysicalJoker: false),
      ];

      ctrl.players[0].hand = [...row0, ...row1, ...row2];
      ctrl.humanRows = [List.from(row0), List.from(row1), List.from(row2)];
      ctrl.selectedCardId = null;

      final candidates = ctrl.getValidDiscardCandidates();
      expect(candidates.length, equals(1));
      expect(candidates.first.id, equals('ck'));
      expect(ctrl.willHumanFinishCausePenalty(), isFalse);
    });

    test('Unassisted Mode: Multiple valid discard candidates detected', () {
      final ctrl = OfflineTableController.instance;
      ctrl.status = 'playing';
      ctrl.currentTurnSeat = 0;
      ctrl.hasDrawnThisTurn = true;
      ctrl.wildRank = 1;

      // Row 0: H7, H8, H9, H10, HJ (5 cards run - discarding H7 or HJ leaves a valid 4-card run!)
      // Row 1: DK, CK, SK (3 cards set)
      // Row 2: D4, C4, S4 (3 cards set)
      final row0 = [
        const CardModel(id: 'h7', suit: 'H', rank: 7, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'h8', suit: 'H', rank: 8, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'h9', suit: 'H', rank: 9, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'h10', suit: 'H', rank: 10, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'hj', suit: 'H', rank: 11, deckIndex: 1, isPhysicalJoker: false),
      ];
      final row1 = [
        const CardModel(id: 'dk', suit: 'D', rank: 13, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'ck', suit: 'C', rank: 13, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'sk', suit: 'S', rank: 13, deckIndex: 1, isPhysicalJoker: false),
      ];
      final row2 = [
        const CardModel(id: 'd4', suit: 'D', rank: 4, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'c4', suit: 'C', rank: 4, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 's4', suit: 'S', rank: 4, deckIndex: 1, isPhysicalJoker: false),
      ];

      ctrl.players[0].hand = [...row0, ...row1, ...row2];
      ctrl.humanRows = [List.from(row0), List.from(row1), List.from(row2)];
      ctrl.selectedCardId = null;

      final candidates = ctrl.getValidDiscardCandidates();
      expect(candidates.length, greaterThanOrEqualTo(2));
      final candIds = candidates.map((c) => c.id).toSet();
      expect(candIds.contains('h7'), isTrue);
      expect(candIds.contains('hj'), isTrue);
      expect(ctrl.willHumanFinishCausePenalty(), isFalse);
    });

    test('Unassisted Mode: Invalid hand returns empty candidates and willHumanFinishCausePenalty is true', () {
      final ctrl = OfflineTableController.instance;
      ctrl.status = 'playing';
      ctrl.currentTurnSeat = 0;
      ctrl.hasDrawnThisTurn = true;
      ctrl.wildRank = 2;

      // 11 unrelated cards with NO melds possible:
      final hand = [
        const CardModel(id: 'c1', suit: 'S', rank: 3, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'c2', suit: 'H', rank: 6, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'c3', suit: 'D', rank: 9, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'c4', suit: 'C', rank: 12, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'c5', suit: 'S', rank: 1, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'c6', suit: 'H', rank: 4, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'c7', suit: 'D', rank: 7, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'c8', suit: 'C', rank: 10, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'c9', suit: 'S', rank: 8, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'c10', suit: 'H', rank: 11, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'c11', suit: 'D', rank: 13, deckIndex: 1, isPhysicalJoker: false),
      ];
      ctrl.players[0].hand = List.from(hand);
      ctrl.humanRows = [hand.sublist(0, 4), hand.sublist(4, 8), hand.sublist(8, 11)];
      ctrl.selectedCardId = null;

      final candidates = ctrl.getValidDiscardCandidates();
      expect(candidates, isEmpty);
      expect(ctrl.willHumanFinishCausePenalty(), isTrue);
    });

    test('humanDeclareFinish auto-selects single candidate when selectedCardId is null', () {
      final ctrl = OfflineTableController.instance;
      ctrl.status = 'playing';
      ctrl.currentTurnSeat = 0;
      ctrl.hasDrawnThisTurn = true;
      ctrl.wildRank = 2;

      final row0 = [
        const CardModel(id: 'h7', suit: 'H', rank: 7, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'h8', suit: 'H', rank: 8, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'h9', suit: 'H', rank: 9, deckIndex: 1, isPhysicalJoker: false),
      ];
      final row1 = [
        const CardModel(id: 'd5', suit: 'D', rank: 5, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'c5', suit: 'C', rank: 5, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 's5', suit: 'S', rank: 5, deckIndex: 1, isPhysicalJoker: false),
      ];
      final row2 = [
        const CardModel(id: 's1', suit: 'S', rank: 1, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 's2', suit: 'S', rank: 2, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 's3', suit: 'S', rank: 3, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 's4', suit: 'S', rank: 4, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'ck', suit: 'C', rank: 13, deckIndex: 1, isPhysicalJoker: false),
      ];

      ctrl.players[0].hand = [...row0, ...row1, ...row2];
      ctrl.humanRows = [List.from(row0), List.from(row1), List.from(row2)];
      ctrl.selectedCardId = null;

      ctrl.humanDeclareFinish();

      expect(ctrl.status, equals('round_summary'));
      expect(ctrl.lastFinisherSeat, equals(0));
      expect(ctrl.lastFalseDeclarerSeat, isNull);
      expect(ctrl.discardPile.last.id, equals('ck'));
    });
  });

  group('Section B: Discard Selection UI & Widget Flow Tests', () {
    testWidgets('Unassisted Mode: Single candidate auto-finishes without showing bottom sheet',
        (WidgetTester tester) async {
      final ctrl = OfflineTableController.instance;
      await SettingsService.instance.setAssisted(false);
      ctrl.status = 'playing';
      ctrl.currentTurnSeat = 0;
      ctrl.hasDrawnThisTurn = true;
      ctrl.wildRank = 2;

      final row0 = [
        const CardModel(id: 'h7', suit: 'H', rank: 7, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'h8', suit: 'H', rank: 8, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'h9', suit: 'H', rank: 9, deckIndex: 1, isPhysicalJoker: false),
      ];
      final row1 = [
        const CardModel(id: 'd5', suit: 'D', rank: 5, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'c5', suit: 'C', rank: 5, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 's5', suit: 'S', rank: 5, deckIndex: 1, isPhysicalJoker: false),
      ];
      final row2 = [
        const CardModel(id: 's1', suit: 'S', rank: 1, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 's2', suit: 'S', rank: 2, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 's3', suit: 'S', rank: 3, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 's4', suit: 'S', rank: 4, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'ck', suit: 'C', rank: 13, deckIndex: 1, isPhysicalJoker: false),
      ];

      ctrl.players[0].hand = [...row0, ...row1, ...row2];
      ctrl.humanRows = [List.from(row0), List.from(row1), List.from(row2)];
      ctrl.selectedCardId = null; // No card selected!

      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(home: OfflineTableScreen()),
      );
      await tester.pump();

      // Tap EL AÇ BİTİR
      final finishBtn = find.textContaining('EL AÇ');
      await tester.tap(finishBtn);
      await tester.pumpAndSettle();

      // No bottom sheet or false finish warning dialog
      expect(find.text('Atılacak Kartı Seçin'), findsNothing);
      expect(find.text('Hatalı El Açma Uyarısı'), findsNothing);

      // Clean finish achieved!
      expect(ctrl.status, equals('round_summary'));
      expect(ctrl.lastFinisherSeat, equals(0));
      expect(ctrl.lastFalseDeclarerSeat, isNull);
    });

    testWidgets('Unassisted Mode: Multiple candidates opens bottom sheet; selecting card declares finish',
        (WidgetTester tester) async {
      final ctrl = OfflineTableController.instance;
      await SettingsService.instance.setAssisted(false);
      ctrl.status = 'playing';
      ctrl.currentTurnSeat = 0;
      ctrl.hasDrawnThisTurn = true;
      ctrl.wildRank = 1;

      // 5-card run: H7, H8, H9, H10, HJ
      final row0 = [
        const CardModel(id: 'h7', suit: 'H', rank: 7, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'h8', suit: 'H', rank: 8, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'h9', suit: 'H', rank: 9, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'h10', suit: 'H', rank: 10, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'hj', suit: 'H', rank: 11, deckIndex: 1, isPhysicalJoker: false),
      ];
      final row1 = [
        const CardModel(id: 'dk', suit: 'D', rank: 13, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'ck', suit: 'C', rank: 13, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'sk', suit: 'S', rank: 13, deckIndex: 1, isPhysicalJoker: false),
      ];
      final row2 = [
        const CardModel(id: 'd4', suit: 'D', rank: 4, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'c4', suit: 'C', rank: 4, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 's4', suit: 'S', rank: 4, deckIndex: 1, isPhysicalJoker: false),
      ];

      ctrl.players[0].hand = [...row0, ...row1, ...row2];
      ctrl.humanRows = [List.from(row0), List.from(row1), List.from(row2)];
      ctrl.selectedCardId = null;

      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(home: OfflineTableScreen()),
      );
      await tester.pump();

      // Tap EL AÇ BİTİR
      final finishBtn = find.textContaining('EL AÇ');
      await tester.tap(finishBtn);
      await tester.pumpAndSettle();

      // Bottom sheet is now open!
      expect(find.text('Atılacak Kartı Seçin'), findsOneWidget);
      expect(find.text('Elinizi açıp bitirmek için masaya atmak istediğiniz kartı seçin:'), findsOneWidget);

      // Verify candidates are rendered as PlayingCardWidgets in sheet
      final cardWidgets = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(PlayingCardWidget),
      );
      expect(cardWidgets, findsAtLeastNWidgets(2));

      // Tap the first candidate card in bottom sheet
      await tester.tap(cardWidgets.first);
      await tester.pumpAndSettle();

      // Round finished cleanly with chosen card!
      expect(ctrl.status, equals('round_summary'));
      expect(ctrl.lastFinisherSeat, equals(0));
      expect(ctrl.lastFalseDeclarerSeat, isNull);
    });

    testWidgets('Multiple candidates: Tapping "Vazgeç" preserves hand and cancels finish without penalty',
        (WidgetTester tester) async {
      final ctrl = OfflineTableController.instance;
      await SettingsService.instance.setAssisted(false);
      ctrl.status = 'playing';
      ctrl.currentTurnSeat = 0;
      ctrl.hasDrawnThisTurn = true;
      ctrl.wildRank = 1;

      final row0 = [
        const CardModel(id: 'h7', suit: 'H', rank: 7, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'h8', suit: 'H', rank: 8, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'h9', suit: 'H', rank: 9, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'h10', suit: 'H', rank: 10, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'hj', suit: 'H', rank: 11, deckIndex: 1, isPhysicalJoker: false),
      ];
      final row1 = [
        const CardModel(id: 'dk', suit: 'D', rank: 13, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'ck', suit: 'C', rank: 13, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'sk', suit: 'S', rank: 13, deckIndex: 1, isPhysicalJoker: false),
      ];
      final row2 = [
        const CardModel(id: 'd4', suit: 'D', rank: 4, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'c4', suit: 'C', rank: 4, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 's4', suit: 'S', rank: 4, deckIndex: 1, isPhysicalJoker: false),
      ];

      ctrl.players[0].hand = [...row0, ...row1, ...row2];
      ctrl.humanRows = [List.from(row0), List.from(row1), List.from(row2)];
      ctrl.selectedCardId = null;

      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(home: OfflineTableScreen()),
      );
      await tester.pump();

      // Tap EL AÇ BİTİR
      final finishBtn = find.textContaining('EL AÇ');
      await tester.tap(finishBtn);
      await tester.pumpAndSettle();

      expect(find.text('Atılacak Kartı Seçin'), findsOneWidget);

      // Tap Vazgeç button inside bottom sheet
      final cancelBtn = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.widgetWithText(OutlinedButton, 'Vazgeç'),
      );
      expect(cancelBtn, findsOneWidget);
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();

      // Bottom sheet is closed
      expect(find.text('Atılacak Kartı Seçin'), findsNothing);

      // Game state remains completely untouched
      expect(ctrl.status, equals('playing'));
      expect(ctrl.isHumanTurn, isTrue);
      expect(ctrl.players[0].hand.length, equals(11));
      expect(ctrl.players[0].totalScore, equals(0));
      expect(ctrl.lastFalseDeclarerSeat, isNull);
    });

    testWidgets('Assisted Mode: Multiple candidates opens bottom sheet; selecting card declares finish',
        (WidgetTester tester) async {
      final ctrl = OfflineTableController.instance;
      await SettingsService.instance.setAssisted(true);
      ctrl.status = 'playing';
      ctrl.currentTurnSeat = 0;
      ctrl.hasDrawnThisTurn = true;
      ctrl.wildRank = 1;

      final row0 = [
        const CardModel(id: 'h7', suit: 'H', rank: 7, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'h8', suit: 'H', rank: 8, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'h9', suit: 'H', rank: 9, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'h10', suit: 'H', rank: 10, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'hj', suit: 'H', rank: 11, deckIndex: 1, isPhysicalJoker: false),
      ];
      final row1 = [
        const CardModel(id: 'dk', suit: 'D', rank: 13, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'ck', suit: 'C', rank: 13, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'sk', suit: 'S', rank: 13, deckIndex: 1, isPhysicalJoker: false),
      ];
      final row2 = [
        const CardModel(id: 'd4', suit: 'D', rank: 4, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'c4', suit: 'C', rank: 4, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 's4', suit: 'S', rank: 4, deckIndex: 1, isPhysicalJoker: false),
      ];

      ctrl.players[0].hand = [...row0, ...row1, ...row2];
      ctrl.humanRows = [List.from(row0), List.from(row1), List.from(row2)];
      ctrl.selectedCardId = null;

      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(home: OfflineTableScreen()),
      );
      await tester.pump();

      // Tap EL AÇ BİTİR
      final finishBtn = find.textContaining('EL AÇ');
      await tester.tap(finishBtn);
      await tester.pumpAndSettle();

      // Bottom sheet opens
      expect(find.text('Atılacak Kartı Seçin'), findsOneWidget);
      final cardWidgets = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(PlayingCardWidget),
      );
      await tester.tap(cardWidgets.first);
      await tester.pumpAndSettle();

      // Successfully finished
      expect(ctrl.status, equals('round_summary'));
      expect(ctrl.lastFinisherSeat, equals(0));
    });
  });
}
