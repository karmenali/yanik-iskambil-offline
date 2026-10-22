import 'package:flutter/material.dart';

class VipAvatar {
  final String key;
  final String title;
  final String emoji;
  final Color color;

  const VipAvatar({
    required this.key,
    required this.title,
    required this.emoji,
    required this.color,
  });

  static const List<VipAvatar> all = [
    VipAvatar(key: 'lion', title: 'Aslan', emoji: '🦁', color: Color(0xFFD97706)),
    VipAvatar(key: 'king', title: 'Kral', emoji: '👑', color: Color(0xFFEAB308)),
    VipAvatar(key: 'queen', title: 'Kraliçe', emoji: '👸', color: Color(0xFFEC4899)),
    VipAvatar(key: 'wolf', title: 'Kurt', emoji: '🐺', color: Color(0xFF3B82F6)),
    VipAvatar(key: 'boss', title: 'Boss', emoji: '🕶️', color: Color(0xFF10B981)),
    VipAvatar(key: 'joker', title: 'Joker', emoji: '🃏', color: Color(0xFF8B5CF6)),
  ];

  static VipAvatar fromKey(String? key) {
    return all.firstWhere(
      (a) => a.key == key,
      orElse: () => all.first,
    );
  }
}

class CardModel {
  final String id;
  final String suit; // 'S', 'H', 'D', 'C', 'J'
  final int rank; // 1..13, 0 for Joker
  final int deckIndex;
  final bool isPhysicalJoker;

  const CardModel({
    required this.id,
    required this.suit,
    required this.rank,
    required this.deckIndex,
    required this.isPhysicalJoker,
  });

  bool isWild(int wildRank) {
    return isPhysicalJoker || (wildRank > 0 && rank == wildRank);
  }

  String get rankLabel {
    if (isPhysicalJoker) return 'JOKER';
    switch (rank) {
      case 1:
        return 'A';
      case 11:
        return 'J';
      case 12:
        return 'Q';
      case 13:
        return 'K';
      default:
        return rank.toString();
    }
  }

  String get suitSymbol {
    if (isPhysicalJoker) return '🃏';
    switch (suit) {
      case 'S':
        return '♠';
      case 'H':
        return '♥';
      case 'D':
        return '♦';
      case 'C':
        return '♣';
      default:
        return '♠';
    }
  }

  Color get suitColor {
    if (isPhysicalJoker) return const Color(0xFF7C3AED);
    if (suit == 'H' || suit == 'D') {
      return const Color(0xFFDC2626);
    }
    return const Color(0xFF1E293B);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'suit': suit,
        'rank': rank,
        'deckIndex': deckIndex,
        'isPhysicalJoker': isPhysicalJoker,
      };

  factory CardModel.fromJson(Map<String, dynamic> json) => CardModel(
        id: json['id']?.toString() ?? '',
        suit: json['suit']?.toString() ?? 'S',
        rank: int.tryParse(json['rank']?.toString() ?? '0') ?? 0,
        deckIndex: int.tryParse(json['deckIndex']?.toString() ?? '1') ?? 1,
        isPhysicalJoker: json['isPhysicalJoker'] == true,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is CardModel && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => '$suitSymbol$rankLabel';
}

class HandEvaluation {
  final bool canFinish;
  final List<List<CardModel>> melds;
  final List<CardModel> unmelded;
  final int penalty;
  final List<CardModel> orderedCards;

  HandEvaluation({
    required this.canFinish,
    required this.melds,
    required this.unmelded,
    required this.penalty,
    required this.orderedCards,
  });
}

class ShowdownPlayerResult {
  final String userId;
  final String username;
  final String avatar;
  final int seatIndex;
  final bool isFinisher;
  final bool isFalseDeclarer;
  final List<List<CardModel>> melds;
  final List<CardModel> unmelded;
  final int roundPenalty;
  final int previousScore;
  final int newTotalScore;
  final bool burnedThisRound;

  ShowdownPlayerResult({
    required this.userId,
    required this.username,
    required this.avatar,
    required this.seatIndex,
    required this.isFinisher,
    required this.isFalseDeclarer,
    required this.melds,
    required this.unmelded,
    required this.roundPenalty,
    required this.previousScore,
    required this.newTotalScore,
    required this.burnedThisRound,
  });
}
