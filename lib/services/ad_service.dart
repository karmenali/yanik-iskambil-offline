import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService instance = AdService._internal();
  AdService._internal();

  /// Google AdMob Resmi Test Geçiş Reklamı (Interstitial) ID'leri:
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
  bool _isMobileAdsInitialized = false;
  bool _isConsentUpdating = false;
  bool _isInitializing = false;
  bool _isShowingAd = false;

  /// Reklam sıklık sınırlayıcısı (Frequency Capping):
  /// Başlangıç politikası olarak her üç turda en fazla bir geçiş reklamı gösterilir.
  int _completedRoundsCount = 0;
  int? _lastProcessedRound;

  int get completedRoundsCount => _completedRoundsCount;
  int? get lastProcessedRound => _lastProcessedRound;
  bool get isShowingAd => _isShowingAd;
  bool get isMobileAdsInitialized => _isMobileAdsInitialized;

  @visibleForTesting
  void resetCompletedRoundsCount() {
    _completedRoundsCount = 0;
    _lastProcessedRound = null;
    _isShowingAd = false;
  }

  @visibleForTesting
  void setCompletedRoundsCount(int count) {
    _completedRoundsCount = count;
  }

  @visibleForTesting
  void setLastProcessedRound(int? round) {
    _lastProcessedRound = round;
  }

  @visibleForTesting
  void setIsShowingAd(bool val) {
    _isShowingAd = val;
  }

  /// 1. Rıza Bilgisini Güncelleme ve UMP Akışı
  Future<void> init() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    if (_isMobileAdsInitialized || _isConsentUpdating) return;

    _isConsentUpdating = true;
    try {
      final params = ConsentRequestParameters();
      ConsentInformation.instance.requestConsentInfoUpdate(
        params,
        () async {
          _isConsentUpdating = false;
          // Rıza formu gerekliyse yükle ve kullanıcıya göster
          ConsentForm.loadAndShowConsentFormIfRequired(
            (FormError? formError) async {
              if (formError != null) {
                debugPrint('UMP Rıza formu hatası: ${formError.message}');
              }
              // Rıza durumu kontrolü sonrası reklam isteği izni var mı?
              await _checkAndInitializeMobileAds();
            },
          );
        },
        (FormError formError) async {
          _isConsentUpdating = false;
          debugPrint('UMP Rıza güncelleme hatası: ${formError.message}');
          // Ağ hatası veya çevrimdışıyken önbellekteki rıza ile devam edilebilir mi kontrol et
          await _checkAndInitializeMobileAds();
        },
      );
    } catch (e) {
      _isConsentUpdating = false;
      debugPrint('AdService init genel hatası: $e');
    }
  }

  /// 2. canRequestAds() kontrolü ve AdMob motorunu güvenle başlatma
  Future<void> _checkAndInitializeMobileAds() async {
    if (_isMobileAdsInitialized || _isInitializing) return;
    _isInitializing = true;

    try {
      final canRequest = await ConsentInformation.instance.canRequestAds();
      if (canRequest) {
        if (!_isMobileAdsInitialized) {
          await MobileAds.instance.initialize();
          _isMobileAdsInitialized = true;
          loadInterstitialAd();
        }
      } else {
        debugPrint('Kullanıcı rızası henüz alınmadığı için reklam isteği gönderilmedi.');
      }
    } catch (e) {
      debugPrint('AdMob başlatma hatası: $e');
    } finally {
      _isInitializing = false;
    }
  }

  /// 3. Geçiş Reklamı Yükleme
  /// Rıza doğrulanmadan veya AdMob başlatılmadan reklam isteği gönderilmez.
  void loadInterstitialAd() {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    if (!_isMobileAdsInitialized || _interstitialAd != null || _isLoading) return;

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
          if (_failedLoadAttempts < 3) {
            Future.delayed(const Duration(seconds: 15), () {
              loadInterstitialAd();
            });
          }
        },
      ),
    );
  }

  /// 4. Geçiş Reklamı Gösterme (Tur Sonu & Maç Sonu)
  /// - Sıklık Sınırı: Her üç turda en fazla bir geçiş reklamı.
  /// - Tur & Maç Sonu Tekilleştirmesi: Aynı tur numarası için yinelenen reklam tetiklemeleri engellenir.
  /// - Reklam yoksa veya internetsizse: Oyunu bekletmeden DOĞRUDAN onDismissed çağrılır.
  void showInterstitialAd({
    required VoidCallback onDismissed,
    int? roundNumber,
  }) {
    // 1. Aynı anda zaten bir reklam gösteriliyorsa çift açılmayı engelle
    if (_isShowingAd) {
      onDismissed();
      return;
    }

    // 2. Aynı tur numarası için (örn. hem tur özeti hem maç sonu olayı aynı anda tetiklenirse) mükerrer reklamı önle
    if (roundNumber != null && _lastProcessedRound == roundNumber) {
      debugPrint('AdService: Tur $roundNumber için reklam zaten işlendi, yinelenen çağrı atlandı.');
      onDismissed();
      return;
    }

    if (roundNumber != null) {
      _lastProcessedRound = roundNumber;
    }

    _completedRoundsCount++;

    // Her 3 turda en fazla 1 reklam göster
    if (_completedRoundsCount < 3) {
      onDismissed();
      return;
    }

    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      onDismissed();
      return;
    }

    if (_interstitialAd == null) {
      // Reklam henüz hazır değil veya cihaz internetsiz: oyunu ASLA bekletme!
      loadInterstitialAd();
      onDismissed();
      return;
    }

    _isShowingAd = true;
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _isShowingAd = false;
        _completedRoundsCount = 0; // Reklam gösterildi, sayacı sıfırla
        loadInterstitialAd(); // Sonraki hak için önden yükle
        onDismissed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Reklam gösterim hatası: $error');
        ad.dispose();
        _interstitialAd = null;
        _isShowingAd = false;
        loadInterstitialAd();
        onDismissed();
      },
    );

    try {
      _interstitialAd!.show();
    } catch (e) {
      debugPrint('Reklam gösterim hatası: $e');
      _interstitialAd = null;
      _isShowingAd = false;
      loadInterstitialAd();
      onDismissed();
    }
  }
}
