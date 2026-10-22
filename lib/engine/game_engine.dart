import 'dart:math' as math;
import 'card_model.dart';

class GameEngine {
  /// 106 kağıtlık Yanık İskambil destesi (2 tam deste + 2 Fiziksel Joker)
  static List<CardModel> createDeck() {
    const suits = ['S', 'H', 'D', 'C'];
    final deck = <CardModel>[];

    for (int d = 1; d <= 2; d++) {
      for (final suit in suits) {
        for (int rank = 1; rank <= 13; rank++) {
          deck.add(CardModel(
            id: '${d}_${suit}_$rank',
            suit: suit,
            rank: rank,
            deckIndex: d,
            isPhysicalJoker: false,
          ));
        }
      }
    }

    // 2 Fiziksel Joker
    deck.add(const CardModel(
      id: '1_J_0',
      suit: 'J',
      rank: 0,
      deckIndex: 1,
      isPhysicalJoker: true,
    ));
    deck.add(const CardModel(
      id: '2_J_0',
      suit: 'J',
      rank: 0,
      deckIndex: 2,
      isPhysicalJoker: true,
    ));

    return shuffleDeck(deck);
  }

  /// Fisher-Yates karıştırma algoritması
  static List<CardModel> shuffleDeck(List<CardModel> deck) {
    final arr = List<CardModel>.from(deck);
    final random = math.Random();
    for (int i = arr.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = arr[i];
      arr[i] = arr[j];
      arr[j] = temp;
    }
    return arr;
  }

  /// Kağıt o turun Jokeri mi?
  static bool isWildCard(CardModel card, int wildRank) {
    return card.isPhysicalJoker || (wildRank > 0 && card.rank == wildRank);
  }

  /// Boşta kalan (per olmamış) kağıdın ceza puanı
  static int getRawCardPenalty(CardModel card, int wildRank) {
    if (isWildCard(card, wildRank)) {
      return 25;
    }
    if (card.rank == 1) return 11; // As = 11 puan
    if (card.rank >= 11 && card.rank <= 13) return 10; // J, Q, K = 10 puan
    return card.rank; // 2..10 kendi değeri
  }

  /// Verilen kağıt grubunun geçerli bir Per (Grup veya Seri) olup olmadığını kontrol eder.
  static bool isValidMeld(List<CardModel> cards, int wildRank) {
    if (cards.length < 3) return false;

    final naturals = cards.where((c) => !isWildCard(c, wildRank)).toList();

    // Tümü jokerse (3 veya daha fazla joker per oluşturur)
    if (naturals.isEmpty) return true;

    // 1. GRUP PER (SET): 3 veya 4 kağıt, aynı sayı, FARKLI semboller
    if (cards.length <= 4) {
      final targetRank = naturals[0].rank;
      final allSameRank = naturals.every((c) => c.rank == targetRank);
      if (allSameRank) {
        final suits = naturals.map((c) => c.suit).toSet();
        if (suits.length == naturals.length) {
          return true;
        }
      }
    }

    // 2. SERİ PER (RUN): Aynı sembol, ardışık sayılar, döngüsel olmayan As
    if (cards.length <= 13) {
      final targetSuit = naturals[0].suit;
      final allSameSuit = naturals.every((c) => c.suit == targetSuit);
      if (!allSameSuit) return false;

      final nonAceNaturals = naturals.where((c) => c.rank != 1).toList();
      final nonAceRanks = nonAceNaturals.map((c) => c.rank).toList();
      if (nonAceRanks.toSet().length != nonAceRanks.length) return false;

      final aces = naturals.where((c) => c.rank == 1).toList();
      if (aces.length > 2) return false;

      final List<List<int>> aceAssignments = aces.isEmpty
          ? [[]]
          : aces.length == 1
              ? [
                  [1],
                  [14]
                ]
              : [
                  [1, 14]
                ];

      final len = cards.length;

      for (final acePos in aceAssignments) {
        final positions = [...nonAceRanks, ...acePos]..sort();
        if (positions.toSet().length != positions.length) continue;

        final minPos = positions.first;
        final maxPos = positions.last;

        if (maxPos - minPos < len) {
          final earliestStart = math.max(1, maxPos - len + 1);
          final latestStart = math.min(minPos, 14 - len + 1);
          if (earliestStart <= latestStart) {
            return true;
          }
        }
      }
    }

    return false;
  }

