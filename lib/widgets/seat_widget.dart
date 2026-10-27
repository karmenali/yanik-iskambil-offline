import 'package:flutter/material.dart';
import '../engine/card_model.dart';
import '../l10n/l10n_extension.dart';

class SeatWidget extends StatelessWidget {
  final String username;
  final String avatarKey;
  final int totalScore;
  final int cardCount;
  final bool isCurrentTurn;
  final bool isDealer;
  final bool isEliminated;
  final bool isBot;

  const SeatWidget({
    super.key,
    required this.username,
    required this.avatarKey,
    required this.totalScore,
    required this.cardCount,
    required this.isCurrentTurn,
    this.isDealer = false,
    this.isEliminated = false,
    this.isBot = false,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = VipAvatar.fromKey(avatarKey);
    final l10n = l10nOf(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isCurrentTurn
            ? const Color(0xFF1E3A2B).withValues(alpha: 0.95)
            : const Color(0xFF0A2218).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentTurn
              ? const Color(0xFFFDE047)
              : (isEliminated
                  ? const Color(0xFFDC2626)
                  : const Color(0xFFD4AF37).withValues(alpha: 0.4)),
          width: isCurrentTurn ? 2.0 : 1.2,
        ),
        boxShadow: isCurrentTurn
            ? [
                BoxShadow(
                  color: const Color(0xFFFDE047).withValues(alpha: 0.35),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: avatar.color.withValues(alpha: 0.25),
                  border: Border.all(
                    color: isEliminated ? const Color(0xFFDC2626) : avatar.color,
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  avatar.emoji,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              if (isDealer)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Color(0xFFD97706),
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      'D',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),

          // Bilgiler
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    username,
                    style: TextStyle(
                      color: isEliminated ? Colors.white54 : Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      decoration:
                          isEliminated ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (isBot) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'BOT',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ceza Puanı
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: isEliminated
                          ? const Color(0xFF7F1D1D)
                          : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isEliminated
                        ? l10n.tableScoresheetBust
                        : l10n.tablePlayerPenalty(totalScore),
                    style: TextStyle(
                      color: isEliminated
                          ? const Color(0xFFFCA5A5)
                          : (totalScore >= 80
                              ? const Color(0xFFF87171)
                              : const Color(0xFFFDE047)),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (isBot && !isEliminated) ...[
                  const SizedBox(width: 6),
                  Text(
                    '🎴 $cardCount',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ],
    ),
  );
}
}
