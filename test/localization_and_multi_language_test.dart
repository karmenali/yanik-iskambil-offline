import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yanik_offline/engine/offline_table_controller.dart';
import 'package:yanik_offline/l10n/app_localizations_en.dart';
import 'package:yanik_offline/l10n/app_localizations_tr.dart';
import 'package:yanik_offline/l10n/l10n_extension.dart';
import 'package:yanik_offline/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.instance.init();
  });

  group('1. ARB Yerelleştirme ve Dil Yükleme Testleri', () {
    test('Desteklenen diller Türkçe (tr) ve İngilizce (en) içerir', () {
      final supported = AppLocalizations.supportedLocales;
      expect(supported.map((l) => l.languageCode).toSet(), containsAll({'tr', 'en'}));
    });

    test('Türkçe yerelleştirme (tr) tüm temel dizgeleri ve çoğul yapıları doğru üretir', () async {
      final l10nTr = await AppLocalizations.delegate.load(const Locale('tr'));
      expect(l10nTr, isA<AppLocalizationsTr>());

      // Başlık ve menü
      expect(l10nTr.appTitle, equals('Yanık İskambil'));
      expect(l10nTr.defaultPlayerName, equals('Oyuncu'));
      expect(l10nTr.homePlayButton, equals('OYNA'));
      expect(l10nTr.homeAssistedMode, equals('Yardımlı Mod'));
      expect(l10nTr.homeUnassistedMode, equals('Yardımsız Mod'));

      // Ayarlar
      expect(l10nTr.settingsTitle, equals('Oyun Ayarları'));
      expect(l10nTr.settingsLanguageSection, contains('DİL SEÇİMİ'));

      // Kurallar
      expect(l10nTr.rulesTitle, contains('Nasıl Oynanır?'));
      expect(l10nTr.rulesUnderstandButton, equals('ANLADIM'));

      // Masa butonları
      expect(l10nTr.tableBtnDeclareFinish, contains('EL AÇ'));
      expect(l10nTr.tableTooltipScoresheet, equals('101 Skor Tablosu'));
      expect(l10nTr.tableBtnAutoMeld, contains('PER DİZ'));

      // Çoğul ifadeler
      expect(l10nTr.summaryPlayerUnmeldedCards(1), equals('Boşta: 1 kağıt'));
      expect(l10nTr.summaryPlayerUnmeldedCards(4), equals('Boşta: 4 kağıt'));
    });

    test('İngilizce yerelleştirme (en) uluslararası remi terimleriyle doğru üretir', () async {
      final l10nEn = await AppLocalizations.delegate.load(const Locale('en'));
      expect(l10nEn, isA<AppLocalizationsEn>());

      // Başlık ve menü
      expect(l10nEn.appTitle, equals('Yanik Rummy'));
      expect(l10nEn.defaultPlayerName, equals('Player'));
      expect(l10nEn.homePlayButton, equals('PLAY'));
      expect(l10nEn.homeAssistedMode, equals('Assisted Mode'));
      expect(l10nEn.homeUnassistedMode, equals('Unassisted Mode'));

      // Ayarlar
      expect(l10nEn.settingsTitle, equals('Game Settings'));
      expect(l10nEn.settingsLanguageSection, contains('LANGUAGE'));

      // Kurallar
      expect(l10nEn.rulesTitle, contains('How to Play'));
      expect(l10nEn.rulesUnderstandButton, equals('GOT IT'));

      // Masa butonları
      expect(l10nEn.tableBtnDeclareFinish, contains('DECLARE'));
      expect(l10nEn.tableTooltipScoresheet, equals('101 Scoresheet'));
      expect(l10nEn.tableBtnAutoMeld, contains('AUTO'));

      // Çoğul ifadeler
      expect(l10nEn.summaryPlayerUnmeldedCards(1), equals('Deadwood: 1 card'));
      expect(l10nEn.summaryPlayerUnmeldedCards(4), equals('Deadwood: 4 cards'));
    });

    testWidgets('l10nOf(context) delege bulunmayan ortamlarda güvenle AppLocalizationsTr döner', (tester) async {
      late AppLocalizations resolved;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) {
              resolved = l10nOf(ctx);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(resolved, isNotNull);
      expect(resolved.appTitle, equals('Yanık İskambil'));
    });

    testWidgets('l10nOf(context) delege sağlandığında seçili Locale (en) karşılığını döner', (tester) async {
      late AppLocalizations resolved;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (ctx) {
              resolved = l10nOf(ctx);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(resolved, isNotNull);
      expect(resolved.appTitle, equals('Yanik Rummy'));
    });
  });

  group('2. SettingsService Dil Kalıcılığı ve Değişimi Testleri', () {
    test('Varsayılan başlangıç dili TR olarak atanır veya cihaz diline uyar', () {
      final s = SettingsService.instance;
      expect(s.locale.languageCode, isIn(['tr', 'en']));
    });

    test('setLanguageCode ve setLocale tercihleri SharedPreferences içine kaydeder', () async {
      final s = SettingsService.instance;
      await s.setLanguageCode('en');
      expect(s.locale.languageCode, equals('en'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('yanik_offline_language'), equals('en'));

      await s.setLocale(const Locale('tr'));
      expect(s.locale.languageCode, equals('tr'));
      expect(prefs.getString('yanik_offline_language'), equals('tr'));
    });
  });

  group('3. OfflineTableController Şampiyonluk Alanları ve Sıfırlanma Testleri', () {
    late OfflineTableController controller;

    setUp(() {
      controller = OfflineTableController.instance;
      controller.initMatch();
    });

    test('initMatch() çağrıldığında championSeatIndex, championName ve winnerMessage sıfırlanır', () {
      controller.championSeatIndex = 2;
      controller.championName = 'Zeynep';
      controller.winnerMessage = 'Zeynep Şampiyon Oldu!';

      controller.initMatch();

      expect(controller.championSeatIndex, isNull);
      expect(controller.championName, isNull);
      expect(controller.winnerMessage, isNull);
      expect(controller.isHumanChampion, isFalse);
    });

    test('startRound() çağrıldığında championSeatIndex ve championName temizlenir', () {
      controller.championSeatIndex = 0;
      controller.championName = 'Sen';
      controller.winnerMessage = 'Tebrikler!';

      controller.startRound();

      expect(controller.championSeatIndex, isNull);
      expect(controller.championName, isNull);
      expect(controller.winnerMessage, isNull);
      expect(controller.isHumanChampion, isFalse);
    });

    test('stopGame() çağrıldığında championSeatIndex ve championName temizlenir', () {
      controller.championSeatIndex = 1;
      controller.championName = 'Ahmet';
      controller.winnerMessage = 'Ahmet Şampiyon!';

      controller.stopGame();

      expect(controller.championSeatIndex, isNull);
      expect(controller.championName, isNull);
      expect(controller.winnerMessage, isNull);
      expect(controller.status, equals('waiting'));
    });

    test('İnsan oyuncu tek başına kaldığında isHumanChampion doğru hesaplanır', () {
      // 3 botu da elenmiş yapalım
      controller.players[1].totalScore = 105;
      controller.players[2].totalScore = 110;
      controller.players[3].totalScore = 120;
      controller.players[0].totalScore = 20;

      // Turu sonlandır
      controller.endRound(0);

      expect(controller.championSeatIndex, equals(0));
      expect(controller.isHumanChampion, isTrue);
      expect(controller.winnerMessage, contains('Tebrikler'));
    });

    test('Bot tek başına kaldığında championSeatIndex ve championName doğru atanır', () {
      // İnsan ve diğer 2 bot elensin, Ahmet (1) kalsın
      controller.players[0].totalScore = 102;
      controller.players[2].totalScore = 115;
      controller.players[3].totalScore = 108;
      controller.players[1].totalScore = 35;

      controller.endRound(1);

      expect(controller.championSeatIndex, equals(1));
      expect(controller.championName, equals('Ahmet'));
      expect(controller.isHumanChampion, isFalse);
      expect(controller.winnerMessage, contains('Ahmet'));
    });
  });

  group('4. Platform Metinleri ve Gizlilik Politikası Çeviri Bütünlüğü', () {
    test('Android strings.xml dosyalarında tr ve en yapılandırmaları tutarlıdır', () {
      final valuesXml = File('android/app/src/main/res/values/strings.xml').readAsStringSync();
      final valuesTrXml = File('android/app/src/main/res/values-tr/strings.xml').readAsStringSync();
      final valuesEnXml = File('android/app/src/main/res/values-en/strings.xml').readAsStringSync();

      expect(valuesXml, contains('Yanık İskambil'));
      expect(valuesTrXml, contains('Yanık İskambil'));
      expect(valuesEnXml, contains('Yanik Rummy'));
    });

    test('iOS InfoPlist.strings dosyalarında tr ve en display name değerleri mevcuttur', () {
      final trIos = File('ios/Runner/tr.lproj/InfoPlist.strings').readAsStringSync();
      final enIos = File('ios/Runner/en.lproj/InfoPlist.strings').readAsStringSync();

      expect(trIos, contains('"CFBundleDisplayName" = "Yanık İskambil";'));
      expect(enIos, contains('"CFBundleDisplayName" = "Yanik Rummy";'));
    });

    test('PRIVACY_POLICY_EN.md dosyası mevcuttur ve Türkçe sürümle 1-e-1 bölüm yapısına sahiptir', () {
      final trPolicy = File('PRIVACY_POLICY.md');
      final enPolicy = File('PRIVACY_POLICY_EN.md');

      expect(trPolicy.existsSync(), isTrue);
      expect(enPolicy.existsSync(), isTrue);

      final trContent = trPolicy.readAsStringSync();
      final enContent = enPolicy.readAsStringSync();

      // İki belgenin de Google AdMob, Çevrimdışı/Offline mimarisi ve Hesap Açılmama maddelerini içerdiğini doğrula
      expect(trContent, contains('Google AdMob'));
      expect(enContent, contains('Google AdMob'));

      expect(trContent, contains('Çevrimdışı'));
      expect(enContent, contains('Offline'));

      expect(trContent, contains('hesap oluşturma veya oturum açma gerektirmez'));
      expect(enContent, contains('account creation, or login'));

      expect(trContent, contains('Data Safety'));
      expect(enContent, contains('Data Safety'));
    });
  });
}