  /// Seriyi görsel olarak doğru sıraya (jokerleri boşluklara yerleştirerek) dizer.
  static List<CardModel> orderMeldCards(List<CardModel> cards, int wildRank) {
    final naturals = cards.where((c) => !isWildCard(c, wildRank)).toList();
    final wilds = cards.where((c) => isWildCard(c, wildRank)).toList();
    if (naturals.length <= 1) return List<CardModel>.from(cards);

    // Grup per ise (aynı sayı farklı renkler)
    if (naturals.every((c) => c.rank == naturals[0].rank)) {
      return [...naturals, ...wilds];
    }

    // Oyuncunun mevcut dizilimi geçerli bir ardışık sıra mı kontrol et
    for (final aceAs14 in [false, true]) {
      bool matchesExistingOrder = true;
      int? impliedStart;
      for (int i = 0; i < cards.length; i++) {
        final c = cards[i];
        if (!isWildCard(c, wildRank)) {
          final pos = c.rank == 1 && aceAs14 ? 14 : c.rank;
          final startCandidate = pos - i;
          if (impliedStart == null) {
            impliedStart = startCandidate;
          } else if (impliedStart != startCandidate) {
            matchesExistingOrder = false;
            break;
          }
        }
      }
      if (matchesExistingOrder &&
          impliedStart != null &&
          impliedStart >= 1 &&
          impliedStart + cards.length - 1 <= 14) {
        return List<CardModel>.from(cards);
      }
    }

    // Seri per ise
    final hasHighCards = naturals.any((c) => c.rank >= 10);
    final mapped = naturals
        .map((c) => _CardPos(
              card: c,
              pos: c.rank == 1 && hasHighCards ? 14 : c.rank,
            ))
        .toList()
      ..sort((a, b) => a.pos.compareTo(b.pos));

    final result = <CardModel>[];
    final usedWilds = List<CardModel>.from(wilds);

    for (int i = 0; i < mapped.length; i++) {
      if (i > 0) {
        final gap = mapped[i].pos - mapped[i - 1].pos - 1;
        for (int g = 0; g < gap && usedWilds.isNotEmpty; g++) {
          result.add(usedWilds.removeAt(0));
        }
      }
      result.add(mapped[i].card);
    }

    int currentMaxPos = mapped.last.pos;
    while (usedWilds.isNotEmpty) {
      if (currentMaxPos < 14) {
        result.add(usedWilds.removeAt(0));
        currentMaxPos++;
      } else {
        result.insert(0, usedWilds.removeAt(0));
      }
    }
    return result;
  }

