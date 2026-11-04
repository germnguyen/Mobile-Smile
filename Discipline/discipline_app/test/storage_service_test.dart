import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:discipline_app/models/habit.dart';
import 'package:discipline_app/models/habit_log.dart';
import 'package:discipline_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Habit and HabitLog Models', () {
    test('Habit serialization and deserialization', () {
      final habit = Habit(
        id: 'habit-1',
        title: 'Chạy bộ buổi sáng',
        description: 'Chạy ít nhất 30 phút quanh công viên',
        frequency: 'daily',
        reminderTime: '06:30',
        createdAt: DateTime(2026, 11, 4, 6, 0),
      );

      final json = habit.toJson();
      final fromJson = Habit.fromJson(json);

      expect(fromJson.id, 'habit-1');
      expect(fromJson.title, 'Chạy bộ buổi sáng');
      expect(fromJson.description, 'Chạy ít nhất 30 phút quanh công viên');
      expect(fromJson.frequency, 'daily');
      expect(fromJson.reminderTime, '06:30');
      expect(fromJson.frequencyLabel, 'Mỗi ngày');
    });

    test('HabitLog serialization and date formatting', () {
      final date = DateTime(2026, 11, 4);
      final formatted = HabitLog.formatDate(date);
      expect(formatted, '2026-11-04');

      final log = HabitLog(
        id: 'log-1',
        habitId: 'habit-1',
        date: formatted,
      );

      final json = log.toJson();
      final fromJson = HabitLog.fromJson(json);

      expect(fromJson.id, 'log-1');
      expect(fromJson.habitId, 'habit-1');
      expect(fromJson.date, '2026-11-04');
    });
  });

  group('StorageService tests', () {
    late StorageService storageService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storageService = StorageService();
    });

    test('Save and load habits', () async {
      final habits = [
        Habit(id: '1', title: 'Đọc sách 20 trang', reminderTime: '21:00'),
        Habit(id: '2', title: 'Uống 2L nước', reminderTime: '09:00'),
      ];

      await storageService.saveHabits(habits);
      final loaded = await storageService.loadHabits();

      expect(loaded.length, 2);
      expect(loaded[0].title, 'Đọc sách 20 trang');
      expect(loaded[1].title, 'Uống 2L nước');
    });

    test('Save and load habit logs', () async {
      final logs = [
        HabitLog(id: 'l1', habitId: '1', date: '2026-11-04'),
        HabitLog(id: 'l2', habitId: '2', date: '2026-11-04'),
      ];

      await storageService.saveHabitLogs(logs);
      final loaded = await storageService.loadHabitLogs();

      expect(loaded.length, 2);
      expect(loaded[0].habitId, '1');
      expect(loaded[1].habitId, '2');
    });

    test('Clear all storage', () async {
      await storageService.saveHabits([Habit(id: '1', title: 'Test')]);
      await storageService.saveHabitLogs([HabitLog(id: 'l1', habitId: '1', date: '2026-11-04')]);

      await storageService.clearAll();

      final habits = await storageService.loadHabits();
      final logs = await storageService.loadHabitLogs();

      expect(habits, isEmpty);
      expect(logs, isEmpty);
    });
  });
}
