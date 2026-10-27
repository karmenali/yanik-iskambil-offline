import 'package:flutter/material.dart';
import '../engine/card_model.dart';
import '../l10n/l10n_extension.dart';
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
    final l10n = l10nOf(context);

    return PopScope(
      canPop: false, // Yanlışlıkla geri tuşuyla kapatmayı engelle
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
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
                padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F3224),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      isGameOver
                          ? l10n.summaryTitleGameOver
                          : l10n.summaryTitleRoundResult(roundNumber),
                      style: const TextStyle(
                        color: Color(0xFFFDE047),
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),

              // Şampiyonluk mesajı (varsa)
              if (winnerMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 14),
                  color: const Color(0xFFD97706).withValues(alpha: 0.25),
                  child: Text(
                    winnerMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFFDE047),
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              // Oyuncuların elleri ve ceza puanları (Dikey Kaydırılabilir)
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  itemCount: results.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final res = results[i];
                    return _buildPlayerResultCard(res, l10n);
                  },
                ),
              ),

              // Aksiyon Butonları (Oyun bittiyse: Ana Menü ve Tekrar Oyna; Normal tur sonuysa: Devam Et)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
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
                                  AdService.instance.showInterstitialAd(
                                    roundNumber: roundNumber,
                                    onDismissed: () {
                                      onMainMenu?.call();
                                    },
                                  );
                                },
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.home_rounded,
                                        color: Color(0xFFFDE047),
                                        size: 19,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        l10n.summaryBtnMainMenu,
                                        style: const TextStyle(
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
                                    roundNumber: roundNumber,
                                    onDismissed: () {
                                      if (onPlayAgain != null) {
                                        onPlayAgain!();
                                      } else {
                                        onContinue();
                                      }
                                    },
                                  );
                                },
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.replay_rounded, size: 20),
                                      const SizedBox(width: 6),
                                      Text(
                                        l10n.summaryBtnPlayAgain,
                                        style: const TextStyle(
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
                              roundNumber: roundNumber,
                              onDismissed: onContinue,
                            );
                          },
                          child: Text(
                            l10n.summaryBtnContinue,
                            style: const TextStyle(
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

  Widget _buildPlayerResultCard(ShowdownPlayerResult res, AppLocalizations l10n) {
    final avatar = VipAvatar.fromKey(res.avatar);
    final bool isMe = res.userId == 'user_me';

    // Kart Boyutları: Okunabilir profesyonel standart (40×58 dp)
    const double cardW = 40.0;
    const double cardH = 58.0;

    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: res.isFinisher
            ? const Color(0xFF133827)
            : (isMe ? const Color(0xFF0B2217) : const Color(0xFF05160F)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: res.isFinisher
              ? const Color(0xFF10B981)
              : (res.burnedThisRound
                  ? const Color(0xFFDC2626)
                  : (isMe ? const Color(0xFFD4AF37).withValues(alpha: 0.7) : Colors.white12)),
          width: res.isFinisher ? 1.6 : (isMe ? 1.2 : 1.0),
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
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: res.username,
                            style: TextStyle(
                              color: isMe ? const Color(0xFFFDE047) : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          if (isMe)
                            TextSpan(
                              text: l10n.tablePlayerYouSuffix,
                              style: const TextStyle(
                                color: Color(0xFFFDE047),
                                fontWeight: FontWeight.bold,
                                fontSize: 10.5,
                              ),
                            ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      res.isFinisher
                          ? l10n.summaryPlayerDeclared
                          : (res.isFalseDeclarer
                              ? l10n.summaryPlayerFalseFinish
                              : l10n.summaryPlayerUnmeldedCards(res.unmelded.length)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: Column(
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
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        res.burnedThisRound
                            ? l10n.summaryPlayerBust(res.newTotalScore)
                            : l10n.summaryPlayerTotalScore(res.newTotalScore),
                        style: TextStyle(
                          color: res.burnedThisRound
                              ? const Color(0xFFDC2626)
                              : const Color(0xFFFDE047),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Alt Satır: Perler ve Kalan Kağıtlar (Yatay Kaydırılabilir)
          if (res.melds.isNotEmpty || res.unmelded.isNotEmpty) ...[
            const SizedBox(height: 7),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. PER KAPSÜLLERİ (MELD CAPSULES) - Her per bağımsız çerçevede ve 12 dp aralıkla
                  for (int mIdx = 0; mIdx < res.melds.length; mIdx++)
                    _buildMeldCapsule(res.melds[mIdx], mIdx + 1, cardW, cardH, l10n),

                  // 2. ELDE KALANLAR (DEADWOOD) - Belirgin kırmızı/amber çerçeveli ayrılmış panel
                  if (res.unmelded.isNotEmpty)
                    _buildDeadwoodPanel(res.unmelded, cardW, cardH, l10n),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Bağımsız Per Kapsülü Bileşeni
  Widget _buildMeldCapsule(
    List<CardModel> meld,
    int meldNumber,
    double cardW,
    double cardH,
    AppLocalizations l10n,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.fromLTRB(5, 4, 5, 5),
      decoration: BoxDecoration(
        color: const Color(0xFF063322).withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.70),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 3, left: 1),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 10,
                  color: Color(0xFF34D399),
                ),
                const SizedBox(width: 3),
                Text(
                  l10n.summaryMeldBadge(meldNumber),
                  style: const TextStyle(
                    color: Color(0xFF34D399),
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: meld.map((c) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: PlayingCardWidget(
                  card: c,
                  wildRank: wildRank,
                  width: cardW,
                  height: cardH,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Boşta Kalan Kartlar (Deadwood) Paneli Bileşeni
  Widget _buildDeadwoodPanel(
    List<CardModel> unmelded,
    double cardW,
    double cardH,
    AppLocalizations l10n,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.fromLTRB(5, 4, 5, 5),
      decoration: BoxDecoration(
        color: const Color(0xFF261010).withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.70),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 3, left: 1),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 10,
                  color: Color(0xFFF87171),
                ),
                const SizedBox(width: 3),
                Text(
                  l10n.summaryDeadwoodBadge(unmelded.length),
                  style: const TextStyle(
                    color: Color(0xFFF87171),
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: unmelded.map((c) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: PlayingCardWidget(
                  card: c,
                  wildRank: wildRank,
                  width: cardW,
                  height: cardH,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
