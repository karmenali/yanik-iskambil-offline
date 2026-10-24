import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yanik_offline/engine/card_model.dart';
import 'package:yanik_offline/engine/hand_sorter.dart';
import 'package:yanik_offline/engine/offline_table_controller.dart';
import 'package:yanik_offline/screens/home_screen.dart';
import 'package:yanik_offline/services/settings_service.dart';
import 'package:yanik_offline/services/sound_fx.dart';

CardModel _c(String id, String suit, int rank, {int deckIndex = 0, bool isPhysicalJoker = false}) {
  return CardModel(
    id: id,
    suit: suit,
    rank: rank,
    deckIndex: deckIndex,
    isPhysicalJoker: isPhysicalJoker,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HandSorter - Zorunlu El Sıralama Kuralları Testleri', () {
    test('Normal kartlar 2..10, J, Q, K, A artan sırada dizilir (As en sondadır)', () {
      final hand = [
        _c('A_spade', 'S', 1),
        _c('K_spade', 'S', 13),
        _c('2_spade', 'S', 2),
        _c('10_spade', 'S', 10),
        _c('J_spade', 'S', 11),
        _c('5_spade', 'S', 5),
        _c('Q_spade', 'S', 12),
      ];

      final sorted = HandSorter.sortHand(hand);

      expect(sorted.map((c) => c.rank).toList(), equals([2, 5, 10, 11, 12, 13, 1]));
      expect(sorted.first.rank, equals(2));
      expect(sorted.last.rank, equals(1)); // As en sonda
    });

    test('Aynı rank değerindeki kartlar Maça -> Kupa -> Karo -> Sinek sırasında dizilir', () {
      final hand = [
        _c('C7', 'C', 7),
        _c('S7', 'S', 7),
        _c('D7', 'D', 7),
        _c('H7', 'H', 7),
      ];

      final sorted = HandSorter.sortHand(hand);

      expect(sorted.map((c) => c.suit).toList(), equals(['S', 'H', 'D', 'C']));
    });

    test('Aynı rank değerinde As kartları da Maça -> Kupa -> Karo -> Sinek sırasındadır', () {
      final hand = [
        _c('C1', 'C', 1),
        _c('S1', 'S', 1),
        _c('D1', 'D', 1),
        _c('H1', 'H', 1),
      ];

      final sorted = HandSorter.sortHand(hand);

      expect(sorted.map((c) => c.suit).toList(), equals(['S', 'H', 'D', 'C']));
    });

    test('Fiziksel jokerler bütün normal kartlardan (As dahil) sonra yer alır', () {
      final hand = [
        _c('joker_1', 'J', 0, isPhysicalJoker: true),
        _c('A_spade', 'S', 1),
        _c('K_spade', 'S', 13),
        _c('2_heart', 'H', 2),
      ];

      final sorted = HandSorter.sortHand(hand);

      expect(sorted[0].rank, equals(2));
      expect(sorted[1].rank, equals(13));
      expect(sorted[2].rank, equals(1)); // As
      expect(sorted[3].isPhysicalJoker, isTrue); // Joker en sonda
    });

    test('Birden fazla fiziksel joker kararlı ve deterministik sırada dizilir', () {
      final hand = [
        _c('joker_b', 'J', 0, deckIndex: 1, isPhysicalJoker: true),
        _c('joker_a', 'J', 0, deckIndex: 0, isPhysicalJoker: true),
      ];

      final sorted = HandSorter.sortHand(hand);

      expect(sorted[0].deckIndex, equals(0));
      expect(sorted[1].deckIndex, equals(1));
    });

    test('Aynı el tekrar sıralandığında sonuç değişmez (idempotent)', () {
      final hand = [
        _c('H5', 'H', 5),
        _c('S1', 'S', 1),
        _c('J1', 'J', 0, isPhysicalJoker: true),
        _c('C2', 'C', 2),
        _c('S5', 'S', 5),
        _c('D13', 'D', 13),
      ];

      final sort1 = HandSorter.sortHand(hand);
      final sort2 = HandSorter.sortHand(sort1);
      final sort3 = HandSorter.sortHand(sort2);

      expect(sort1.map((c) => c.id).toList(), equals(sort2.map((c) => c.id).toList()));
      expect(sort2.map((c) => c.id).toList(), equals(sort3.map((c) => c.id).toList()));
      expect(sort1.length, equals(hand.length));
    });

    test('humanSortRanks() controller veri modelini ve ıstaka sıralarını günceller', () {
      final ctrl = OfflineTableController.instance;
      ctrl.initMatch();

      expect(ctrl.players[0].hand, isNotEmpty);
      final originalCount = ctrl.players[0].hand.length;

      ctrl.humanSortRanks();

      expect(ctrl.players[0].hand.length, equals(originalCount));
      // HandSorter ile sıralanmış liste ile controller elinin birebir aynı sırada olduğunu doğrula
      final expected = HandSorter.sortHand(ctrl.players[0].hand);
      for (int i = 0; i < expected.length; i++) {
        expect(ctrl.players[0].hand[i].id, equals(expected[i].id));
      }

      // Istaka sıralarının (humanRows) toplam kart sayısı el kart sayısına eşit olmalıdır
      final totalInRows = ctrl.humanRows.fold<int>(0, (sum, r) => sum + r.length);
      expect(totalInRows, equals(originalCount));
    });
  });

  group('Home Screen (Ana Ekran) Gereksinimleri Testleri', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await SettingsService.instance.init();
      OfflineTableController.instance.stopGame();
    });

    tearDown(() {
      OfflineTableController.instance.stopGame();
    });

    testWidgets('Ana ekranda istenmeyen slogan, wifi ikonu ve dolgu metinleri bulunmaz', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: HomeScreen()),
      );
      await tester.pumpAndSettle();

      // İstenmeyen metinler bulunmamalıdır:
      expect(find.text('KLASİK İSKAMBİL DENEYİMİ'), findsNothing);
      expect(find.textContaining('1 Oyuncu + 3 Bot'), findsNothing);
      expect(find.textContaining('%100 Çevrimdışı'), findsNothing);
      expect(find.byIcon(Icons.wifi_off_rounded), findsNothing);

      // Başlık ve OYNA butonu bulunmalıdır:
      expect(find.text('YANIK İSKAMBİL'), findsOneWidget);
      expect(find.text('OYNA'), findsOneWidget);
    });

    testWidgets('Aktif oyun yokken OYNA butonu doğrudan oyunu başlatır', (tester) async {
      final ctrl = OfflineTableController.instance;
      ctrl.stopGame();
      expect(ctrl.hasActiveMatch, isFalse);

      await tester.pumpWidget(
        const MaterialApp(home: HomeScreen()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('OYNA'));
      await tester.pumpAndSettle();

      // Onay diyaloğu çıkmadan oyun masasına geçmiş olmalıdır
      expect(find.text('Yeni Oyun Başlatılsın mı?'), findsNothing);
      expect(ctrl.status, equals('playing'));
    });

    testWidgets('Aktif oyun varken OYNA butonu onay penceresi açar ve İptal seçilince oyunu korur', (tester) async {
      final ctrl = OfflineTableController.instance;
      ctrl.initMatch();
      expect(ctrl.hasActiveMatch, isTrue);

      final initialCards = List<CardModel>.from(ctrl.players[0].hand);
      final initialRound = ctrl.roundNumber;

      await tester.pumpWidget(
        const MaterialApp(home: HomeScreen()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('OYNA'));
      await tester.pumpAndSettle();

      // Onay diyaloğu görünür olmalıdır
      expect(find.text('Yeni Oyun Başlatılsın mı?'), findsOneWidget);
      expect(find.text('İptal'), findsOneWidget);
      expect(find.text('Yeni Oyuna Başla'), findsOneWidget);

      // İptal butonuna tıkla
      await tester.tap(find.text('İptal'));
      await tester.pumpAndSettle();

      // Oyun durumu ve kartlar aynen korunmuş olmalıdır
      expect(ctrl.hasActiveMatch, isTrue);
      expect(ctrl.roundNumber, equals(initialRound));
      expect(ctrl.players[0].hand.length, equals(initialCards.length));
    });

    testWidgets('Aktif oyun onay penceresinde "Yeni Oyuna Başla" seçilirse tek bir yeni oyun başlar', (tester) async {
      final ctrl = OfflineTableController.instance;
      ctrl.initMatch();
      expect(ctrl.hasActiveMatch, isTrue);

      await tester.pumpWidget(
        const MaterialApp(home: HomeScreen()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('OYNA'));
      await tester.pumpAndSettle();

      expect(find.text('Yeni Oyun Başlatılsın mı?'), findsOneWidget);

      // Onayla
      await tester.tap(find.text('Yeni Oyuna Başla'));
      await tester.pumpAndSettle();

      expect(ctrl.status, equals('playing'));
      expect(ctrl.roundNumber, equals(1));
    });

    testWidgets('Kullanıcının kayıtlı oyun modu tercihi korunur', (tester) async {
      // Yardımsız modu kaydet
      await SettingsService.instance.setAssisted(false);

      await tester.pumpWidget(
        const MaterialApp(home: HomeScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Yardımsız Mod'), findsOneWidget);
      expect(SettingsService.instance.isAssisted, isFalse);

      // Yardımlı moda geri al
      await SettingsService.instance.setAssisted(true);
      await tester.pumpAndSettle();

      expect(find.text('Yardımlı Mod'), findsOneWidget);
      expect(SettingsService.instance.isAssisted, isTrue);
    });
  });

  group('Ses ve Titreşim Altyapısı Testleri', () {
    test('Kayıtlı tercih yokken titreşim varsayılan olarak KAPALIDIR', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsService.instance;
      await settings.init();

      expect(settings.vibrationEnabled, isFalse);
    });

    test('Ses ve titreşim ayarları birbirinden bağımsız çalışır', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsService.instance;
      await settings.init();

      // Başlangıç: Ses açık, Titreşim kapalı
      expect(settings.soundEnabled, isTrue);
      expect(settings.vibrationEnabled, isFalse);

      // Titreşimi aç
      await settings.setVibrationEnabled(true);
      expect(settings.vibrationEnabled, isTrue);
      expect(settings.soundEnabled, isTrue); // Ses etkilenmemeli

      // Sesi kapat
      await settings.setSoundEnabled(false);
      expect(settings.soundEnabled, isFalse);
      expect(settings.vibrationEnabled, isTrue); // Titreşim etkilenmemeli
    });

    test('Ses ve titreşim tercihleri kalıcı olarak saklanır', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsService.instance;
      await settings.init();

      await settings.setSoundEnabled(false);
      await settings.setVibrationEnabled(true);

      // Yeni init ile yeniden yükle
      await settings.init();

      expect(settings.soundEnabled, isFalse);
      expect(settings.vibrationEnabled, isTrue);
    });

    test('SoundFx ses ve titreşim metotları hata vermeden çalışır', () {
      expect(() => SoundFx.playCardDraw(), returnsNormally);
      expect(() => SoundFx.playCardDiscard(), returnsNormally);
      expect(() => SoundFx.playCardSlide(), returnsNormally);
      expect(() => SoundFx.playCardTap(), returnsNormally);
      expect(() => SoundFx.playCelebration(), returnsNormally);
      expect(() => SoundFx.triggerHaptic(), returnsNormally);
    });
  });

  group('Oyun Akışı ve Çift Tıklama Dayanıklılığı Testleri', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await SettingsService.instance.init();
      OfflineTableController.instance.initMatch();
    });

    tearDown(() {
      OfflineTableController.instance.stopGame();
    });

    test('Hızlı tekrarlı kart çekme çağrıları çift kart çekilmesine neden olmaz', () {
      final ctrl = OfflineTableController.instance;
      // İnsan oyuncunun sırası olsun
      ctrl.currentTurnSeat = 0;
      ctrl.hasDrawnThisTurn = false;

      final initialHandCount = ctrl.players[0].hand.length;
      final initialDrawPileCount = ctrl.drawPileCount;

      // 1. Çekme
      ctrl.humanDrawCard(fromDiscard: false);
      expect(ctrl.hasDrawnThisTurn, isTrue);
      expect(ctrl.players[0].hand.length, equals(initialHandCount + 1));
      expect(ctrl.drawPileCount, equals(initialDrawPileCount - 1));

      // Hızlı 2. ve 3. Çekme denemesi (Aynı tur içinde)
      ctrl.humanDrawCard(fromDiscard: false);
      ctrl.humanDrawCard(fromDiscard: false);

      // Kart sayısı değişmemelidir
      expect(ctrl.players[0].hand.length, equals(initialHandCount + 1));
      expect(ctrl.drawPileCount, equals(initialDrawPileCount - 1));
    });

    test('Hızlı tekrarlı kart atma çağrıları çift kart atılmasına neden olmaz', () {
      final ctrl = OfflineTableController.instance;
      ctrl.currentTurnSeat = 0;
      ctrl.hasDrawnThisTurn = true;

      final cardToDiscard = ctrl.players[0].hand.first.id;
      final initialHandCount = ctrl.players[0].hand.length;

      // 1. Atma
      ctrl.humanDiscardCard(cardToDiscard);
      expect(ctrl.hasDrawnThisTurn, isFalse);
      expect(ctrl.players[0].hand.length, equals(initialHandCount - 1));

      // Hızlı 2. Atma denemesi
      ctrl.humanDiscardCard(cardToDiscard);

      // Kart sayısı tekrar azalmamalıdır
      expect(ctrl.players[0].hand.length, equals(initialHandCount - 1));
    });
  });
}
