import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static final SettingsService instance = SettingsService._internal();
  SettingsService._internal();

  static const String _keyAssisted = 'yanik_offline_assisted';
  static const String _keySound = 'yanik_offline_sound';
  static const String _keyVibration = 'yanik_offline_vibration';
  static const String _keyPlayerName = 'yanik_offline_player_name';
  static const String _keyPlayerAvatar = 'yanik_offline_player_avatar';

  bool _isAssisted = true; // true = Yardımlı Mod (varsayılan), false = Yardımsız Mod
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _playerName = 'Oyuncu';
  String _playerAvatar = 'lion';

  bool get isAssisted => _isAssisted;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  String get playerName => _playerName;
  String get playerAvatar => _playerAvatar;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isAssisted = prefs.getBool(_keyAssisted) ?? true;
    _soundEnabled = prefs.getBool(_keySound) ?? true;
    _vibrationEnabled = prefs.getBool(_keyVibration) ?? true;
    _playerName = prefs.getString(_keyPlayerName) ?? 'Oyuncu';
    _playerAvatar = prefs.getString(_keyPlayerAvatar) ?? 'lion';
    notifyListeners();
  }

  Future<void> setAssisted(bool value) async {
    _isAssisted = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAssisted, value);
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySound, value);
  }

  Future<void> setVibrationEnabled(bool value) async {
    _vibrationEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyVibration, value);
  }

  Future<void> setPlayerProfile({required String name, required String avatar}) async {
    _playerName = name.trim().isEmpty ? 'Oyuncu' : name.trim();
    _playerAvatar = avatar;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPlayerName, _playerName);
    await prefs.setString(_keyPlayerAvatar, _playerAvatar);
  }
}
