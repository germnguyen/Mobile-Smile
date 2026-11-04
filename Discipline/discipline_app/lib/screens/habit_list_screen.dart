import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/date_selector_strip.dart';
import '../widgets/habit_card.dart';
import '../widgets/today_summary_card.dart';

class HabitListScreen extends StatelessWidget {
  final VoidCallback onAddHabit;
  final Function(Habit) onEditHabit;

  const HabitListScreen({
    super.key,
    required this.onAddHabit,
    required this.onEditHabit,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<HabitProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          );
        }

        final selectedDate = provider.selectedDate;
        final habits = provider.habits;
        final completedCount = provider.getCompletedCountForDate(selectedDate);
        final completionRate = provider.getCompletionRateForDate(selectedDate);

        return Scaffold(
          backgroundColor: AppTheme.scaffoldBg,
          appBar: AppBar(
            title: const Row(
              children: [
                Icon(Icons.shield_outlined, color: AppTheme.primaryColor, size: 26),
                SizedBox(width: 8),
                Text(
                  'Kỷ Luật Bản Thân',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_circle, color: AppTheme.primaryColor, size: 28),
                tooltip: 'Thêm thói quen mới',
                onPressed: onAddHabit,
              ),
            ],
          ),
          body: RefreshIndicator(
            color: AppTheme.primaryColor,
            onRefresh: () async {
              await provider.init();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                // Motivational Summary Card
                TodaySummaryCard(
                  selectedDate: selectedDate,
                  completedCount: completedCount,
                  totalCount: habits.length,
                  rate: completionRate,
                ),

                // Horizontal Date Selector (7 days)
                DateSelectorStrip(
                  selectedDate: selectedDate,
                  onDateSelected: (date) {
                    provider.setSelectedDate(date);
                  },
                ),

                const SizedBox(height: 12),

                // Header for Habit list
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Danh sách mục tiêu',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '$completedCount/${habits.length} hoàn thành',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                // Habit List or Empty State
                if (habits.isEmpty)
                  _buildEmptyState(context)
                else
                  ...habits.map((habit) {
                    final isCompleted = provider.isHabitCompletedOn(habit.id, selectedDate);
                    final streak = provider.calculateStreak(habit.id);

                    return HabitCard(
                      habit: habit,
                      isCompleted: isCompleted,
                      streak: streak,
                      onToggle: () {
                        provider.toggleHabitCompletion(habit.id, selectedDate);
                      },
                      onEdit: () => onEditHabit(habit),
                      onDelete: () {
                        provider.deleteHabit(habit.id);
                      },
                    );
                  }),

                const SizedBox(height: 80), // spacing for FAB / Bottom Nav
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            elevation: 3,
            onPressed: onAddHabit,
            icon: const Icon(Icons.add),
            label: const Text('Thêm thói quen', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.format_list_bulleted_add,
              size: 48,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Chưa có thói quen nào',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Kỷ luật là cầu nối giữa mục tiêu và thành tựu. Hãy thêm thói quen đầu tiên để bắt đầu ngay hôm nay!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onAddHabit,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Tạo thói quen ngay'),
          ),
        ],
      ),
    );
  }
}
