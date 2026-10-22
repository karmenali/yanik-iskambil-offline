import 'package:flutter_test/flutter_test.dart';
import 'package:yanik_offline/engine/card_model.dart';
import 'package:yanik_offline/engine/game_engine.dart';

void main() {
  group('GameEngine Tests', () {
    test('createDeck creates 106 cards with 2 jokers', () {
      final deck = GameEngine.createDeck();
      expect(deck.length, 106);
      final physicalJokers = deck.where((c) => c.isPhysicalJoker).toList();
      expect(physicalJokers.length, 2);
    });

    test('isValidMeld validates set (grup per) correctly', () {
      // 3 of 7s with different suits
      final cards = [
        const CardModel(id: '1_S_7', suit: 'S', rank: 7, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '1_H_7', suit: 'H', rank: 7, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '1_D_7', suit: 'D', rank: 7, deckIndex: 1, isPhysicalJoker: false),
      ];
      expect(GameEngine.isValidMeld(cards, 5), isTrue);

      // Same suit in set is invalid
      final invalidCards = [
        const CardModel(id: '1_S_7', suit: 'S', rank: 7, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '2_S_7', suit: 'S', rank: 7, deckIndex: 2, isPhysicalJoker: false),
        const CardModel(id: '1_D_7', suit: 'D', rank: 7, deckIndex: 1, isPhysicalJoker: false),
      ];
      expect(GameEngine.isValidMeld(invalidCards, 5), isFalse);
    });

    test('isValidMeld validates run (seri per) correctly with wildcards', () {
      // 4-5-6 of Hearts
      final cards = [
        const CardModel(id: '1_H_4', suit: 'H', rank: 4, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '1_H_5', suit: 'H', rank: 5, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '1_H_6', suit: 'H', rank: 6, deckIndex: 1, isPhysicalJoker: false),
      ];
      expect(GameEngine.isValidMeld(cards, 9), isTrue);

      // With wild card (rank 5 is wild): 4-Wild(5)-6
      final wildRun = [
        const CardModel(id: '1_H_4', suit: 'H', rank: 4, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '1_S_5', suit: 'S', rank: 5, deckIndex: 1, isPhysicalJoker: false), // wild
        const CardModel(id: '1_H_6', suit: 'H', rank: 6, deckIndex: 1, isPhysicalJoker: false),
      ];
      expect(GameEngine.isValidMeld(wildRun, 5), isTrue);
    });

    test('dealRoundHands deals 10 cards each to 4 players', () {
      final pids = ['p0', 'p1', 'p2', 'p3'];
      final dealt = GameEngine.dealRoundHands(pids);
      expect(dealt.hands.length, 4);
      for (final pid in pids) {
        expect(dealt.hands[pid]!.length, 10);
      }
      expect(dealt.drawPile.length, 66); // 106 - 40 = 66 (including indicator at bottom)
      expect(dealt.wildRank, greaterThanOrEqualTo(1));
      expect(dealt.wildRank, lessThanOrEqualTo(13));
    });
  });
}
