import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../engine/card_model.dart';
import '../engine/offline_table_controller.dart';
import '../services/sound_fx.dart';
import '../widgets/playing_card_widget.dart';
import '../widgets/round_summary_dialog.dart';
import 'settings_dialog.dart';

class _HitCardResult {
  final CardModel card;
  final int row;
  final int index;
  final Offset grabOffset;

  _HitCardResult({
    required this.card,
    required this.row,
    required this.index,
    required this.grabOffset,
  });
}

class OfflineTableScreen extends StatefulWidget {
  const OfflineTableScreen({super.key});

  @override
  State<OfflineTableScreen> createState() => _OfflineTableScreenState();
}

class _OfflineTableScreenState extends State<OfflineTableScreen>
    with WidgetsBindingObserver {
  final _ctrl = OfflineTableController.instance;
  bool _showingSummaryDialog = false;
  bool _showScoreboardModal = false;

  // 3 Sıralı Istaka Sürükleme ve Yerel Durum
  List<List<CardModel>> _localRows = [[], [], []];
  String? _draggingCardId;
  Offset _dragGrabOffset = Offset.zero;
  Offset _dragLocalPos = Offset.zero;
  int _lastTargetRowIndex = -1;
  int _lastTargetSlotIndex = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncLocalRowsFromController();
    _ctrl.addListener(_onTableUpdate);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ctrl.removeListener(_onTableUpdate);
    _ctrl.stopGame();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _ctrl.pauseGame();
    } else if (state == AppLifecycleState.resumed) {
      _ctrl.resumeGame();
    }
  }

  void _syncLocalRowsFromController() {
    _localRows = [
      List<CardModel>.from(_ctrl.humanRows[0]),
      List<CardModel>.from(_ctrl.humanRows[1]),
      List<CardModel>.from(_ctrl.humanRows[2]),
    ];
  }

  void _onTableUpdate() {
    if (!mounted) return;

    // Kullanıcı o an parmağıyla kart sürüklemiyorsa controller ile senkronize et
    if (_draggingCardId == null) {
      _syncLocalRowsFromController();
    }

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
            onPlayAgain: () {
              _showingSummaryDialog = false;
              _ctrl.initMatch();
              _syncLocalRowsFromController();
              if (mounted) setState(() {});
            },
            onMainMenu: () {
              _showingSummaryDialog = false;
              _ctrl.stopGame();
              if (mounted) Navigator.of(context).pop();
            },
          ),
        ).then((_) {
          _showingSummaryDialog = false;
        });
      });
    }
  }

  Future<void> _confirmAndLeaveTable() async {
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
    if (leave == true && mounted) {
      _ctrl.stopGame();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final seats = _ctrl.players;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _confirmAndLeaveTable();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF06140E),
        body: Stack(
          children: [
            // 1. ZYNGA 3D MAUN & ZÜMRÜT ÇUHA MASA ARKA PLAN GÖRSELİ
            Positioned.fill(
              child: RepaintBoundary(
                child: Image.asset(
                  'assets/images/table_bg.jpg',
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -0.2),
                ),
              ),
            ),

            Positioned.fill(
              child: RepaintBoundary(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.45),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.82),
                      ],
                      stops: const [0.0, 0.42, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // 2. ANA DİKEY ZYNGA MASA DÜZENİ (ÜST MASA + ALT 3 SIRALI DİKEY ISTAKA)
            SafeArea(
              child: Column(
                children: [
                  _buildZyngaTopBar(),

                  // ORTA CASINO MASASI (Saat Yönünde 4 Koltuk, Gösterge Jokeri, Deste ve Atılan Kağıt)
                  Expanded(
                    flex: 46,
                    child: _buildZyngaCasinoTableArea(seats),
                  ),

                  // ALT OYUNCU ELİ: 3 SIRALI DİKEY ISTAKA + 60 FPS SÜRÜKLEME + 4 ZYNGA BUTONU
                  Expanded(
                    flex: 54,
                    child: RepaintBoundary(
                      child: _buildThreeRowBottomHandAndControls(),
                    ),
                  ),
                ],
              ),
            ),

            // 3. TAM 101 PUAN TABLOSU MODALI (Açıldığında)
            if (_showScoreboardModal) _buildScoreboardOverlay(),

            // 4. OYUN BİTTİ DÖNGÜSÜ GÜVENLİK MODALI
            if (_ctrl.status == 'game_over' && !_showingSummaryDialog)
              _buildGameOverOverlay(),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. ÜST BAR (Ahşap & Altın Tasarım)
  // ===========================================================================
  Widget _buildZyngaTopBar() {
    final isAssisted = _ctrl.isAssisted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E130C), Color(0xFF2D1B10), Color(0xFF1E130C)],
        ),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.75),
            width: 1.5,
          ),
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black87, blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          // Geri Butonu
          InkWell(
            onTap: _confirmAndLeaveTable,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF3E2723), Color(0xFF1B0F0D)],
                ),
                border: Border.all(
                  color: const Color(0xFFD4AF37),
                  width: 1.3,
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFFFDE047),
                size: 13,
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Mod Rozeti (Yardımlı / Yardımsız)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isAssisted
                    ? const [Color(0xFF1E3A8A), Color(0xFF0F172A)]
                    : const [Color(0xFF991B1B), Color(0xFF450A0A)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFD4AF37),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isAssisted ? '✨' : '🔥',
                  style: const TextStyle(fontSize: 10),
                ),
                const SizedBox(width: 3),
                Text(
                  isAssisted ? 'Yardımlı' : 'Yardımsız',
                  style: const TextStyle(
                    color: Color(0xFFFDE047),
                    fontWeight: FontWeight.w900,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // Tur Rozeti
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.65),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.refresh_rounded, color: Color(0xFFFDE047), size: 12),
                const SizedBox(width: 3),
                Text(
                  'El ${_ctrl.roundNumber}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // 101 Puan Tablosu Butonu
          InkWell(
            onTap: () {
              SoundFx.playCardTap();
              setState(() => _showScoreboardModal = !_showScoreboardModal);
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD4AF37)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.leaderboard, color: Color(0xFFFDE047), size: 13),
                  SizedBox(width: 3),
                  Text(
                    '101',
                    style: TextStyle(
                      color: Color(0xFFFDE047),
                      fontWeight: FontWeight.w900,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Ayarlar Dişlisi
          InkWell(
            onTap: () {
              SoundFx.playCardTap();
              showDialog(
                context: context,
                builder: (_) => const SettingsDialog(),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black54,
                border: Border.all(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.65),
                ),
              ),
              child: const Icon(
                Icons.settings,
                color: Colors.white70,
                size: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. CASINO MASASI ALANI (Koltuklar + Masa Ortası)
  // ===========================================================================
  Widget _buildZyngaCasinoTableArea(List<OfflinePlayer> seats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        // Koltukları saat yönünde yerleştir (0: Sen sol-alt, 1: bot sol-üst, 2: bot sağ-üst, 3: bot sağ-alt)
        final seatPositions = _calculateRelativeSeatPositions(seats.length, 0, w, h);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // MASA ORTASI: GÖSTERGE JOKERİ + KAPALI DESTE + ATILAN KAĞIT
            Align(
              alignment: const Alignment(0, 0.05),
              child: _buildCenterTableFeltCards(),
            ),

            // SAAT YÖNÜNDE 4 OYUNCU AVATARI
            for (int i = 0; i < seats.length; i++)
              Positioned(
                left: seatPositions[i].dx,
                top: seatPositions[i].dy,
                child: _buildZyngaCircularSeatAvatar(
                  seat: seats[i],
                  seatIndex: i,
                ),
              ),
          ],
        );
      },
    );
  }

  /// Orijinal Masa Matematiksel Koltuk Pozisyonları (Sağdan Sola / Saat Yönünün Tersine)
  List<Offset> _calculateRelativeSeatPositions(
    int count,
    int mySeatIdx,
    double w,
    double h,
  ) {
    const double avatarWidth = 76.0;
    final double leftX = 6.0;
    final double rightX = w - avatarWidth - 6.0;

    // Sağdan sola (saat yönünün tersine) 4 koltuk:
    // 0: Sen (Sol-Alt - ortadaki gösterge kartına asla değmez)
    // 1: Sağ-Alt (Senin sağındaki oyuncu - Ahmet)
    // 2: Sağ-Üst (Zeynep)
    // 3: Sol-Üst (Mehmet - Senin solundaki oyuncu)
    final counterClockwiseSlots = [
      Offset(leftX + 2, h * 0.65), // 0: Sen (Sol-Alt)
      Offset(rightX - 2, h * 0.65), // 1: Sağ-Alt (Senin sağındaki oyuncu)
      Offset(rightX - 4, h * 0.03), // 2: Sağ-Üst
      Offset(leftX + 4, h * 0.03), // 3: Sol-Üst (Senin solundaki oyuncu)
    ];

    final result = List<Offset>.filled(count, Offset.zero);
    for (int seatIdx = 0; seatIdx < count; seatIdx++) {
      final rel = (seatIdx - mySeatIdx + count) % count;
      result[seatIdx] = counterClockwiseSlots[rel];
    }
    return result;
  }

  /// Orijinal 76px Dairesel Avatar Bileşeni (Sabit Neon Yeşil Çember, 'D' Dağıtan Rozeti, Puan Pili)
  Widget _buildZyngaCircularSeatAvatar({
    required OfflinePlayer seat,
    required int seatIndex,
  }) {
    final isMe = seatIndex == 0;
    final isCurrentTurn = _ctrl.status == 'playing' && _ctrl.currentTurnSeat == seatIndex;
    final isDealer = _ctrl.dealerSeat == seatIndex;
    final avatar = VipAvatar.fromKey(seat.avatar);

    return RepaintBoundary(
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Sabit %100 Dolu Neon Yeşil Halka (Dönmez, sabit ve temiz durur)
                if (isCurrentTurn)
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF22C55E),
                        width: 3.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.65),
                          blurRadius: 12,
                          spreadRadius: 1.5,
                        ),
                      ],
                    ),
                  ),

              // Avatar Dairesi
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      avatar.color.withValues(alpha: 0.55),
                      const Color(0xFF0F172A),
                    ],
                  ),
                  border: Border.all(
                    color: isMe ? const Color(0xFFFACC15) : const Color(0xFFD4AF37),
                    width: isMe ? 2.4 : 1.8,
                  ),
                ),
                child: Center(
                  child: Text(
                    avatar.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),

              // Dağıtan (Dealer 'D') Rozeti (Sol Alt)
              if (isDealer)
                Positioned(
                  left: 0,
                  bottom: 0,
                  child: Container(
                    width: 17,
                    height: 17,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFACC15),
                      border: Border.all(color: Colors.black, width: 1),
                    ),
                    child: const Center(
                      child: Text(
                        'D',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 9.5,
                        ),
                      ),
                    ),
                  ),
                ),

              // Elindeki Kağıt Sayısı Rozeti (Sağ Üst)
              if (_ctrl.status == 'playing' && !seat.isEliminated)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFD4AF37),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${seat.hand.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),

          // İsim ve 101 Puan Pili
          Container(
            width: 76,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: isCurrentTurn
                    ? const Color(0xFF22C55E)
                    : const Color(0xFFD4AF37).withValues(alpha: 0.65),
                width: 1.0,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  seat.isBot
                      ? '🤖 ${seat.username}'
                      : isMe
                          ? '${seat.username} (Sen)'
                          : seat.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isMe ? const Color(0xFFFDE047) : Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 8.5,
                  ),
                ),
                Text(
                  seat.isEliminated
                      ? 'YANDI (${seat.totalScore})'
                      : '${seat.totalScore}/101',
                  style: TextStyle(
                    color: seat.isEliminated || seat.totalScore >= 85
                        ? Colors.redAccent
                        : const Color(0xFFFDE047),
                    fontWeight: FontWeight.w900,
                    fontSize: 8.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  /// Masa Ortası: Gösterge Jokeri (Sol) + 3D Kapalı Deste (Orta) + Atılan Kağıt (Sağ)
  /// Sabit 72px genişlikli yuvalar sayesinde kart çekildiğinde veya atıldığında ASLA kayma olmaz!
  Widget _buildCenterTableFeltCards() {
    final indicator = _ctrl.indicatorCard;
    final drawCount = _ctrl.drawPileCount;
    final discardTop = _ctrl.topDiscardCard;
    final canDrawNow = _ctrl.isHumanTurn && !_ctrl.hasDrawnThisTurn;

    return Container(
      width: 260,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 1. GÖSTERGE JOKERİ (72px sabit genişlik)
          SizedBox(
            width: 72,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (indicator != null)
                  PlayingCardWidget(
                    card: indicator,
                    wildRank: _ctrl.wildRank,
                    showWildHints: true,
                    width: 52,
                    height: 74,
                  )
                else
                  const SizedBox(width: 52, height: 74),
                const SizedBox(height: 3),
                Text(
                  indicator != null
                      ? 'GÖSTERGE ${indicator.rankLabel}${indicator.suitSymbol}'
                      : 'GÖSTERGE',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFFDE047),
                    fontWeight: FontWeight.w900,
                    fontSize: 9.5,
                    shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                ),
              ],
            ),
          ),

          // 2. 3D KAPALI DESTE (72px sabit genişlik)
          SizedBox(
            width: 72,
            child: GestureDetector(
              onTap: canDrawNow ? () => _ctrl.humanDrawCard(fromDiscard: false) : null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: canDrawNow
                          ? [
                              BoxShadow(
                                color: const Color(0xFF22C55E).withValues(alpha: 0.8),
                                blurRadius: 14,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: CardBackWidget(
                      width: 52,
                      height: 74,
                      deckCount: drawCount,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    canDrawNow ? '👇 ÇEK ($drawCount)' : 'DESTE $drawCount',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: canDrawNow
                          ? const Color(0xFF4ADE80)
                          : const Color(0xFFFDE047),
                      fontWeight: FontWeight.w900,
                      fontSize: 9.5,
                      shadows: const [
                        Shadow(color: Colors.black, blurRadius: 4),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. ATILAN KAĞIT (72px sabit genişlik)
          SizedBox(
            width: 72,
            child: GestureDetector(
              onTap: () => _showDiscardHistorySheet(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  discardTop != null
                      ? PlayingCardWidget(
                          card: discardTop,
                          wildRank: _ctrl.wildRank,
                          showWildHints: _ctrl.isAssisted,
                          width: 52,
                          height: 74,
                        )
                      : Container(
                          width: 52,
                          height: 74,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.28),
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'ATILAN',
                              style: TextStyle(
                                color: Colors.white38,
                                fontWeight: FontWeight.bold,
                                fontSize: 8.5,
                              ),
                            ),
                          ),
                        ),
                  const SizedBox(height: 3),
                  Text(
                    discardTop != null
                        ? 'ATILAN ${discardTop.rankLabel}${discardTop.suitSymbol}'
                        : 'ATILAN',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFFDE047),
                      fontWeight: FontWeight.w900,
                      fontSize: 9.5,
                      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. ALT OYUNCU ELİ: 3 SIRALI ISTAKA + 4 ADET 3D ZYNGA BUTONU
  // ===========================================================================
  Widget _buildThreeRowBottomHandAndControls() {
    final isAssisted = _ctrl.isAssisted;
    final meldedIds = _ctrl.meldedCardIds;
    final canFinish = _ctrl.canFinishNow;
    final deadwoodPoints = _ctrl.currentHandPenalty;
    final isPlaying = _ctrl.isPlaying;
    final isMyTurn = _ctrl.isHumanTurn;
    final hasDrawn = _ctrl.hasDrawnThisTurn;

    CardModel? selectedCard;
    if (_ctrl.selectedCardId != null && _ctrl.players.isNotEmpty) {
      for (final card in _ctrl.players[0].hand) {
        if (card.id == _ctrl.selectedCardId) {
          selectedCard = card;
          break;
        }
      }
    }

    return Column(
      children: [
        // Bilgi Bandı (Ceza Puanı, El Açmaya Hazır, Seçili Kart)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: !isAssisted
                        ? const Color(0xFFEF4444)
                        : canFinish
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFD4AF37).withValues(alpha: 0.65),
                  ),
                ),
                child: Text(
                  !isAssisted
                      ? '🔥 Yardımsız Mod'
                      : canFinish
                          ? '✨ El Açmaya Hazır'
                          : 'Ceza: $deadwoodPoints Puan',
                  style: TextStyle(
                    color: !isAssisted
                        ? const Color(0xFFFCA5A5)
                        : canFinish
                            ? const Color(0xFF4ADE80)
                            : const Color(0xFFFDE047),
                    fontWeight: FontWeight.w900,
                    fontSize: 10.5,
                  ),
                ),
              ),
              if (selectedCard != null)
                Text(
                  'Seçili: ${selectedCard.rankLabel}${selectedCard.suitSymbol}',
                  style: const TextStyle(
                    color: Color(0xFFFDE047),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
        ),

        // 3 SIRALI DİKEY ISTAKA ALANI
        Expanded(
          child: _buildThreeRowInteractiveRack(
            meldedIds: meldedIds,
            isMyTurn: isMyTurn,
            hasDrawn: hasDrawn,
          ),
        ),

        // 4'LÜ ALT AKSİYON BUTONLARI (ZYNGA 3D TASARIM)
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 2, 8, 5),
          child: Row(
            children: [
              // 1. DESTEDEN ÇEK
              Expanded(
                child: _buildZynga3DButton(
                  label: 'DESTEDEN\nÇEK',
                  isGold: true,
                  enabled: isPlaying && isMyTurn && !hasDrawn,
                  glow: isPlaying && isMyTurn && !hasDrawn,
                  onTap: () => _ctrl.humanDrawCard(fromDiscard: false),
                ),
              ),
              const SizedBox(width: 6),

              // 2. OTOMATİK PER DİZ / SAYIYA GÖRE SIRALA
              Expanded(
                child: _buildZynga3DButton(
                  label: isAssisted ? 'OTOMATİK\nPER DİZ' : 'SAYIYA GÖRE\nSIRALA',
                  isGold: false,
                  enabled: _ctrl.players.isNotEmpty && _ctrl.players[0].hand.isNotEmpty,
                  onTap: () {
                    if (isAssisted) {
                      _ctrl.humanSortMelds();
                    } else {
                      _ctrl.humanSortRanks();
                    }
                    _syncLocalRowsFromController();
                  },
                ),
              ),
              const SizedBox(width: 6),

              // 3. KAĞIDI AT
              Expanded(
                child: _buildZynga3DButton(
                  label: 'KAĞIDI\nAT',
                  isGold: true,
                  enabled: isPlaying &&
                      isMyTurn &&
                      hasDrawn &&
                      _ctrl.selectedCardId != null,
                  glow: isPlaying &&
                      isMyTurn &&
                      hasDrawn &&
                      _ctrl.selectedCardId != null,
                  onTap: () {
                    if (_ctrl.selectedCardId != null) {
                      _ctrl.humanDiscardCard(_ctrl.selectedCardId!);
                      _syncLocalRowsFromController();
                    }
                  },
                ),
              ),
              const SizedBox(width: 6),

              // 4. EL AÇ / BİTİR
              Expanded(
                child: _buildZynga3DButton(
                  label: 'EL AÇ\nBİTİR',
                  isGold: false,
                  enabled: isPlaying && isMyTurn && canFinish,
                  glow: isPlaying && isMyTurn && canFinish,
                  onTap: () {
                    _ctrl.humanDeclareFinish();
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 3 Sıralı Dikey Istaka ve Pan Hareketleri
  Widget _buildThreeRowInteractiveRack({
    required Set<String> meldedIds,
    required bool isMyTurn,
    required bool hasDrawn,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;
        final rowH = (maxH / 3.0).floorToDouble().clamp(74.0, 126.0);
        final cardH = (rowH * 0.94).floorToDouble().clamp(68.0, 116.0);
        final cardW = (cardH * 0.70).floorToDouble().clamp(48.0, 82.0);

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: (details) {
            final pos = details.localPosition;
            final hitResult = _hitTestCardWithOffset(pos, maxW, rowH, cardW, cardH);
            if (hitResult == null) return;

            SoundFx.playCardTap();
            HapticFeedback.selectionClick();
            setState(() {
              _draggingCardId = hitResult.card.id;
              _dragGrabOffset = hitResult.grabOffset;
              _dragLocalPos = pos;
              _lastTargetRowIndex = hitResult.row;
              _lastTargetSlotIndex = hitResult.index;
            });
          },
          onPanUpdate: (details) {
            if (_draggingCardId == null) return;
            final pos = details.localPosition;
            final targetRow = (pos.dy / rowH).floor().clamp(0, 2);
            _moveDraggedCardToRowSlot(
              _draggingCardId!,
              targetRow,
              pos.dx - _dragGrabOffset.dx,
              maxW,
              cardW,
            );

            setState(() {
              _dragLocalPos = pos;
            });
          },
          onPanEnd: (_) {
            if (_draggingCardId == null) return;
            setState(() {
              _draggingCardId = null;
              _lastTargetRowIndex = -1;
              _lastTargetSlotIndex = -1;
            });
            _ctrl.syncHumanRows(_localRows);
          },
          onPanCancel: () {
            if (_draggingCardId != null) {
              setState(() {
                _draggingCardId = null;
                _lastTargetRowIndex = -1;
                _lastTargetSlotIndex = -1;
              });
            }
          },
          child: SizedBox(
            width: maxW,
            height: maxH,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 3 SIRANIN AHŞAP/ALTIN RAF ÇİZGİLERİ
                for (int r = 0; r < 3; r++)
                  Positioned(
                    left: 8,
                    right: 8,
                    top: r * rowH + 2,
                    height: rowH - 4,
                    child: GestureDetector(
                      onTap: () {
                        // Seçili kart varsa boşluğa tıklanınca o sıranın sonuna taşı
                        if (_ctrl.selectedCardId != null) {
                          _moveCardToRowEnd(_ctrl.selectedCardId!, r);
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFF0A261A).withValues(alpha: 0.55),
                              const Color(0xFF1F120B).withValues(alpha: 0.78),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.42),
                            width: 1.1,
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Icon(
                              Icons.drag_indicator_rounded,
                              color: const Color(0xFFD4AF37).withValues(alpha: 0.30),
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // HER SIRADAKİ NORMAL KARTLAR (Sürüklenen kart HARİÇ)
                for (int r = 0; r < 3; r++)
                  ..._buildRowCardsWidgets(
                    rowIdx: r,
                    rowCards: _localRows[r],
                    maxW: maxW,
                    rowH: rowH,
                    cardW: cardW,
                    cardH: cardH,
                    meldedIds: meldedIds,
                    isMyTurn: isMyTurn,
                    hasDrawn: hasDrawn,
                    renderDraggingCard: false,
                  ),

                // SÜRÜKLENEN KART HER ZAMAN EN ÜSTTE
                if (_draggingCardId != null)
                  _buildFloatingDraggedCard(
                    maxW: maxW,
                    rowH: rowH,
                    cardW: cardW,
                    cardH: cardH,
                    meldedIds: meldedIds,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildRowCardsWidgets({
    required int rowIdx,
    required List<CardModel> rowCards,
    required double maxW,
    required double rowH,
    required double cardW,
    required double cardH,
    required Set<String> meldedIds,
    required bool isMyTurn,
    required bool hasDrawn,
    bool renderDraggingCard = true,
  }) {
    final count = rowCards.length;
    if (count == 0) return const [];

    const double leftPadding = 34.0;
    const double rightPadding = 14.0;
    final double usableW = maxW - leftPadding - rightPadding;
    final double stepX = count > 1
        ? ((usableW - cardW) / (count - 1)).clamp(26.0, cardW + 8.0)
        : 0.0;
    final double totalRowW = cardW + stepX * (count - 1);
    final double startX =
        leftPadding + ((usableW - totalRowW) / 2).clamp(0.0, usableW);
    final double baseTop = rowIdx * rowH + (rowH - cardH) / 2;

    final widgets = <Widget>[];

    for (int idx = 0; idx < count; idx++) {
      final card = rowCards[idx];
      final cardId = card.id;

      final isDragging = _draggingCardId == cardId;
      if (isDragging && !renderDraggingCard) continue;

      final isSelected = _ctrl.selectedCardId == cardId;
      final isMelded = meldedIds.contains(cardId);
      final isWinningDiscard =
          _ctrl.isAssisted && _ctrl.winningDiscardCardId == cardId;

      final double left = startX + idx * stepX;
      final double top = baseTop - (isSelected ? 8.0 : 0.0);

      widgets.add(
        AnimatedPositioned(
          key: ValueKey(cardId),
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          left: left,
          top: top,
          child: RepaintBoundary(
            child: GestureDetector(
              onTap: () {
                SoundFx.playCardTap();
                _ctrl.selectCard(cardId);
              },
              child: PlayingCardWidget(
                card: card,
                wildRank: _ctrl.wildRank,
                showWildHints: _ctrl.isAssisted,
                width: cardW,
                height: cardH,
                isSelected: isSelected,
                isMelded: isMelded,
                isWinningDiscardCandidate: isWinningDiscard,
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildFloatingDraggedCard({
    required double maxW,
    required double rowH,
    required double cardW,
    required double cardH,
    required Set<String> meldedIds,
  }) {
    CardModel? draggingCard;
    if (_ctrl.players.isNotEmpty) {
      for (final c in _ctrl.players[0].hand) {
        if (c.id == _draggingCardId) {
          draggingCard = c;
          break;
        }
      }
    }
    if (draggingCard == null) return const SizedBox.shrink();

    final double left = (_dragLocalPos.dx - _dragGrabOffset.dx)
        .clamp(4.0, maxW - cardW - 4.0);
    final double top = (_dragLocalPos.dy - _dragGrabOffset.dy)
        .clamp(-30.0, rowH * 3 - cardH + 10.0);

    return Positioned(
      key: ValueKey('floating_${draggingCard.id}'),
      left: left,
      top: top,
      child: IgnorePointer(
        child: Transform.rotate(
          angle: -0.05,
          child: Transform.scale(
            scale: 1.08,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: PlayingCardWidget(
                card: draggingCard,
                wildRank: _ctrl.wildRank,
                showWildHints: _ctrl.isAssisted,
                width: cardW,
                height: cardH,
                isSelected: true,
                isMelded: meldedIds.contains(draggingCard.id),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _HitCardResult? _hitTestCardWithOffset(
    Offset pos,
    double maxW,
    double rowH,
    double cardW,
    double cardH,
  ) {
    final int r = (pos.dy / rowH).floor().clamp(0, 2);
    final rowCards = _localRows[r];
    if (rowCards.isEmpty) return null;

    final count = rowCards.length;
    const double leftPadding = 34.0;
    const double rightPadding = 14.0;
    final double usableW = maxW - leftPadding - rightPadding;
    final double stepX = count > 1
        ? ((usableW - cardW) / (count - 1)).clamp(26.0, cardW + 8.0)
        : 0.0;
    final double totalRowW = cardW + stepX * (count - 1);
    final double startX =
        leftPadding + ((usableW - totalRowW) / 2).clamp(0.0, usableW);
    final double baseTop = r * rowH + (rowH - cardH) / 2;

    for (int i = count - 1; i >= 0; i--) {
      final left = startX + i * stepX;
      if (pos.dx >= left && pos.dx <= left + cardW &&
          pos.dy >= baseTop - 10 && pos.dy <= baseTop + cardH + 10) {
        return _HitCardResult(
          card: rowCards[i],
          row: r,
          index: i,
          grabOffset: Offset(pos.dx - left, pos.dy - baseTop),
        );
      }
    }
    return null;
  }

  void _moveDraggedCardToRowSlot(
    String cardId,
    int targetRow,
    double cardLeftX,
    double maxW,
    double cardW,
  ) {
    CardModel? movingCard;
    int fromRow = -1;
    int fromIdx = -1;

    for (int r = 0; r < 3; r++) {
      final idx = _localRows[r].indexWhere((c) => c.id == cardId);
      if (idx != -1) {
        fromRow = r;
        fromIdx = idx;
        movingCard = _localRows[r][idx];
        break;
      }
    }
    if (movingCard == null) return;

    final destRowList = _localRows[targetRow];
    final countAfter =
        fromRow == targetRow ? destRowList.length : destRowList.length + 1;
    const double leftPadding = 34.0;
    const double rightPadding = 14.0;
    final double usableW = maxW - leftPadding - rightPadding;
    final double stepX = countAfter > 1
        ? ((usableW - cardW) / (countAfter - 1)).clamp(26.0, cardW + 8.0)
        : 0.0;
    final double totalRowW = cardW + stepX * (countAfter - 1);
    final double startX =
        leftPadding + ((usableW - totalRowW) / 2).clamp(0.0, usableW);

    int candidateIdx = 0;
    if (stepX > 0) {
      final double cardCenterX = cardLeftX + cardW / 2;
      candidateIdx = ((cardCenterX - startX) / stepX)
          .round()
          .clamp(0, countAfter - 1);
    }

    if (fromRow == targetRow && candidateIdx == fromIdx) {
      _lastTargetRowIndex = targetRow;
      _lastTargetSlotIndex = candidateIdx;
      return;
    }

    if (_lastTargetRowIndex == targetRow && _lastTargetSlotIndex == candidateIdx) {
      return;
    }

    _lastTargetRowIndex = targetRow;
    _lastTargetSlotIndex = candidateIdx;

    _localRows[fromRow].removeAt(fromIdx);
    final clampedInsert = candidateIdx.clamp(0, _localRows[targetRow].length);
    _localRows[targetRow].insert(clampedInsert, movingCard);
    HapticFeedback.selectionClick();
  }

  void _moveCardToRowEnd(String cardId, int targetRow) {
    CardModel? movingCard;
    for (int r = 0; r < 3; r++) {
      final idx = _localRows[r].indexWhere((c) => c.id == cardId);
      if (idx != -1) {
        movingCard = _localRows[r].removeAt(idx);
        break;
      }
    }
    if (movingCard == null) return;
    setState(() {
      _localRows[targetRow].add(movingCard!);
    });
    _ctrl.syncHumanRows(_localRows);
  }

  Widget _buildZynga3DButton({
    required String label,
    required bool isGold,
    required bool enabled,
    required VoidCallback onTap,
    bool glow = false,
  }) {
    final List<Color> gradientColors = !enabled
        ? [const Color(0xFF1F2937), const Color(0xFF111827)]
        : isGold
            ? [
                const Color(0xFFFDE047),
                const Color(0xFFD97706),
                const Color(0xFF92400E),
              ]
            : [
                const Color(0xFF10B981),
                const Color(0xFF047857),
                const Color(0xFF064E3B),
              ];

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 44,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled ? const Color(0xFFFDE047) : Colors.white24,
            width: glow ? 2.2 : 1.4,
          ),
          boxShadow: [
            if (glow)
              BoxShadow(
                color: (isGold
                        ? const Color(0xFFFACC15)
                        : const Color(0xFF10B981))
                    .withValues(alpha: 0.65),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            const BoxShadow(
              color: Colors.black87,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: !enabled
                  ? Colors.white30
                  : isGold
                      ? const Color(0xFF1F1206)
                      : Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 10.5,
              height: 1.15,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 4. ATILAN KAĞITLAR GEÇMİŞİ MODALI
  // ===========================================================================
  void _showDiscardHistorySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A2418),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final history = _ctrl.discardPile.reversed.toList();
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🗑️ Yere Atılan Son Kağıtlar',
                style: TextStyle(
                  color: Color(0xFFFDE047),
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 12),
              history.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Bu elde henüz yere kağıt atılmadı.',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  : SizedBox(
                      height: 84,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: history.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (_, idx) => PlayingCardWidget(
                          card: history[idx],
                          wildRank: _ctrl.wildRank,
                          width: 52,
                          height: 76,
                        ),
                      ),
                    ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // 5. 101 PUAN ÇETELESİ MODALI (Orijinal Kareli Kağıt / Defter Tasarımı)
  // ===========================================================================
  Widget _buildScoreboardOverlay() {
    final seats = _ctrl.players;
    final history = _ctrl.roundHistory;

    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _showScoreboardModal = false),
        child: Container(
          color: Colors.black.withValues(alpha: 0.85),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480, maxHeight: 620),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  // Otantik sarımsı kareli defter kağıdı görünümü
                  color: const Color(0xFFFBF8EE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFB45309),
                    width: 2.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black87,
                      blurRadius: 28,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Çetele Üst Başlığı (El yazısı / defter tarzı)
                    Row(
                      children: [
                        const Icon(
                          Icons.edit_note_rounded,
                          color: Color(0xFF78350F),
                          size: 26,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '📝 OYUN ÇETELESİ (101 CEZA TABLOSU)',
                                style: TextStyle(
                                  color: Color(0xFF451A03),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'El #${_ctrl.roundNumber} • ${_ctrl.isAssisted ? "Yardımlı Mod" : "Yardımsız Mod"}',
                                style: const TextStyle(
                                  color: Color(0xFF92400E),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _showScoreboardModal = false),
                          icon: const Icon(Icons.close, color: Color(0xFF78350F)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // ÇETELE TABLOSU: Sütun Başlıkları (El No + Her Oyuncunun Adı)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFE9D7),
                        border: Border(
                          top: BorderSide(color: Color(0xFF78350F), width: 1.5),
                          bottom: BorderSide(color: Color(0xFF78350F), width: 1.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 52,
                            child: Text(
                              'EL',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF451A03),
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                            child: VerticalDivider(color: Color(0xFF78350F), width: 8),
                          ),
                          ...seats.map(
                            (p) => Expanded(
                              child: Text(
                                p.seatIndex == 0 ? '${p.username} (Sen)' : p.username,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: p.seatIndex == 0
                                      ? const Color(0xFF1E3A8A)
                                      : const Color(0xFF451A03),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ÇETELE GÖVDESİ: Her Elin Satırı (1. El, 2. El... Açtı / Ceza Puanı)
                    Flexible(
                      child: history.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Text(
                                  'Henüz el tamamlanmadı. İlk el bittiğinde cezalar buraya yazılacaktır.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF92400E),
                                    fontStyle: FontStyle.italic,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              itemCount: history.length,
                              separatorBuilder: (_, _) => const Divider(
                                color: Color(0xFFE2D9C2),
                                height: 1,
                                thickness: 1,
                              ),
                              itemBuilder: (context, idx) {
                                final row = history[idx];
                                final rNum = row.roundNumber;
                                final finisherId = row.finisherUserId;
                                final scores = row.scoresByUser;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                    horizontal: 6,
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 52,
                                        child: Text(
                                          '$rNum. El',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Color(0xFF78350F),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 18,
                                        child: VerticalDivider(
                                          color: Color(0xFFD6C8AC),
                                          width: 8,
                                        ),
                                      ),
                                      ...seats.map((p) {
                                        final sc = scores[p.userId];
                                        final isFinisher = finisherId == p.userId;
                                        String text = '-';
                                        Color col = const Color(0xFF1F2937);
                                        FontWeight fw = FontWeight.w600;

                                        if (isFinisher) {
                                          text = 'AÇTI';
                                          col = const Color(0xFF047857);
                                          fw = FontWeight.w900;
                                        } else if (sc != null) {
                                          text = '+$sc';
                                          col = const Color(0xFFB91C1C);
                                          fw = FontWeight.bold;
                                        }

                                        return Expanded(
                                          child: Text(
                                            text,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: col,
                                              fontWeight: fw,
                                              fontSize: 12,
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),

                    // ÇETELE EN ALT TOPLAM VE DURUM SATIRI
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFE9D7),
                        border: Border(
                          top: BorderSide(color: Color(0xFF78350F), width: 2),
                          bottom: BorderSide(color: Color(0xFF78350F), width: 1.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 52,
                            child: Text(
                              'TOPLAM',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF451A03),
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 28,
                            child: VerticalDivider(color: Color(0xFF78350F), width: 8),
                          ),
                          ...seats.map((p) {
                            final tot = p.totalScore;
                            final isBurned = p.isEliminated || tot >= 101;

                            return Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$tot',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isBurned
                                          ? const Color(0xFFB91C1C)
                                          : const Color(0xFF1E3A8A),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (isBurned)
                                    Container(
                                      margin: const EdgeInsets.only(top: 2),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEE2E2),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: const Color(0xFFEF4444),
                                          width: 1,
                                        ),
                                      ),
                                      child: const Text(
                                        'YANDI',
                                        style: TextStyle(
                                          color: Color(0xFFDC2626),
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    final winnerMsg = _ctrl.winnerMessage ?? 'Oyun Sona Erdi!';
    final isHumanWinner = winnerMsg.contains('Tebrikler');

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.88),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF091C14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD4AF37), width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black87, blurRadius: 20, spreadRadius: 4),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isHumanWinner ? '🏆 ŞAMPİYON! 🏆' : '🔥 OYUN BİTTİ',
                  style: const TextStyle(
                    color: Color(0xFFFDE047),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  winnerMsg,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            _ctrl.stopGame();
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            'ANA MENÜ',
                            style: TextStyle(
                              color: Color(0xFFFDE047),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 6,
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4AF37),
                            foregroundColor: const Color(0xFF0A2218),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            _ctrl.initMatch();
                            _syncLocalRowsFromController();
                            setState(() {});
                          },
                          child: const Text(
                            'TEKRAR OYNA 🏆',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
