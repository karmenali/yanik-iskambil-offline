import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../engine/card_model.dart';
import '../engine/game_engine.dart';
import '../engine/offline_table_controller.dart';
import '../services/sound_fx.dart';
import '../widgets/playing_card_widget.dart';
import '../widgets/round_summary_dialog.dart';
import '../widgets/victory_celebration_overlay.dart';
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

  /// Satır içerisindeki per bitiş indekslerini tespit eder (Aynı satırdaki per grupları arasında ayrım için)
  @visibleForTesting
  static List<int> findMeldEndIndices(List<CardModel> cards, int wildRank) {
    final result = <int>[];
    final n = cards.length;
    if (n < 4) return result;

    int i = 0;
    while (i < n) {
      int foundLen = 0;
      final maxLen = n - i;
      for (int len = maxLen; len >= 3; len--) {
        final sub = cards.sublist(i, i + len);
        if (GameEngine.isValidMeld(sub, wildRank)) {
          foundLen = len;
          break;
        }
      }

      if (foundLen > 0) {
        // Eğer bu per satırın başından başlamıyorsa, önceki kart ile arasına boşluk koy
        if (i > 0 && !result.contains(i - 1)) {
          result.add(i - 1);
        }
        final endIndex = i + foundLen - 1;
        // Eğer bu perden sonra da kartlar varsa, sonrasına da boşluk koy
        if (endIndex < n - 1 && !result.contains(endIndex)) {
          result.add(endIndex);
        }
        i = endIndex + 1;
      } else {
        i++;
      }
    }
    return result;
  }

  /// 12-16 dp per ayrım boşluğu ve ekran sınırlarını taşmayan dinamik kart koordinatları
  @visibleForTesting
  static List<double> calculateCardLefts(
    int count,
    double maxW,
    double cardW,
    List<int> gapIndices,
  ) {
    if (count == 0) return const [];

    const double leftPadding = 34.0;
    const double rightPadding = 14.0;
    final double usableW = (maxW - leftPadding - rightPadding).clamp(60.0, maxW);

    if (count == 1) {
      final startX = leftPadding + ((usableW - cardW) / 2).clamp(0.0, usableW);
      return [startX];
    }

    final int k = gapIndices.length;
    const double desiredGap = 14.0; // 12-16 dp kuralına tam uygun sabit boşluk
    double gap = desiredGap;
    double stepX;

    // Hedef: cardW + (count - 1) * stepX + k * gap <= usableW
    final double spaceForStepsWithDesiredGap = usableW - cardW - (k * desiredGap);
    final double candStep = spaceForStepsWithDesiredGap / (count - 1);

    if (candStep >= 24.0) {
      stepX = candStep.clamp(24.0, cardW + 6.0);
      gap = desiredGap;
    } else {
      // Dar ekranlarda önce kart okunabilirliğini koru (min 24dp basamak)
      stepX = 24.0;
      final double remainingForGaps = usableW - cardW - (count - 1) * 24.0;
      gap = k > 0 ? (remainingForGaps / k).clamp(0.0, desiredGap) : 0.0;
      if (remainingForGaps < 0) {
        // Aşırı dar veya bölünmüş ekranlarda taşmayı sıfırlamak için stepX'i daralt
        stepX = ((usableW - cardW) / (count - 1)).clamp(16.0, cardW + 6.0);
        gap = 0.0;
      }
    }

    final double totalRowW = cardW + stepX * (count - 1) + gap * k;
    final double startX =
        leftPadding + ((usableW - totalRowW) / 2).clamp(0.0, usableW);

    final lefts = <double>[];
    double currentX = startX;
    for (int i = 0; i < count; i++) {
      lefts.add(currentX);
      currentX += stepX;
      if (gapIndices.contains(i)) {
        currentX += gap;
      }
    }
    return lefts;
  }
}

class _FlyingCardInfo {
  final CardModel? card;
  final Offset startPos;
  final Offset endPos;
  final double startScale;
  final double endScale;

  _FlyingCardInfo({
    required this.card,
    required this.startPos,
    required this.endPos,
    this.startScale = 1.0,
    this.endScale = 1.0,
  });
}

