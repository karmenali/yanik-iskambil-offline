import 'dart:async';
import 'package:flutter/foundation.dart';
import 'card_model.dart';
import 'game_engine.dart';
import 'hand_sorter.dart';
import '../services/settings_service.dart';
import '../services/sound_fx.dart';

class OfflinePlayer {
  final String userId;
  final String username;
  final String avatar;
  final int seatIndex;
  final bool isBot;
  int totalScore;
  bool isEliminated;
  List<CardModel> hand;
  List<List<CardModel>> openedMelds;

  OfflinePlayer({
    required this.userId,
    required this.username,
    required this.avatar,
    required this.seatIndex,
    required this.isBot,
    this.totalScore = 0,
    this.isEliminated = false,
    List<CardModel>? hand,
    List<List<CardModel>>? openedMelds,
  })  : hand = hand ?? [],
        openedMelds = openedMelds ?? [];
}

class RoundHistoryEntry {
  final int roundNumber;
  final String? finisherUserId;
  final Map<String, int> scoresByUser;

  const RoundHistoryEntry({
    required this.roundNumber,
    required this.finisherUserId,
    required this.scoresByUser,
  });
}

class OfflineTableController extends ChangeNotifier {
  static final OfflineTableController instance = OfflineTableController._internal();
  OfflineTableController._internal();

  String status = 'waiting'; // 'waiting', 'dealing', 'playing', 'round_summary', 'game_over'
  int roundNumber = 1;
  int dealerSeat = 0;
  int currentTurnSeat = 1;
  bool hasDrawnThisTurn = false;

  final List<OfflinePlayer> players = [];
  List<CardModel> drawPile = [];
  List<CardModel> discardPile = [];
  CardModel? indicatorCard;
  int wildRank = 0;

  // İnsan oyuncunun 3 sıralı ıstakası
  List<List<CardModel>> humanRows = [[], [], []];
  String? selectedCardId;

  // El sonu durumu
  List<ShowdownPlayerResult>? lastShowdown;
  int? lastFinisherSeat;
  int? lastFalseDeclarerSeat;
  String? winnerMessage;
  int? championSeatIndex;
  String? championName;
  bool get isHumanChampion => championSeatIndex == 0;
  final List<RoundHistoryEntry> roundHistory = [];

  Timer? _botTimer;
  bool _isPaused = false;
  bool get isPaused => _isPaused;

  void pauseGame() {
    _isPaused = true;
    _botTimer?.cancel();
    _botTimer = null;
  }

  void resumeGame() {
    if (!_isPaused) return;
    _isPaused = false;
    if (status == 'playing' && !isHumanTurn) {
      _scheduleBotTurn();
    }
  }

  void stopGame() {
    _isPaused = true;
    _botTimer?.cancel();
    _botTimer = null;
    status = 'waiting';
    winnerMessage = null;
    championSeatIndex = null;
    championName = null;
    notifyListeners();
  }

  bool get isHumanTurn => currentTurnSeat == 0 && status == 'playing';
  OfflinePlayer get humanPlayer => players.isNotEmpty ? players[0] : OfflinePlayer(userId: 'human', username: 'Oyuncu', avatar: 'lion', seatIndex: 0, isBot: false);

  int get drawPileCount => drawPile.length;
  CardModel? get topDiscardCard => discardPile.isNotEmpty ? discardPile.last : null;
  bool get isAssisted => SettingsService.instance.isAssisted;
  bool get isPlaying => status == 'playing';
  bool get isRoundSummary => status == 'round_summary';
  bool get isGameOver => status == 'game_over';
  bool get hasActiveMatch =>
      (status == 'playing' || status == 'dealing' || status == 'round_summary') &&
      players.isNotEmpty &&
      players.any((p) => p.hand.isNotEmpty);

  // --- Asist / Yardımcı Mod Hesaplama Önbelleği (O(1) Akıcılık) ---
  String? _cachedEvalKey;
  Set<String> _cachedMeldedCardIds = const {};
  int _cachedPenalty = 0;

