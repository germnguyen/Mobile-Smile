import 'package:flutter/foundation.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../services/storage_service.dart';

class DailyStat {
  final DateTime date;
  final String dateString;
  final String dayLabel; // e.g. "T2", "T3", "CN"
  final int completedCount;
  final int totalCount;
  final double rate; // 0.0 to 1.0

  DailyStat({
    required this.date,
    required this.dateString,
    required this.dayLabel,
    required this.completedCount,
    required this.totalCount,
    required this.rate,
  });
}

class MonthlyStat {
  final int year;
  final int month;
  final int totalHabits;
  final int totalCompletions;
  final int totalDaysLogged;
  final double averageRate;
  final String? bestHabitTitle;

  MonthlyStat({
    required this.year,
    required this.month,
    required this.totalHabits,
    required this.totalCompletions,
    required this.totalDaysLogged,
    required this.averageRate,
    this.bestHabitTitle,
  });
}

class HabitProvider extends ChangeNotifier {
  final StorageService _storageService;

  List<Habit> _habits = [];
  List<HabitLog> _logs = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;

  HabitProvider({StorageService? storageService})
      : _storageService = storageService ?? StorageService() {
    init();
  }

  List<Habit> get habits => List.unmodifiable(_habits);
  List<HabitLog> get logs => List.unmodifiable(_logs);
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;

  /// Initialize and load data from local storage
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    _habits = await _storageService.loadHabits();
    _logs = await _storageService.loadHabitLogs();

    _isLoading = false;
    notifyListeners();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  // ==================== CRUD OPERATIONS ====================

  Future<void> addHabit(Habit habit) async {
    _habits.add(habit);
    await _storageService.saveHabits(_habits);
    notifyListeners();
  }

  Future<void> updateHabit(Habit updatedHabit) async {
    final index = _habits.indexWhere((h) => h.id == updatedHabit.id);
    if (index != -1) {
      _habits[index] = updatedHabit;
      await _storageService.saveHabits(_habits);
      notifyListeners();
    }
  }

  Future<void> deleteHabit(String habitId) async {
    _habits.removeWhere((h) => h.id == habitId);
    _logs.removeWhere((l) => l.habitId == habitId);
    await _storageService.saveHabits(_habits);
    await _storageService.saveHabitLogs(_logs);
    notifyListeners();
  }

  // ==================== CHECK-IN COMPLETION ====================

  Future<void> toggleHabitCompletion(String habitId, DateTime date) async {
    final dateStr = HabitLog.formatDate(date);
    final existingIndex = _logs.indexWhere(
      (l) => l.habitId == habitId && l.date == dateStr,
    );

    if (existingIndex != -1) {
      // Remove log (uncheck)
      _logs.removeAt(existingIndex);
    } else {
      // Add completion log (check)
      final newLog = HabitLog(
        id: '${habitId}_${dateStr}_${DateTime.now().millisecondsSinceEpoch}',
        habitId: habitId,
        date: dateStr,
        completedAt: DateTime.now(),
      );
      _logs.add(newLog);
    }

    await _storageService.saveHabitLogs(_logs);
    notifyListeners();
  }

  bool isHabitCompletedOn(String habitId, DateTime date) {
    final dateStr = HabitLog.formatDate(date);
    return _logs.any((l) => l.habitId == habitId && l.date == dateStr);
  }

  // ==================== STREAKS & METRICS ====================

  /// Calculates current consecutive days streak for a habit
  int calculateStreak(String habitId) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayStr = HabitLog.formatDate(today);

    final completedToday = _logs.any((l) => l.habitId == habitId && l.date == todayStr);

    int streak = 0;
    DateTime checkDate = completedToday ? today : today.subtract(const Duration(days: 1));

