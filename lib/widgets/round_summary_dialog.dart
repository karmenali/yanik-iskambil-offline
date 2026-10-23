import 'package:flutter/material.dart';
import '../engine/card_model.dart';
import '../services/ad_service.dart';
import 'playing_card_widget.dart';

class RoundSummaryDialog extends StatelessWidget {
  final List<ShowdownPlayerResult> results;
  final int roundNumber;
  final int wildRank;
  final String? winnerMessage;
  final VoidCallback onContinue;
  final VoidCallback? onPlayAgain;
  final VoidCallback? onMainMenu;

  const RoundSummaryDialog({
    super.key,
    required this.results,
    required this.roundNumber,
    required this.wildRank,
    this.winnerMessage,
    required this.onContinue,
    this.onPlayAgain,
    this.onMainMenu,
  });

  @override
  Widget build(BuildContext context) {
    final isGameOver = winnerMessage != null;

    return PopScope(
      canPop: false, // Yanlışlıkla geri tuşuyla kapatmayı engelle
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF091C14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFD4AF37),
              width: 1.8,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black87,
                blurRadius: 25,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Başlık
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F3224),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isGameOver ? '🏆 OYUN BİTTİ' : '📊 TUR $roundNumber SONUCU',
                      style: const TextStyle(
                        color: Color(0xFFFDE047),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Şampiyonluk mesajı (varsa)
              if (winnerMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  color: const Color(0xFFD97706).withValues(alpha: 0.25),
                  child: Text(
                    winnerMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFFDE047),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              // Oyuncuların elleri ve ceza puanları
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(14),
                  itemCount: results.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final res = results[i];
                    return _buildPlayerResultCard(res);
                  },
                ),
              ),

              // Aksiyon Butonları (Oyun bittiyse: Ana Menü ve Tekrar Oyna; Normal tur sonuysa: Devam Et)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: isGameOver
                    ? Row(
                        children: [
                          // 1. Ana Menü Butonu
                          Expanded(
                            flex: 4,
                            child: SizedBox(
                              height: 48,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Color(0xFFD4AF37),
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  backgroundColor: Colors.black38,
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  onMainMenu?.call();
                                },
                                child: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.home_rounded,
                                        color: Color(0xFFFDE047),
                                        size: 19,
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        'ANA MENÜ',
                                        style: TextStyle(
                                          color: Color(0xFFFDE047),
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // 2. Tekrar Oyna Butonu
                          Expanded(
                            flex: 6,
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD4AF37),
                                  foregroundColor: const Color(0xFF0A2218),
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  AdService.instance.showInterstitialAd(
                                    onDismissed: () {
                                      if (onPlayAgain != null) {
                                        onPlayAgain!();
                                      } else {
                                        onContinue();
                                      }
                                    },
                                  );
                                },
                                child: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.replay_rounded, size: 20),
                                      SizedBox(width: 6),
                                      Text(
                                        'TEKRAR OYNA 🏆',
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4AF37),
                            foregroundColor: const Color(0xFF0A2218),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            AdService.instance.showInterstitialAd(
                              onDismissed: onContinue,
                            );
                          },
                          child: const Text(
                            'DEVAM ET ➜',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerResultCard(ShowdownPlayerResult res) {
    final avatar = VipAvatar.fromKey(res.avatar);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: res.isFinisher
            ? const Color(0xFF133827)
            : const Color(0xFF05160F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: res.isFinisher
              ? const Color(0xFF10B981)
              : (res.burnedThisRound
                  ? const Color(0xFFDC2626)
                  : Colors.white12),
          width: res.isFinisher ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst Satır: Avatar, İsim, Durum, Ceza Puanı
          Row(
            children: [
              Text(avatar.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      res.username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      res.isFinisher
                          ? '✨ Eli Açtı (0 Ceza)'
                          : (res.isFalseDeclarer
                              ? '❌ Hatalı El Açma (101 Ceza)'
                              : 'Boşta: ${res.unmelded.length} kağıt'),
                      style: TextStyle(
                        color: res.isFinisher
                            ? const Color(0xFF34D399)
                            : (res.isFalseDeclarer
                                ? const Color(0xFFF87171)
                                : Colors.white60),
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '+${res.roundPenalty}',
                    style: TextStyle(
                      color: res.isFinisher
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF87171),
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    res.burnedThisRound
                        ? '🔥 YANDI (${res.newTotalScore})'
                        : 'Toplam: ${res.newTotalScore} / 101',
                    style: TextStyle(
                      color: res.burnedThisRound
                          ? const Color(0xFFDC2626)
                          : const Color(0xFFFDE047),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Alt Satır: Perler ve Kalan Kağıtlar
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Perler
                ...res.melds.map((meld) {
                  return Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: meld.map((c) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1.5),
                          child: PlayingCardWidget(
                            card: c,
                            wildRank: wildRank,
                            width: 24,
                            height: 35,
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }),

                // Boşta kalanlar
                if (res.unmelded.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: res.unmelded.map((c) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1.5),
                          child: PlayingCardWidget(
                            card: c,
                            wildRank: wildRank,
                            width: 24,
                            height: 35,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