  String? _cachedWinCheckKey;
  ({bool canWin, CardModel? discardCard, HandEvaluation? evaluation})? _cachedWinCheck;

  bool _hasVibratedForCurrentHumanTurn = false;

  void _invalidateAssistedCache() {
    _cachedEvalKey = null;
    _cachedMeldedCardIds = const {};
    _cachedPenalty = 0;
    _cachedWinCheckKey = null;
    _cachedWinCheck = null;
  }

  void _checkAndTriggerTurnStartHaptic() {
    if (status == 'playing' && isHumanTurn) {
      if (!_hasVibratedForCurrentHumanTurn) {
        _hasVibratedForCurrentHumanTurn = true;
        SoundFx.triggerTurnStartHaptic();
      }
    } else {
      _hasVibratedForCurrentHumanTurn = false;
    }
  }

  void _ensureHandEvaluated() {
    if (players.isEmpty) {
      _cachedMeldedCardIds = const {};
      _cachedPenalty = 0;
      return;
    }
    final hand = players[0].hand;
    final currentKey = '$wildRank:${hand.length}:${hand.map((c) => c.id).join(',')}';
    if (_cachedEvalKey == currentKey) {
      return;
    }

    _cachedEvalKey = currentKey;
    final eval = GameEngine.evaluateHandOptimal(hand, wildRank);
    final ids = <String>{};
    for (final m in eval.melds) {
      for (final c in m) {
        ids.add(c.id);
      }
    }
    _cachedMeldedCardIds = ids;
    _cachedPenalty = eval.penalty;
  }

  void _ensureWinCheckEvaluated() {
    if (!isAssisted || !isHumanTurn || players.isEmpty || players[0].hand.length != 11) {
      _cachedWinCheckKey = null;
      _cachedWinCheck = null;
      return;
    }
    final hand = players[0].hand;
    final rowStr = humanRows.map((r) => r.map((c) => c.id).join(',')).join(';');
    final currentKey = '$wildRank:${hand.length}:${hand.map((c) => c.id).join(',')}:$rowStr:$selectedCardId';

    if (_cachedWinCheckKey == currentKey && _cachedWinCheck != null) {
      return;
    }

    _cachedWinCheckKey = currentKey;
    _cachedWinCheck = GameEngine.findWinningDiscard(
      hand,
      wildRank,
      handRows: humanRows.map((r) => r.map((c) => c.id).toList()).toList(),
      preferredDiscardCardId: selectedCardId,
    );
  }

  Set<String> get meldedCardIds {
    if (!isAssisted || players.isEmpty) return const <String>{};
    _ensureHandEvaluated();
    return _cachedMeldedCardIds;
  }

  bool get canFinishNow {
    if (!isHumanTurn || !hasDrawnThisTurn || players.isEmpty || players[0].hand.length != 11) {
      return false;
    }
    if (isAssisted) {
      _ensureWinCheckEvaluated();
      return _cachedWinCheck?.canWin ?? false;
    } else {
      return true;
    }
  }

  String? get winningDiscardCardId {
    if (!isAssisted || !isHumanTurn || players.isEmpty || players[0].hand.length != 11) {
      return null;
    }
    _ensureWinCheckEvaluated();
    return (_cachedWinCheck != null && _cachedWinCheck!.canWin)
        ? _cachedWinCheck!.discardCard?.id
        : null;
  }

  int get currentHandPenalty {
    if (players.isEmpty) return 0;
    _ensureHandEvaluated();
    return _cachedPenalty;
  }

  void syncHumanRows(List<List<CardModel>> rows) {
    humanRows = rows.map((r) => List<CardModel>.from(r)).toList();
    final all = <CardModel>[];
    for (final r in humanRows) {
      all.addAll(r);
    }
    if (players.isNotEmpty) {
      players[0].hand = all;
    }
    _invalidateAssistedCache();
    notifyListeners();
  }

