import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService instance = AdService._internal();
  AdService._internal();

  /// Google AdMob Resmi Test Geçiş Reklamı (Interstitial) ID'leri:
  /// Yayına çıkarken kendi AdMob Interstitial ID'nizi buraya yazabilirsiniz.
  static const String _androidDefaultInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _iosDefaultInterstitialId =
      'ca-app-pub-3940256099942544/4411468910';

  String get interstitialAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) return _androidDefaultInterstitialId;
    if (Platform.isIOS) return _iosDefaultInterstitialId;
    return '';
  }

  InterstitialAd? _interstitialAd;
  bool _isLoading = false;
  int _failedLoadAttempts = 0;

  Future<void> init() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    try {
      await MobileAds.instance.initialize();
      loadInterstitialAd();
    } catch (e) {
      debugPrint('AdMob başlatma hatası: $e');
    }
  }

  void loadInterstitialAd() {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    if (_interstitialAd != null || _isLoading) return;

    final unitId = interstitialAdUnitId;
    if (unitId.isEmpty) return;

    _isLoading = true;
    InterstitialAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoading = false;
          _failedLoadAttempts = 0;
          debugPrint('Geçiş reklamı başarıyla yüklendi.');
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _isLoading = false;
          _failedLoadAttempts++;
          debugPrint('Geçiş reklamı yüklenemedi: $error');
          // Bir süre sonra tekrar dene
          if (_failedLoadAttempts < 3) {
            Future.delayed(const Duration(seconds: 15), () {
              loadInterstitialAd();
            });
          }
        },
      ),
    );
  }

  /// Her tur sonunda "Devam Et" butonuna basıldığında çağrılır.
  /// Reklam hazırsa gösterir; kapandığında `onDismissed` çağrılır.
  /// Reklam hazır değilse (veya internetsizse) oyunu bekletmeden DOĞRUDAN `onDismissed` çağrılır!
  void showInterstitialAd({required VoidCallback onDismissed}) {
    if (_interstitialAd == null) {
      // Reklam hazır değil veya offline, oyunu bekletme!
      loadInterstitialAd();
      onDismissed();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd(); // Sonraki tur için önden yükle
        onDismissed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Reklam gösterim hatası: $error');
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd();
        onDismissed();
      },
    );

    _interstitialAd!.show();
  }
}
