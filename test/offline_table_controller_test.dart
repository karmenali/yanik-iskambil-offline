import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yanik_offline/engine/card_model.dart';
import 'package:yanik_offline/engine/offline_table_controller.dart';
import 'package:yanik_offline/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'yanik_offline_sound': false,
      'yanik_offline_vibration': false,
    });
    await SettingsService.instance.init();
  });

  group('OfflineTableController Flow & Rule Tests', () {
    test('initMatch sets up 4 players in counter-clockwise order', () {
      final ctrl = OfflineTableController.instance;
      ctrl.initMatch();

      expect(ctrl.players.length, 4);
      // 0: İnsan (Sol-Alt)
      expect(ctrl.players[0].isBot, isFalse);
      expect(ctrl.players[0].seatIndex, 0);
      // 1: Ahmet (Sağ-Alt)
      expect(ctrl.players[1].isBot, isTrue);
      expect(ctrl.players[1].username, 'Ahmet');
      expect(ctrl.players[1].seatIndex, 1);
      // 2: Zeynep (Sağ-Üst)
      expect(ctrl.players[2].isBot, isTrue);
      expect(ctrl.players[2].username, 'Zeynep');
      expect(ctrl.players[2].seatIndex, 2);
      // 3: Mehmet (Sol-Üst)
      expect(ctrl.players[3].isBot, isTrue);
      expect(ctrl.players[3].username, 'Mehmet');
      expect(ctrl.players[3].seatIndex, 3);

      expect(ctrl.roundNumber, 1);
      expect(ctrl.dealerSeat, 0);
      // İlk sıra dağıtandan sonraki oyuncuda (1: Ahmet)
      expect(ctrl.currentTurnSeat, 1);
      expect(ctrl.drawPile.length, 66);
    });

    test('getNextActiveSeatIndex skips eliminated players correctly', () {
      final ctrl = OfflineTableController.instance;
      ctrl.initMatch();

      // Kimse elenmemişken
      expect(ctrl.getNextActiveSeatIndex(0), 1);
      expect(ctrl.getNextActiveSeatIndex(1), 2);
      expect(ctrl.getNextActiveSeatIndex(2), 3);
      expect(ctrl.getNextActiveSeatIndex(3), 0);

      // Ahmet (1) elendiğinde
      ctrl.players[1].isEliminated = true;
      expect(ctrl.getNextActiveSeatIndex(0), 2); // 0 -> 2
      expect(ctrl.getNextActiveSeatIndex(3), 0);

      // Ahmet (1) ve Zeynep (2) elendiğinde
      ctrl.players[2].isEliminated = true;
      expect(ctrl.getNextActiveSeatIndex(0), 3); // 0 -> 3
      expect(ctrl.getNextActiveSeatIndex(3), 0);
    });

    test('Drawing card ONLY pulls from closed drawPile', () {
      final ctrl = OfflineTableController.instance;
      ctrl.initMatch();

      ctrl.currentTurnSeat = 0; // Sırayı insana ver
      ctrl.hasDrawnThisTurn = false;

      final initialDrawPileCount = ctrl.drawPileCount;
      final initialHandCount = ctrl.players[0].hand.length;

      // Kapalı desteden kart çek
      ctrl.humanDrawCard();

      expect(ctrl.drawPileCount, initialDrawPileCount - 1);
      expect(ctrl.players[0].hand.length, initialHandCount + 1);
      expect(ctrl.hasDrawnThisTurn, isTrue);

      // Aynı turda 2. kez çekme engellenmeli
      ctrl.humanDrawCard();
      expect(ctrl.players[0].hand.length, initialHandCount + 1);
    });

    test('False declare in Yardimsiz mode: False declarer gets 101, OTHER players get 0', () {
      final ctrl = OfflineTableController.instance;
      ctrl.initMatch();

      // Oyunculara ceza puanı olacak kartlar ver
      ctrl.players[0].hand = [
        const CardModel(id: '1_S_2', suit: 'S', rank: 2, deckIndex: 1, isPhysicalJoker: false),
      ];
      ctrl.players[1].hand = [
        const CardModel(id: '1_H_10', suit: 'H', rank: 10, deckIndex: 1, isPhysicalJoker: false),
      ];
      ctrl.players[2].hand = [
        const CardModel(id: '1_D_10', suit: 'D', rank: 10, deckIndex: 1, isPhysicalJoker: false),
      ];
      ctrl.players[3].hand = [
        const CardModel(id: '1_C_10', suit: 'C', rank: 10, deckIndex: 1, isPhysicalJoker: false),
      ];

      // İnsan (0) hatalı el açtı
      ctrl.endRound(null, falseDeclarerSeat: 0);

      expect(ctrl.lastShowdown, isNotNull);
      final showdown = ctrl.lastShowdown!;

      // 0: Hatalı açan 101 almalı ve yanmalı
      final p0 = showdown.firstWhere((p) => p.seatIndex == 0);
      expect(p0.isFalseDeclarer, isTrue);
      expect(p0.roundPenalty, 101);
      expect(p0.burnedThisRound, isTrue);

      // 1, 2, 3: Masum oyuncuların tur cezası 0 OLMALI!
      final p1 = showdown.firstWhere((p) => p.seatIndex == 1);
      final p2 = showdown.firstWhere((p) => p.seatIndex == 2);
      final p3 = showdown.firstWhere((p) => p.seatIndex == 3);
      expect(p1.roundPenalty, 0);
      expect(p2.roundPenalty, 0);
      expect(p3.roundPenalty, 0);
    });

    test('Legit finish: Finisher gets 0, losers get deadwood points', () {
      final ctrl = OfflineTableController.instance;
      ctrl.initMatch();

      // Deterministik test: Göstergeyi Papaz (13) yaparak As ve 5'in wild olmasını engelle
      ctrl.wildRank = 13;

      // Bot 1 (Ahmet) bitirsin
      ctrl.players[0].hand = [
        // As = 10, 5 = 5 -> toplam 15 ceza
        const CardModel(id: '1_S_1', suit: 'S', rank: 1, deckIndex: 1, isPhysicalJoker: false),
        const CardModel(id: '1_S_5', suit: 'S', rank: 5, deckIndex: 1, isPhysicalJoker: false),
      ];
      ctrl.players[1].openedMelds = [
        [
          const CardModel(id: '1_H_3', suit: 'H', rank: 3, deckIndex: 1, isPhysicalJoker: false),
          const CardModel(id: '1_H_4', suit: 'H', rank: 4, deckIndex: 1, isPhysicalJoker: false),
          const CardModel(id: '1_H_5', suit: 'H', rank: 5, deckIndex: 1, isPhysicalJoker: false),
        ]
      ];
      ctrl.players[1].hand = [];

      ctrl.endRound(1); // 1 nolu Ahmet bitirdi

      final showdown = ctrl.lastShowdown!;
      final p1 = showdown.firstWhere((p) => p.seatIndex == 1);
      expect(p1.isFinisher, isTrue);
      expect(p1.roundPenalty, 0);

      final p0 = showdown.firstWhere((p) => p.seatIndex == 0);
      expect(p0.isFinisher, isFalse);
      expect(p0.roundPenalty, 15); // As(10) + 5 = 15
    });

    test('When all players exceed 101, player with lowest total score is champion', () {
      final ctrl = OfflineTableController.instance;
      ctrl.initMatch();

      ctrl.players[0].totalScore = 105;
      ctrl.players[1].totalScore = 120;
      ctrl.players[2].totalScore = 110;
      ctrl.players[3].totalScore = 130;

      // Turu kimse bitirmeden bitir (herkes yansın)
      ctrl.players[0].hand = [];
      ctrl.players[1].hand = [];
      ctrl.players[2].hand = [];
      ctrl.players[3].hand = [];
      ctrl.endRound(null);

      // En düşük skora sahip olan (105 puanla İnsan) şampiyon olmalı
      expect(ctrl.winnerMessage, contains('Şampiyon'));
      expect(ctrl.winnerMessage, contains('Tebrikler'));
    });

    test('Lifecycle pauseGame and resumeGame correctly stop and restart bot loop without duplicate draw', () {
      final ctrl = OfflineTableController.instance;
      ctrl.initMatch();

      // Bot 1'in sırası olsun
      ctrl.currentTurnSeat = 1;
      ctrl.hasDrawnThisTurn = false;
      final initialBotHandCount = ctrl.players[1].hand.length;

      // Oyunu duraklat
      ctrl.pauseGame();
      expect(ctrl.isPaused, isTrue);

      // Duraklatılmışken botun kart sayısı artmamalı
      expect(ctrl.players[1].hand.length, initialBotHandCount);

      // Botun eline 1 kart çekilmiş gibi işaretleyelim (hasDrawnThisTurn = true)
      ctrl.players[1].hand.add(ctrl.drawPile.removeAt(0));
      ctrl.hasDrawnThisTurn = true;
      final handCountAfterDraw = ctrl.players[1].hand.length;

      // Oyunu devam ettir
      ctrl.resumeGame();
      expect(ctrl.isPaused, isFalse);

      // resumeGame botun tekrar kart çekmesini engellemeli (hasDrawnThisTurn zaten true olduğu için)
      expect(ctrl.players[1].hand.length, handCountAfterDraw);
      ctrl.pauseGame(); // Temizle
    });

    test('Game over and replay flow: initMatch cleanly wipes previous match scores, cards, and state', () {
      final ctrl = OfflineTableController.instance;
      ctrl.initMatch();

      // Birinci maçı simüle et
      ctrl.players[0].totalScore = 105;
      ctrl.players[0].isEliminated = true;
      ctrl.roundNumber = 5;
      ctrl.endRound(1);
      expect(ctrl.winnerMessage, isNotNull);

      // Kullanıcı "TEKRAR OYNA" dediğinde
      ctrl.initMatch();

      // Durumların sıfırlandığını doğrula
      expect(ctrl.roundNumber, 1);
      expect(ctrl.status, 'playing');
      expect(ctrl.winnerMessage, isNull);
      expect(ctrl.lastShowdown, isNull);
      expect(ctrl.roundHistory, isEmpty);
      expect(ctrl.isPaused, isFalse);
      for (final p in ctrl.players) {
        expect(p.totalScore, 0, reason: '${p.username} skoru 0 olmalı');
        expect(p.isEliminated, isFalse, reason: '${p.username} elenmemiş olmalı');
        expect(p.hand.length, 10, reason: '${p.username} 10 karta sahip olmalı');
      }
      ctrl.pauseGame(); // Timer'ları durdur
    });

    test('stopGame stops all bot timers and sets status to waiting', () {
      final ctrl = OfflineTableController.instance;
      ctrl.initMatch();

      ctrl.stopGame();
      expect(ctrl.status, 'waiting');
      expect(ctrl.isPaused, isTrue);
    });
  });
}