  void initMatch() {
    _botTimer?.cancel();
    _botTimer = null;
    _isPaused = false;
    _invalidateAssistedCache();
    _hasVibratedForCurrentHumanTurn = false;
    final settings = SettingsService.instance;

    winnerMessage = null;
    championSeatIndex = null;
    championName = null;
    lastShowdown = null;
    lastFinisherSeat = null;
    lastFalseDeclarerSeat = null;
    selectedCardId = null;

    roundHistory.clear();
    players.clear();
    // 0: İnsan Oyuncu (Sol-Alt)
    players.add(OfflinePlayer(
      userId: 'human',
      username: settings.playerName,
      avatar: settings.playerAvatar,
      seatIndex: 0,
      isBot: false,
    ));
    // 1: Sağ-Alt (Senin sağındaki oyuncu - Sağdan sola akışta ilk sıra bunda)
    players.add(OfflinePlayer(
      userId: 'bot_1',
      username: 'Ahmet',
      avatar: 'king',
      seatIndex: 1,
      isBot: true,
    ));
    // 2: Sağ-Üst (Karşı sağdaki oyuncu)
    players.add(OfflinePlayer(
      userId: 'bot_2',
      username: 'Zeynep',
      avatar: 'queen',
      seatIndex: 2,
      isBot: true,
    ));
    // 3: Sol-Üst (Senin solundaki oyuncu)
    players.add(OfflinePlayer(
      userId: 'bot_3',
      username: 'Mehmet',
      avatar: 'wolf',
      seatIndex: 3,
      isBot: true,
    ));

    roundNumber = 1;
    dealerSeat = 0;
    startRound();
  }

  void startRound() {
    _botTimer?.cancel();
    status = 'dealing';
    hasDrawnThisTurn = false;
    discardPile.clear();
    winnerMessage = null;
    championSeatIndex = null;
    championName = null;
    lastShowdown = null;
    lastFinisherSeat = null;
    lastFalseDeclarerSeat = null;
    selectedCardId = null;
    _invalidateAssistedCache();
    _hasVibratedForCurrentHumanTurn = false;

    // Yalnızca masada elenmemiş (aktif) oyunculara kart dağıt
    final activePlayerIds =
        players.where((p) => !p.isEliminated).map((p) => p.userId).toList();
    final dealt = GameEngine.dealRoundHands(activePlayerIds);

    drawPile = dealt.drawPile;
    indicatorCard = dealt.indicatorCard;
    wildRank = dealt.wildRank;

    for (int i = 0; i < players.length; i++) {
      if (players[i].isEliminated) {
        players[i].hand = [];
        players[i].openedMelds.clear();
      } else {
        players[i].hand = dealt.hands[players[i].userId] ?? [];
        players[i].openedMelds.clear();
      }
    }

    _distributeHumanCardsToRows(players[0].hand);

    // Dağıtandan sonraki aktif oyuncudan başla
    currentTurnSeat = getNextActiveSeatIndex(dealerSeat);
    status = 'playing';
    SoundFx.playCardSlide();
    _checkAndTriggerTurnStartHaptic();
    notifyListeners();

    if (!isHumanTurn) {
      _scheduleBotTurn();
    }
  }

  void _distributeHumanCardsToRows(List<CardModel> hand) {
    if (hand.isEmpty) {
      humanRows = [[], [], []];
      return;
    }
    // 1. HandSorter kurallarına göre deterministik sırala
    final sorted = HandSorter.sortHand(hand);
    players[0].hand = List<CardModel>.from(sorted);

    // 2. 3 ıstaka sırasına dengeli dağıt (Örn: 10 kart için 4, 3, 3; 11 kart için 4, 4, 3)
    final n = sorted.length;
    final count0 = (n / 3.0).ceil();
    final rem = n - count0;
    final count1 = (rem / 2.0).ceil();
    final count2 = n - count0 - count1;

    humanRows = [
      sorted.sublist(0, count0),
      sorted.sublist(count0, count0 + count1),
      sorted.sublist(count0 + count1, count0 + count1 + count2),
    ];
  }

  void selectCard(String cardId) {
    if (selectedCardId == cardId) {
      selectedCardId = null;
    } else {
      selectedCardId = cardId;
      SoundFx.playCardTap();
    }
    notifyListeners();
  }