  /// Optimum per ve ceza değerlendirmesi
  static HandEvaluation evaluateHandOptimal(List<CardModel> cards, int wildRank) {
    final n = cards.length;
    if (n == 0) {
      return HandEvaluation(
        canFinish: true,
        melds: [],
        unmelded: [],
        penalty: 0,
        orderedCards: [],
      );
    }

    final validMelds = <_CandidateMeld>[];
    final totalMasks = 1 << n;

    for (int mask = 0; mask < totalMasks; mask++) {
      int bitCount = 0;
      int temp = mask;
      while (temp > 0) {
        bitCount += temp & 1;
        temp >>= 1;
      }
      if (bitCount < 3 || bitCount > 10) continue;

      final subset = <CardModel>[];
      for (int i = 0; i < n; i++) {
        if ((mask & (1 << i)) != 0) {
          subset.add(cards[i]);
        }
      }

      if (isValidMeld(subset, wildRank)) {
        validMelds.add(_CandidateMeld(mask: mask, bitCount: bitCount, cards: subset));
      }
    }

    validMelds.sort((a, b) => b.bitCount.compareTo(a.bitCount));

    final rawPenalties = cards.map((c) => getRawCardPenalty(c, wildRank)).toList();

    bool bestIsFinishReady = false;
    int bestPenalty = 999999;
    List<int> bestMeldMasks = [];
    int bestMeldedCardCount = -1;
    int bestDiscardCandidateValue = -1;

    _MaskState evaluateMaskState(int usedMask) {
      int penalty = 0;
      int meldedCount = 0;
      int singleUnmeldedVal = -1;
      for (int i = 0; i < n; i++) {
        if ((usedMask & (1 << i)) == 0) {
          penalty += rawPenalties[i];
          singleUnmeldedVal = isWildCard(cards[i], wildRank) ? 0 : rawPenalties[i];
        } else {
          meldedCount++;
        }
      }
      final isFinishReady =
          (n == 10 && meldedCount == 10) || (n == 11 && meldedCount == 10);
      return _MaskState(
        isFinishReady: isFinishReady,
        penalty: isFinishReady && n == 10 ? 0 : penalty,
        meldedCount: meldedCount,
        discardCandidateValue: n == 11 && meldedCount == 10 ? singleUnmeldedVal : -1,
      );
    }

    final minStartIdxByMask = <int, int>{};

    void search(int usedMask, int startIdx, List<int> currentMasks) {
      final prevStart = minStartIdxByMask[usedMask];
      if (prevStart != null && prevStart <= startIdx) return;
      minStartIdxByMask[usedMask] = startIdx;

      final state = evaluateMaskState(usedMask);

      bool isBetter = false;
      if (state.isFinishReady && !bestIsFinishReady) {
        isBetter = true;
      } else if (state.isFinishReady && bestIsFinishReady) {
        if (state.discardCandidateValue > bestDiscardCandidateValue) {
          isBetter = true;
        }
      } else if (!state.isFinishReady && !bestIsFinishReady) {
        if (state.penalty < bestPenalty ||
            (state.penalty == bestPenalty && state.meldedCount > bestMeldedCardCount)) {
          isBetter = true;
        }
      }

      if (isBetter) {
        bestIsFinishReady = state.isFinishReady;
        bestPenalty = state.penalty;
        bestMeldMasks = List<int>.from(currentMasks);
        bestMeldedCardCount = state.meldedCount;
        bestDiscardCandidateValue = state.discardCandidateValue;
      }

      if (n == 10 && bestIsFinishReady) return;

      for (int i = startIdx; i < validMelds.length; i++) {
        final m = validMelds[i];
        if ((usedMask & m.mask) == 0) {
          if (n == 11 && state.meldedCount + m.bitCount > 10) continue;
          currentMasks.add(m.mask);
          search(usedMask | m.mask, i + 1, currentMasks);
          currentMasks.removeLast();
        }
      }
    }

    search(0, 0, []);

    int finalUsedMask = 0;
    final chosenMelds = <List<CardModel>>[];
    for (final mMask in bestMeldMasks) {
      finalUsedMask |= mMask;
      final meldCards = <CardModel>[];
      for (int i = 0; i < n; i++) {
        if ((mMask & (1 << i)) != 0) {
          meldCards.add(cards[i]);
        }
      }
      chosenMelds.add(orderMeldCards(meldCards, wildRank));
    }

    final unmelded = <CardModel>[];
    for (int i = 0; i < n; i++) {
      if ((finalUsedMask & (1 << i)) == 0) {
        unmelded.add(cards[i]);
      }
    }

    const suitOrder = {'S': 1, 'H': 2, 'C': 3, 'D': 4, 'J': 5};
    unmelded.sort((a, b) {
      final aWild = isWildCard(a, wildRank) ? 1 : 0;
      final bWild = isWildCard(b, wildRank) ? 1 : 0;
      if (aWild != bWild) return aWild.compareTo(bWild);
      final sA = suitOrder[a.suit] ?? 1;
      final sB = suitOrder[b.suit] ?? 1;
      if (sA != sB) return sA.compareTo(sB);
      return a.rank.compareTo(b.rank);
    });

    final orderedCards = [...chosenMelds.expand((m) => m), ...unmelded];

    return HandEvaluation(
      canFinish: unmelded.isEmpty && n == 10,
      melds: chosenMelds,
      unmelded: unmelded,
      penalty: bestIsFinishReady ? 0 : bestPenalty,
      orderedCards: orderedCards,
    );
  }

  /// Bir satırdaki kağıtların geçerli per oluşturup oluşturmadığını inceler
  static ({bool valid, List<List<CardModel>> melds}) decomposeRowIntoMelds(
    List<CardModel> rowCards,
    int wildRank,
  ) {
    final len = rowCards.length;
    if (len == 0) return (valid: true, melds: <List<CardModel>>[]);
    if (len < 3) return (valid: false, melds: <List<CardModel>>[]);

    if (isValidMeld(rowCards, wildRank)) {
      return (valid: true, melds: [orderMeldCards(rowCards, wildRank)]);
    }

    if (len >= 6) {
      for (int split1 = 3; split1 <= len - 3; split1++) {
        final firstPart = rowCards.sublist(0, split1);
        final restPart = rowCards.sublist(split1);
        if (isValidMeld(firstPart, wildRank)) {
          final sub = decomposeRowIntoMelds(restPart, wildRank);
          if (sub.valid) {
            return (
              valid: true,
              melds: [orderMeldCards(firstPart, wildRank), ...sub.melds]
            );
          }
        }
      }
    }

    final rowEval = evaluateHandOptimal(rowCards, wildRank);
    if (rowEval.unmelded.isEmpty && rowEval.melds.expand((m) => m).length == len) {
      return (valid: true, melds: rowEval.melds);
    }

    return (valid: false, melds: <List<CardModel>>[]);
  }

