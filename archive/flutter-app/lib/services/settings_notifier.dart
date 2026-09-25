import 'dart:convert';
import 'package:athan_app_v2/models/settings.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global settings notifier to notify listeners when settings change
class SettingsNotifier extends ChangeNotifier {
  static final SettingsNotifier _instance = SettingsNotifier._internal();
  factory SettingsNotifier() => _instance;
  SettingsNotifier._internal();

  AppSettings _settings = AppSettings();
  AppSettings get settings => _settings;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('app_settings');
    if (settingsJson != null) {
      _settings = AppSettings.fromJson(json.decode(settingsJson));
      if (kDebugMode) {
        debugPrint(
            '📖 Loaded settings - Fajr adjustment: ${_settings.timeAdjustments.fajrAdjustment}');
      }
      notifyListeners();
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_settings', json.encode(settings.toJson()));
    _settings = settings;
    if (kDebugMode) {
      debugPrint(
          '💾 Saved settings - Fajr adjustment: ${_settings.timeAdjustments.fajrAdjustment}');
      debugPrint(
          '💾 Notifying ${hasListeners ? "listeners" : "NO listeners"}...');
    }
    notifyListeners();
  }
}

/// Global instance for easy access
final settingsNotifier = SettingsNotifier();