  /// İnsan oyuncu kart çeker (Yalnızca kapalı desteden)
  void humanDrawCard({bool fromDiscard = false}) {
    if (!isHumanTurn || hasDrawnThisTurn) return;

    if (drawPile.isEmpty) {
      // Deste bittiyse turu bitir
      endRound(null);
      return;
    }
    final drawnCard = drawPile.removeAt(0);

    players[0].hand.add(drawnCard);
    // Çekilen kartı en az kartı olan sıraya ekle (dengeli tutar)
    int targetRow = 2;
    int minCards = humanRows[2].length;
    for (int r = 1; r >= 0; r--) {
      if (humanRows[r].length < minCards) {
        minCards = humanRows[r].length;
        targetRow = r;
      }
    }
    humanRows[targetRow].add(drawnCard);
    hasDrawnThisTurn = true;
    selectedCardId = null;
    _invalidateAssistedCache();
    notifyListeners();
  }

  /// İnsan oyuncu kart atar
  void humanDiscardCard(String cardId) {
    if (!isHumanTurn || !hasDrawnThisTurn) return;

    final idx = players[0].hand.indexWhere((c) => c.id == cardId);
    if (idx == -1) return;

    final discarded = players[0].hand.removeAt(idx);
    discardPile.add(discarded);
    _removeCardFromHumanRows(cardId);

    selectedCardId = null;
    hasDrawnThisTurn = false;
    _invalidateAssistedCache();

    // Deste tükendiyse ve kimse bitmediyse tur sona erer
    if (drawPile.isEmpty) {
      endRound(null);
      return;
    }

    _advanceTurn();
  }

  void _removeCardFromHumanRows(String cardId) {
    for (int r = 0; r < 3; r++) {
      humanRows[r].removeWhere((c) => c.id == cardId);
    }
  }

  /// Oyuncunun elindeki 11 karttan hangilerinin atılması durumunda
  /// elin geçerli bir şekilde açılabileceğini (bitirilebileceğini) tespit eder.
  List<CardModel> getValidDiscardCandidates() {
    if (!isHumanTurn || !hasDrawnThisTurn || players.isEmpty || players[0].hand.length != 11) {
      return [];
    }

    final isAssisted = SettingsService.instance.isAssisted;
    final hand11 = players[0].hand;
    final validCandidates = <CardModel>[];

    if (!isAssisted) {
      // YARDIMSIZ MOD: Istaka satırlarındaki (humanRows) yerleşime göre kontrol.
      // Bir kartın atılabilmesi için, o kart çıkarıldığında kalan 10 kartın
      // her satırda geçerli perler oluşturması ve toplam kart sayısının 10 olması gerekir.
      for (final cand in hand11) {
        bool allRowsValid = true;
        int meldedCount = 0;

        for (int r = 0; r < 3; r++) {
          final rowCards = humanRows[r].where((c) => c.id != cand.id).toList();
          if (rowCards.isEmpty) continue;
          meldedCount += rowCards.length;

          final decomp = GameEngine.decomposeRowIntoMelds(rowCards, wildRank);
          if (!decomp.valid) {
            allRowsValid = false;
            break;
          }
        }

        if (allRowsValid && meldedCount == 10) {
          validCandidates.add(cand);
        }
      }
    } else {
      // YARDIMLI MOD:
      // Hem oyuncunun dizdiği satırlara bakar, hem de genel optimum kombinasyona bakar.
      for (final cand in hand11) {
        // Önce ıstaka satırları kontrolü
        bool allRowsValid = true;
        int meldedCount = 0;

        for (int r = 0; r < 3; r++) {
          final rowCards = humanRows[r].where((c) => c.id != cand.id).toList();
          if (rowCards.isEmpty) continue;
          meldedCount += rowCards.length;

          final decomp = GameEngine.decomposeRowIntoMelds(rowCards, wildRank);
          if (!decomp.valid) {
            allRowsValid = false;
            break;
          }
        }

        if (allRowsValid && meldedCount == 10) {
          validCandidates.add(cand);
          continue;
        }

        // Genel optimum el değerlendirmesi
        final remaining10 = hand11.where((c) => c.id != cand.id).toList();
        final eval10 = GameEngine.evaluateHandOptimal(remaining10, wildRank);
        if (eval10.canFinish) {
          validCandidates.add(cand);
        }
      }
    }

    return validCandidates;
  }

