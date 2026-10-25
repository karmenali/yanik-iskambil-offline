import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yanik_offline/engine/card_model.dart';
import 'package:yanik_offline/engine/game_engine.dart';
import 'package:yanik_offline/engine/offline_table_controller.dart';
import 'package:yanik_offline/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'yanik_offline_sound': false,
      'yanik_offline_vibration': false,
      'yanik_offline_assisted': true,
    });
    await SettingsService.instance.init();
  });

  tearDown(() {
    OfflineTableController.instance.stopGame();
  });

  group('Section C: In-Game Performance & Multi-Round Regression Tests', () {
    test('Simulate 50 consecutive rounds: Zero crashes, proper scoring and state continuity', () {
      final ctrl = OfflineTableController.instance;
      ctrl.initMatch();

      expect(ctrl.players.length, equals(4));
      expect(ctrl.status, equals('playing'));

      for (int r = 1; r <= 50; r++) {
        // Fast-forward round: simulate finisher
        final activePlayers = ctrl.players.where((p) => !p.isEliminated).toList();
        if (activePlayers.length <= 1) {
          // A match ended; start a new match
          ctrl.initMatch();
          continue;
        }

        final finisherSeat = activePlayers.first.seatIndex;
        ctrl.endRound(finisherSeat);

        expect(ctrl.status, equals('round_summary'));
        expect(ctrl.lastShowdown, isNotNull);
        expect(ctrl.lastShowdown!.length, equals(4));

        // Advance to next round
        ctrl.continueAfterRound();

        if (ctrl.status == 'game_over') {
          // Final winner declared
          expect(ctrl.winnerMessage, isNotNull);
          ctrl.initMatch();
        } else {
          expect(ctrl.status, equals('playing'));
          expect(ctrl.roundNumber, greaterThan(1));
        }
      }
    });

    test('Dynamic Assisted <-> Unassisted mode switching does not corrupt state or cache', () async {
      final ctrl = OfflineTableController.instance;
      ctrl.initMatch();

      // Start in Assisted mode
      await SettingsService.instance.setAssisted(true);
      expect(ctrl.isAssisted, isTrue);

      final penaltyAssisted = ctrl.currentHandPenalty;
      expect(penaltyAssisted, isA<int>());

      // Switch to Unassisted mode
      await SettingsService.instance.setAssisted(false);
      expect(ctrl.isAssisted, isFalse);

      final penaltyUnassisted = ctrl.currentHandPenalty;
      expect(penaltyUnassisted, isA<int>());

      // Switch back to Assisted mode
      await SettingsService.instance.setAssisted(true);
      expect(ctrl.isAssisted, isTrue);
      expect(ctrl.currentHandPenalty, equals(penaltyAssisted));
    });

    test('Deck exhaustion triggers tie-break round summary cleanly without winner', () {
      final ctrl = OfflineTableController.instance;
      ctrl.initMatch();

      // Drain draw pile
      ctrl.drawPile.clear();
      expect(ctrl.drawPile.isEmpty, isTrue);

      // Trigger round end due to exhausted draw pile
      ctrl.endRound(null);

      expect(ctrl.status, equals('round_summary'));
      expect(ctrl.lastFinisherSeat, isNull);
      expect(ctrl.lastFalseDeclarerSeat, isNull);
      expect(ctrl.lastShowdown, isNotNull);
      expect(ctrl.lastShowdown!.length, equals(4));
    });

    test('Player elimination logic: Players reaching >= 101 points are eliminated and skipped', () {
      final ctrl = OfflineTableController.instance;
      ctrl.initMatch();

      // Set bot 1 to 95 points
      ctrl.players[1].totalScore = 95;

      // Finish round where human wins (bot 1 gets penalty and exceeds 101)
      ctrl.players[1].hand = [
        const CardModel(id: 'k1', suit: 'S', rank: 13, deckIndex: 1, isPhysicalJoker: false), // 10 pts
      ];
      ctrl.endRound(0);

      expect(ctrl.players[1].totalScore, greaterThanOrEqualTo(101));
      expect(ctrl.players[1].isEliminated, isTrue);

      // Start next round
      ctrl.continueAfterRound();
      expect(ctrl.players[1].hand, isEmpty); // Eliminated players receive 0 cards
    });

    test('Game Engine decomposeRowIntoMelds edge cases', () {
      const wildRank = 5;

      // 3 of a kind
      final set3 = [
        const CardModel(id: '1', suit: 'H', rank: 8, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '2', suit: 'D', rank: 8, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '3', suit: 'C', rank: 8, deckIndex: 1, isPhysicalJoker: false),
      ];
      final resSet = GameEngine.decomposeRowIntoMelds(set3, wildRank);
      expect(resSet.valid, isTrue);
      expect(resSet.melds.length, equals(1));

      // 4 of a kind
      final set4 = [
        ...set3,
        const CardModel(id: '4', suit: 'S', rank: 8, deckIndex: 1, isPhysicalJoker: false),
      ];
      final resSet4 = GameEngine.decomposeRowIntoMelds(set4, wildRank);
      expect(resSet4.valid, isTrue);

      // Invalid: same suit duplicate in set
      final setDup = [
        ...set3,
        const CardModel(id: '5', suit: 'H', rank: 8, deckIndex: 2, isPhysicalJoker: false),
      ];
      final resDup = GameEngine.decomposeRowIntoMelds(setDup, wildRank);
      expect(resDup.valid, isFalse);

      // Sequence with wild card
      final runWithWild = [
        const CardModel(id: 'r1', suit: 'H', rank: 4, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'r2', suit: 'D', rank: 5, deckIndex: 1, isPhysicalJoker: false), // Wild because wildRank == 5
        const CardModel(id: 'r3', suit: 'H', rank: 6, deckIndex: 1, isPhysicalJoker: false),
      ];
      final resRunWild = GameEngine.decomposeRowIntoMelds(runWithWild, wildRank);
      expect(resRunWild.valid, isTrue);
    });
  });
}
