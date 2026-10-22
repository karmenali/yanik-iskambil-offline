import 'package:flutter/material.dart';
import '../engine/card_model.dart';
import '../engine/game_engine.dart';
import '../engine/offline_table_controller.dart';
import '../services/settings_service.dart';
import '../widgets/playing_card_widget.dart';
import '../widgets/round_summary_dialog.dart';
import '../widgets/seat_widget.dart';
import 'settings_dialog.dart';

class OfflineTableScreen extends StatefulWidget {
  const OfflineTableScreen({super.key});

  @override
  State<OfflineTableScreen> createState() => _OfflineTableScreenState();
}

class _OfflineTableScreenState extends State<OfflineTableScreen> {
  final _ctrl = OfflineTableController.instance;
  bool _showingSummaryDialog = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onTableUpdate);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onTableUpdate);
    super.dispose();
  }

  void _onTableUpdate() {
    if (!mounted) return;
    setState(() {});

    // Tur sonu özeti geldiyse ve henüz modal açılmadıysa ANINDA aç! (Süre yok)
    if (_ctrl.status == 'round_summary' &&
        _ctrl.lastShowdown != null &&
        !_showingSummaryDialog) {
      _showingSummaryDialog = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => RoundSummaryDialog(
            results: _ctrl.lastShowdown!,
            roundNumber: _ctrl.roundNumber,
            wildRank: _ctrl.wildRank,
            winnerMessage: _ctrl.winnerMessage,
            onContinue: () {
              _showingSummaryDialog = false;
              _ctrl.continueAfterRound();
            },
          ),
        ).then((_) {
          _showingSummaryDialog = false;
        });
      });
    }
  }

  Future<bool> _onWillPop() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A2218),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFD4AF37)),
        ),
        title: const Text(
          'Masadan Çıkılsın mı?',
          style: TextStyle(color: Color(0xFFFDE047), fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Mevcut oyun sonlandırılacak ve ana menüye dönülecektir.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İPTAL', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ÇIK'),
          ),
        ],
      ),
    );
    return leave == true;
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.instance;
    final isAssisted = settings.isAssisted;

    // Oyuncuların el analizi (Yardımlı mod için)
    HandEvaluation? eval;
    if (isAssisted && _ctrl.players.isNotEmpty) {
      eval = GameEngine.evaluateHandOptimal(_ctrl.players[0].hand, _ctrl.wildRank);
    }

    final meldedCardIds = eval?.melds.expand((m) => m).map((c) => c.id).toSet() ?? {};

    // 11 kağıt varsa bitiş kontrolü
    bool canDeclareWin = false;
    if (_ctrl.isHumanTurn && _ctrl.hasDrawnThisTurn && _ctrl.players[0].hand.length == 11) {
      if (isAssisted) {
        final winCheck = GameEngine.findWinningDiscard(
          _ctrl.players[0].hand,
          _ctrl.wildRank,
          preferredDiscardCardId: _ctrl.selectedCardId,
        );
        canDeclareWin = winCheck.canWin;
      } else {
        // Yardımsız modda oyuncu istediği zaman el açabilir (risk alır)
        canDeclareWin = true;
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldLeave = await _onWillPop();
        if (shouldLeave && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Arka Plan
            Positioned.fill(
              child: Image.asset(
                'assets/images/table_bg.jpg',
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.35),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // 1. ÜST BAR: Geri, Tur Bilgisi, Ayarlar
                  _buildTopBar(),

                  // 2. KUZEY OYUNCUSU (BOT 2 - ZEYNEP)
                  if (_ctrl.players.length >= 4)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: SeatWidget(
                        username: _ctrl.players[2].username,
                        avatarKey: _ctrl.players[2].avatar,
                        totalScore: _ctrl.players[2].totalScore,
                        cardCount: _ctrl.players[2].hand.length,
                        isCurrentTurn: _ctrl.currentTurnSeat == 2,
                        isDealer: _ctrl.dealerSeat == 2,
                        isEliminated: _ctrl.players[2].isEliminated,
                        isBot: true,
                      ),
                    ),

                  const Spacer(flex: 1),

                  // 3. ORTA ALAN: BATI (BOT 3), MASA ORTASI (DESTE/ATILAN), DOĞU (BOT 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // BATI (BOT 3 - MEHMET)
                        if (_ctrl.players.length >= 4)
                          SeatWidget(
                            username: _ctrl.players[3].username,
                            avatarKey: _ctrl.players[3].avatar,
                            totalScore: _ctrl.players[3].totalScore,
                            cardCount: _ctrl.players[3].hand.length,
                            isCurrentTurn: _ctrl.currentTurnSeat == 3,
                            isDealer: _ctrl.dealerSeat == 3,
                            isEliminated: _ctrl.players[3].isEliminated,
                            isBot: true,
                          ),

                        // ORTA MASA: Deste (Çekmece), Gösterge Jokeri, Atılan Kartlar
                        _buildCenterTableArea(),

                        // DOĞU (BOT 1 - AHMET)
                        if (_ctrl.players.length >= 4)
                          SeatWidget(
                            username: _ctrl.players[1].username,
                            avatarKey: _ctrl.players[1].avatar,
                            totalScore: _ctrl.players[1].totalScore,
                            cardCount: _ctrl.players[1].hand.length,
                            isCurrentTurn: _ctrl.currentTurnSeat == 1,
                            isDealer: _ctrl.dealerSeat == 1,
                            isEliminated: _ctrl.players[1].isEliminated,
                            isBot: true,
                          ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),

                  // 4. İNSAN OYUNCUNUN BİLGİ VE AKSİYON ÇUBUĞU
                  _buildActionBar(eval, canDeclareWin),

                  const SizedBox(height: 6),

                  // 5. 3 SIRALI ISTAKA ALANI
                  _buildHumanRack(meldedCardIds, isAssisted),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // ÜST BAR
  // ===========================================================================
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
            onPressed: () async {
              final leave = await _onWillPop();
              if (leave && mounted) Navigator.pop(context);
            },
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Text(
                  'TUR ${_ctrl.roundNumber}',
                  style: const TextStyle(
                    color: Color(0xFFFDE047),
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.white54,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  SettingsService.instance.isAssisted ? 'Yardımlı' : 'Yardımsız',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFFFDE047), size: 22),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const SettingsDialog(),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ORTA MASA: Deste + Gösterge Jokeri + Atılan Kartlar
  // ===========================================================================
  Widget _buildCenterTableArea() {
    final canDrawFromDeck = _ctrl.isHumanTurn && !_ctrl.hasDrawnThisTurn;
    final topDiscard = _ctrl.discardPile.isNotEmpty ? _ctrl.discardPile.last : null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // DESTE (Çekilecek Kağıtlar + Gösterge Jokeri)
        GestureDetector(
          onTap: canDrawFromDeck
              ? () => _ctrl.humanDrawCard(fromDiscard: false)
              : null,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Gösterge Jokeri (Altta, yarısı sağa/yukarı kayık)
              if (_ctrl.indicatorCard != null)
                Positioned(
                  left: 14,
                  top: 0,
                  child: Transform.rotate(
                    angle: 0.12,
                    child: PlayingCardWidget(
                      card: _ctrl.indicatorCard!,
                      wildRank: _ctrl.wildRank,
                      width: 50,
                      height: 72,
                    ),
                  ),
                ),

              // Kapalı Deste Gövdesi
              Container(
                width: 50,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: canDrawFromDeck
                        ? const Color(0xFFFDE047)
                        : Colors.white54,
                    width: canDrawFromDeck ? 2.0 : 1.0,
                  ),
                  boxShadow: canDrawFromDeck
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFDE047).withValues(alpha: 0.5),
                            blurRadius: 10,
                            spreadRadius: 1,
                          )
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.layers, color: Colors.white70, size: 20),
                    const SizedBox(height: 2),
                    Text(
                      '${_ctrl.drawPile.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              if (canDrawFromDeck)
                Positioned(
                  bottom: -18,
                  left: -8,
                  right: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'KART ÇEK',
                      style: TextStyle(
                        color: Color(0xFF0A2218),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(width: 32),

        // ATILAN KART YIĞINI (DISCARD PILE)
        GestureDetector(
          onTap: (canDrawFromDeck && topDiscard != null)
              ? () => _ctrl.humanDrawCard(fromDiscard: true)
              : null,
          child: Container(
            width: 50,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white24, width: 1.0),
            ),
            alignment: Alignment.center,
            child: topDiscard != null
                ? PlayingCardWidget(
                    card: topDiscard,
                    wildRank: _ctrl.wildRank,
                    width: 50,
                    height: 72,
                  )
                : const Text(
                    'BOŞ',
                    style: TextStyle(color: Colors.white30, fontSize: 10),
                  ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // AKSİYON ÇUBUĞU (SIRALA, AT, EL AÇ)
  // ===========================================================================
  Widget _buildActionBar(HandEvaluation? eval, bool canDeclareWin) {
    final hasDrawn = _ctrl.hasDrawnThisTurn;
    final isTurn = _ctrl.isHumanTurn;
    final hasSelected = _ctrl.selectedCardId != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Sol: Per Diz & Sayı Sırala
          Row(
            children: [
              _buildSmallActionButton(
                label: 'Per Diz',
                icon: Icons.auto_awesome,
                onTap: _ctrl.humanSortMelds,
              ),
              const SizedBox(width: 8),
              _buildSmallActionButton(
                label: 'Sayı Sırala',
                icon: Icons.sort_by_alpha,
                onTap: _ctrl.humanSortRanks,
              ),
            ],
          ),

          // Orta: Durum / Ceza Bilgisi (Yardımlı Modda)
          if (eval != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: eval.canFinish
                    ? const Color(0xFF10B981).withValues(alpha: 0.3)
                    : Colors.black45,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: eval.canFinish
                      ? const Color(0xFF10B981)
                      : const Color(0xFFD4AF37).withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                eval.canFinish
                    ? '✓ El Açılabilir!'
                    : 'Ceza: ${eval.penalty}',
                style: TextStyle(
                  color: eval.canFinish
                      ? const Color(0xFF34D399)
                      : const Color(0xFFFDE047),
                  fontWeight: FontWeight.bold,
                  fontSize: 11.5,
                ),
              ),
            ),

          // Sağ: KART AT & EL AÇ
          Row(
            children: [
              // El Aç Butonu
              if (isTurn && hasDrawn)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canDeclareWin
                        ? const Color(0xFF10B981)
                        : Colors.white24,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _ctrl.humanDeclareFinish,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.workspace_premium, size: 16),
                      SizedBox(width: 4),
                      Text('EL AÇ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                    ],
                  ),
                ),

              const SizedBox(width: 8),

              // Kart At Butonu
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: (isTurn && hasDrawn && hasSelected)
                      ? const Color(0xFFD4AF37)
                      : Colors.white24,
                  foregroundColor: (isTurn && hasDrawn && hasSelected)
                      ? const Color(0xFF0A2218)
                      : Colors.white38,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: (isTurn && hasDrawn && hasSelected)
                    ? () => _ctrl.humanDiscardCard(_ctrl.selectedCardId!)
                    : null,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_upward, size: 16),
                    SizedBox(width: 4),
                    Text('AT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFFFDE047), size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 3 SIRALI ISTAKA (RACK)
  // ===========================================================================
  Widget _buildHumanRack(Set<String> meldedCardIds, bool isAssisted) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF071F15).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _ctrl.isHumanTurn
              ? const Color(0xFFFDE047)
              : const Color(0xFFD4AF37).withValues(alpha: 0.5),
          width: _ctrl.isHumanTurn ? 1.8 : 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRackRow(0, meldedCardIds, isAssisted),
          const SizedBox(height: 5),
          _buildRackRow(1, meldedCardIds, isAssisted),
          const SizedBox(height: 5),
          _buildRackRow(2, meldedCardIds, isAssisted),
        ],
      ),
    );
  }

  Widget _buildRackRow(int rowIndex, Set<String> meldedCardIds, bool isAssisted) {
    final rowCards = _ctrl.humanRows[rowIndex];

    return DragTarget<String>(
      onAcceptWithDetails: (details) {
        _ctrl.moveCard(details.data, rowIndex, rowCards.length);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          height: 68,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty
                ? const Color(0xFF10B981).withValues(alpha: 0.25)
                : Colors.black26,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: candidateData.isNotEmpty
                  ? const Color(0xFF10B981)
                  : Colors.white12,
            ),
          ),
          child: rowCards.isEmpty
              ? const Center(
                  child: Text(
                    'Sıra Boş',
                    style: TextStyle(color: Colors.white24, fontSize: 10),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: rowCards.length,
                  itemBuilder: (ctx, i) {
                    final card = rowCards[i];
                    final isSelected = _ctrl.selectedCardId == card.id;
                    final isMelded = meldedCardIds.contains(card.id);

                    final cardWidget = PlayingCardWidget(
                      card: card,
                      wildRank: _ctrl.wildRank,
                      showWildHints: isAssisted,
                      isSelected: isSelected,
                      isMelded: isMelded,
                      width: 44,
                      height: 64,
                      onTap: () => _ctrl.selectCard(card.id),
                    );

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Draggable<String>(
                        data: card.id,
                        feedback: Material(
                          color: Colors.transparent,
                          child: Opacity(
                            opacity: 0.85,
                            child: PlayingCardWidget(
                              card: card,
                              wildRank: _ctrl.wildRank,
                              showWildHints: isAssisted,
                              width: 48,
                              height: 70,
                            ),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.3,
                          child: cardWidget,
                        ),
                        child: cardWidget,
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