  /// Yardımsız modda el açma butonuna basıldığında hamlenin geçersiz olup olmayacağını
  /// (doğrudan 101 ceza alınıp alınmayacağını) kontrol eder.
  bool willHumanFinishCausePenalty() {
    if (!isHumanTurn || !hasDrawnThisTurn || players.isEmpty || players[0].hand.length != 11) {
      return false;
    }
    final isAssisted = SettingsService.instance.isAssisted;
    if (isAssisted) {
      return false; // Yardımlı modda sadece geçerli el açılabilir
    }

    final validCandidates = getValidDiscardCandidates();
    if (validCandidates.isNotEmpty) {
      // Eğer kullanıcı açıkça bir kart seçmişse ve bu kart geçerli adaylardan biriyse ceza yok
      if (selectedCardId != null && validCandidates.any((c) => c.id == selectedCardId)) {
        return false;
      }
      // Kart seçilmemişse sistem otomatik seçecek veya diyalogla seçtirecektir, ceza uyarısı tetiklenmez
      if (selectedCardId == null) {
        return false;
      }
      // Kullanıcı geçerli adaylar varken açıkça aday DIŞINDA bir kart seçmişse ceza oluşur
      return true;
    }

    // Elde hiçbir geçerli bitiş adayı yoksa kesinlikle hatalı açmadır (101 ceza!)
    return true;
  }

  /// İnsan oyuncu el açar / bitirir
  void humanDeclareFinish({String? discardCardId}) {
    if (!isHumanTurn || !hasDrawnThisTurn || players[0].hand.length != 11) return;

    final isAssisted = SettingsService.instance.isAssisted;
    final rowIds = humanRows.map((r) => r.map((c) => c.id).toList()).toList();
    final validCandidates = getValidDiscardCandidates();

    // Atılacak kartı belirle:
    // 1. Parametre olarak iletilmişse
    // 2. Seçili kart geçerli adaylardan biriyse
    // 3. Tek geçerli aday varsa
    // 4. Adaylar içinden ilki (güvenli fallback)
    // 5. Hiç aday yoksa seçili kart veya son kart (hatalı açma akışı)
    String chosenDiscardId;
    if (discardCardId != null && players[0].hand.any((c) => c.id == discardCardId)) {
      chosenDiscardId = discardCardId;
    } else if (selectedCardId != null && validCandidates.any((c) => c.id == selectedCardId)) {
      chosenDiscardId = selectedCardId!;
    } else if (validCandidates.length == 1) {
      chosenDiscardId = validCandidates.first.id;
    } else if (validCandidates.isNotEmpty) {
      chosenDiscardId = validCandidates.first.id;
    } else {
      chosenDiscardId = selectedCardId ?? players[0].hand.last.id;
    }

    if (isAssisted) {
      // Yardımlı Mod: Otomatik kontrol
      final winCheck = GameEngine.findWinningDiscard(
        players[0].hand,
        wildRank,
        handRows: rowIds,
        preferredDiscardCardId: chosenDiscardId,
      );

      if (winCheck.canWin && winCheck.discardCard != null) {
        final discardCard = winCheck.discardCard!;
        players[0].hand.removeWhere((c) => c.id == discardCard.id);
        discardPile.add(discardCard);
        _removeCardFromHumanRows(discardCard.id);

        players[0].openedMelds = winCheck.evaluation?.melds ?? [];
        selectedCardId = null;
        hasDrawnThisTurn = false;
        _invalidateAssistedCache();
        endRound(0);
        return;
      }
    } else {
      // Yardımsız Mod: Istaka satırları geçerli per mi kontrol et
      final candDiscard = players[0].hand.firstWhere(
        (c) => c.id == chosenDiscardId,
        orElse: () => players[0].hand.last,
      );

      final rowMelds = <List<CardModel>>[];
      bool allRowsValid = true;
      int meldedCount = 0;

      for (int r = 0; r < 3; r++) {
        final rowCards =
            humanRows[r].where((c) => c.id != candDiscard.id).toList();
        if (rowCards.isEmpty) continue;
        meldedCount += rowCards.length;

        final decomp = GameEngine.decomposeRowIntoMelds(rowCards, wildRank);
        if (!decomp.valid) {
          allRowsValid = false;
          break;
        }
        rowMelds.addAll(decomp.melds);
      }

      if (allRowsValid && meldedCount == 10) {
        // Geçerli bitiş
        players[0].hand.removeWhere((c) => c.id == candDiscard.id);
        discardPile.add(candDiscard);
        _removeCardFromHumanRows(candDiscard.id);
        players[0].openedMelds = rowMelds;
        selectedCardId = null;
        hasDrawnThisTurn = false;
        _invalidateAssistedCache();
        endRound(0);
        return;
      } else {
        // Hatalı el açma -> Yardımsız modda direkt 101 ceza ile yanar
        selectedCardId = null;
        hasDrawnThisTurn = false;
        _invalidateAssistedCache();
        endRound(null, falseDeclarerSeat: 0);
        return;
      }
    }
  }

