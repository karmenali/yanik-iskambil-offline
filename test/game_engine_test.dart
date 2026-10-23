import 'package:flutter_test/flutter_test.dart';
import 'package:yanik_offline/engine/card_model.dart';
import 'package:yanik_offline/engine/game_engine.dart';

void main() {
  group('GameEngine Tests', () {
    test('createDeck creates 106 cards with 2 physical jokers', () {
      final deck = GameEngine.createDeck();
      expect(deck.length, 106);
      final physicalJokers = deck.where((c) => c.isPhysicalJoker).toList();
      expect(physicalJokers.length, 2);
    });

    test('getRawCardPenalty applies correct Yanik penalties', () {
      // 1. As = 10 puan (Kullanıcı Kuralı)
      const ace = CardModel(id: '1_S_1', suit: 'S', rank: 1, deckIndex: 1, isPhysicalJoker: false);
      expect(GameEngine.getRawCardPenalty(ace, 5), 10);

      // 2. J, Q, K = 10 puan
      const jack = CardModel(id: '1_H_11', suit: 'H', rank: 11, deckIndex: 1, isPhysicalJoker: false);
      const queen = CardModel(id: '1_D_12', suit: 'D', rank: 12, deckIndex: 1, isPhysicalJoker: false);
      const king = CardModel(id: '1_C_13', suit: 'C', rank: 13, deckIndex: 1, isPhysicalJoker: false);
      expect(GameEngine.getRawCardPenalty(jack, 5), 10);
      expect(GameEngine.getRawCardPenalty(queen, 5), 10);
      expect(GameEngine.getRawCardPenalty(king, 5), 10);

      // 3. 2..10 = kendi rakam değeri
      const two = CardModel(id: '1_S_2', suit: 'S', rank: 2, deckIndex: 1, isPhysicalJoker: false);
      const seven = CardModel(id: '1_S_7', suit: 'S', rank: 7, deckIndex: 1, isPhysicalJoker: false);
      const ten = CardModel(id: '1_S_10', suit: 'S', rank: 10, deckIndex: 1, isPhysicalJoker: false);
      expect(GameEngine.getRawCardPenalty(two, 5), 2);
      expect(GameEngine.getRawCardPenalty(seven, 5), 7);
      expect(GameEngine.getRawCardPenalty(ten, 5), 10);

      // 4. Fiziksel Joker = 25 puan
      const joker = CardModel(id: '1_J_0', suit: 'J', rank: 0, deckIndex: 1, isPhysicalJoker: true);
      expect(GameEngine.getRawCardPenalty(joker, 5), 25);

      // 5. Gösterge ile aynı sayılı kart (Wild) = 25 puan
      const wildCard = CardModel(id: '1_H_5', suit: 'H', rank: 5, deckIndex: 1, isPhysicalJoker: false);
      expect(GameEngine.getRawCardPenalty(wildCard, 5), 25);

      // 6. Gösterge As ise As da Joker olur = 25 puan
      expect(GameEngine.getRawCardPenalty(ace, 1), 25);
    });

    test('Ace ranking rules in runs: A-2-3 valid, Q-K-A valid, K-A-2 INVALID', () {
      // A-2-3 of Spades: Geçerli küçük seri
      final smallAceRun = [
        const CardModel(id: '1_S_1', suit: 'S', rank: 1, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '1_S_2', suit: 'S', rank: 2, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '1_S_3', suit: 'S', rank: 3, deckIndex: 1, isPhysicalJoker: false),
      ];
      expect(GameEngine.isValidMeld(smallAceRun, 9), isTrue);

      // Q-K-A of Spades: Geçerli büyük seri (As = 14)
      final bigAceRun = [
        const CardModel(id: '1_S_12', suit: 'S', rank: 12, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '1_S_13', suit: 'S', rank: 13, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '1_S_1', suit: 'S', rank: 1, deckIndex: 1, isPhysicalJoker: false),
      ];
      expect(GameEngine.isValidMeld(bigAceRun, 9), isTrue);

      // K-A-2 of Spades: GEÇERSİZ (Döngüsel As yasaktır)
      final circularRun = [
        const CardModel(id: '1_S_13', suit: 'S', rank: 13, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '1_S_1', suit: 'S', rank: 1, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '1_S_2', suit: 'S', rank: 2, deckIndex: 1, isPhysicalJoker: false),
      ];
      expect(GameEngine.isValidMeld(circularRun, 9), isFalse);
    });

    test('Joker meld rules: 3 Jokers form a valid meld (Kullanıcı Kuralı)', () {
      final threePhysicalJokers = [
        const CardModel(id: '1_J_0', suit: 'J', rank: 0, deckIndex: 1, isPhysicalJoker: true),
        const CardModel(id: '2_J_0', suit: 'J', rank: 0, deckIndex: 2, isPhysicalJoker: true),
        const CardModel(id: '1_H_8', suit: 'H', rank: 8, deckIndex: 1, isPhysicalJoker: false), // wild (8)
      ];
      expect(GameEngine.isValidMeld(threePhysicalJokers, 8), isTrue);
    });

    test('Meld validation: Set (grup per) duplicate suits and sizes', () {
      // 3 of 7s with different suits: Geçerli
      final validSet = [
        const CardModel(id: '1_S_7', suit: 'S', rank: 7, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '1_H_7', suit: 'H', rank: 7, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '1_D_7', suit: 'D', rank: 7, deckIndex: 1, isPhysicalJoker: false),
      ];
      expect(GameEngine.isValidMeld(validSet, 5), isTrue);

      // 4 of 7s with 4 different suits: Geçerli
      final validSet4 = [
        ...validSet,
        const CardModel(id: '1_C_7', suit: 'C', rank: 7, deckIndex: 1, isPhysicalJoker: false),
      ];
      expect(GameEngine.isValidMeld(validSet4, 5), isTrue);

      // 5 of 7s: GEÇERSİZ (Grup per en fazla 4 olabilir)
      final invalidSet5 = [
        ...validSet4,
        const CardModel(id: '2_S_7', suit: 'S', rank: 7, deckIndex: 2, isPhysicalJoker: false),
      ];
      expect(GameEngine.isValidMeld(invalidSet5, 5), isFalse);

      // Aynı renkten iki kart grup perde olamaz: GEÇERSİZ
      final duplicateSuitSet = [
        const CardModel(id: '1_S_7', suit: 'S', rank: 7, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '2_S_7', suit: 'S', rank: 7, deckIndex: 2, isPhysicalJoker: false),
        const CardModel(id: '1_D_7', suit: 'D', rank: 7, deckIndex: 1, isPhysicalJoker: false),
      ];
      expect(GameEngine.isValidMeld(duplicateSuitSet, 5), isFalse);

      // 2 kartlı grup: GEÇERSİZ (< 3)
      expect(GameEngine.isValidMeld(validSet.sublist(0, 2), 5), isFalse);
    });

    test('dealRoundHands deals 10 cards each to 4 players and sets 66 in drawPile', () {
      final pids = ['p0', 'p1', 'p2', 'p3'];
      final dealt = GameEngine.dealRoundHands(pids);
      expect(dealt.hands.length, 4);
      for (final pid in pids) {
        expect(dealt.hands[pid]!.length, 10);
      }
      expect(dealt.drawPile.length, 66); // 106 - 40 = 66 (en alttaki gösterge dahil)
      expect(dealt.wildRank, inInclusiveRange(1, 13));
    });

    test('evaluateHandOptimal evaluates complete 10-card meld with 0 penalty', () {
      final hand10 = [
        // 3-4-5 Kupa (Seri)
        const CardModel(id: '1_H_3', suit: 'H', rank: 3, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '1_H_4', suit: 'H', rank: 4, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '1_H_5', suit: 'H', rank: 5, deckIndex: 1, isPhysicalJoker: false),
        // 7-8-9 Maça (Seri)
        const CardModel(id: '1_S_7', suit: 'S', rank: 7, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '1_S_8', suit: 'S', rank: 8, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '1_S_9', suit: 'S', rank: 9, deckIndex: 1, isPhysicalJoker: false),
        // K-K-K-K (4'lü grup per)
        const CardModel(id: '1_S_13', suit: 'S', rank: 13, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '1_H_13', suit: 'H', rank: 13, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '1_D_13', suit: 'D', rank: 13, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '1_C_13', suit: 'C', rank: 13, deckIndex: 1, isPhysicalJoker: false),
      ];

      final eval = GameEngine.evaluateHandOptimal(hand10, 2);
      expect(eval.canFinish, isTrue);
      expect(eval.penalty, 0);
      expect(eval.unmelded.isEmpty, isTrue);
      expect(eval.melds.length, 3);
    });

    test('findWinningDiscard detects winning discard card on 11 cards', () {
      final hand11 = [
        // 3-4-5 Kupa (3)
        const CardModel(id: '1_H_3', suit: 'H', rank: 3, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '1_H_4', suit: 'H', rank: 4, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '1_H_5', suit: 'H', rank: 5, deckIndex: 1, isPhysicalJoker: false),
        // 7-8-9 Maça (3)
        const CardModel(id: '1_S_7', suit: 'S', rank: 7, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '1_S_8', suit: 'S', rank: 8, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '1_S_9', suit: 'S', rank: 9, deckIndex: 1, isPhysicalJoker: false),
        // K-K-K-K (4)
        const CardModel(id: '1_S_13', suit: 'S', rank: 13, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '1_H_13', suit: 'H', rank: 13, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '1_D_13', suit: 'D', rank: 13, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '1_C_13', suit: 'C', rank: 13, deckIndex: 1, isPhysicalJoker: false),
        // Fazlalık 11. kart: 2 Karo
        const CardModel(id: '1_D_2', suit: 'D', rank: 2, deckIndex: 1, isPhysicalJoker: false),
      ];

      // wildRank = 6 (2 veya 13 joker değil)
      final winCheck = GameEngine.findWinningDiscard(hand11, 6);
      expect(winCheck.canWin, isTrue);
      expect(winCheck.discardCard?.id, '1_D_2');
      expect(winCheck.evaluation?.canFinish, isTrue);
      expect(winCheck.evaluation?.penalty, 0);
    });

    test('selectBestAutoDiscard discards unmelded highest penalty card, never a Joker', () {
      final hand11 = [
        // 3-4-5 Kupa
        const CardModel(id: '1_H_3', suit: 'H', rank: 3, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '1_H_4', suit: 'H', rank: 4, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '1_H_5', suit: 'H', rank: 5, deckIndex: 1, isPhysicalJoker: false),
        // Unmelded cards
        const CardModel(id: '1_S_2', suit: 'S', rank: 2, deckIndex: 1, isPhysicalJoker: false), // 2 pts
        const CardModel(id: '1_S_10', suit: 'S', rank: 10, deckIndex: 1, isPhysicalJoker: false), // 10 pts
        const CardModel(id: '1_H_1', suit: 'H', rank: 1, deckIndex: 1, isPhysicalJoker: false), // As = 10 pts
        const CardModel(id: '1_D_12', suit: 'D', rank: 12, deckIndex: 1, isPhysicalJoker: false), // Q = 10 pts
        const CardModel(id: '1_C_4', suit: 'C', rank: 4, deckIndex: 1, isPhysicalJoker: false), // 4 pts
        const CardModel(id: '1_C_6', suit: 'C', rank: 6, deckIndex: 1, isPhysicalJoker: false), // 6 pts
        const CardModel(id: '2_D_8', suit: 'D', rank: 8, deckIndex: 2, isPhysicalJoker: false), // 8 pts
        // Joker
        const CardModel(id: '1_J_0', suit: 'J', rank: 0, deckIndex: 1, isPhysicalJoker: true),
      ];

      // wildRank = 9
      final discarded = GameEngine.selectBestAutoDiscard(hand11, 9);
      // Joker atılmamalı, unmelded 10 puanlıklardan biri atılmalı
      expect(discarded.isPhysicalJoker, isFalse);
      expect(GameEngine.getRawCardPenalty(discarded, 9), 10);
    });
  });
}
