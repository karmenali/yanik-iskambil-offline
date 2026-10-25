import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yanik_offline/main.dart';
import 'package:yanik_offline/screens/home_screen.dart';
import 'package:yanik_offline/services/settings_service.dart';
import 'package:yanik_offline/widgets/game_logo_widget.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.instance.init();
  });

  group('Uygulama İkonu ve Varlık Testleri', () {
    test('Yeni app_icon ve game_logo varlıkları diskte mevcuttur', () {
      expect(File('assets/images/app_icon.png').existsSync(), isTrue);
      expect(File('assets/images/app_icon.jpg').existsSync(), isTrue);
      expect(File('assets/images/game_logo.jpg').existsSync(), isTrue);
      expect(File('android/app/src/main/ic_launcher-web.png').existsSync(), isTrue);
      expect(File('windows/runner/resources/app_icon.ico').existsSync(), isTrue);
    });

    test('Android mipmap klasörlerinde ic_launcher ikonları eksiksiz üretilmiştir', () {
      final mipmaps = [
        'android/app/src/main/res/mipmap-mdpi/ic_launcher.png',
        'android/app/src/main/res/mipmap-hdpi/ic_launcher.png',
        'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png',
        'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png',
        'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
      ];
      for (final path in mipmaps) {
        final f = File(path);
        expect(f.existsSync(), isTrue, reason: '$path bulunamadı');
        expect(f.lengthSync(), greaterThan(100), reason: '$path boş olamaz');
      }
    });

    testWidgets('GameLogoWidget aktif olarak Image.asset ile app_icon.png render eder', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: GameLogoWidget(size: 120),
            ),
          ),
        ),
      );

      expect(find.byType(GameLogoWidget), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });
  });

  group('Oyun Adı "Yanık İskambil" ve Ekran Uyumluluk Testleri', () {
    test('Android strings.xml içinde app_name "Yanık İskambil" olarak tanımlıdır', () {
      final defaultStrings = File('android/app/src/main/res/values/strings.xml').readAsStringSync();
      expect(defaultStrings, contains('<string name="app_name">Yanık İskambil</string>'));

      final trStrings = File('android/app/src/main/res/values-tr/strings.xml').readAsStringSync();
      expect(trStrings, contains('<string name="app_name">Yanık İskambil</string>'));
    });

    testWidgets('MaterialApp başlığı "Yanık İskambil" olarak ayarlanmıştır', (tester) async {
      await tester.pumpWidget(const YanikOfflineApp());
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.title, equals('Yanık İskambil'));
    });

    testWidgets('Ana ekranda "YANIK İSKAMBİL" başlığı FittedBox ile tam görüntülenir', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();

      final titleFinder = find.text('YANIK İSKAMBİL');
      expect(titleFinder, findsOneWidget);

      // FittedBox ile sarmalandığını doğrula
      final fittedBoxFinder = find.ancestor(
        of: titleFinder,
        matching: find.byType(FittedBox),
      );
      expect(fittedBoxFinder, findsWidgets);
    });

    testWidgets('Dar ekranlarda (320px) ve büyük font ölçeğinde (2.0x) ad taşma yapmadan tam görüntülenir', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 568),
            textScaler: TextScaler.linear(2.0),
          ),
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('YANIK İSKAMBİL'), findsOneWidget);
    });
  });
}
