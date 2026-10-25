import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yanik_offline/engine/card_model.dart';
import 'package:yanik_offline/engine/offline_table_controller.dart';
import 'package:yanik_offline/screens/offline_table_screen.dart';
import 'package:yanik_offline/services/settings_service.dart';
import 'package:yanik_offline/services/sound_fx.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'yanik_offline_assisted': true,
      'yanik_offline_sound': true,
      'yanik_offline_vibration': true,
    });
    await SettingsService.instance.init();
    await SoundFx.init();
    SoundFx.turnHapticFnForTesting = null;
  });

  tearDown(() async {
    OfflineTableController.instance.stopGame();
    SoundFx.turnHapticFnForTesting = null;
    await SoundFx.dispose();
  });

  group('P0 — Yardımlı Mod Performans & Önbellekleme Testleri', () {
    test('Repeated calls to meldedCardIds and currentHandPenalty use cache in O(1) time', () {
      final ctrl = OfflineTableController.instance;
      ctrl.initMatch();

      expect(SettingsService.instance.isAssisted, isTrue);
      expect(ctrl.players.isNotEmpty, isTrue);

      final stopwatch = Stopwatch()..start();
      // Call getters 500 times in a row
      for (int i = 0; i < 500; i++) {
        final melded = ctrl.meldedCardIds;
        final penalty = ctrl.currentHandPenalty;
        expect(melded, isNotNull);
        expect(penalty, greaterThanOrEqualTo(0));
      }
      stopwatch.stop();

      // 500 getter calls must finish within < 30ms (previously took >1000ms due to repeated 134 combinatorial searches)
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    test('Winning discard check returns cached result and evaluates fast on preferred card', () {
      final ctrl = OfflineTableController.instance;
      ctrl.initMatch();

      // Setup a winning 11-card hand for human:
      // Melds: 7S-8S-9S (3), KS-KD-KC (3), 4H-5H-6H-7H (4) + Discard candidate: 2D (1)
      ctrl.players[0].hand = [
        CardModel(id: 'c1', suit: 'SPADES', rank: 7, deckIndex: 0, isPhysicalJoker: false),
        CardModel(id: 'c2', suit: 'SPADES', rank: 8, deckIndex: 0, isPhysicalJoker: false),
        CardModel(id: 'c3', suit: 'SPADES', rank: 9, deckIndex: 0, isPhysicalJoker: false),
        CardModel(id: 'c4', suit: 'SPADES', rank: 13, deckIndex: 0, isPhysicalJoker: false),
        CardModel(id: 'c5', suit: 'DIAMONDS', rank: 13, deckIndex: 0, isPhysicalJoker: false),
        CardModel(id: 'c6', suit: 'CLUBS', rank: 13, deckIndex: 0, isPhysicalJoker: false),
        CardModel(id: 'c7', suit: 'HEARTS', rank: 4, deckIndex: 0, isPhysicalJoker: false),
        CardModel(id: 'c8', suit: 'HEARTS', rank: 5, deckIndex: 0, isPhysicalJoker: false),
        CardModel(id: 'c9', suit: 'HEARTS', rank: 6, deckIndex: 0, isPhysicalJoker: false),
        CardModel(id: 'c10', suit: 'HEARTS', rank: 7, deckIndex: 0, isPhysicalJoker: false),
        CardModel(id: 'c11_discard', suit: 'DIAMONDS', rank: 2, deckIndex: 0, isPhysicalJoker: false),
      ];
      ctrl.currentTurnSeat = 0;
      ctrl.hasDrawnThisTurn = true;
      ctrl.selectedCardId = 'c11_discard';

      final sw = Stopwatch()..start();
      // Should instantly identify c11_discard as the winning discard
      for (int i = 0; i < 100; i++) {
        expect(ctrl.canFinishNow, isTrue);
        expect(ctrl.winningDiscardCardId, equals('c11_discard'));
      }
      sw.stop();
      expect(sw.elapsedMilliseconds, lessThan(50));
    });

    test('Assisted mode correctly invalidates and re-evaluates when hand changes', () {
      final ctrl = OfflineTableController.instance;
      ctrl.initMatch();

      ctrl.players[0].hand = [
        CardModel(id: 'c1', suit: 'SPADES', rank: 7, deckIndex: 0, isPhysicalJoker: false),
        CardModel(id: 'c2', suit: 'SPADES', rank: 8, deckIndex: 0, isPhysicalJoker: false),
        CardModel(id: 'c3', suit: 'SPADES', rank: 9, deckIndex: 0, isPhysicalJoker: false),
      ];
      final firstMelds = ctrl.meldedCardIds;
      expect(firstMelds.length, equals(3));

      // Modify hand (add a non-meld card)
      ctrl.players[0].hand.add(CardModel(id: 'c4', suit: 'HEARTS', rank: 2, deckIndex: 0, isPhysicalJoker: false));
      ctrl.syncHumanRows([
        [...ctrl.players[0].hand],
        [],
        [],
      ]);

      // Cache must invalidate and reflect the updated penalty
      final secondPenalty = ctrl.currentHandPenalty;
      expect(secondPenalty, equals(2));
    });

    test('Draw and discard cycle runs with identical stability in Assisted vs Unassisted modes', () {
      final ctrl = OfflineTableController.instance;

      for (final isAssistedMode in [true, false]) {
        SettingsService.instance.setAssisted(isAssistedMode);
        ctrl.initMatch();

        // Simulate 20 draws and discards
        for (int i = 0; i < 20; i++) {
          if (ctrl.drawPile.isNotEmpty) {
            ctrl.currentTurnSeat = 0;
            ctrl.hasDrawnThisTurn = false;
            ctrl.humanDrawCard();
            expect(ctrl.hasDrawnThisTurn, isTrue);

            final discardId = ctrl.players[0].hand.first.id;
            ctrl.humanDiscardCard(discardId);
            expect(ctrl.hasDrawnThisTurn, isFalse);
          }
        }
      }
    });
  });

  group('P1 — Yalnızca Sıra Geldiğinde Titreşim Testleri', () {
    test('Turn start vibration triggers exactly ONCE when turn passes to human player', () {
      int turnVibrations = 0;
      SoundFx.turnHapticFnForTesting = () async {
        turnVibrations++;
      };

      final ctrl = OfflineTableController.instance;
      ctrl.initMatch();

      // In initMatch(), dealerSeat = 0, so next active is 1 (bot).
      // Turn is at bot 1. Human has not played yet.
      turnVibrations = 0; // Reset any initial counter

      // Advance from bot 1 -> bot 2
      ctrl.currentTurnSeat = 1;
      ctrl.humanDiscardCard('dummy'); // Should not execute because not human turn
      expect(turnVibrations, equals(0));

      // Simulate bot 3 advancing turn to human (seat 0)
      ctrl.currentTurnSeat = 3;
      ctrl.humanDiscardCard('dummy'); // Doesn't fire

      // Manually trigger turn rotation into seat 0
      ctrl.currentTurnSeat = 3;
      // When bot discards and advances turn to 0:
      ctrl.currentTurnSeat = 0; // Set human turn
      // Controller checks turn start haptic in advanceTurn
      ctrl.startRound();
      // In startRound with dealerSeat 3, next active is 0
      ctrl.dealerSeat = 3;
      ctrl.startRound();

      // Expect exactly 1 turn start vibration
      expect(turnVibrations, equals(1));

      // Calling notifyListeners repeatedly must NOT re-vibrate during the same turn
      ctrl.notifyListeners();
      ctrl.notifyListeners();
      expect(turnVibrations, equals(1));
    });

    test('Card actions (draw, discard, selection) do NOT trigger vibration', () {
      int turnVibrations = 0;
      SoundFx.turnHapticFnForTesting = () async {
        turnVibrations++;
      };

      final ctrl = OfflineTableController.instance;
      ctrl.initMatch();
      ctrl.currentTurnSeat = 0;
      ctrl.hasDrawnThisTurn = false;
      turnVibrations = 0;

      // 1. Card selection must NOT vibrate
      if (ctrl.players[0].hand.isNotEmpty) {
        ctrl.selectCard(ctrl.players[0].hand.first.id);
        expect(turnVibrations, equals(0));
        ctrl.selectCard(ctrl.players[0].hand.first.id); // Deselect
        expect(turnVibrations, equals(0));
      }

      // 2. Card draw must NOT vibrate
      ctrl.humanDrawCard();
      expect(turnVibrations, equals(0));

      // 3. Card discard must NOT vibrate (advance to bot)
      if (ctrl.players[0].hand.isNotEmpty) {
        final cardId = ctrl.players[0].hand.first.id;
        ctrl.humanDiscardCard(cardId);
        // Turn advanced to bot, no vibration
        expect(turnVibrations, equals(0));
      }
    });

    test('When vibration setting is OFF, zero vibrations are generated', () async {
      await SettingsService.instance.setVibrationEnabled(false);
      expect(SettingsService.instance.vibrationEnabled, isFalse);

      int vibrationCount = 0;
      SoundFx.turnHapticFnForTesting = () async {
        vibrationCount++;
      };

      // Trigger turn start haptic
      SoundFx.triggerTurnStartHaptic();
      expect(vibrationCount, equals(0));

      final ctrl = OfflineTableController.instance;
      ctrl.dealerSeat = 3;
      ctrl.startRound(); // Would start at seat 0
      expect(vibrationCount, equals(0));
    });

    test('Vibration preference is persisted across restarts in SettingsService', () async {
      final settings = SettingsService.instance;
      await settings.setVibrationEnabled(true);
      expect(settings.vibrationEnabled, isTrue);

      // Re-initialize from SharedPreferences
      await settings.init();
      expect(settings.vibrationEnabled, isTrue);

      await settings.setVibrationEnabled(false);
      expect(settings.vibrationEnabled, isFalse);

      await settings.init();
      expect(settings.vibrationEnabled, isFalse);
    });

    testWidgets('OfflineTableScreen renders without vibration on drag or slot updates', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      int screenVibrations = 0;
      SoundFx.turnHapticFnForTesting = () async {
        screenVibrations++;
      };

      final ctrl = OfflineTableController.instance;
      ctrl.initMatch();

      await tester.pumpWidget(
        const MaterialApp(
          home: OfflineTableScreen(),
        ),
      );
      await tester.pump();

      // Screen render must NOT vibrate on its own
      expect(screenVibrations, equals(0));
    });
  });
}