  /// Per Diz butonu
  void humanSortMelds() {
    final eval = GameEngine.evaluateHandOptimal(players[0].hand, wildRank);
    humanRows = [[], [], []];

    int rowIndex = 0;
    for (final meld in eval.melds) {
      if (rowIndex < 3) {
        humanRows[rowIndex].addAll(meld);
        rowIndex++;
      } else {
        humanRows[2].addAll(meld);
      }
    }
    // Per dışındaki kartları en az kartı olan sıraya dengeli ekle
    for (final c in eval.unmelded) {
      int targetRow = 0;
      int minCount = humanRows[0].length;
      for (int r = 1; r < 3; r++) {
        if (humanRows[r].length < minCount) {
          minCount = humanRows[r].length;
          targetRow = r;
        }
      }
      humanRows[targetRow].add(c);
    }
    SoundFx.playCardTap();
    _invalidateAssistedCache();
    notifyListeners();
  }

  /// Sayı Sırala butonu: HandSorter kurallarına göre deterministik sıralama yapar.
  void humanSortRanks() {
    if (players.isEmpty || players[0].hand.isEmpty) return;
    final sorted = HandSorter.sortHand(players[0].hand);
    players[0].hand = List<CardModel>.from(sorted);

    // 3 ıstaka sırasına dengeli ve okunabilir yerleştir (4, 3, 3 / 4, 4, 3 vb.)
    final n = sorted.length;
    final count0 = (n / 3.0).ceil();
    final rem = n - count0;
    final count1 = (rem / 2.0).ceil();
    final count2 = n - count0 - count1;

    humanRows = [
      sorted.sublist(0, count0),
      sorted.sublist(count0, count0 + count1),
      sorted.sublist(count0 + count1, count0 + count1 + count2),
    ];
    SoundFx.playCardTap();
    _invalidateAssistedCache();
    notifyListeners();
  }

  /// Istaka içinde kartı taşıma
  void moveCard(String cardId, int targetRow, int targetIndex) {
    CardModel? card;
    for (int r = 0; r < 3; r++) {
      final idx = humanRows[r].indexWhere((c) => c.id == cardId);
      if (idx != -1) {
        card = humanRows[r].removeAt(idx);
        break;
      }
    }

    if (card != null) {
      targetRow = targetRow.clamp(0, 2);
      final list = humanRows[targetRow];
      final insertIdx = targetIndex.clamp(0, list.length);
      list.insert(insertIdx, card);
      SoundFx.playCardTap();
      _invalidateAssistedCache();
      notifyListeners();
    }
  }

  /// Aktif (elenmemiş) bir sonraki oyuncunun koltuk numarasını bulur
  int getNextActiveSeatIndex(int fromSeat) {
    if (players.isEmpty) return 0;
    for (int step = 1; step <= 4; step++) {
      final candidate = (fromSeat + step) % 4;
      if (candidate < players.length && !players[candidate].isEliminated) {
        return candidate;
      }
    }
    return fromSeat;
  }

