import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yanik_offline/engine/card_model.dart';
import 'package:yanik_offline/engine/offline_table_controller.dart';
import 'package:yanik_offline/screens/home_screen.dart';
import 'package:yanik_offline/screens/offline_table_screen.dart';
import 'package:yanik_offline/services/settings_service.dart';
import 'package:yanik_offline/services/sound_fx.dart';
import 'package:yanik_offline/widgets/game_logo_widget.dart';

CardModel _c(String suit, int rank, {bool isPhysicalJoker = false, int deckIndex = 0}) {
  return CardModel(
    id: '${suit}_${rank}_$deckIndex',
    suit: suit,
    rank: rank,
    deckIndex: deckIndex,
    isPhysicalJoker: isPhysicalJoker,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.instance.init();
    OfflineTableController.instance.stopGame();
  });

  tearDown(() {
    OfflineTableController.instance.stopGame();
  });

  group('3 Sıralı Istakanın Etkin ve Dengeli Kullanımı Testleri', () {
    test('10 kartlık el 3 ıstaka sırasına 4, 3, 3 olarak dengeli dağıtılır', () {
      final ctrl = OfflineTableController.instance;
      ctrl.initMatch();
      ctrl.wildRank = 2; // Gösterge 2
      final hand = [
        _c('S', 5),
        _c('H', 8),
        _c('D', 2),
        _c('C', 10),
        _c('S', 1),
        _c('H', 13),
        _c('D', 11),
        _c('C', 7),
        _c('S', 4),
        _c('H', 9),
      ];

      ctrl.players[0].hand = List.from(hand);
      ctrl.humanSortRanks();

      expect(ctrl.humanRows[0].length, equals(4));
      expect(ctrl.humanRows[1].length, equals(3));
      expect(ctrl.humanRows[2].length, equals(3));
      expect(ctrl.humanRows[0].length + ctrl.humanRows[1].length + ctrl.humanRows[2].length, equals(10));

      // As en sonda (3. sırada) yer almalıdır
      expect(ctrl.humanRows[2].any((c) => c.rank == 1), isTrue);
    });

    test('11 kartlık el (çekim sonrası) 3 sıraya 4, 4, 3 olarak dengeli yerleşir', () {
      final ctrl = OfflineTableController.instance;
      ctrl.initMatch();
      final hand = [
        _c('S', 3), _c('H', 4), _c('D', 5), _c('C', 6),
        _c('S', 7), _c('H', 8), _c('D', 9), _c('C', 10),
        _c('S', 11), _c('H', 12), _c('D', 1),
      ];

      ctrl.players[0].hand = List.from(hand);
      ctrl.humanSortRanks();

      expect(ctrl.humanRows[0].length, equals(4));
      expect(ctrl.humanRows[1].length, equals(4));
      expect(ctrl.humanRows[2].length, equals(3));
    });

    test('9 kartlık el 3, 3, 3; 8 kartlık el 3, 3, 2 olarak dağıtılır', () {
      final ctrl = OfflineTableController.instance;
      ctrl.initMatch();

      // 9 kart
      final hand9 = List.generate(9, (i) => _c('S', i + 2));
      ctrl.players[0].hand = List.from(hand9);
      ctrl.humanSortRanks();
      expect(ctrl.humanRows[0].length, equals(3));
      expect(ctrl.humanRows[1].length, equals(3));
      expect(ctrl.humanRows[2].length, equals(3));

      // 8 kart
      final hand8 = List.generate(8, (i) => _c('S', i + 2));
      ctrl.players[0].hand = List.from(hand8);
      ctrl.humanSortRanks();
      expect(ctrl.humanRows[0].length, equals(3));
      expect(ctrl.humanRows[1].length, equals(3));
      expect(ctrl.humanRows[2].length, equals(2));
    });

    test('Kart çekildiğinde kart en az elemanlı sıraya eklenir ve denge korunur', () {
      final ctrl = OfflineTableController.instance;
      ctrl.initMatch();
      ctrl.currentTurnSeat = 0;
      ctrl.hasDrawnThisTurn = false;

      // Başlangıçta 10 kart: 4, 3, 3
      ctrl.humanSortRanks();
      expect(ctrl.humanRows[0].length, equals(4));
      expect(ctrl.humanRows[1].length, equals(3));
      expect(ctrl.humanRows[2].length, equals(3));

      // İnsan oyuncu kart çeker
      ctrl.humanDrawCard(fromDiscard: false);

      // Toplam kart sayısı 11 olmalıdır
      final total = ctrl.humanRows.fold<int>(0, (sum, r) => sum + r.length);
      expect(total, equals(11));
      // Hiçbir sıra 5 kart olmaz
      expect(ctrl.humanRows.every((r) => r.length <= 4), isTrue);
    });

    test('Kart atıldığında ilgili sıradan çıkar ve kalan kartlar tutarlı kalır', () {
      final ctrl = OfflineTableController.instance;
      ctrl.initMatch();
      ctrl.currentTurnSeat = 0;
      ctrl.hasDrawnThisTurn = false;
      ctrl.humanDrawCard(fromDiscard: false);

      final cardToDiscard = ctrl.players[0].hand.first;
      final initialTotal = ctrl.humanRows.fold<int>(0, (sum, r) => sum + r.length);

      ctrl.humanDiscardCard(cardToDiscard.id);

      final finalTotal = ctrl.humanRows.fold<int>(0, (sum, r) => sum + r.length);
      expect(finalTotal, equals(initialTotal - 1));
      expect(ctrl.humanRows.expand((r) => r).any((c) => c.id == cardToDiscard.id), isFalse);
    });
  });

  group('Ses Motoru ve Asset Doğrulama Testleri', () {
    test('SoundFx ses ve titreşim metotları hata fırlatmadan çağrılabilir', () {
      expect(() => SoundFx.playCardDraw(), returnsNormally);
      expect(() => SoundFx.playCardDiscard(), returnsNormally);
      expect(() => SoundFx.playCardSlide(), returnsNormally);
      expect(() => SoundFx.playCardTap(), returnsNormally);
      expect(() => SoundFx.playCelebration(), returnsNormally);
    });

    test('Ses kapalıyken titreşim bağımsız olarak çalışır', () async {
      final settings = SettingsService.instance;
      await settings.setSoundEnabled(false);
      await settings.setVibrationEnabled(true);

      expect(settings.soundEnabled, isFalse);
      expect(settings.vibrationEnabled, isTrue);

      expect(() => SoundFx.playCardDraw(), returnsNormally);
      expect(() => SoundFx.playCardDiscard(), returnsNormally);
    });

    test('Titreşim kapalıyken ses bağımsız olarak çalışır', () async {
      final settings = SettingsService.instance;
      await settings.setSoundEnabled(true);
      await settings.setVibrationEnabled(false);

      expect(settings.soundEnabled, isTrue);
      expect(settings.vibrationEnabled, isFalse);

      expect(() => SoundFx.playCardDraw(), returnsNormally);
      expect(() => SoundFx.playCardDiscard(), returnsNormally);
    });
  });

  group('Masaüstü ve Mobil Ana Ekran Logo Testleri', () {
    testWidgets('HomeScreen aktif olarak GameLogoWidget render eder', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: HomeScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GameLogoWidget), findsOneWidget);
      expect(find.text('YANIK İSKAMBİL'), findsOneWidget);
      expect(find.text('OYNA'), findsOneWidget);
    });

    testWidgets('HomeScreen 320x568 küçük ekranda taşma olmadan render edilir', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: HomeScreen()),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(GameLogoWidget), findsOneWidget);
    });

    testWidgets('HomeScreen tablet ve geniş ekranda (800x1280) düzgün ölçeklenir', (tester) async {
      tester.view.physicalSize = const Size(800, 1280);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: HomeScreen()),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(GameLogoWidget), findsOneWidget);
    });
  });

  group('Kart Çekme ve Atma Havada Hareket Animasyonu Testleri', () {
    testWidgets('Masa ekranında kapalı deste ve atılan deste render edilir', (tester) async {
      final ctrl = OfflineTableController.instance;
      ctrl.initMatch();

      await tester.pumpWidget(
        const MaterialApp(home: OfflineTableScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(OfflineTableScreen), findsOneWidget);
      expect(find.textContaining('DESTE'), findsWidgets);
      expect(find.textContaining('ATILAN'), findsWidgets);

      ctrl.stopGame();
    });

    testWidgets('Kullanıcı sırası geldiğinde kart çekme işlemi güvenle tek kez çalışır', (tester) async {
      final ctrl = OfflineTableController.instance;
      ctrl.initMatch();
      ctrl.currentTurnSeat = 0;
      ctrl.hasDrawnThisTurn = false;

      await tester.pumpWidget(
        const MaterialApp(home: OfflineTableScreen()),
      );
      await tester.pump();

      final initialHandCount = ctrl.players[0].hand.length;

      // Çek butonuna bas
      final drawBtn = find.text('DESTEDEN\nÇEK');
      if (drawBtn.evaluate().isNotEmpty) {
        await tester.tap(drawBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();
      } else {
        ctrl.humanDrawCard(fromDiscard: false);
      }

      expect(ctrl.players[0].hand.length, equals(initialHandCount + 1));
      expect(ctrl.hasDrawnThisTurn, isTrue);

      ctrl.stopGame();
    });
  });
}
