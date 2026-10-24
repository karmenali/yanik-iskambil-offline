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

  Set<String> get meldedCardIds {
    if (!isAssisted || players.isEmpty) return <String>{};
    final eval = GameEngine.evaluateHandOptimal(players[0].hand, wildRank);
    final ids = <String>{};
    for (final m in eval.melds) {
      for (final c in m) {
        ids.add(c.id);
      }
    }
    return ids;
  }

  bool get canFinishNow {
    if (!isHumanTurn || !hasDrawnThisTurn || players.isEmpty || players[0].hand.length != 11) {
      return false;
    }
    if (isAssisted) {
      final winCheck = GameEngine.findWinningDiscard(
        players[0].hand,
        wildRank,
        preferredDiscardCardId: selectedCardId,
      );
      return winCheck.canWin;
    } else {
      return true;
    }
  }

  String? get winningDiscardCardId {
    if (!isAssisted || !isHumanTurn || players.isEmpty || players[0].hand.length != 11) {
      return null;
    }
    final winCheck = GameEngine.findWinningDiscard(players[0].hand, wildRank);
    return winCheck.canWin ? winCheck.discardCard?.id : null;
  }

  int get currentHandPenalty {
    if (players.isEmpty) return 0;
    final eval = GameEngine.evaluateHandOptimal(players[0].hand, wildRank);
    return eval.penalty;
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
    notifyListeners();
  }

  void initMatch() {
    _botTimer?.cancel();
    _botTimer = null;
    _isPaused = false;
    final settings = SettingsService.instance;

    winnerMessage = null;
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
    lastShowdown = null;
    lastFinisherSeat = null;
    lastFalseDeclarerSeat = null;
    selectedCardId = null;

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
    notifyListeners();

    if (!isHumanTurn) {
      _scheduleBotTurn();
    }
  }

  void _distributeHumanCardsToRows(List<CardModel> hand) {
    // Otomatik optimal dizilimi uygula
    final eval = GameEngine.evaluateHandOptimal(hand, wildRank);
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
    // Kalanları sırayla dağıt
    int r = 0;
    for (final c in eval.unmelded) {
      humanRows[r % 3].add(c);
      r++;
    }
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
    // 3. sıranın sonuna ekle
    humanRows[2].add(drawnCard);
    hasDrawnThisTurn = true;
    selectedCardId = drawnCard.id;
    SoundFx.playCardDraw();
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
    SoundFx.playCardDiscard();

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

    final candDiscardId = selectedCardId ?? players[0].hand.last.id;
    final rowMelds = <List<CardModel>>[];
    bool allRowsValid = true;
    int meldedCount = 0;

    for (int r = 0; r < 3; r++) {
      final rowCards =
          humanRows[r].where((c) => c.id != candDiscardId).toList();
      if (rowCards.isEmpty) continue;
      meldedCount += rowCards.length;

      final decomp = GameEngine.decomposeRowIntoMelds(rowCards, wildRank);
      if (!decomp.valid) {
        allRowsValid = false;
        break;
      }
      rowMelds.addAll(decomp.melds);
    }

    final isValid = allRowsValid && meldedCount == 10;
    return !isValid;
  }

  /// İnsan oyuncu el açar / bitirir
  void humanDeclareFinish() {
    if (!isHumanTurn || !hasDrawnThisTurn || players[0].hand.length != 11) return;

    final isAssisted = SettingsService.instance.isAssisted;
    final rowIds = humanRows.map((r) => r.map((c) => c.id).toList()).toList();

    if (isAssisted) {
      // Yardımlı Mod: Otomatik kontrol (önce ıstaka sıralarını, sonra genel kombinasyonu dener)
      final winCheck = GameEngine.findWinningDiscard(
        players[0].hand,
        wildRank,
        handRows: rowIds,
        preferredDiscardCardId: selectedCardId,
      );

      if (winCheck.canWin && winCheck.discardCard != null) {
        final discardCard = winCheck.discardCard!;
        players[0].hand.removeWhere((c) => c.id == discardCard.id);
        discardPile.add(discardCard);
        _removeCardFromHumanRows(discardCard.id);

        players[0].openedMelds = winCheck.evaluation?.melds ?? [];
        endRound(0);
        return;
      }
    } else {
      // Yardımsız Mod: Istaka satırları geçerli per mi kontrol et
      final candDiscardId = selectedCardId ?? players[0].hand.last.id;
      final candDiscard = players[0].hand.firstWhere((c) => c.id == candDiscardId);

      final rowMelds = <List<CardModel>>[];
      bool allRowsValid = true;
      int meldedCount = 0;

      for (int r = 0; r < 3; r++) {
        final rowCards =
            humanRows[r].where((c) => c.id != candDiscardId).toList();
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
        players[0].hand.removeWhere((c) => c.id == candDiscardId);
        discardPile.add(candDiscard);
        _removeCardFromHumanRows(candDiscardId);
        players[0].openedMelds = rowMelds;
        endRound(0);
        return;
      } else {
        // Hatalı el açma -> Yardımsız modda direkt 101 ceza ile yanar
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
    int r = 0;
    for (final c in eval.unmelded) {
      humanRows[r % 3].add(c);
      r++;
    }
    SoundFx.playCardTap();
    notifyListeners();
  }

  /// Sayı Sırala butonu: HandSorter kurallarına göre deterministik sıralama yapar.
  void humanSortRanks() {
    if (players.isEmpty || players[0].hand.isEmpty) return;
    final sorted = HandSorter.sortHand(players[0].hand);
    players[0].hand = List<CardModel>.from(sorted);

    // 3 ıstaka sırasına dengeli ve okunabilir yerleştir (küçük ranklar üst sırada, büyükler ve jokerler alt sıralarda)
    humanRows = [[], [], []];
    final perRow = (sorted.length / 3.0).ceil();
    for (int i = 0; i < sorted.length; i++) {
      final r = (i / perRow).floor().clamp(0, 2);
      humanRows[r].add(sorted[i]);
    }
    SoundFx.playCardTap();
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
        winnerMessage = champion.seatIndex == 0
            ? 'Tebrikler! Masayı Şampiyon Olarak Tamamladınız! 🏆'
            : '${champion.username} Şampiyon Oldu!';
      } else {
        alivePlayers.sort((a, b) => a.totalScore.compareTo(b.totalScore));
        final champion = alivePlayers.first;
        winnerMessage = champion.seatIndex == 0
            ? 'Tebrikler! Masayı Şampiyon Olarak Tamamladınız! 🏆'
            : '${champion.username} Şampiyon Oldu!';
      }
    } else {
      winnerMessage = null;
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