  void _advanceTurn() {
    if (status != 'playing') return;

    currentTurnSeat = getNextActiveSeatIndex(currentTurnSeat);
    hasDrawnThisTurn = false;
    _checkAndTriggerTurnStartHaptic();
    notifyListeners();

    if (!isHumanTurn) {
      _scheduleBotTurn();
    }
  }

  /// Bot Hamle Döngüsü
  void _scheduleBotTurn() {
    _botTimer?.cancel();
    _botTimer = null;
    if (status != 'playing' || _isPaused || isHumanTurn) return;

    final bot = players[currentTurnSeat];
    if (bot.isEliminated) {
      _advanceTurn();
      return;
    }

    if (hasDrawnThisTurn) {
      // Bot daha önce kart çekmişse (örneğin duraklatılıp devam edildiyse), doğrudan atma adımına geç
      _scheduleBotDiscard(bot);
    } else {
      // Bot henüz kart çekmemiş, kart çekme adımını zamanla
      _scheduleBotDraw(bot);
    }
  }

  void _scheduleBotDraw(OfflinePlayer bot) {
    _botTimer?.cancel();
    _botTimer = Timer(const Duration(milliseconds: 1000), () {
      if (status != 'playing' || _isPaused || currentTurnSeat != bot.seatIndex || hasDrawnThisTurn) {
        return;
      }

      // 1. Kart çekme kararı (Kural: Yalnızca kapalı desteden çekilir)
      if (drawPile.isEmpty) {
        endRound(null);
        return;
      }
      final drawnCard = drawPile.removeAt(0);

      bot.hand.add(drawnCard);
      hasDrawnThisTurn = true;
      SoundFx.playCardDraw();
      notifyListeners();

      // 2. Kart atma veya El açma kararını zamanla
      _scheduleBotDiscard(bot);
    });
  }

  void _scheduleBotDiscard(OfflinePlayer bot) {
    _botTimer?.cancel();
    _botTimer = Timer(const Duration(milliseconds: 650), () {
      if (status != 'playing' || _isPaused || currentTurnSeat != bot.seatIndex || !hasDrawnThisTurn) {
        return;
      }

      // Kazanabiliyor mu?
      final winCheck = GameEngine.findWinningDiscard(bot.hand, wildRank);
      if (winCheck.canWin && winCheck.discardCard != null) {
        final discardCard = winCheck.discardCard!;
        bot.hand.removeWhere((c) => c.id == discardCard.id);
        discardPile.add(discardCard);
        bot.openedMelds = winCheck.evaluation?.melds ?? [];
        endRound(bot.seatIndex);
        return;
      }

      // Kazanamıyorsa en gereksiz kartı at
      final toDiscard = GameEngine.selectBestAutoDiscard(bot.hand, wildRank);
      bot.hand.removeWhere((c) => c.id == toDiscard.id);
      discardPile.add(toDiscard);
      SoundFx.playCardDiscard();

      // Deste tükendiyse ve kimse bitmediyse tur sona erer
      if (drawPile.isEmpty) {
        endRound(null);
        return;
      }

      _advanceTurn();
    });
  }

