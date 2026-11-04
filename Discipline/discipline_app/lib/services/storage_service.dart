import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';

class StorageService {
  static const String _habitsKey = 'habits_data';
  static const String _habitLogsKey = 'habit_logs_data';

  final SharedPreferences? _prefs;

  StorageService([this._prefs]);

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ?? await SharedPreferences.getInstance();
  }

  /// Load all saved habits
  Future<List<Habit>> loadHabits() async {
    final prefs = await _getPrefs();
    final jsonString = prefs.getString(_habitsKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded
          .map((item) => Habit.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Save list of habits
  Future<bool> saveHabits(List<Habit> habits) async {
    final prefs = await _getPrefs();
    final rawList = habits.map((h) => h.toJson()).toList();
    final jsonString = jsonEncode(rawList);
    return prefs.setString(_habitsKey, jsonString);
  }

  /// Load all habit logs (daily completions)
  Future<List<HabitLog>> loadHabitLogs() async {
    final prefs = await _getPrefs();
    final jsonString = prefs.getString(_habitLogsKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded
          .map((item) => HabitLog.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Save list of habit logs
  Future<bool> saveHabitLogs(List<HabitLog> logs) async {
    final prefs = await _getPrefs();
    final rawList = logs.map((l) => l.toJson()).toList();
    final jsonString = jsonEncode(rawList);
    return prefs.setString(_habitLogsKey, jsonString);
  }

  /// Clear all stored data
  Future<bool> clearAll() async {
    final prefs = await _getPrefs();
    await prefs.remove(_habitsKey);
    await prefs.remove(_habitLogsKey);
    return true;
  }
}

