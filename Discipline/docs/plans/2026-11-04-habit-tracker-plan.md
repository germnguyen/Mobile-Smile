# Personal Discipline Habit Tracker Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a complete Flutter personal discipline / habit tracking mobile app that runs smoothly on Web with a responsive mobile phone frame, local storage via SharedPreferences, daily check-in UI, and comprehensive day/week/month statistics.

**Architecture:** Provider-based MVVM/Clean state architecture.
- **Data Layer:** `Habit` & `HabitLog` models + `StorageService` persisting JSON to `shared_preferences`.
- **State Layer:** `HabitProvider` handling CRUD, daily check-ins, streaks, and analytics queries.
- **UI Layer:** Responsive Mobile Wrapper frame (`ResponsiveMobileWrapper`) wrapping 2 main views: Habits List Screen (with daily check-in & quick day selector) and Statistics Screen (day/week/month rates), plus Add/Edit Habit Modal/Screen.

**Tech Stack:**
- Flutter 3.x (Dart 3.x)
- `provider: ^6.1.2` for reactive state management
- `shared_preferences: ^2.2.2` for cross-platform local storage (native Web & Mobile support)
- `intl: ^0.19.0` for Vietnamese/standard date & time formatting

**Spec:** User prompt requirements:
1. Habit list, Add/Edit habit, and Progress statistics screens.
2. Habit CRUD: name, description, frequency, reminder time.
3. Daily habit completion system with intuitive interactive UI.
4. Local storage with SQLite or SharedPreferences (using SharedPreferences for lightweight Web support).
5. Statistics screen showing completion rates by Day, Week, and Month.
6. Responsive web layout constrained to mobile dimensions for lightweight testing.
7. Git commit after every task.

## Global Constraints
- Minimal third-party dependencies (strictly `provider`, `shared_preferences`, `intl`).
- All interactive screens must fit gracefully within a centered phone frame on Web desktop browsers (`maxWidth: 450px`).
- Clean separation of concerns: models, services, providers, screens, widgets.
- Clean git commits after each individual task.

## Review Focus
1. Data persistence across browser reloads: Habit CRUD and daily completion logs must reload accurately from SharedPreferences.
2. Web responsiveness: On desktop browser viewports, the app must center with mobile dimensions without layout overflowing or clipping.
3. Accurate date parsing & matching: Check-ins must match date strings (`yyyy-MM-dd`) independent of device timezone shifts.
4. Statistics calculation: Completion rates for Day, Week (7 days), Month (current month) must handle empty states (0 habits created) without division by zero.
5. Form validation: Adding/editing habits must validate non-empty title and proper reminder time formatting.

---

### Task 1: Project Setup, Dependencies & Responsive Mobile Shell

**Files:**
- Modify: `discipline_app/pubspec.yaml`
- Create: `discipline_app/lib/theme/app_theme.dart`
- Create: `discipline_app/lib/widgets/responsive_mobile_wrapper.dart`
- Create: `discipline_app/lib/screens/main_navigation_screen.dart`
- Modify: `discipline_app/lib/main.dart`

**Steps:**
- [ ] Add `provider: ^6.1.2`, `shared_preferences: ^2.2.2`, and `intl: ^0.19.0` to `discipline_app/pubspec.yaml`.
- [ ] Run `flutter pub get` inside `discipline_app`.
- [ ] Define `AppTheme` with clean modern Material 3 styling (primary emerald/indigo discipline colors, card themes, rounded buttons).
- [ ] Implement `ResponsiveMobileWrapper` which centers content, constraints width to `450px`, and applies a subtle device frame border and shadow on wide screens.
- [ ] Create `MainNavigationScreen` featuring a `BottomNavigationBar` switching between "Thói quen" (Habits) and "Thống kê" (Statistics), plus a floating action button for "Thêm thói quen".
- [ ] Update `main.dart` to bootstrap the app with `ResponsiveMobileWrapper`.
- [ ] Commit changes: `feat: setup dependencies, theme, and responsive mobile shell`.

---

### Task 2: Data Models & Local Storage Service (SharedPreferences)

**Files:**
- Create: `discipline_app/lib/models/habit.dart`
- Create: `discipline_app/lib/models/habit_log.dart`
- Create: `discipline_app/lib/services/storage_service.dart`
- Create: `discipline_app/test/storage_service_test.dart`

**Steps:**
- [ ] Implement `Habit` model with fields: `id`, `title`, `description`, `frequency` ('daily', 'weekdays', 'weekends'), `reminderTime` (String 'HH:mm'), `createdAt` (DateTime), and `toJson`/`fromJson`.
- [ ] Implement `HabitLog` model with fields: `habitId`, `date` (format: 'yyyy-MM-dd'), `completedAt` (DateTime), and `toJson`/`fromJson`.
- [ ] Implement `StorageService` using `SharedPreferences`:
  - `saveHabits(List<Habit> habits)` / `loadHabits()`
  - `saveHabitLogs(List<HabitLog> logs)` / `loadHabitLogs()`
  - `clearAll()` (useful for test/reset)
- [ ] Write unit tests verifying serialization and deserialization of `Habit` and `HabitLog`.
- [ ] Run `flutter test test/storage_service_test.dart`.
- [ ] Commit changes: `feat: implement habit data models and shared preferences storage service`.

---

