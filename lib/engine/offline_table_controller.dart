import 'dart:async';
import 'package:flutter/foundation.dart';
import 'card_model.dart';
import 'game_engine.dart';
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

  Timer? _botTimer;

  bool get isHumanTurn => currentTurnSeat == 0 && status == 'playing';
  OfflinePlayer get humanPlayer => players[0];

  void initMatch() {
    _botTimer?.cancel();
    final settings = SettingsService.instance;

    players.clear();
    // 0: İnsan Oyuncu
    players.add(OfflinePlayer(
      userId: 'human',
      username: settings.playerName,
      avatar: settings.playerAvatar,
      seatIndex: 0,
      isBot: false,
    ));
    // 1: Bot Doğu
    players.add(OfflinePlayer(
      userId: 'bot_1',
      username: 'Ahmet',
      avatar: 'king',
      seatIndex: 1,
      isBot: true,
    ));
    // 2: Bot Kuzey
    players.add(OfflinePlayer(
      userId: 'bot_2',
      username: 'Zeynep',
      avatar: 'queen',
      seatIndex: 2,
      isBot: true,
    ));
    // 3: Bot Batı
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

    final playerIds = players.map((p) => p.userId).toList();
    final dealt = GameEngine.dealRoundHands(playerIds);

    drawPile = dealt.drawPile;
    indicatorCard = dealt.indicatorCard;
    wildRank = dealt.wildRank;

    for (int i = 0; i < players.length; i++) {
      players[i].hand = dealt.hands[players[i].userId] ?? [];
      players[i].openedMelds.clear();
    }

    _distributeHumanCardsToRows(players[0].hand);

    // Dağıtandan sonraki oyuncudan başla
    currentTurnSeat = (dealerSeat + 1) % 4;
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

  /// İnsan oyuncu kart çeker
  void humanDrawCard({required bool fromDiscard}) {
    if (!isHumanTurn || hasDrawnThisTurn) return;

    CardModel? drawnCard;
    if (fromDiscard) {
      if (discardPile.isEmpty) return;
      drawnCard = discardPile.removeLast();
    } else {
      if (drawPile.isEmpty) {
        // Deste bittiyse turu bitir
        endRound(null);
        return;
      }
      drawnCard = drawPile.removeAt(0);
    }

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

    _advanceTurn();
  }

  void _removeCardFromHumanRows(String cardId) {
    for (int r = 0; r < 3; r++) {
      humanRows[r].removeWhere((c) => c.id == cardId);
    }
  }

  /// İnsan oyuncu el açar / bitirir
  void humanDeclareFinish() {
    if (!isHumanTurn || !hasDrawnThisTurn || players[0].hand.length != 11) return;

    final isAssisted = SettingsService.instance.isAssisted;

    if (isAssisted) {
      // Yardımlı Mod: Otomatik kontrol
      final winCheck = GameEngine.findWinningDiscard(
        players[0].hand,
        wildRank,
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

  /// Sayı Sırala butonu
  void humanSortRanks() {
    final sorted = List<CardModel>.from(players[0].hand)
      ..sort((a, b) {
        final aWild = GameEngine.isWildCard(a, wildRank) ? 1 : 0;
        final bWild = GameEngine.isWildCard(b, wildRank) ? 1 : 0;
        if (aWild != bWild) return aWild.compareTo(bWild);
        if (a.rank != b.rank) return a.rank.compareTo(b.rank);
        return a.suit.compareTo(b.suit);
      });

    humanRows = [[], [], []];
    for (int i = 0; i < sorted.length; i++) {
      humanRows[i % 3].add(sorted[i]);
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

  void _advanceTurn() {
    if (status != 'playing') return;

    currentTurnSeat = (currentTurnSeat + 1) % 4;
    hasDrawnThisTurn = false;
    notifyListeners();

    if (!isHumanTurn) {
      _scheduleBotTurn();
    }
  }

  /// Bot Hamle Döngüsü
  void _scheduleBotTurn() {
    _botTimer?.cancel();
    if (status != 'playing' || isHumanTurn) return;

    final bot = players[currentTurnSeat];
    if (bot.isEliminated) {
      _advanceTurn();
      return;
    }

    // Bot düşünme süresi (1200ms)
    _botTimer = Timer(const Duration(milliseconds: 1200), () {
      if (status != 'playing' || currentTurnSeat != bot.seatIndex) return;

      // 1. Kart çekme kararı
      CardModel? drawnCard;

      if (discardPile.isNotEmpty) {
        final topDiscard = discardPile.last;
        // Atılan kart botun elini bitiriyor mu?
        final testHand = [...bot.hand, topDiscard];
        final winTest = GameEngine.findWinningDiscard(testHand, wildRank);
        if (winTest.canWin) {
          drawnCard = discardPile.removeLast();
        }
      }

      if (drawnCard == null) {
        if (drawPile.isEmpty) {
          endRound(null);
          return;
        }
        drawnCard = drawPile.removeAt(0);
      }

      bot.hand.add(drawnCard);
      hasDrawnThisTurn = true;
      SoundFx.playCardDraw();
      notifyListeners();

      // 2. Kart atma veya El açma kararı (600ms sonra)
      _botTimer = Timer(const Duration(milliseconds: 650), () {
        if (status != 'playing' || currentTurnSeat != bot.seatIndex) return;

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

        _advanceTurn();
      });
    });
  }

  /// Tur Sonu Değerlendirmesi (Anında Showdown, Süre Yok)
  void endRound(int? finisherSeat, {int? falseDeclarerSeat}) {
    _botTimer?.cancel();
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

      int roundPenalty = 0;
      if (isFinisher) {
        roundPenalty = 0;
      } else if (isFalseDeclarer) {
        roundPenalty = 101; // Hatalı el açan direkt yanar
      } else {
        roundPenalty = eval.penalty;
      }

      final prevScore = p.totalScore;
      p.totalScore += roundPenalty;
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
        unmelded: isFinisher ? [] : eval.unmelded,
        roundPenalty: roundPenalty,
        previousScore: prevScore,
        newTotalScore: p.totalScore,
        burnedThisRound: burned,
      ));
    }

    lastShowdown = results;
    if (finisherSeat == 0) {
      SoundFx.playCelebration();
    } else {
      SoundFx.playCardDiscard();
    }

    // Oyun bitti mi kontrol et (İnsan yandı mı veya tek kişi mi kaldı?)
    final alivePlayers = players.where((p) => !p.isEliminated).toList();
    if (players[0].isEliminated || alivePlayers.length <= 1) {
      // Şampiyon belirlendi
      alivePlayers.sort((a, b) => a.totalScore.compareTo(b.totalScore));
      final champion = alivePlayers.isNotEmpty ? alivePlayers.first : players[0];
      winnerMessage = champion.seatIndex == 0
          ? 'Tebrikler! Masayı Şampiyon Olarak Tamamladınız! 🏆'
          : '${champion.username} Şampiyon Oldu!';
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
      dealerSeat = (dealerSeat + 1) % 4;
      startRound();
    }
  }

  @override
  void dispose() {
    _botTimer?.cancel();
    super.dispose();
  }
}
