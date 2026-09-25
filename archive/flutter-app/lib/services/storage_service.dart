import 'dart:convert';
import 'package:athan_app_v2/models/settings.dart';
import 'package:athan_app_v2/models/recitation_plan.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _settingsKey = 'app_settings';
  static const String _recitationPlanKey = 'recitation_plans';
  static final StorageService _instance = StorageService._internal();
  SharedPreferences? _prefs;

  factory StorageService() {
    return _instance;
  }

  StorageService._internal();

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Settings Methods
  Future<AppSettings> getSettings() async {
    await initialize();
    final String? jsonData = _prefs?.getString(_settingsKey);
    if (jsonData == null || jsonData.isEmpty) {
      return AppSettings();
    }
    try {
      final Map<String, dynamic> data = json.decode(jsonData);
      return AppSettings.fromJson(data);
    } catch (e) {
      return AppSettings();
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    await initialize();
    final String jsonData = json.encode(settings.toJson());
    await _prefs?.setString(_settingsKey, jsonData);
  }

  // Recitation Plan Methods
  Future<Map<String, dynamic>> _getAllRecitationPlans() async {
    await initialize();
    final String? jsonData = _prefs?.getString(_recitationPlanKey);
    if (jsonData == null || jsonData.isEmpty) {
      return {};
    }
    try {
      return json.decode(jsonData) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  Future<MonthlyRecitationPlan> getMonthlyPlan(int year, int month) async {
    final allPlans = await _getAllRecitationPlans();
    final key = '$year-${month.toString().padLeft(2, '0')}';
    if (!allPlans.containsKey(key)) {
      return MonthlyRecitationPlan.empty(year, month);
    }
    try {
      return MonthlyRecitationPlan.fromJson(
          allPlans[key] as Map<String, dynamic>);
    } catch (e) {
      return MonthlyRecitationPlan.empty(year, month);
    }
  }

  Future<void> saveMonthlyPlan(MonthlyRecitationPlan plan) async {
    await initialize();
    final allPlans = await _getAllRecitationPlans();
    final key = '${plan.year}-${plan.month.toString().padLeft(2, '0')}';
    allPlans[key] = plan.toJson();
    await _prefs?.setString(_recitationPlanKey, json.encode(allPlans));
  }

  Future<void> saveDailyPlan(
      DateTime date, DailyRecitationPlan dailyPlan) async {
    final monthPlan = await getMonthlyPlan(date.year, date.month);
    final updatedPlan = monthPlan.updateDailyPlan(date, dailyPlan);
    await saveMonthlyPlan(updatedPlan);
  }

  Future<DailyRecitationPlan> getDailyPlan(DateTime date) async {
    final monthPlan = await getMonthlyPlan(date.year, date.month);
    return monthPlan.getDailyPlan(date);
  }

  Future<void> clearAllRecitationPlans() async {
    await initialize();
    await _prefs?.remove(_recitationPlanKey);
  }
}
