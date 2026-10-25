import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'settings_service.dart';

/// Zynga / Batak HD Standartlarında Düşük Gecikmeli, Sıfır Bellek Sızıntılı Ses ve Haptik Motoru.
///
/// Android platformundaki ses kesilmesi ("audio dropout") ve donma ("UI jank / freezing") sorunlarının
/// kök nedeni:
/// 1. Tek bir AudioPlayer üzerinde her ses için art arda `play(AssetSource(...))` çağrıldığında
///    native SoundPoolPlayer'ın her seferinde `release()` ve `soundPool.unload()` yapıp ardından
///    Dispatchers.IO ile yeni ses yüklemesidir.
/// 2. Hızlı kart hareketleri ve bot turlarında bu döngü yüzlerce kez tekrarlanarak SoundPool
///    örnek sınırını (sample limit) doldurmakta, seslerin tamamen kesilmesine yol açmaktaydı.
/// 3. Bot hamlelerinde bile titreşim motorunun tetiklenmesi ve insan hamlelerinde ekran+controller
///    çift tetiklemesi Android Vibrator IPC kuyruğunu ve UI thread'ini kilitlemekteydi.
///
/// Bu sınıf:
/// - Her ses türü için sabit, yeniden kullanılan (reusable) izole AudioPlayer havuzu tutar.
/// - Ses kaynaklarını tek seferlik yükler (`setSource`); her çalma işleminde belleğe yeniden yükleme yapmaz.
/// - `stop()` + `resume()` kombinasyonu ile sıfır gecikmeli (zero-latency) oynatma sağlar.
/// - Minimum aralık kontrolü (throttling / debounce) ile gereksiz tekrarları ve çift tetiklemeleri engeller.
/// - Haptik titreşimi ses motorundan tamamen ayırır; bot hamlelerinde titreşime asla izin vermez.
/// - Ses/titreşim ayarları kapalıyken hiçbir native çağrı veya platform kanalı çalıştırmaz.
class SoundFx {
  static bool get _isTest => Platform.environment.containsKey('FLUTTER_TEST');

  // Her ses efekti için özel, izole AudioPlayer örneği
  static AudioPlayer? _drawPlayer;
  static AudioPlayer? _discardPlayer;
  static AudioPlayer? _slidePlayer;
  static AudioPlayer? _tapPlayer;
  static AudioPlayer? _celebrationPlayer;

  static bool _isInitialized = false;

  // Throttling / Hızlı tekrar engelleyiciler (Son tetiklenme zamanları - epoch ms)
  static int _lastDrawTime = 0;
  static int _lastDiscardTime = 0;
  static int _lastSlideTime = 0;
  static int _lastTapTime = 0;
  static int _lastHapticTime = 0;
  static int _lastCelebrationTime = 0;

  // Kenney Casino Audio OGG & WAV Dosyaları
  static const String _assetCardDraw = 'sounds/card_draw.ogg';
  static const String _assetCardDiscard = 'sounds/card_discard.ogg';
  static const String _assetCardSlide = 'sounds/card_slide.ogg';
  static const String _assetCardTap = 'sounds/card_tap.ogg';
  static const String _assetCelebration = 'sounds/celebration.wav';

