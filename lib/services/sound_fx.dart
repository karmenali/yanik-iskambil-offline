import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'settings_service.dart';

class SoundFx {
  static AudioPlayer? _sfxPlayer;
  static bool get _isTest => Platform.environment.containsKey('FLUTTER_TEST');
  static AudioPlayer get _player => _sfxPlayer ??= AudioPlayer();
  static bool _isInitialized = false;

  static const Map<String, String> _soundAssetMap = {
    'card_draw': 'sounds/card_draw.wav',
    'card_slide': 'sounds/card_slide.wav',
    'card_discard': 'sounds/card_discard.wav',
    'card_tap': 'sounds/card_tap.wav',
    'celebration': 'sounds/celebration.wav',
  };

  static Future<void> init() async {
    if (_isInitialized) return;
    try {
      if (!_isTest) {
        await _player.setReleaseMode(ReleaseMode.stop);
        await _player.setPlayerMode(PlayerMode.lowLatency);
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('SoundFx init hatası: $e');
    }
  }

  static void playCardDraw() {
    triggerHaptic(HapticFeedback.lightImpact);
    if (!SettingsService.instance.soundEnabled) return;
    _playSfx('card_draw');
  }

  static void playCardSlide() {
    triggerHaptic(HapticFeedback.selectionClick);
    if (!SettingsService.instance.soundEnabled) return;
    _playSfx('card_slide');
  }

  static void playCardDiscard() {
    triggerHaptic(HapticFeedback.mediumImpact);
    if (!SettingsService.instance.soundEnabled) return;
    _playSfx('card_discard');
  }

  static void playCardTap() {
    triggerHaptic(HapticFeedback.lightImpact);
    if (!SettingsService.instance.soundEnabled) return;
    _playSfx('card_tap');
  }

  static void playCelebration() {
    triggerHaptic(HapticFeedback.heavyImpact);
    if (!SettingsService.instance.soundEnabled) return;
    _playSfx('celebration');
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

  static void _playSfx(String key) {
    if (_isTest) return; // Unit/Widget test ortamında native ses sürücüsü çağrılmaz
    try {
      final assetPath = _soundAssetMap[key];
      if (assetPath == null) return;
      _player.play(AssetSource(assetPath), mode: PlayerMode.lowLatency).catchError((e) {
        debugPrint('SoundFx $key çalma hatası: $e');
      });
    } catch (e) {
      debugPrint('SoundFx genel hatası: $e');
    }
  }
}