class _OfflineTableScreenState extends State<OfflineTableScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final _ctrl = OfflineTableController.instance;
  bool _showingSummaryDialog = false;
  bool _showScoreboardModal = false;
  bool _isConfirmingFinish = false;

  // Zafer Kutlaması (Victory Celebration) Durumu
  late AnimationController _celebrationAnimController;
  bool _isCelebrationActive = false;
  int? _celebrationWinnerSeat;
  String _celebrationWinnerName = '';
  bool _isCelebrationHumanWinner = false;
  bool _isCelebrationGrandChampion = false;
  int _lastCelebratedRound = -1;

  // Uçan Kart Hareketi (Havada süzülme animasyonu)
  late AnimationController _flightAnimController;
  late Animation<double> _flightCurve;
  _FlyingCardInfo? _flyingCard;
  bool _isFlightAnimating = false;
  String? _hiddenDiscardingCardId;

  final GlobalKey _drawDeckKey = GlobalKey();
  final GlobalKey _discardPileKey = GlobalKey();
  final GlobalKey _rackKey = GlobalKey();
  final Map<String, GlobalKey> _cardKeys = {};

  // 3 Sıralı Istaka Sürükleme ve Yerel Durum
  List<List<CardModel>> _localRows = [[], [], []];
  String? _draggingCardId;
  Offset _dragGrabOffset = Offset.zero;
  final ValueNotifier<Offset> _dragPosNotifier =
      ValueNotifier<Offset>(Offset.zero);
  int _lastTargetRowIndex = -1;
  int _lastTargetSlotIndex = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _flightAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 230),
    );
    _flightCurve = CurvedAnimation(
      parent: _flightAnimController,
      curve: Curves.easeOutCubic,
    );

    _celebrationAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    );
    _celebrationAnimController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _finishCelebrationAndShowDialog();
      }
    });

    _syncLocalRowsFromController();
    _ctrl.addListener(_onTableUpdate);
  }

  @override
  void dispose() {
    _flightAnimController.dispose();
    _celebrationAnimController.dispose();
    _dragPosNotifier.dispose();
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

    // Tur sonu değerlendirmesi: Zafer kutlaması ve özet diyaloğu akışı
    if (_ctrl.status == 'round_summary' && _ctrl.lastShowdown != null) {
      if (_ctrl.lastFinisherSeat != null) {
        // Bir oyuncu eli açıp bitirdi: Yeni bir tur ise kutlamayı TAM 1 KEZ tetikle
        if (_lastCelebratedRound != _ctrl.roundNumber &&
            !_isCelebrationActive &&
            !_showingSummaryDialog) {
          _lastCelebratedRound = _ctrl.roundNumber;
          _startVictoryCelebration(_ctrl.lastFinisherSeat!);
        }
      } else {
        // Deste tükendi / berabere (Kazanan yok): Doğrudan özet diyaloğunu aç
        if (!_showingSummaryDialog && !_isCelebrationActive) {
          _showSummaryDialog();
        }
      }
    }
  }

  void _startVictoryCelebration(int finisherSeat) {
    if (!mounted) return;
    final winner = _ctrl.players.isNotEmpty &&
            finisherSeat >= 0 &&
            finisherSeat < _ctrl.players.length
        ? _ctrl.players[finisherSeat]
        : null;
    final isHuman = finisherSeat == 0;
    final isGrandChampion =
        _ctrl.winnerMessage != null && _ctrl.winnerMessage!.isNotEmpty;
    final winnerName = winner != null
        ? (isHuman ? 'Sen' : winner.username)
        : 'Kazanan';

    setState(() {
      _isCelebrationActive = true;
      _celebrationWinnerSeat = finisherSeat;
      _celebrationWinnerName = winnerName;
      _isCelebrationHumanWinner = isHuman;
      _isCelebrationGrandChampion = isGrandChampion;
    });

    _celebrationAnimController.forward(from: 0.0);
  }

  void _finishCelebrationAndShowDialog() {
    if (!mounted) return;
    if (_showingSummaryDialog) return;

    _celebrationAnimController.stop();
    setState(() {
      _isCelebrationActive = false;
    });

    _showSummaryDialog();
  }

  void _showSummaryDialog() {
    if (_showingSummaryDialog || !mounted) return;
    if (_ctrl.lastShowdown == null) return;

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
            _lastCelebratedRound = -1;
            _isCelebrationActive = false;
            _celebrationAnimController.reset();
            _ctrl.initMatch();
            _syncLocalRowsFromController();
            if (mounted) setState(() {});
          },
          onMainMenu: () {
            _showingSummaryDialog = false;
            _lastCelebratedRound = -1;
            _isCelebrationActive = false;
            _celebrationAnimController.reset();
            _ctrl.stopGame();
            if (mounted) Navigator.of(context).pop();
          },
        ),
      ).then((_) {
        _showingSummaryDialog = false;
      });
    });
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

  void _handleAnimatedDraw() {
    if (_isFlightAnimating || !_ctrl.isPlaying || !_ctrl.isHumanTurn || _ctrl.hasDrawnThisTurn) {
      return;
    }

    final deckBox = _drawDeckKey.currentContext?.findRenderObject() as RenderBox?;
    final rackBox = _rackKey.currentContext?.findRenderObject() as RenderBox?;
    final tableBox = context.findRenderObject() as RenderBox?;

    if (deckBox == null || rackBox == null || tableBox == null) {
      _ctrl.humanDrawCard(fromDiscard: false);
      _syncLocalRowsFromController();
      return;
    }

    final deckPos = tableBox.globalToLocal(deckBox.localToGlobal(Offset.zero));
    final rackPos = tableBox.globalToLocal(rackBox.localToGlobal(Offset.zero));

    final targetPos = Offset(
      rackPos.dx + (rackBox.size.width / 2) - 26,
      rackPos.dy + (rackBox.size.height * 0.68),
    );

    setState(() {
      _isFlightAnimating = true;
      _flyingCard = _FlyingCardInfo(
        card: null,
        startPos: deckPos,
        endPos: targetPos,
        startScale: 1.0,
        endScale: 1.0,
      );
    });

    SoundFx.playCardDraw();
    _flightAnimController.forward(from: 0.0).then((_) {
      if (!mounted) return;
      _ctrl.humanDrawCard(fromDiscard: false);
      _syncLocalRowsFromController();
      setState(() {
        _flyingCard = null;
        _isFlightAnimating = false;
      });
    });
  }

  void _handleAnimatedDiscard() {
    if (_isFlightAnimating || !_ctrl.isPlaying || !_ctrl.isHumanTurn || !_ctrl.hasDrawnThisTurn) {
      return;
    }
    final cardId = _ctrl.selectedCardId;
    if (cardId == null) return;

    if (_ctrl.players.isEmpty || _ctrl.players[0].hand.isEmpty) return;
    CardModel? card;
    for (final c in _ctrl.players[0].hand) {
      if (c.id == cardId) {
        card = c;
        break;
      }
    }
    if (card == null) return;

    final cardBox = _cardKeys[cardId]?.currentContext?.findRenderObject() as RenderBox?;
    final discardBox = _discardPileKey.currentContext?.findRenderObject() as RenderBox?;
    final tableBox = context.findRenderObject() as RenderBox?;

    if (cardBox == null || discardBox == null || tableBox == null) {
      _ctrl.humanDiscardCard(cardId);
      _syncLocalRowsFromController();
      return;
    }

    final startPos = tableBox.globalToLocal(cardBox.localToGlobal(Offset.zero));
    final endPos = tableBox.globalToLocal(discardBox.localToGlobal(Offset.zero));

    setState(() {
      _isFlightAnimating = true;
      _hiddenDiscardingCardId = cardId;
      _flyingCard = _FlyingCardInfo(
        card: card,
        startPos: startPos,
        endPos: endPos,
        startScale: 1.05,
        endScale: 1.0,
      );
    });

    SoundFx.playCardDiscard();
    _flightAnimController.forward(from: 0.0).then((_) {
      if (!mounted) return;
      _ctrl.humanDiscardCard(cardId);
      _syncLocalRowsFromController();
      setState(() {
        _flyingCard = null;
        _hiddenDiscardingCardId = null;
        _isFlightAnimating = false;
      });
    });
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
                    flex: 44,
                    child: _buildZyngaCasinoTableArea(seats),
                  ),

                  // ALT OYUNCU ELİ: 3 SIRALI DİKEY ISTAKA + 60 FPS SÜRÜKLEME + 4 ZYNGA BUTONU
                  Expanded(
                    flex: 56,
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

            // 5. UÇAN KART HAREKET ANİMASYONU KATMANI (Havada süzülme)
            if (_flyingCard != null)
              AnimatedBuilder(
                animation: _flightCurve,
                builder: (context, _) {
                  final t = _flightCurve.value;
                  final currentPos = Offset.lerp(_flyingCard!.startPos, _flyingCard!.endPos, t)!;
                  final currentScale = _flyingCard!.startScale + (_flyingCard!.endScale - _flyingCard!.startScale) * t;

                  return Positioned(
                    left: currentPos.dx,
                    top: currentPos.dy,
                    child: IgnorePointer(
                      child: Transform.scale(
                        scale: currentScale,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black54,
                                blurRadius: 16,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: _flyingCard!.card == null
                              ? const CardBackWidget(width: 52, height: 74)
                              : PlayingCardWidget(
                                  card: _flyingCard!.card!,
                                  wildRank: _ctrl.wildRank,
                                  showWildHints: _ctrl.isAssisted,
                                  width: 52,
                                  height: 74,
                                ),
                        ),
                      ),
                    ),
                  );
                },
              ),

            // 6. PRESTİJLİ ZAFER KUTLAMASI (Victory Celebration Overlay)
            if (_isCelebrationActive)
              Positioned.fill(
                child: VictoryCelebrationOverlay(
                  animation: _celebrationAnimController,
                  winnerName: _celebrationWinnerName,
                  isHumanWinner: _isCelebrationHumanWinner,
                  isGrandChampion: _isCelebrationGrandChampion,
                  onTap: _finishCelebrationAndShowDialog,
                ),
              ),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Sol Grup: Geri, Mod Rozeti, Tur Rozeti
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Geri Butonu (En az 48x48 dp dokunma alanı)
                  Semantics(
                    button: true,
                    label: 'Masadan ayrıl',
                    child: Tooltip(
                      message: 'Masadan Ayrıl',
                      child: InkWell(
                        onTap: _confirmAndLeaveTable,
                        borderRadius: BorderRadius.circular(24),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          child: Center(
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
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Mod Rozeti (Yardımlı / Yardımsız)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
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
                  const SizedBox(width: 5),

                  // Tur Rozeti
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
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
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Sağ Grup: 101 Skor Tablosu & Ayarlar
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 101 Puan Tablosu Butonu (En az 48x48 dp dokunma alanı)
                Semantics(
                  button: true,
                  label: '101 Skor Tablosu',
                  child: Tooltip(
                    message: '101 Skor Tablosu',
                    child: InkWell(
                      onTap: () {
                        SoundFx.playCardTap();
                        setState(() => _showScoreboardModal = !_showScoreboardModal);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        child: Center(
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
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // Ayarlar Dişlisi (En az 48x48 dp dokunma alanı)
                Semantics(
                  button: true,
                  label: 'Ayarlar',
                  child: Tooltip(
                    message: 'Ayarlar',
                    child: InkWell(
                      onTap: () {
                        SoundFx.playCardTap();
                        showDialog(
                          context: context,
                          builder: (_) => const SettingsDialog(),
                        );
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        child: Center(
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
                      ),
                    ),
                  ),
                ),
              ],
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
    final isWinnerCelebrated = _isCelebrationActive && _celebrationWinnerSeat == seatIndex;
    final avatar = VipAvatar.fromKey(seat.avatar);

    return RepaintBoundary(
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Kazanan Kutlama Parıltı Halkası (Altın Corona Efekti)
                if (isWinnerCelebrated)
                  AnimatedBuilder(
                    animation: _celebrationAnimController,
                    builder: (context, _) {
                      final pulse = (0.5 + 0.5 * math.sin(_celebrationAnimController.value * math.pi * 6)).abs();
                      return Container(
                        width: 58 + 4 * pulse,
                        height: 58 + 4 * pulse,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFDE047),
                            width: 3.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD97706).withValues(alpha: 0.8),
                              blurRadius: 18 + 6 * pulse,
                              spreadRadius: 3 + 2 * pulse,
                            ),
                            BoxShadow(
                              color: const Color(0xFFFDE047).withValues(alpha: 0.6),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      );
                    },
                  )
                // Sabit %100 Dolu Neon Yeşil Halka (Dönmez, sabit ve temiz durur)
                else if (isCurrentTurn)
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
                    color: isWinnerCelebrated
                        ? const Color(0xFFFDE047)
                        : (isMe ? const Color(0xFFFACC15) : const Color(0xFFD4AF37)),
                    width: isWinnerCelebrated ? 2.8 : (isMe ? 2.4 : 1.8),
                  ),
                ),
                child: Center(
                  child: Text(
                    avatar.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),

              // Kazanan Taç Rozeti ('👑 KAZANDI')
              if (isWinnerCelebrated)
                Positioned(
                  top: -11,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFDE047), Color(0xFFD97706)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                      border: Border.all(color: Colors.white, width: 0.8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('👑', style: TextStyle(fontSize: 9.5)),
                        SizedBox(width: 2),
                        Text(
                          'KAZANDI',
                          style: TextStyle(
                            color: Color(0xFF1E130C),
                            fontWeight: FontWeight.w900,
                            fontSize: 8,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
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
                color: isWinnerCelebrated
                    ? const Color(0xFFFDE047)
                    : isCurrentTurn
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFD4AF37).withValues(alpha: 0.65),
                width: isWinnerCelebrated ? 1.4 : 1.0,
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
      width: 268,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 1. GÖSTERGE REFERANS KARTI (76px genişlik, FittedBox ile asla taşmaz)
          SizedBox(
            width: 76,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (indicator != null)
                  PlayingCardWidget(
                    card: indicator,
                    wildRank: _ctrl.wildRank,
                    showWildHints: false,
                    isIndicator: true,
                    width: 52,
                    height: 74,
                  )
                else
                  const SizedBox(width: 52, height: 74),
                const SizedBox(height: 3),
                const SizedBox(
                  height: 16,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: Text(
                      'GÖSTERGE',
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFFDE047),
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 0.5,
                        shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. 3D KAPALI DESTE (76px genişlik, FittedBox ile asla taşmaz)
          SizedBox(
            key: _drawDeckKey,
            width: 76,
            child: GestureDetector(
              onTap: canDrawNow ? _handleAnimatedDraw : null,
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
                  SizedBox(
                    height: 16,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text(
                        canDrawNow ? '👇 ÇEK ($drawCount)' : 'DESTE $drawCount',
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: canDrawNow
                              ? const Color(0xFF4ADE80)
                              : const Color(0xFFFDE047),
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          shadows: const [
                            Shadow(color: Colors.black, blurRadius: 4),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. ATILAN KAĞIT (76px genişlik, FittedBox ile asla taşmaz)
          SizedBox(
            key: _discardPileKey,
            width: 76,
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
                  const SizedBox(
                    height: 16,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text(
                        'ATILAN KART',
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFFDE047),
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 0.3,
                          shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                        ),
                      ),
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
    final winningDiscardId = isAssisted ? _ctrl.winningDiscardCardId : null;

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
            winningDiscardId: winningDiscardId,
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
                  onTap: _handleAnimatedDraw,
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
                  onTap: _handleAnimatedDiscard,
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
                  onTap: _onDeclareFinishPressed,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Yardımsız modda hatalı el açma onayı diyaloğu ve bitiş tetiklemesi
  Future<void> _onDeclareFinishPressed() async {
    if (_isConfirmingFinish || !_ctrl.isHumanTurn || !_ctrl.hasDrawnThisTurn) return;

    final candidates = _ctrl.getValidDiscardCandidates();

    // 1. Durum: Elde hiçbir geçerli bitiş yok (Geçersiz el açma)
    if (candidates.isEmpty) {
      if (!_ctrl.isAssisted) {
        _isConfirmingFinish = true;
        SoundFx.playCardTap();
        final confirmed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogCtx) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0F261C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
              ),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFEF4444), size: 28),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hatalı El Açma Uyarısı',
                      style: TextStyle(
                        color: Color(0xFFFDE047),
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              content: const Text(
                'Geçersiz el açarsanız 101 ceza alacaksınız. Devam etmek istiyor musunuz?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogCtx).pop(false);
                  },
                  child: const Text(
                    'Vazgeç',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(dialogCtx).pop(true);
                  },
                  child: const Text(
                    'Devam Et',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            );
          },
        );
        _isConfirmingFinish = false;
        if (confirmed == true && mounted) {
          _ctrl.humanDeclareFinish();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Eliniz henüz bitişe hazır değil.'),
            duration: Duration(seconds: 2),
            backgroundColor: Color(0xFF1E3A2F),
          ),
        );
      }
      return;
    }

    // 2. Durum: Kullanıcı zaten geçerli adaylardan birini seçmişse doğrudan o kartla bitir
    if (_ctrl.selectedCardId != null &&
        candidates.any((c) => c.id == _ctrl.selectedCardId)) {
      _ctrl.humanDeclareFinish(discardCardId: _ctrl.selectedCardId);
      return;
    }

    // 3. Durum: Yalnızca 1 adet geçerli atılabilir kart varsa kullanıcıyı yormadan otomatik seçip bitir
    if (candidates.length == 1) {
      final singleCard = candidates.first;
      _ctrl.selectedCardId = singleCard.id;
      _ctrl.humanDeclareFinish(discardCardId: singleCard.id);
      return;
    }

    // 4. Durum: Birden fazla geçerli kart atılabiliyorsa BottomSheet ile sor
    _isConfirmingFinish = true;
    final chosenCardId = await _showDiscardSelectionSheet(candidates);
    _isConfirmingFinish = false;

    if (chosenCardId != null && mounted) {
      _ctrl.humanDeclareFinish(discardCardId: chosenCardId);
    }
  }

  /// Birden fazla atılabilir kart adayı olduğunda gösterilen modern seçim BottomSheet'i
  Future<String?> _showDiscardSelectionSheet(List<CardModel> candidates) async {
    SoundFx.playCardTap();
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF0A2218),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: Color(0xFFD4AF37), width: 1.5),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.touch_app, color: Color(0xFFFDE047), size: 20),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Atılacak Kartı Seçin',
                        style: TextStyle(
                          color: Color(0xFFFDE047),
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Elinizi açıp bitirmek için masaya atmak istediğiniz kartı seçin:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 18),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: candidates.map((card) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: InkWell(
                          onTap: () {
                            SoundFx.playCardTap();
                            Navigator.of(sheetCtx).pop(card.id);
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFD4AF37),
                                width: 2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black45,
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: PlayingCardWidget(
                              card: card,
                              wildRank: _ctrl.wildRank,
                              showWildHints: _ctrl.isAssisted,
                              width: 58,
                              height: 84,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(sheetCtx).pop(null),
                    child: const Text(
                      'Vazgeç',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Satır içerisindeki per bitiş indekslerini tespit eder (Aynı satırdaki per grupları arasında ayrım için)
  List<int> _findMeldEndIndices(List<CardModel> cards, int wildRank) =>
      OfflineTableScreen.findMeldEndIndices(cards, wildRank);

  /// 12-16 dp per ayrım boşluğu ve ekran sınırlarını taşmayan dinamik kart koordinatları
  List<double> _calculateCardLefts(
    int count,
    double maxW,
    double cardW,
    List<int> gapIndices,
  ) =>
      OfflineTableScreen.calculateCardLefts(count, maxW, cardW, gapIndices);

  /// 3 Sıralı Dikey Istaka ve Pan Hareketleri
  Widget _buildThreeRowInteractiveRack({
    required Set<String> meldedIds,
    required String? winningDiscardId,
    required bool isMyTurn,
    required bool hasDrawn,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;

        // Küçük ekran uyumu: Satır yüksekliğini maxH / 3.0'a oranla (asla butonların arkasına taşmaz)
        final rawRowH = (maxH / 3.0).floorToDouble();
        final rowH = rawRowH.clamp(56.0, 120.0);
        final cardH = (rowH * 0.90).floorToDouble().clamp(50.0, 110.0);
        final cardW = (cardH * 0.70).floorToDouble().clamp(36.0, 78.0);

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: (details) {
            final pos = details.localPosition;
            final hitResult =
                _hitTestCardWithOffset(pos, maxW, rowH, cardW, cardH);
            if (hitResult == null) return;

            SoundFx.playCardTap();
            _dragGrabOffset = hitResult.grabOffset;
            _dragPosNotifier.value = pos;
            _lastTargetRowIndex = hitResult.row;
            _lastTargetSlotIndex = hitResult.index;
            setState(() {
              _draggingCardId = hitResult.card.id;
            });
          },
          onPanUpdate: (details) {
            if (_draggingCardId == null) return;
            final pos = details.localPosition;

            // 1. Sadece hareket eden yüzen kartın konumunu ValueNotifier ile güncelle (0ms full rebuild)
            _dragPosNotifier.value = pos;

            // 2. Kart yeni bir sıraya veya slota geçtiyse satır listesini güncelle
            final targetRow = (pos.dy / rowH).floor().clamp(0, 2);
            final changed = _moveDraggedCardToRowSlot(
              _draggingCardId!,
              targetRow,
              pos.dx - _dragGrabOffset.dx,
              maxW,
              cardW,
            );

            // Sadece gerçek bir slot sırası değiştiğinde ıstakayı yeniden çiz
            if (changed) {
              setState(() {});
            }
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
            key: _rackKey,
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
                    winningDiscardId: winningDiscardId,
                    isMyTurn: isMyTurn,
                    hasDrawn: hasDrawn,
                    renderDraggingCard: false,
                  ),

                // SÜRÜKLENEN KART HER ZAMAN EN ÜSTTE (ValueNotifier ile izole)
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
    required String? winningDiscardId,
    required bool isMyTurn,
    required bool hasDrawn,
    bool renderDraggingCard = true,
  }) {
    final count = rowCards.length;
    if (count == 0) return const [];

    final gapIndices = _findMeldEndIndices(rowCards, _ctrl.wildRank);
    final cardLefts = _calculateCardLefts(count, maxW, cardW, gapIndices);
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
          winningDiscardId != null && winningDiscardId == cardId;

      final double left = cardLefts[idx];
      final double top = baseTop - (isSelected ? 6.0 : 0.0);

      if (_hiddenDiscardingCardId == cardId) {
        // Kart masaya uçarken ıstakada boş yerini koru, çift çizme
        widgets.add(
          Positioned(
            left: left,
            top: top,
            child: SizedBox(width: cardW, height: cardH),
          ),
        );
        continue;
      }

      final cardKey = _cardKeys.putIfAbsent(cardId, () => GlobalKey());

      widgets.add(
        AnimatedPositioned(
          key: ValueKey(cardId),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          left: left,
          top: top,
          child: RepaintBoundary(
            key: cardKey,
            child: GestureDetector(
              onTap: () {
                _ctrl.selectCard(cardId);
              },
              child: AnimatedScale(
                scale: isSelected ? 1.05 : 1.0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
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

    return ValueListenableBuilder<Offset>(
      valueListenable: _dragPosNotifier,
      builder: (context, pos, _) {
        final double left =
            (pos.dx - _dragGrabOffset.dx).clamp(4.0, maxW - cardW - 4.0);
        final double top = (pos.dy - _dragGrabOffset.dy)
            .clamp(-30.0, rowH * 3 - cardH + 10.0);

        return Positioned(
          key: ValueKey('floating_${draggingCard!.id}'),
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
      },
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
    final gapIndices = _findMeldEndIndices(rowCards, _ctrl.wildRank);
    final cardLefts = _calculateCardLefts(count, maxW, cardW, gapIndices);
    final double baseTop = r * rowH + (rowH - cardH) / 2;

    for (int i = count - 1; i >= 0; i--) {
      final left = cardLefts[i];
      if (pos.dx >= left &&
          pos.dx <= left + cardW &&
          pos.dy >= baseTop - 10 &&
          pos.dy <= baseTop + cardH + 10) {
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

  bool _moveDraggedCardToRowSlot(
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
    if (movingCard == null) return false;

    final destRowList = _localRows[targetRow];
    final countAfter =
        fromRow == targetRow ? destRowList.length : destRowList.length + 1;
    final gapIndices = _findMeldEndIndices(destRowList, _ctrl.wildRank);
    final slotLefts = _calculateCardLefts(countAfter, maxW, cardW, gapIndices);

    int candidateIdx = 0;
    if (slotLefts.isNotEmpty) {
      final double cardCenterX = cardLeftX + cardW / 2;
      double minDist = double.infinity;
      for (int i = 0; i < slotLefts.length; i++) {
        final center = slotLefts[i] + cardW / 2;
        final dist = (cardCenterX - center).abs();
        if (dist < minDist) {
          minDist = dist;
          candidateIdx = i;
        }
      }
    }

    if (fromRow == targetRow && candidateIdx == fromIdx) {
      _lastTargetRowIndex = targetRow;
      _lastTargetSlotIndex = candidateIdx;
      return false;
    }

    if (_lastTargetRowIndex == targetRow &&
        _lastTargetSlotIndex == candidateIdx) {
      return false;
    }

    _lastTargetRowIndex = targetRow;
    _lastTargetSlotIndex = candidateIdx;

    _localRows[fromRow].removeAt(fromIdx);
    final clampedInsert = candidateIdx.clamp(0, _localRows[targetRow].length);
    _localRows[targetRow].insert(clampedInsert, movingCard);
    return true;
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

    return Semantics(
      button: true,
      enabled: enabled,
      label: label.replaceAll('\n', ' '),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 48,
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
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
                          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                          tooltip: 'Kapat',
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