    while (true) {
      final dateStr = HabitLog.formatDate(checkDate);
      final hasCompleted = _logs.any((l) => l.habitId == habitId && l.date == dateStr);
      if (hasCompleted) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  /// Calculates the best (maximum) streak a habit has ever achieved
  int calculateBestStreak(String habitId) {
    final habitLogs = _logs
        .where((l) => l.habitId == habitId)
        .map((l) => DateTime.parse(l.date))
        .toList();

    if (habitLogs.isEmpty) return 0;

    habitLogs.sort((a, b) => a.compareTo(b));

    // Remove duplicates if any
    final uniqueDates = <DateTime>[];
    for (var d in habitLogs) {
      final clean = DateTime(d.year, d.month, d.day);
      if (uniqueDates.isEmpty || uniqueDates.last != clean) {
        uniqueDates.add(clean);
      }
    }

    int maxStreak = 1;
    int currentStreak = 1;

    for (int i = 1; i < uniqueDates.length; i++) {
      final diff = uniqueDates[i].difference(uniqueDates[i - 1]).inDays;
      if (diff == 1) {
        currentStreak++;
        if (currentStreak > maxStreak) {
          maxStreak = currentStreak;
        }
      } else if (diff > 1) {
        currentStreak = 1;
      }
    }

    return maxStreak;
  }

  // ==================== ANALYTICS & STATS ====================

  /// Completion rate for a specific date (0.0 to 1.0)
  double getCompletionRateForDate(DateTime date) {
    if (_habits.isEmpty) return 0.0;
    final dateStr = HabitLog.formatDate(date);
    final completedCount = _logs.where((l) => l.date == dateStr).length;
    return (completedCount / _habits.length).clamp(0.0, 1.0);
  }

  int getCompletedCountForDate(DateTime date) {
    final dateStr = HabitLog.formatDate(date);
    return _logs.where((l) => l.date == dateStr).length;
  }

  /// 7-day stats ending today (or custom anchor)
  List<DailyStat> getWeeklyStats([DateTime? anchor]) {
    final anchorDate = anchor ?? DateTime.now();
    final cleanAnchor = DateTime(anchorDate.year, anchorDate.month, anchorDate.day);
    final List<DailyStat> stats = [];

    final dayNames = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    for (int i = 6; i >= 0; i--) {
      final d = cleanAnchor.subtract(Duration(days: i));
      final dateStr = HabitLog.formatDate(d);
      final completed = _logs.where((l) => l.date == dateStr).length;
      final total = _habits.length;
      final rate = total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;
      final dayLabel = dayNames[d.weekday - 1];

      stats.add(
        DailyStat(
          date: d,
          dateString: dateStr,
          dayLabel: dayLabel,
          completedCount: completed,
          totalCount: total,
          rate: rate,
        ),
      );
    }

    return stats;
  }

  /// Monthly stats for a given month/year
  MonthlyStat getMonthlyStats([DateTime? anchor]) {
    final now = anchor ?? DateTime.now();
    final year = now.year;
    final month = now.month;

    // Filter logs for this month
    final monthPrefix = '$year-${month.toString().padLeft(2, '0')}';
    final monthLogs = _logs.where((l) => l.date.startsWith(monthPrefix)).toList();

    // Unique days in this month where at least one habit was completed
    final uniqueLoggedDays = monthLogs.map((l) => l.date).toSet().length;

    // Days elapsed so far this month (up to today or days in month)
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final currentDay = (now.year == DateTime.now().year && now.month == DateTime.now().month)
        ? DateTime.now().day
        : daysInMonth;

    final potentialCompletions = _habits.length * currentDay;
    final avgRate = potentialCompletions > 0
        ? (monthLogs.length / potentialCompletions).clamp(0.0, 1.0)
        : 0.0;

    // Find best habit
    String? bestTitle;
    int highestCount = 0;
    for (var habit in _habits) {
      final count = monthLogs.where((l) => l.habitId == habit.id).length;
      if (count > highestCount) {
        highestCount = count;
        bestTitle = habit.title;
      }
    }

    return MonthlyStat(
      year: year,
      month: month,
      totalHabits: _habits.length,
      totalCompletions: monthLogs.length,
      totalDaysLogged: uniqueLoggedDays,
      averageRate: avgRate,
      bestHabitTitle: bestTitle,
    );
  }
}