### Task 3: State Management with HabitProvider

**Files:**
- Create: `discipline_app/lib/providers/habit_provider.dart`
- Create: `discipline_app/test/habit_provider_test.dart`

**Steps:**
- [ ] Implement `HabitProvider` extending `ChangeNotifier`:
  - CRUD operations: `addHabit`, `updateHabit`, `deleteHabit`.
  - Check-in toggle: `toggleHabitCompletion(String habitId, DateTime date)`.
  - Query methods:
    - `isCompleted(String habitId, DateTime date)`
    - `getCompletionRateForDate(DateTime date)` -> double (0.0 to 1.0)
    - `getStreak(String habitId)` -> current consecutive days streak
    - `getWeeklyStats()` -> returns list of day stats for the past 7 days
    - `getMonthlyStats()` -> returns completion rate and total check-ins for the current month
  - Auto-initialization from `StorageService.loadHabits()` and `loadHabitLogs()`.
- [ ] Write unit tests for `HabitProvider` verifying CRUD, toggle completions, streaks, and stats calculations.
- [ ] Run `flutter test test/habit_provider_test.dart`.
- [ ] Commit changes: `feat: implement habit provider with streaks and statistics logic`.

---

### Task 4: Habit List Screen with Daily Check-In & Streak UI

**Files:**
- Create: `discipline_app/lib/widgets/date_selector_strip.dart`
- Create: `discipline_app/lib/widgets/habit_card.dart`
- Create: `discipline_app/lib/widgets/today_summary_card.dart`
- Create: `discipline_app/lib/screens/habit_list_screen.dart`

**Steps:**
- [ ] Create `TodaySummaryCard` displaying current date, circular/linear progress indicator of today's discipline completion rate, and motivational message.
- [ ] Create `DateSelectorStrip` allowing the user to tap across recent days (e.g., past 7 days) to view or check off habits for specific dates.
- [ ] Create `HabitCard` displaying:
  - Habit title and description
  - Frequency badge and reminder time chip
  - Current streak counter (e.g. "🔥 5 ngày")
  - Interactive completion toggle button with smooth visual feedback
  - Popup menu / action buttons for Edit and Delete (with confirmation dialog).
- [ ] Assemble `HabitListScreen` handling empty state ("Chưa có thói quen nào. Bấm + để tạo mới!"), pull-to-refresh, and smooth list scrolling.
- [ ] Commit changes: `feat: implement habit list screen with interactive check-in and streak badges`.

---

### Task 5: Add & Edit Habit Screen

**Files:**
- Create: `discipline_app/lib/screens/habit_form_screen.dart`

**Steps:**
- [ ] Implement `HabitFormScreen` supporting both Create (empty fields) and Edit (prefilled fields from existing `Habit`):
  - Form validation for habit title (required, max length).
  - Optional description input.
  - Frequency selector dropdown/segmented buttons ("Hàng ngày", "Ngày trong tuần", "Cuối tuần").
  - Reminder time picker dialog (`showTimePicker`) formatted nicely (e.g. "07:00 AM").
- [ ] Handle save action: call `HabitProvider.addHabit` or `updateHabit`, show confirmation `SnackBar`, and navigate back.
- [ ] Connect "Thêm thói quen" FloatingActionButton and HabitCard "Chỉnh sửa" action to open this screen.
- [ ] Commit changes: `feat: implement add and edit habit form with reminder time picker`.

---

### Task 6: Progress Statistics Screen (Day, Week, Month)

**Files:**
- Create: `discipline_app/lib/widgets/stat_summary_card.dart`
- Create: `discipline_app/lib/widgets/weekly_bar_chart.dart`
- Create: `discipline_app/lib/screens/statistics_screen.dart`

**Steps:**
- [ ] Create `StatSummaryCard` for high-level KPIs: Total Habits, Completed Today, Best Streak, Overall Discipline Score.
- [ ] Create `WeeklyBarChart` (pure Flutter custom widget, lightweight without heavy charting packages) showing completion percentage for each of the last 7 days.
- [ ] Build `StatisticsScreen` with TabBar / Segmented Button for:
  - **Theo Ngày (Day)**: Today's rate, list of completed habits vs habits remaining.
  - **Theo Tuần (Week)**: 7-day visual consistency bar chart, average weekly rate, most disciplined days.
  - **Theo Tháng (Month)**: Total monthly check-ins, monthly completion rate, habit consistency breakdown.
- [ ] Handle empty states when no habits or logs exist yet.
- [ ] Commit changes: `feat: implement progress statistics screen for day, week, and month`.

---

### Task 7: Integration, Verification & Web Compatibility Polish

**Files:**
- Modify: `discipline_app/lib/main.dart`
- Test: All unit and widget tests
- Documentation: `discipline_app/README.md`

**Steps:**
- [ ] Integrate `MultiProvider` in `main.dart` wrapping `MaterialApp` and `MainNavigationScreen`.
- [ ] Verify test suite passing: `flutter test`.
- [ ] Run `flutter analyze` to ensure zero errors and zero warnings.
- [ ] Test web build: `flutter build web --release` or verify web bundle generation.
- [ ] Update `README.md` with features description, screenshots/architecture details, and command instructions (`flutter run -d chrome`).
- [ ] Final commit: `feat: finalize discipline tracker app with responsive web support`.
