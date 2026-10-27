import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'services/ad_service.dart';
import 'services/settings_service.dart';
import 'services/sound_fx.dart';

void main() async {
  // Global Hata Yakalayıcı (Uygulamanın beklenmedik kapanmasını önler)
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('PlatformDispatcher Hatası: $error');
    return true; // Hatayı yutarak uygulamanın çökmesini engeller
  };

  WidgetsFlutterBinding.ensureInitialized();

  // Dikey yön kilidi
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  } catch (_) {}

  try {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF04120C),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  } catch (_) {}

  // Temel ayarları oku
  try {
    await SettingsService.instance.init();
  } catch (e) {
    debugPrint('SettingsService init hatası: $e');
  }

  // ÖNCE ARAYÜZÜ ÇALIŞTIR (Asla harici eklentiler yüzünden arayüz açılışını engelleme!)
  runApp(const YanikOfflineApp());

  // Arka plan servislerini (AdMob, Ses) arayüz açıldıktan sonra güvenle başlat
  Future.microtask(() async {
    try {
      await SoundFx.init();
    } catch (e) {
      debugPrint('SoundFx init hatası: $e');
    }

    try {
      await AdService.instance.init();
    } catch (e) {
      debugPrint('AdService init hatası: $e');
    }
  });
}

class YanikOfflineApp extends StatelessWidget {
  const YanikOfflineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsService.instance,
      builder: (context, _) {
        final currentLocale = SettingsService.instance.locale;
        return MaterialApp(
          title: 'Yanık İskambil',
          debugShowCheckedModeBanner: false,
          locale: currentLocale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF05160F),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFD4AF37),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}
