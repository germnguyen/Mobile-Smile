import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_summary_card.dart';
import '../widgets/weekly_bar_chart.dart';

enum StatPeriod { day, week, month }

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  StatPeriod _selectedPeriod = StatPeriod.day;

  @override
  Widget build(BuildContext context) {
    return Consumer<HabitProvider>(
      builder: (context, provider, child) {
        final habits = provider.habits;
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        // Calculate maximum streak across all habits
        int overallBestStreak = 0;
        for (var h in habits) {
          final s = provider.calculateBestStreak(h.id);
          if (s > overallBestStreak) {
            overallBestStreak = s;
          }
        }

        final todayRate = provider.getCompletionRateForDate(today);
        final todayCompleted = provider.getCompletedCountForDate(today);

        return Scaffold(
          backgroundColor: AppTheme.scaffoldBg,
          appBar: AppBar(
            title: const Row(
              children: [
                Icon(Icons.insights, color: AppTheme.primaryColor, size: 26),
                SizedBox(width: 8),
                Text(
                  'Thống Kê Kỷ Luật',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ],
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // High-level KPI Summary Grid
              Row(
                children: [
                  Expanded(
                    child: StatSummaryCard(
                      title: 'Tổng thói quen',
                      value: '${habits.length}',
                      icon: Icons.checklist,
                      iconColor: AppTheme.primaryColor,
                      bgColor: AppTheme.primaryColor.withOpacity(0.12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatSummaryCard(
                      title: 'Chuỗi kỷ lục',
                      value: '$overallBestStreak ngày',
                      icon: Icons.local_fire_department,
                      iconColor: const Color(0xFFD97706),
                      bgColor: const Color(0xFFFEF3C7),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Segmented Tab for Period: Day / Week / Month
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _buildSegmentButton(StatPeriod.day, 'Theo Ngày'),
                    _buildSegmentButton(StatPeriod.week, 'Theo Tuần'),
                    _buildSegmentButton(StatPeriod.month, 'Theo Tháng'),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Dynamic content based on selected period
              if (_selectedPeriod == StatPeriod.day)
                _buildDayStatistics(context, provider, today, todayRate, todayCompleted)
              else if (_selectedPeriod == StatPeriod.week)
                _buildWeekStatistics(context, provider, today)
              else
                _buildMonthStatistics(context, provider, today),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSegmentButton(StatPeriod period, String title) {
    final isSelected = _selectedPeriod == period;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPeriod = period;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // ================= 1. DAY STATISTICS =================
  Widget _buildDayStatistics(
    BuildContext context,
    HabitProvider provider,
    DateTime today,
    double rate,
    int completedCount,
  ) {
    final habits = provider.habits;
    final percentage = (rate * 100).toInt();

    final completedHabits = habits.where((h) => provider.isHabitCompletedOn(h.id, today)).toList();
    final pendingHabits = habits.where((h) => !provider.isHabitCompletedOn(h.id, today)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Today Completion Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tiến độ hôm nay',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd/MM/yyyy').format(today),
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  Text(
                    '$percentage%',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: rate,
                  minHeight: 12,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Đã hoàn thành $completedCount trên tổng số ${habits.length} thói quen',
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Completed vs Pending breakdown
        if (completedHabits.isNotEmpty) ...[
          const Text(
            '✅ Đã hoàn thành',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          ...completedHabits.map((h) => _buildHabitStatusTile(h.title, h.reminderTime, true)),
          const SizedBox(height: 16),
        ],

        if (pendingHabits.isNotEmpty) ...[
          const Text(
            '⏳ Chưa hoàn thành',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          ...pendingHabits.map((h) => _buildHabitStatusTile(h.title, h.reminderTime, false)),
        ],

        if (habits.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('Chưa có thói quen nào để thống kê.', style: TextStyle(color: AppTheme.textSecondary)),
            ),
          ),
      ],
    );
  }

  Widget _buildHabitStatusTile(String title, String reminderTime, bool isCompleted) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isCompleted ? AppTheme.successColor : AppTheme.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isCompleted ? AppTheme.textPrimary : AppTheme.textSecondary,
              ),
            ),
          ),
          Text(
            reminderTime,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  // ================= 2. WEEK STATISTICS =================
  Widget _buildWeekStatistics(BuildContext context, HabitProvider provider, DateTime today) {
    final weeklyStats = provider.getWeeklyStats(today);

    // Calculate weekly average
    double totalRate = 0;
    int perfectDays = 0;
    int totalCompletionsThisWeek = 0;

    for (var s in weeklyStats) {
      totalRate += s.rate;
      totalCompletionsThisWeek += s.completedCount;
      if (s.rate >= 1.0 && s.totalCount > 0) {
        perfectDays++;
      }
    }

    final avgWeeklyRate = (totalRate / 7 * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 7-day Bar Chart
        WeeklyBarChart(weeklyStats: weeklyStats),

        const SizedBox(height: 16),

        // Summary metrics
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              _buildMetricRow('Tỷ lệ hoàn thành tuần', '$avgWeeklyRate%', AppTheme.primaryColor),
              const Divider(height: 24),
              _buildMetricRow('Tổng số lần hoàn thành', '$totalCompletionsThisWeek lần', AppTheme.textPrimary),
              const Divider(height: 24),
              _buildMetricRow('Số ngày đạt 100%', '$perfectDays / 7 ngày', AppTheme.successColor),
            ],
          ),
        ),
      ],
    );
  }

  // ================= 3. MONTH STATISTICS =================
  Widget _buildMonthStatistics(BuildContext context, HabitProvider provider, DateTime today) {
    final monthStat = provider.getMonthlyStats(today);
    final percentage = (monthStat.averageRate * 100).toInt();

    String disciplineGrade;
    Color gradeColor;
    if (percentage >= 80) {
      disciplineGrade = 'Xuất sắc 🌟';
      gradeColor = AppTheme.successColor;
    } else if (percentage >= 50) {
      disciplineGrade = 'Khá tốt 👍';
      gradeColor = AppTheme.primaryColor;
    } else {
      disciplineGrade = 'Cần cố gắng thêm 💪';
      gradeColor = const Color(0xFFD97706);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF312E81), Color(0xFF4338CA)], // Indigo
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tháng ${monthStat.month}/${monthStat.year}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      disciplineGrade,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tỷ lệ tháng: $percentage%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${monthStat.totalCompletions} lượt hoàn thành trong tháng',
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              _buildMetricRow('Số ngày hoạt động', '${monthStat.totalDaysLogged} ngày', AppTheme.primaryColor),
              const Divider(height: 24),
              _buildMetricRow(
                'Thói quen kiên trì nhất',
                monthStat.bestHabitTitle ?? 'Chưa có',
                AppTheme.accentColor,
              ),
              const Divider(height: 24),
              _buildMetricRow('Đánh giá kỷ luật', disciplineGrade, gradeColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: valueColor),
        ),
      ],
    );
  }
}
