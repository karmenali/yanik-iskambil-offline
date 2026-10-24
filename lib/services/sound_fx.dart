import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'settings_service.dart';

class SoundFx {
  static AudioPlayer? _sfxPlayer;
  static bool get _isTest => Platform.environment.containsKey('FLUTTER_TEST');
  static AudioPlayer get _player => _sfxPlayer ??= AudioPlayer();
  static final Map<String, Uint8List> _wavCache = {};
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;
    try {
      if (!_isTest) {
        await _player.setReleaseMode(ReleaseMode.stop);
        await _player.setPlayerMode(PlayerMode.lowLatency);
      }
      // Ses önbelleğini hemen hazırla
      _wavCache['card_draw'] = _generateCardDrawWav();
      _wavCache['card_slide'] = _generateCardSlideWav();
      _wavCache['card_discard'] = _generateCardDiscardWav();
      _wavCache['card_tap'] = _generateCardTapWav();
      _wavCache['celebration'] = _generateCelebrationWav();
      _isInitialized = true;
    } catch (_) {}
  }

  static void playCardDraw() {
    triggerHaptic(HapticFeedback.lightImpact);
    if (!SettingsService.instance.soundEnabled) return;
    _playAcousticSfx('card_draw', _generateCardDrawWav);
  }

  static void playCardSlide() {
    triggerHaptic(HapticFeedback.selectionClick);
    if (!SettingsService.instance.soundEnabled) return;
    _playAcousticSfx('card_slide', _generateCardSlideWav);
  }

  static void playCardDiscard() {
    triggerHaptic(HapticFeedback.mediumImpact);
    if (!SettingsService.instance.soundEnabled) return;
    _playAcousticSfx('card_discard', _generateCardDiscardWav);
  }

  static void playCardTap() {
    triggerHaptic(HapticFeedback.lightImpact);
    if (!SettingsService.instance.soundEnabled) return;
    _playAcousticSfx('card_tap', _generateCardTapWav);
  }

  static void playCelebration() {
    triggerHaptic(HapticFeedback.heavyImpact);
    if (!SettingsService.instance.soundEnabled) return;
    _playAcousticSfx('celebration', _generateCelebrationWav);
  }

  static void triggerHaptic([Future<void> Function()? hapticFn]) {
    if (SettingsService.instance.vibrationEnabled) {
      try {
        if (hapticFn != null) {
          hapticFn();
        } else {
          HapticFeedback.selectionClick();
        }
      } catch (_) {}
    }
  }

  static void _playAcousticSfx(
    String key,
    Uint8List Function() generator,
  ) {
    if (_isTest) return; // Unit test ortamında native ses sürücüsü çağrılmaz
    try {
      final wav = _wavCache.putIfAbsent(key, generator);
      _player.play(BytesSource(wav), mode: PlayerMode.lowLatency).catchError((_) {});
    } catch (_) {}
  }

  // Akustik WAV Sentezleyiciler
  static Uint8List _generateCardDrawWav() {
    const sampleRate = 22050;
    const durationMs = 95;
    final totalSamples = (sampleRate * durationMs / 1000).round();
    final pcm = Uint8List(totalSamples);
    final rand = math.Random(42);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / totalSamples;
      // Kart çekme: Yumuşak yükselen hava sürtünmesi ve çıtırtı zarfı
      final env = math.sin(t * math.pi * 0.90);
      final freq = 280.0 + (t * 220.0);
      final sine = math.sin(2 * math.pi * freq * (i / sampleRate));
      final noise = (rand.nextDouble() * 2 - 1) * 0.40;
      final sample = ((sine * 0.60 + noise) * env * 65).round();
      pcm[i] = (sample + 128).clamp(0, 255);
    }
    return _createWavHeader(pcm, sampleRate);
  }

  static Uint8List _generateCardSlideWav() {
    const sampleRate = 22050;
    const durationMs = 120;
    final totalSamples = (sampleRate * durationMs / 1000).round();
    final pcm = Uint8List(totalSamples);
    final rand = math.Random(1337);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / totalSamples;
      final env = math.sin(t * math.pi);
      final noise = (rand.nextDouble() * 2 - 1);
      final sample = (noise * env * 48).round();
      pcm[i] = (sample + 128).clamp(0, 255);
    }
    return _createWavHeader(pcm, sampleRate);
  }

  static Uint8List _generateCardDiscardWav() {
    const sampleRate = 22050;
    const durationMs = 150;
    final totalSamples = (sampleRate * durationMs / 1000).round();
    final pcm = Uint8List(totalSamples);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / totalSamples;
      final env = math.exp(-t * 12);
      final freq = 120.0 - (t * 40.0);
      final sine = math.sin(2 * math.pi * freq * (i / sampleRate));
      final sample = (sine * env * 90).round();
      pcm[i] = (sample + 128).clamp(0, 255);
    }
    return _createWavHeader(pcm, sampleRate);
  }

  static Uint8List _generateCardTapWav() {
    const sampleRate = 22050;
    const durationMs = 70;
    final totalSamples = (sampleRate * durationMs / 1000).round();
    final pcm = Uint8List(totalSamples);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / totalSamples;
      final env = math.exp(-t * 25);
      final sine = math.sin(2 * math.pi * 320 * (i / sampleRate));
      final sample = (sine * env * 65).round();
      pcm[i] = (sample + 128).clamp(0, 255);
    }
    return _createWavHeader(pcm, sampleRate);
  }

  static Uint8List _generateCelebrationWav() {
    const sampleRate = 22050;
    const durationMs = 450;
    final totalSamples = (sampleRate * durationMs / 1000).round();
    final pcm = Uint8List(totalSamples);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / totalSamples;
      final env = (1.0 - t).clamp(0.0, 1.0);
      final freq = 523.25 + (t * 300); // C5 to G5
      final sine = math.sin(2 * math.pi * freq * (i / sampleRate));
      final sample = (sine * env * 80).round();
      pcm[i] = (sample + 128).clamp(0, 255);
    }
    return _createWavHeader(pcm, sampleRate);
  }

  static Uint8List _createWavHeader(Uint8List pcmData, int sampleRate) {
    final byteData = ByteData(44 + pcmData.length);
    // RIFF
    byteData.setUint8(0, 0x52);
    byteData.setUint8(1, 0x49);
    byteData.setUint8(2, 0x46);
    byteData.setUint8(3, 0x46);
    byteData.setUint32(4, 36 + pcmData.length, Endian.little);
    // WAVE
    byteData.setUint8(8, 0x57);
    byteData.setUint8(9, 0x41);
    byteData.setUint8(10, 0x56);
    byteData.setUint8(11, 0x45);
    // fmt
    byteData.setUint8(12, 0x66);
    byteData.setUint8(13, 0x6D);
    byteData.setUint8(14, 0x74);
    byteData.setUint8(15, 0x20);
    byteData.setUint32(16, 16, Endian.little);
    byteData.setUint16(20, 1, Endian.little); // PCM
    byteData.setUint16(22, 1, Endian.little); // 1 channel
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, sampleRate, Endian.little); // byte rate (8-bit mono)
    byteData.setUint16(32, 1, Endian.little); // block align
    byteData.setUint16(34, 8, Endian.little); // bits per sample
    // data
    byteData.setUint8(36, 0x64);
    byteData.setUint8(37, 0x61);
    byteData.setUint8(38, 0x74);
    byteData.setUint8(39, 0x61);
    byteData.setUint32(40, pcmData.length, Endian.little);

    final out = byteData.buffer.asUint8List();
    out.setRange(44, 44 + pcmData.length, pcmData);
    return out;
  }
}
