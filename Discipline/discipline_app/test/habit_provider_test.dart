import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:discipline_app/models/habit.dart';
import 'package:discipline_app/models/habit_log.dart';
import 'package:discipline_app/providers/habit_provider.dart';
import 'package:discipline_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storageService;
  late HabitProvider provider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storageService = StorageService();
    provider = HabitProvider(storageService: storageService);
    await provider.init();
  });

  group('HabitProvider CRUD', () {
    test('Add habit', () async {
      final habit = Habit(id: 'h1', title: 'Tập thể dục');
      await provider.addHabit(habit);

      expect(provider.habits.length, 1);
      expect(provider.habits.first.title, 'Tập thể dục');
    });

    test('Update habit', () async {
      final habit = Habit(id: 'h1', title: 'Tập thể dục');
      await provider.addHabit(habit);

      final updated = habit.copyWith(title: 'Tập gym 45 phút', reminderTime: '18:00');
      await provider.updateHabit(updated);

      expect(provider.habits.length, 1);
      expect(provider.habits.first.title, 'Tập gym 45 phút');
      expect(provider.habits.first.reminderTime, '18:00');
    });

    test('Delete habit', () async {
      final habit1 = Habit(id: 'h1', title: 'Tập thể dục');
      final habit2 = Habit(id: 'h2', title: 'Uống nước');
      await provider.addHabit(habit1);
      await provider.addHabit(habit2);

      await provider.toggleHabitCompletion('h1', DateTime.now());
      expect(provider.logs.length, 1);

      await provider.deleteHabit('h1');

      expect(provider.habits.length, 1);
      expect(provider.habits.first.id, 'h2');
      // Verify cascading delete of associated logs
      expect(provider.logs.where((l) => l.habitId == 'h1'), isEmpty);
    });
  });

  group('HabitProvider Completions & Streaks', () {
    test('Toggle completion on and off', () async {
      final habit = Habit(id: 'h1', title: 'Đọc sách');
      await provider.addHabit(habit);

      final today = DateTime.now();
      expect(provider.isHabitCompletedOn('h1', today), isFalse);

      // Check in
      await provider.toggleHabitCompletion('h1', today);
      expect(provider.isHabitCompletedOn('h1', today), isTrue);
      expect(provider.getCompletedCountForDate(today), 1);
      expect(provider.getCompletionRateForDate(today), 1.0);

      // Uncheck
      await provider.toggleHabitCompletion('h1', today);
      expect(provider.isHabitCompletedOn('h1', today), isFalse);
      expect(provider.getCompletedCountForDate(today), 0);
      expect(provider.getCompletionRateForDate(today), 0.0);
    });

    test('Streak calculation across consecutive days', () async {
      final habit = Habit(id: 'h1', title: 'Dậy sớm');
      await provider.addHabit(habit);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final twoDaysAgo = today.subtract(const Duration(days: 2));

      // 0 days initially
      expect(provider.calculateStreak('h1'), 0);

      // Complete 2 days ago and yesterday (today not yet completed)
      await provider.toggleHabitCompletion('h1', twoDaysAgo);
      await provider.toggleHabitCompletion('h1', yesterday);
      expect(provider.calculateStreak('h1'), 2);

      // Complete today as well -> streak is now 3
      await provider.toggleHabitCompletion('h1', today);
      expect(provider.calculateStreak('h1'), 3);
    });
  });

  group('HabitProvider Statistics (Day, Week, Month)', () {
    test('Empty habits list rate safety', () {
      expect(provider.getCompletionRateForDate(DateTime.now()), 0.0);
      final weekly = provider.getWeeklyStats();
      expect(weekly.length, 7);
      expect(weekly.every((d) => d.rate == 0.0), isTrue);

      final monthly = provider.getMonthlyStats();
      expect(monthly.averageRate, 0.0);
      expect(monthly.totalHabits, 0);
    });

    test('Weekly stats calculation', () async {
      final h1 = Habit(id: 'h1', title: 'H1');
      final h2 = Habit(id: 'h2', title: 'H2');
      await provider.addHabit(h1);
      await provider.addHabit(h2);

      final today = DateTime.now();
      await provider.toggleHabitCompletion('h1', today);

      final weekly = provider.getWeeklyStats(today);
      expect(weekly.length, 7);
      final todayStat = weekly.last;
      expect(todayStat.completedCount, 1);
      expect(todayStat.totalCount, 2);
      expect(todayStat.rate, 0.5);
    });

    test('Monthly stats calculation', () async {
      final h1 = Habit(id: 'h1', title: 'Thiền');
      await provider.addHabit(h1);

      final today = DateTime.now();
      await provider.toggleHabitCompletion('h1', today);

      final monthly = provider.getMonthlyStats(today);
      expect(monthly.totalHabits, 1);
      expect(monthly.totalCompletions, 1);
      expect(monthly.bestHabitTitle, 'Thiền');
    });
  });
}
