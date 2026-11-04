import 'package:flutter/material.dart';
import '../providers/habit_provider.dart';
import '../theme/app_theme.dart';

class WeeklyBarChart extends StatelessWidget {
  final List<DailyStat> weeklyStats;

  const WeeklyBarChart({super.key, required this.weeklyStats});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Biểu đồ 7 ngày gần nhất',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                'Tỷ lệ hoàn thành',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 140,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weeklyStats.map((stat) {
                final isToday = stat.date.year == now.year &&
                    stat.date.month == now.month &&
                    stat.date.day == now.day;

                final percentage = (stat.rate * 100).toInt();

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Percentage / count text
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: stat.rate > 0 ? AppTheme.primaryColor : AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Bar
                    Container(
                      width: 24,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.bottomCenter,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 24,
                        height: (80 * stat.rate).clamp(stat.rate > 0 ? 6.0 : 0.0, 80.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isToday
                                ? [AppTheme.accentColor, const Color(0xFF818CF8)]
                                : [AppTheme.primaryColor, AppTheme.primaryLight],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Day Label
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isToday ? AppTheme.primaryColor.withOpacity(0.12) : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        stat.dayLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                          color: isToday ? AppTheme.primaryColor : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