  /// Tur Sonu Değerlendirmesi (Anında Showdown, Süre Yok)
  void endRound(int? finisherSeat, {int? falseDeclarerSeat}) {
    _botTimer?.cancel();
    _botTimer = null;
    status = 'round_summary';
    _hasVibratedForCurrentHumanTurn = false;
    lastFinisherSeat = finisherSeat;
    lastFalseDeclarerSeat = falseDeclarerSeat;

    final results = <ShowdownPlayerResult>[];

    for (int i = 0; i < players.length; i++) {
      final p = players[i];
      final isFinisher = finisherSeat == i;
      final isFalseDeclarer = falseDeclarerSeat == i;

      final eval = GameEngine.evaluateHandOptimal(p.hand, wildRank);
      final displayMelds = isFinisher && p.openedMelds.isNotEmpty
          ? p.openedMelds
          : eval.melds;

      final wasAlreadyEliminated = p.isEliminated;
      int roundPenalty = 0;
      if (wasAlreadyEliminated) {
        // Önceden elenmiş oyuncu yeni ceza almaz
        roundPenalty = 0;
      } else if (falseDeclarerSeat != null) {
        // Hatalı el açma: SADECE hatalı açan 101 ceza alır, diğer oyuncular 0 ceza alır
        roundPenalty = isFalseDeclarer ? 101 : 0;
      } else {
        roundPenalty = isFinisher ? 0 : eval.penalty;
      }

      final prevScore = p.totalScore;
      if (!wasAlreadyEliminated) {
        p.totalScore += roundPenalty;
      }
      final burned = p.totalScore >= 101;
      if (burned) p.isEliminated = true;

      results.add(ShowdownPlayerResult(
        userId: p.userId,
        username: p.username,
        avatar: p.avatar,
        seatIndex: p.seatIndex,
        isFinisher: isFinisher,
        isFalseDeclarer: isFalseDeclarer,
        melds: displayMelds,
        unmelded: isFinisher || wasAlreadyEliminated ? [] : eval.unmelded,
        roundPenalty: roundPenalty,
        previousScore: prevScore,
        newTotalScore: p.totalScore,
        burnedThisRound: !wasAlreadyEliminated && burned,
      ));
    }

    lastShowdown = results;

    // Otantik çetele için tur kaydını ekle
    final scoresMap = <String, int>{};
    for (final r in results) {
      scoresMap[r.userId] = r.roundPenalty;
    }
    roundHistory.add(RoundHistoryEntry(
      roundNumber: roundNumber,
      finisherUserId: finisherSeat != null && finisherSeat >= 0 && finisherSeat < players.length
          ? players[finisherSeat].userId
          : null,
      scoresByUser: scoresMap,
    ));

    if (finisherSeat == 0) {
      SoundFx.playCelebration();
      SoundFx.triggerHapticHeavy();
    } else {
      SoundFx.playCardDiscard();
    }

    // Oyun bitti mi kontrol et (İnsan yandı mı veya tek kişi mi kaldı?)
    final alivePlayers = players.where((p) => !p.isEliminated).toList();
    if (players[0].isEliminated || alivePlayers.length <= 1) {
      // Şampiyon belirlendi
      if (alivePlayers.isEmpty) {
        // Herkes aynı turda 101'i geçtiyse en düşük toplam puana sahip olan kazanır
        final sortedByScore = List<OfflinePlayer>.from(players)
          ..sort((a, b) => a.totalScore.compareTo(b.totalScore));
        final champion = sortedByScore.first;
        championSeatIndex = champion.seatIndex;
        championName = champion.username;
        winnerMessage = champion.seatIndex == 0
            ? 'Tebrikler! Masayı Şampiyon Olarak Tamamladınız! 🏆'
            : '${champion.username} Şampiyon Oldu!';
      } else {
        alivePlayers.sort((a, b) => a.totalScore.compareTo(b.totalScore));
        final champion = alivePlayers.first;
        championSeatIndex = champion.seatIndex;
        championName = champion.username;
        winnerMessage = champion.seatIndex == 0
            ? 'Tebrikler! Masayı Şampiyon Olarak Tamamladınız! 🏆'
            : '${champion.username} Şampiyon Oldu!';
      }
    } else {
      winnerMessage = null;
      championSeatIndex = null;
      championName = null;
    }

    notifyListeners();
  }

  /// Oyuncu tur sonu ekranında "Devam Et" butonuna bastığında çağrılır
  void continueAfterRound() {
    if (winnerMessage != null) {
      status = 'game_over';
      notifyListeners();
    } else {
      roundNumber++;
      dealerSeat = getNextActiveSeatIndex(dealerSeat);
      startRound();
    }
  }

  @override
  void dispose() {
    _botTimer?.cancel();
    _botTimer = null;
    super.dispose();
  }
}
