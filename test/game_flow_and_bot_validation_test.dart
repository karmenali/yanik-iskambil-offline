import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yanik_offline/engine/card_model.dart';
import 'package:yanik_offline/engine/game_engine.dart';
import 'package:yanik_offline/engine/offline_table_controller.dart';
import 'package:yanik_offline/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'yanik_offline_sound': false,
      'yanik_offline_vibration': false,
      'yanik_offline_assisted': true,
    });
    await SettingsService.instance.init();
  });

  group('Scenario 1: Four players sequential draw and discard cycle', () {
    test('Turn rotates 0 -> 1 -> 2 -> 3 -> 0 with strict draw-before-discard rule', () {
      final ctrl = OfflineTableController.instance;
      ctrl.initMatch();

      // İnsan oyuncunun sırası olsun (0)
      ctrl.currentTurnSeat = 0;
      ctrl.hasDrawnThisTurn = false;

      // 1. Çekmeden atamaz
      final handCountBefore = ctrl.players[0].hand.length;
      ctrl.humanDiscardCard(ctrl.players[0].hand.first.id);
      expect(ctrl.players[0].hand.length, handCountBefore, reason: 'Kart çekmeden kart atılamaz');
      expect(ctrl.currentTurnSeat, 0, reason: 'Sıra ilerlememeli');

      // 2. Kart çeker
      ctrl.humanDrawCard();
      expect(ctrl.players[0].hand.length, handCountBefore + 1);
      expect(ctrl.hasDrawnThisTurn, isTrue);

      // 3. İki kez çekemez
      ctrl.humanDrawCard();
      expect(ctrl.players[0].hand.length, handCountBefore + 1, reason: 'Aynı turda 2 kez kart çekilemez');

      // 4. Kart atar -> Sıra Ahmet\'e (1) geçer
      final cardToDiscard = ctrl.players[0].hand.first.id;
      ctrl.humanDiscardCard(cardToDiscard);
      expect(ctrl.players[0].hand.length, handCountBefore);
      expect(ctrl.currentTurnSeat, 1, reason: 'Kart atıldıktan sonra sıra Ahmet\'e (1) geçmeli');
      expect(ctrl.hasDrawnThisTurn, isFalse);

      // 5. Ahmet (1) çeker ve atar -> Sıra Zeynep\'e (2) geçer
      ctrl.players[1].hand.add(ctrl.drawPile.removeAt(0));
      ctrl.hasDrawnThisTurn = true;
      final bot1Discard = GameEngine.selectBestAutoDiscard(ctrl.players[1].hand, ctrl.wildRank);
      ctrl.players[1].hand.removeWhere((c) => c.id == bot1Discard.id);
      ctrl.discardPile.add(bot1Discard);
      // Simüle edilen sıra ilerletme:
      ctrl.currentTurnSeat = ctrl.getNextActiveSeatIndex(ctrl.currentTurnSeat);
      expect(ctrl.currentTurnSeat, 2, reason: 'Sıra Zeynep\'e (2) geçmeli');

      // 6. Zeynep (2) çeker ve atar -> Sıra Mehmet\'e (3) geçer
      ctrl.players[2].hand.add(ctrl.drawPile.removeAt(0));
      ctrl.currentTurnSeat = ctrl.getNextActiveSeatIndex(ctrl.currentTurnSeat);
      expect(ctrl.currentTurnSeat, 3, reason: 'Sıra Mehmet\'e (3) geçmeli');

      // 7. Mehmet (3) çeker ve atar -> Sıra tekrar İnsan Oyuncuya (0) döner
      ctrl.players[3].hand.add(ctrl.drawPile.removeAt(0));
      ctrl.currentTurnSeat = ctrl.getNextActiveSeatIndex(ctrl.currentTurnSeat);
      expect(ctrl.currentTurnSeat, 0, reason: 'Sıra tekrar İnsan Oyuncuya (0) dönmeli');
    });
  });

  group('Scenario 2: Closed deck exhaustion and round termination', () {
    test('When last card is drawn and discarded, round terminates cleanly with endRound(null)', () {
      final ctrl = OfflineTableController.instance;
      ctrl.initMatch();

      // Destedeki kart sayısını 1\'e indir
      ctrl.drawPile = [
        const CardModel(id: 'last_card', suit: 'S', rank: 4, deckIndex: 1, isPhysicalJoker: false)
      ];
      ctrl.currentTurnSeat = 0;
      ctrl.hasDrawnThisTurn = false;

      // Son kartı çek
      ctrl.humanDrawCard();
      expect(ctrl.drawPile.isEmpty, isTrue, reason: 'Deste tamamen boşalmış olmalı');
      expect(ctrl.hasDrawnThisTurn, isTrue);
      expect(ctrl.status, 'playing', reason: 'Kart çeken oyuncu kart atmadan önce oyun henüz bitmemeli');

      // Kartını atar -> Deste boşaldığı için anında tur sonu çağrılmalı
      final discardId = ctrl.players[0].hand.first.id;
      ctrl.humanDiscardCard(discardId);

      expect(ctrl.status, 'round_summary', reason: 'Deste tükendiğinde tur round_summary durumuna geçmeli');
      expect(ctrl.lastFinisherSeat, isNull, reason: 'Deste tükendiğinde kazanan olmamalı');
      expect(ctrl.lastShowdown, isNotNull);
    });
  });

  group('Scenario 3: Valid and Invalid finish behaviors for human and bots', () {
    test('Human Assisted finish: valid 10-meld + 1 discard finishes with 0 penalty', () async {
      final ctrl = OfflineTableController.instance;
      ctrl.initMatch();
      await SettingsService.instance.setAssisted(true);

      ctrl.currentTurnSeat = 0;
      ctrl.hasDrawnThisTurn = true;
      ctrl.wildRank = 9;

      // 10 kart per + 1 kart fazlalık
      ctrl.players[0].hand = [
        // 3-4-5 Kupa (Seri)
        const CardModel(id: '1_H_3', suit: 'H', rank: 3, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '1_H_4', suit: 'H', rank: 4, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '1_H_5', suit: 'H', rank: 5, deckIndex: 1, isPhysicalJoker: false),
        // 7-8-9 Maça (Seri)
        const CardModel(id: '1_S_7', suit: 'S', rank: 7, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '1_S_8', suit: 'S', rank: 8, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '1_S_9', suit: 'S', rank: 9, deckIndex: 1, isPhysicalJoker: false),
        // K-K-K-K (Grup)
        const CardModel(id: '1_S_13', suit: 'S', rank: 13, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '1_H_13', suit: 'H', rank: 13, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '1_D_13', suit: 'D', rank: 13, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '1_C_13', suit: 'C', rank: 13, deckIndex: 1, isPhysicalJoker: false),
        // Fazlalık atılacak kart (2 Karo)
        const CardModel(id: '1_D_2', suit: 'D', rank: 2, deckIndex: 1, isPhysicalJoker: false),
      ];
      ctrl.selectedCardId = '1_D_2';

      expect(ctrl.canFinishNow, isTrue);
      ctrl.humanDeclareFinish();

      expect(ctrl.status, 'round_summary');
      expect(ctrl.lastFinisherSeat, 0);
      final p0Result = ctrl.lastShowdown!.firstWhere((r) => r.seatIndex == 0);
      expect(p0Result.roundPenalty, 0);
      expect(p0Result.isFinisher, isTrue);
    });

    test('Human Unassisted false declare: False declarer gets 101, other players get 0', () async {
      final ctrl = OfflineTableController.instance;
      ctrl.initMatch();
      await SettingsService.instance.setAssisted(false);

      ctrl.currentTurnSeat = 0;
      ctrl.hasDrawnThisTurn = true;
      ctrl.wildRank = 8;

      // Per olmayan rastgele 11 kart
      ctrl.players[0].hand = [
        const CardModel(id: 'c1', suit: 'S', rank: 2, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'c2', suit: 'H', rank: 4, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'c3', suit: 'D', rank: 6, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'c4', suit: 'C', rank: 9, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'c5', suit: 'S', rank: 11, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'c6', suit: 'H', rank: 13, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'c7', suit: 'D', rank: 3, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'c8', suit: 'C', rank: 5, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'c9', suit: 'S', rank: 7, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'c10', suit: 'H', rank: 10, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'c11', suit: 'D', rank: 12, deckIndex: 1, isPhysicalJoker: false),
      ];
      ctrl.humanRows = [
        ctrl.players[0].hand.sublist(0, 4),
        ctrl.players[0].hand.sublist(4, 7),
        ctrl.players[0].hand.sublist(7, 11),
      ];

      // Hatalı el açmayı dene
      ctrl.humanDeclareFinish();

      expect(ctrl.status, 'round_summary');
      expect(ctrl.lastFalseDeclarerSeat, 0);
      final p0Result = ctrl.lastShowdown!.firstWhere((r) => r.seatIndex == 0);
      expect(p0Result.isFalseDeclarer, isTrue);
      expect(p0Result.roundPenalty, 101);

      // Diğer masum oyuncuların cezası 0 olmalı
      for (int i = 1; i <= 3; i++) {
        final piResult = ctrl.lastShowdown!.firstWhere((r) => r.seatIndex == i);
        expect(piResult.roundPenalty, 0, reason: 'Masum oyuncu $i ceza almamalıdır');
      }
    });
  });

  group('Scenario 4: Jokers, indicator card, and Ace edge cases', () {
    test('When indicator is Ace (wildRank == 1), all Aces are wild and worth 25 penalty if unmelded', () {
      const aceSpades = CardModel(id: '1_S_1', suit: 'S', rank: 1, deckIndex: 1, isPhysicalJoker: false);
      const aceHearts = CardModel(id: '1_H_1', suit: 'H', rank: 1, deckIndex: 1, isPhysicalJoker: false);
      const aceClubs = CardModel(id: '1_C_1', suit: 'C', rank: 1, deckIndex: 1, isPhysicalJoker: false);

      // wildRank = 1
      expect(GameEngine.isWildCard(aceSpades, 1), isTrue);
      expect(GameEngine.getRawCardPenalty(aceSpades, 1), 25);

      // 3 Wild Ace meld oluşturur mu?
      expect(GameEngine.isValidMeld([aceSpades, aceHearts, aceClubs], 1), isTrue);

      // Gösterge As değilken (ör. 5) As 10 puan olmalı
      expect(GameEngine.isWildCard(aceSpades, 5), isFalse);
      expect(GameEngine.getRawCardPenalty(aceSpades, 5), 10);
    });

    test('Runs with Jokers in various gap positions validate correctly', () {
      const wild7 = CardModel(id: '1_D_7', suit: 'D', rank: 7, deckIndex: 1, isPhysicalJoker: false); // wild
      const physicalJoker = CardModel(id: '1_J_0', suit: 'J', rank: 0, deckIndex: 1, isPhysicalJoker: true);

      // 4♠ - Joker - 6♠
      final runWithMiddleJoker = [
        const CardModel(id: '1_S_4', suit: 'S', rank: 4, deckIndex: 1, isPhysicalJoker: false),
        physicalJoker,
        const CardModel(id: '1_S_6', suit: 'S', rank: 6, deckIndex: 1, isPhysicalJoker: false),
      ];
      expect(GameEngine.isValidMeld(runWithMiddleJoker, 7), isTrue);

      // 2♠ - Joker - 4♠ - Joker - 6♠ (2 jokerli seri)
      final runWithTwoJokers = [
        const CardModel(id: '1_S_2', suit: 'S', rank: 2, deckIndex: 1, isPhysicalJoker: false),
        physicalJoker,
        const CardModel(id: '1_S_4', suit: 'S', rank: 4, deckIndex: 1, isPhysicalJoker: false),
        wild7,
        const CardModel(id: '1_S_6', suit: 'S', rank: 6, deckIndex: 1, isPhysicalJoker: false),
      ];
      expect(GameEngine.isValidMeld(runWithTwoJokers, 7), isTrue);
    });
  });

  group('Scenario 5: Elimination and Dealer badge rotation', () {
    test('Eliminated player is skipped in dealer rotation and turn succession', () {
      final ctrl = OfflineTableController.instance;
      ctrl.initMatch();

      expect(ctrl.dealerSeat, 0);
      expect(ctrl.currentTurnSeat, 1);

      // Ahmet (1) yandı ve elendi
      ctrl.players[1].totalScore = 105;
      ctrl.players[1].isEliminated = true;

      // Tur bitti, yeni tura geçildi
      ctrl.continueAfterRound();

      // Dağıtıcı (dealer) normalde 1 olacaktı ama 1 elendiği için 2 (Zeynep) olmalı
      expect(ctrl.dealerSeat, 2, reason: 'Elenen oyuncu dağıtıcı olamaz, rozet Zeynep\'e (2) geçmeli');
      // İlk sıra dağıtandan sonraki aktif oyuncu olan Mehmet\'e (3) geçmeli
      expect(ctrl.currentTurnSeat, 3, reason: 'İlk hamle Mehmet\'e (3) geçmeli');
    });

    test('Check if an already-eliminated player receives phantom penalty in subsequent rounds', () {
      final ctrl = OfflineTableController.instance;
      ctrl.initMatch();

      // Tur 1: Ahmet (1) 105 puanla yandı
      ctrl.players[1].totalScore = 105;
      ctrl.players[1].isEliminated = true;

      // Tur 2 başlat
      ctrl.continueAfterRound();
      expect(ctrl.roundNumber, 2);

      // Tur 2\'de İnsan (0) bitirdi
      ctrl.endRound(0);

      // KONTROL: Ahmet Tur 2\'de oynamadı. Toplam puanı hala 105 mi yoksa eline kart verilip ceza mı eklendi?
      final p1Showdown = ctrl.lastShowdown!.firstWhere((p) => p.seatIndex == 1);
      expect(p1Showdown.roundPenalty, 0, reason: 'Elenmiş oyuncu sonraki turlarda ceza almamalıdır');
      expect(ctrl.players[1].totalScore, 105, reason: 'Elenmiş oyuncunun toplam skoru artmamalıdır');
    });
  });

  group('Scenario 6: Champion selection when all players exceed 101', () {
    test('Lowest score wins when all 4 players burn simultaneously', () {
      final ctrl = OfflineTableController.instance;
      ctrl.initMatch();

      ctrl.players[0].totalScore = 112; // İnsan
      ctrl.players[1].totalScore = 104; // Ahmet (EN DÜŞÜK!)
      ctrl.players[2].totalScore = 125; // Zeynep
      ctrl.players[3].totalScore = 118; // Mehmet

      for (int i = 0; i < 4; i++) {
        ctrl.players[i].hand = [];
      }

      ctrl.endRound(null);

      expect(ctrl.status, 'round_summary');
      expect(ctrl.winnerMessage, isNotNull);
      expect(ctrl.winnerMessage, contains('Ahmet'), reason: 'En düşük ceza puanına sahip Ahmet şampiyon olmalı');
    });
  });

  group('Scenario 7: State reset upon starting new round', () {
    test('startRound cleanly resets cards, discard pile, melds, and transient state', () {
      final ctrl = OfflineTableController.instance;
      ctrl.initMatch();

      // Birkaç kart ve durum kirlet
      ctrl.discardPile.add(const CardModel(id: 'junk', suit: 'S', rank: 2, deckIndex: 1, isPhysicalJoker: false));
      ctrl.selectedCardId = 'some_card';
      ctrl.players[0].openedMelds = [
        [const CardModel(id: 'm1', suit: 'H', rank: 3, deckIndex: 1, isPhysicalJoker: false)]
      ];

      ctrl.startRound();

      expect(ctrl.discardPile.isEmpty, isTrue, reason: 'Atılan kartlar sıfırlanmalı');
      expect(ctrl.selectedCardId, isNull, reason: 'Seçili kart sıfırlanmalı');
      expect(ctrl.lastShowdown, isNull, reason: 'Showdown sıfırlanmalı');
      expect(ctrl.lastFinisherSeat, isNull);
      expect(ctrl.lastFalseDeclarerSeat, isNull);
      expect(ctrl.drawPile.length, 66, reason: 'Deste 66 kağıt olmalı');
      for (final p in ctrl.players) {
        expect(p.hand.length, 10, reason: 'Her oyuncuya 10 kağıt verilmeli');
        expect(p.openedMelds.isEmpty, isTrue, reason: 'Açılan perler sıfırlanmalı');
      }
    });
  });

  group('Scenario 8: Penalty calculation when a player wins', () {
    test('Accurate penalty calculation with Ace = 10, K/Q/J = 10, Joker = 25, numbers = face value', () {
      final ctrl = OfflineTableController.instance;
      ctrl.initMatch();
      ctrl.wildRank = 6; // Gösterge 6

      // İnsan (0) bitirdi
      // Ahmet (1): As(10) + Papaz(10) + 7(7) = 27 ceza
      ctrl.players[1].hand = [
        const CardModel(id: 'c1', suit: 'S', rank: 1, deckIndex: 1, isPhysicalJoker: false), // 10
        const CardModel(id: 'c2', suit: 'H', rank: 13, deckIndex: 1, isPhysicalJoker: false), // 10
        const CardModel(id: 'c3', suit: 'D', rank: 7, deckIndex: 1, isPhysicalJoker: false), // 7
      ];
      // Zeynep (2): Fiziksel Joker(25) + Wild 6(25) = 50 ceza (2 kart olduğu için per olamaz)
      ctrl.players[2].hand = [
        const CardModel(id: 'j1', suit: 'J', rank: 0, deckIndex: 1, isPhysicalJoker: true), // 25
        const CardModel(id: 'w1', suit: 'S', rank: 6, deckIndex: 1, isPhysicalJoker: false), // wild = 25
      ];
      // Mehmet (3): 3'lü per (3-4-5 Kupa = 0 ceza) + 8(8) = 8 ceza
      ctrl.players[3].hand = [
        const CardModel(id: 'm1', suit: 'H', rank: 3, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'm2', suit: 'H', rank: 4, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'm3', suit: 'H', rank: 5, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: 'c5', suit: 'S', rank: 8, deckIndex: 1, isPhysicalJoker: false), // 8
      ];

      ctrl.endRound(0);

      final s = ctrl.lastShowdown!;
      expect(s.firstWhere((p) => p.seatIndex == 0).roundPenalty, 0);
      expect(s.firstWhere((p) => p.seatIndex == 1).roundPenalty, 27);
      expect(s.firstWhere((p) => p.seatIndex == 2).roundPenalty, 50);
      expect(s.firstWhere((p) => p.seatIndex == 3).roundPenalty, 8);
    });

    test('1 natural card + 2 jokers forms valid set meld and yields 0 penalty (Kullanici Kurali 3)', () {
      final ctrl = OfflineTableController.instance;
      ctrl.initMatch();
      ctrl.wildRank = 6;

      ctrl.players[1].hand = [
        const CardModel(id: 'j1', suit: 'J', rank: 0, deckIndex: 1, isPhysicalJoker: true),
        const CardModel(id: 'w1', suit: 'S', rank: 6, deckIndex: 1, isPhysicalJoker: false), // wild 6
        const CardModel(id: 'c4', suit: 'C', rank: 3, deckIndex: 1, isPhysicalJoker: false), // 3 of Clubs
      ];

      ctrl.endRound(0); // İnsan bitirdi

      final s = ctrl.lastShowdown!;
      // 1 doğal (3) + 2 joker per oluşturduğu için Ahmet 0 ceza almalı!
      expect(s.firstWhere((p) => p.seatIndex == 1).roundPenalty, 0);
    });
  });

  group('Scenario 9: Bot decision-making and rule compliance', () {
    test('Bot always selects non-wild, unmelded, highest deadwood discard', () {
      final hand11 = [
        // 3-4-5 Kupa (Per)
        const CardModel(id: '1_H_3', suit: 'H', rank: 3, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '1_H_4', suit: 'H', rank: 4, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '1_H_5', suit: 'H', rank: 5, deckIndex: 1, isPhysicalJoker: false),
        // Boştaki kartlar
        const CardModel(id: '1_S_2', suit: 'S', rank: 2, deckIndex: 1, isPhysicalJoker: false), // 2 pts
        const CardModel(id: '1_S_4', suit: 'S', rank: 4, deckIndex: 1, isPhysicalJoker: false), // 4 pts
        const CardModel(id: '1_S_10', suit: 'S', rank: 10, deckIndex: 1, isPhysicalJoker: false), // 10 pts
        const CardModel(id: '1_D_13', suit: 'D', rank: 13, deckIndex: 1, isPhysicalJoker: false), // 10 pts
        const CardModel(id: '1_C_1', suit: 'C', rank: 1, deckIndex: 1, isPhysicalJoker: false), // As = 10 pts
        // Jokerler (Asla atılmamalı)
        const CardModel(id: '1_J_0', suit: 'J', rank: 0, deckIndex: 1, isPhysicalJoker: true),
        const CardModel(id: '1_H_8', suit: 'H', rank: 8, deckIndex: 1, isPhysicalJoker: false), // wild (8)
        const CardModel(id: '1_S_3', suit: 'S', rank: 3, deckIndex: 1, isPhysicalJoker: false), // 3 pts
      ];

      final discard = GameEngine.selectBestAutoDiscard(hand11, 8);

      expect(discard.isPhysicalJoker, isFalse, reason: 'Bot fiziksel jokeri atamaz');
      expect(discard.rank != 8, isTrue, reason: 'Bot wild jokeri atamaz');
      expect(GameEngine.getRawCardPenalty(discard, 8), 10, reason: 'En yüksek ceza puanlı kartı (10) atmalı');
    });

    test('Bot with winning hand detects finish immediately', () {
      final winningHand11 = [
        // 3-4-5 Kupa (3)
        const CardModel(id: '1_H_3', suit: 'H', rank: 3, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '1_H_4', suit: 'H', rank: 4, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '1_H_5', suit: 'H', rank: 5, deckIndex: 1, isPhysicalJoker: false),
        // 7-8-9 Maça (3)
        const CardModel(id: '1_S_7', suit: 'S', rank: 7, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '1_S_8', suit: 'S', rank: 8, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '1_S_9', suit: 'S', rank: 9, deckIndex: 1, isPhysicalJoker: false),
        // K-K-K-K (4)
        const CardModel(id: '1_S_13', suit: 'S', rank: 13, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '1_H_13', suit: 'H', rank: 13, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '1_D_13', suit: 'D', rank: 13, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '1_C_13', suit: 'C', rank: 13, deckIndex: 1, isPhysicalJoker: false),
        // Fazlalık atılacak kart (2 Karo)
        const CardModel(id: '1_D_2', suit: 'D', rank: 2, deckIndex: 1, isPhysicalJoker: false),
      ];

      final winCheck = GameEngine.findWinningDiscard(winningHand11, 6);
      expect(winCheck.canWin, isTrue);
      expect(winCheck.discardCard?.id, '1_D_2');
    });
  });

  group('Scenario 10: 20 consecutive rounds error-free execution', () {
    test('Simulate 20 consecutive rounds with turn plays and verify zero crashes', () {
      final ctrl = OfflineTableController.instance;
      ctrl.initMatch();

      for (int round = 1; round <= 20; round++) {
        // Her turda desteden kartlar çekilsin, atılsın
        expect(ctrl.status, 'playing');
        expect(ctrl.players.length, 4);

        // Birkaç el kart çekip atma simülasyonu
        for (int turn = 0; turn < 4; turn++) {
          final seat = ctrl.currentTurnSeat;
          final player = ctrl.players[seat];
          if (!player.isEliminated && ctrl.drawPile.isNotEmpty) {
            player.hand.add(ctrl.drawPile.removeAt(0));
            final toDiscard = GameEngine.selectBestAutoDiscard(player.hand, ctrl.wildRank);
            player.hand.removeWhere((c) => c.id == toDiscard.id);
            ctrl.discardPile.add(toDiscard);
          }
          ctrl.currentTurnSeat = ctrl.getNextActiveSeatIndex(ctrl.currentTurnSeat);
        }

        // Turu rastgele bir bitiren veya deste sonu ile bitir
        final finisher = round % 4;
        ctrl.endRound(finisher);
        expect(ctrl.status, 'round_summary');
        expect(ctrl.roundHistory.isNotEmpty, isTrue);

        // Sonraki tura geç
        if (ctrl.winnerMessage != null) {
          // Oyun bittiyse yeni maç başlatarak 20 tur serisini sürdür
          ctrl.initMatch();
        } else {
          ctrl.continueAfterRound();
        }
      }
    });
  });
}