  /// Ses motorunu başlatır ve sesleri native ses belleğine (SoundPool) tek seferlik önceden yükler.
  static Future<void> init() async {
    if (_isInitialized || _isTest) return;

    try {
      _drawPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
      _discardPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
      _slidePlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
      _tapPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
      _celebrationPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);

      await Future.wait([
        _drawPlayer!.setPlayerMode(PlayerMode.lowLatency),
        _discardPlayer!.setPlayerMode(PlayerMode.lowLatency),
        _slidePlayer!.setPlayerMode(PlayerMode.lowLatency),
        _tapPlayer!.setPlayerMode(PlayerMode.lowLatency),
        _celebrationPlayer!.setPlayerMode(PlayerMode.lowLatency),
      ]);

      // Ses kaynaklarını tek seferlik yükle (setSource bir defa çağrılır, asla sızıntı yapmaz)
      await Future.wait([
        _drawPlayer!.setSource(AssetSource(_assetCardDraw)),
        _discardPlayer!.setSource(AssetSource(_assetCardDiscard)),
        _slidePlayer!.setSource(AssetSource(_assetCardSlide)),
        _tapPlayer!.setSource(AssetSource(_assetCardTap)),
        _celebrationPlayer!.setSource(AssetSource(_assetCelebration)),
      ]);

      _isInitialized = true;
    } catch (e) {
      debugPrint('SoundFx init uyarısı (oyun akışı etkilenmez): $e');
    }
  }

  /// Güvenli, düşük gecikmeli ve sınırlandırılmış ses çalma
  static void _safePlay({
    required AudioPlayer? player,
    required String assetPath,
    required int lastTime,
    required int minIntervalMs,
    required void Function(int) updateTime,
  }) {
    if (_isTest) return;
    if (!SettingsService.instance.soundEnabled) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - lastTime < minIntervalMs) {
      // Hızlı tekrar eden gereksiz çağrı engellendi (throttling)
      return;
    }
    updateTime(now);

    try {
      if (player == null) return;
      // stop() çağrısı önceki akışı sonlandırır, resume() mevcut ses ID'sini sıfır gecikmeyle baştan oynatır
      player.stop().then((_) {
        player.resume().catchError((_) {
          // Eğer resume SoundPool'da desteklenmezse veya henüz yüklenmediyse güvenli fallback
          player.play(AssetSource(assetPath), mode: PlayerMode.lowLatency).catchError((_) {});
        });
      }).catchError((_) {});
    } catch (_) {}
  }

  /// Kart çekme sesi (Human veya Bot)
  /// Not: Haptik titreşim burada tetiklenmez! Yalnızca ses çalar.
  static void playCardDraw() {
    _safePlay(
      player: _drawPlayer,
      assetPath: _assetCardDraw,
      lastTime: _lastDrawTime,
      minIntervalMs: 160,
      updateTime: (t) => _lastDrawTime = t,
    );
  }

  /// Kart atma sesi (Human veya Bot)
  /// Not: Haptik titreşim burada tetiklenmez! Yalnızca ses çalar.
  static void playCardDiscard() {
    _safePlay(
      player: _discardPlayer,
      assetPath: _assetCardDiscard,
      lastTime: _lastDiscardTime,
      minIntervalMs: 160,
      updateTime: (t) => _lastDiscardTime = t,
    );
  }

  /// Kart kaydırma / deste dağıtma sesi
  static void playCardSlide() {
    _safePlay(
      player: _slidePlayer,
      assetPath: _assetCardSlide,
      lastTime: _lastSlideTime,
      minIntervalMs: 120,
      updateTime: (t) => _lastSlideTime = t,
    );
  }

  /// Kart tıklama / seçme sesi
  static void playCardTap() {
    _safePlay(
      player: _tapPlayer,
      assetPath: _assetCardTap,
      lastTime: _lastTapTime,
      minIntervalMs: 65,
      updateTime: (t) => _lastTapTime = t,
    );
  }

  /// Tur/Oyun kazanma kutlama sesi (Kısa, tok, asil casino akustiği)
  static void playCelebration() {
    if (_isTest) return;
    if (!SettingsService.instance.soundEnabled) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastCelebrationTime < 1000) {
      return; // Tekrarlanan kutlama sesi engellendi
    }
    _lastCelebrationTime = now;

    try {
      _celebrationPlayer?.stop().then((_) {
        _celebrationPlayer?.resume().catchError((_) {
          _celebrationPlayer?.play(AssetSource(_assetCelebration), mode: PlayerMode.lowLatency).catchError((_) {});
        });
      }).catchError((_) {});
    } catch (_) {}
  }

  @visibleForTesting
  static Future<void> Function()? turnHapticFnForTesting;

  /// Oyuncunun oynama sırası başladığında çalışan kısa, net sıra başlangıç titreşimi.
  /// Yalnızca titreşim ayarı açıkken ve sıra ilk kez kullanıcıya geçtiğinde çalışır.
  static void triggerTurnStartHaptic([Future<void> Function()? customHapticFn]) {
    if (!SettingsService.instance.vibrationEnabled) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastHapticTime < 350) {
      return; // Mükerrer çağrı engellemesi
    }
    _lastHapticTime = now;

    try {
      if (customHapticFn != null) {
        customHapticFn();
      } else if (turnHapticFnForTesting != null) {
        turnHapticFnForTesting!();
      } else if (!_isTest) {
        // Android cihazlarda net ve hissedilir kısa dokunsal titreşim
        HapticFeedback.mediumImpact();
      }
    } catch (_) {}
  }

  /// Yalnızca gerçek kullanıcı etkileşimlerinde çalışan, donanımı kasmayan haptik titreşim.
  /// Bot hamlelerinde ASLA çağrılmaz. Titreşim ayarı kapalıysa platform kanalı çalıştırılmaz.
  static void triggerHaptic([Future<void> Function()? hapticFn]) {
    if (!SettingsService.instance.vibrationEnabled) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    // Android VibratorService IPC kuyruğunu ve motorunu kilitlememek için en az 55ms aralık zorunludur
    if (now - _lastHapticTime < 55) {
      return;
    }
    _lastHapticTime = now;

    try {
      if (hapticFn != null) {
        hapticFn();
      } else if (!_isTest) {
        HapticFeedback.selectionClick();
      }
    } catch (_) {}
  }

  static void triggerHapticSelection() => triggerHaptic(HapticFeedback.selectionClick);
  static void triggerHapticLight() => triggerHaptic(HapticFeedback.lightImpact);
  static void triggerHapticMedium() => triggerHaptic(HapticFeedback.mediumImpact);
  static void triggerHapticHeavy() => triggerHaptic(HapticFeedback.heavyImpact);

  /// Tüm audio kaynaklarını kapatır ve serbest bırakır.
  static Future<void> dispose() async {
    _isInitialized = false;
    try {
      await Future.wait([
        _drawPlayer?.dispose() ?? Future.value(),
        _discardPlayer?.dispose() ?? Future.value(),
        _slidePlayer?.dispose() ?? Future.value(),
        _tapPlayer?.dispose() ?? Future.value(),
        _celebrationPlayer?.dispose() ?? Future.value(),
      ]);
    } catch (_) {}
    _drawPlayer = null;
    _discardPlayer = null;
    _slidePlayer = null;
    _tapPlayer = null;
    _celebrationPlayer = null;
  }
}