  /// 11 kağıtlı elde hangi kağıt atılırsa elin bitebileceğini kontrol eder
  static ({bool canWin, CardModel? discardCard, HandEvaluation? evaluation}) findWinningDiscard(
    List<CardModel> cards11,
    int wildRank, {
    List<List<String>>? handRows,
    String? preferredDiscardCardId,
  }) {
    if (cards11.length != 11) return (canWin: false, discardCard: null, evaluation: null);

    CardModel? bestDiscard;
    HandEvaluation? bestEval;
    int bestDiscardScore = -1;

    for (int i = 0; i < cards11.length; i++) {
      final cand = cards11[i];
      final remaining10 = List<CardModel>.from(cards11)..removeAt(i);
      final eval10 = evaluateHandOptimal(remaining10, wildRank);
      if (eval10.canFinish) {
        final score =
            (preferredDiscardCardId != null && cand.id == preferredDiscardCardId ? 1000 : 0) +
                (isWildCard(cand, wildRank) ? 0 : getRawCardPenalty(cand, wildRank));
        if (score > bestDiscardScore) {
          bestDiscardScore = score;
          bestDiscard = cand;
          bestEval = eval10;
        }
      }
    }

    if (bestDiscard != null && bestEval != null) {
      return (canWin: true, discardCard: bestDiscard, evaluation: bestEval);
    }

    return (canWin: false, discardCard: null, evaluation: null);
  }

  /// 11 kağıt içinden per olmayan ve joker olmayan en yüksek ceza puanlı kağıdı seçer (Bot için)
  static CardModel selectBestAutoDiscard(List<CardModel> cards11, int wildRank) {
    final eval11 = evaluateHandOptimal(cards11, wildRank);

    // 1. Boşta kalan ve Joker olmayanlar içinden en yüksek ceza puanlı olanı at
    final nonWildUnmelded =
        eval11.unmelded.where((c) => !isWildCard(c, wildRank)).toList();
    if (nonWildUnmelded.isNotEmpty) {
      nonWildUnmelded.sort(
        (a, b) => getRawCardPenalty(b, wildRank).compareTo(getRawCardPenalty(a, wildRank)),
      );
      return nonWildUnmelded.first;
    }

    // 2. Joker olmayan kağıtlar içinden atıldığında en az ceza bırakanı seç
    final nonWildAll = cards11.where((c) => !isWildCard(c, wildRank)).toList();
    if (nonWildAll.isNotEmpty) {
      CardModel bestCandidate = nonWildAll.first;
      int bestRemainingPenalty = 999999;
      int bestCandidateValue = -1;

      for (final candidate in nonWildAll) {
        final rem10 = cards11.where((c) => c.id != candidate.id).toList();
        final remEval = evaluateHandOptimal(rem10, wildRank);
        final candVal = getRawCardPenalty(candidate, wildRank);
        if (remEval.penalty < bestRemainingPenalty ||
            (remEval.penalty == bestRemainingPenalty && candVal > bestCandidateValue)) {
          bestRemainingPenalty = remEval.penalty;
          bestCandidateValue = candVal;
          bestCandidate = candidate;
        }
      }
      return bestCandidate;
    }

    return cards11.first;
  }

  /// Aktif 4 oyuncuya 2'şer 2'şer toplam 10'ar kağıt dağıtır
  static ({
    Map<String, List<CardModel>> hands,
    List<CardModel> drawPile,
    CardModel indicatorCard,
    int wildRank,
  }) dealRoundHands(List<String> playerIds) {
    final deck = createDeck();
    final hands = <String, List<CardModel>>{};
    for (final pid in playerIds) {
      hands[pid] = [];
    }

    int deckCursor = 0;
    for (int pass = 0; pass < 5; pass++) {
      for (final pid in playerIds) {
        hands[pid]!.add(deck[deckCursor++]);
        hands[pid]!.add(deck[deckCursor++]);
      }
    }

    final remaining = deck.sublist(deckCursor);

    int indicatorIdx = remaining.indexWhere((c) => !c.isPhysicalJoker);
    if (indicatorIdx == -1) indicatorIdx = 0;

    final indicatorCard = remaining.removeAt(indicatorIdx);
    final wildRank = indicatorCard.rank;

    // Gösterge kağıdı destenin en altına yarısı görünür şekilde konur
    final drawPile = [...remaining, indicatorCard];

    return (
      hands: hands,
      drawPile: drawPile,
      indicatorCard: indicatorCard,
      wildRank: wildRank,
    );
  }
}

class _CardPos {
  final CardModel card;
  final int pos;
  _CardPos({required this.card, required this.pos});
}

class _CandidateMeld {
  final int mask;
  final int bitCount;
  final List<CardModel> cards;
  _CandidateMeld({required this.mask, required this.bitCount, required this.cards});
}

class _MaskState {
  final bool isFinishReady;
  final int penalty;
  final int meldedCount;
  final int discardCandidateValue;

  _MaskState({
    required this.isFinishReady,
    required this.penalty,
    required this.meldedCount,
    required this.discardCandidateValue,
  });
}
