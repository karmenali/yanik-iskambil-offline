import 'package:flutter/material.dart';
import '../engine/card_model.dart';
import 'vector_card_renderer.dart';

class PlayingCardWidget extends StatelessWidget {
  final CardModel card;
  final int wildRank;
  final bool showWildHints;
  final bool isSelected;
  final bool isMelded;
  final bool isWinningDiscardCandidate;
  final double width;
  final double height;
  final VoidCallback? onTap;

  const PlayingCardWidget({
    super.key,
    required this.card,
    required this.wildRank,
    this.showWildHints = true,
    this.isSelected = false,
    this.isMelded = false,
    this.isWinningDiscardCandidate = false,
    this.width = 62,
    this.height = 90,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPhysicalJoker = card.isPhysicalJoker;
    final bool isIndicatorWild =
        showWildHints && !isPhysicalJoker && wildRank > 0 && card.rank == wildRank;
    final bool showAsWild = isPhysicalJoker || isIndicatorWild;

    String normalizedSuit = card.suit.toUpperCase();
    if (normalizedSuit.startsWith('SPADE')) {
      normalizedSuit = 'S';
    } else if (normalizedSuit.startsWith('HEART')) {
      normalizedSuit = 'H';
    } else if (normalizedSuit.startsWith('DIAMOND')) {
      normalizedSuit = 'D';
    } else if (normalizedSuit.startsWith('CLUB')) {
      normalizedSuit = 'C';
    } else if (normalizedSuit.isNotEmpty) {
      normalizedSuit = normalizedSuit[0];
    } else {
      normalizedSuit = 'S';
    }

    final cardBody = SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          // GPU Hızlandırmalı Vektörel Kart
          Positioned.fill(
            child: CustomPaint(
              size: Size(width, height),
              painter: VectorCardPainter(
                rank: card.rank,
                suit: normalizedSuit,
                isPhysicalJoker: isPhysicalJoker,
                showAsWild: showAsWild,
                isSelected: isSelected,
                isWinningDiscardCandidate: isWinningDiscardCandidate,
              ),
            ),
          ),

          // Yardımlı modda per rozeti
          if (isMelded && showWildHints)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 9,
                  color: Colors.white,
                ),
              ),
            ),

          // Joker altın tacı (Yardımlı modda)
          if (showAsWild && showWildHints)
            Positioned(
              top: 2,
              left: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '★',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, isSelected ? -10.0 : 0.0, 0),
        child: cardBody,
      ),
    );
  }
}
