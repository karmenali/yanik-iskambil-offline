import 'card_model.dart';

/// Yanık İskambil Offline için deterministik el sıralama motoru.
class HandSorter {
  /// Takım sıralama önceliği: Maça (S) -> Kupa (H) -> Karo (D) -> Sinek (C)
  static int suitPriority(String suit) {
    final s = suit.toUpperCase();
    if (s.startsWith('S') || s.startsWith('MAÇA') || s.startsWith('MACA')) return 0;
    if (s.startsWith('H') || s.startsWith('KUPA')) return 1;
    if (s.startsWith('D') || s.startsWith('KARO')) return 2;
    if (s.startsWith('C') || s.startsWith('SİNEK') || s.startsWith('SINEK')) return 3;
    return 4;
  }

  /// Sayı sıralama önceliği:
  /// 2 -> 3 -> 4 -> 5 -> 6 -> 7 -> 8 -> 9 -> 10 -> J (11) -> Q (12) -> K (13) -> A (1)
  /// As (Ace, rank 1) bütün normal kartlardan sonra gelir (değeri 14 kabul edilir).
  static int rankPriority(int rank) {
    if (rank == 1) return 14;
    return rank;
  }

  /// İki kartı deterministik olarak karşılaştırır.
  /// 1. Fiziksel jokerler bütün normal kartlardan sonra yer alır.
  /// 2. Normal kartlar rank sırasına göre (2..10, J, Q, K, A) dizilir.
  /// 3. Aynı rank değerinde suit sırası: Maça -> Kupa -> Karo -> Sinek.
  /// 4. Çift deste durumunda eşit kartlar için deckIndex ve id tie-breaker kullanılır.
  static int compareCards(CardModel a, CardModel b) {
    // 1. Fiziksel jokerler en sonda yer alır
    if (a.isPhysicalJoker != b.isPhysicalJoker) {
      return a.isPhysicalJoker ? 1 : -1;
    }
    if (a.isPhysicalJoker && b.isPhysicalJoker) {
      final deckCmp = a.deckIndex.compareTo(b.deckIndex);
      if (deckCmp != 0) return deckCmp;
      return a.id.compareTo(b.id);
    }

    // 2. Rank karşılaştırması (2..K..A)
    final aRank = rankPriority(a.rank);
    final bRank = rankPriority(b.rank);
    if (aRank != bRank) {
      return aRank.compareTo(bRank);
    }

    // 3. Suit karşılaştırması (Maça -> Kupa -> Karo -> Sinek)
    final aSuit = suitPriority(a.suit);
    final bSuit = suitPriority(b.suit);
    if (aSuit != bSuit) {
      return aSuit.compareTo(bSuit);
    }

    // 4. Kararlı tie-breaker
    final deckCmp = a.deckIndex.compareTo(b.deckIndex);
    if (deckCmp != 0) return deckCmp;
    return a.id.compareTo(b.id);
  }

  /// Eli deterministik ve kararlı biçimde sıralar.
  /// Orijinal listeyi bozmaz, sıralanmış yeni bir liste döner.
  static List<CardModel> sortHand(List<CardModel> hand) {
    return List<CardModel>.from(hand)..sort(compareCards);
  }
}
