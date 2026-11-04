import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class TodaySummaryCard extends StatelessWidget {
  final DateTime selectedDate;
  final int completedCount;
  final int totalCount;
  final double rate;

  const TodaySummaryCard({
    super.key,
    required this.selectedDate,
    required this.completedCount,
    required this.totalCount,
    required this.rate,
  });

  String _getMotivationalMessage(double completionRate, int total) {
    if (total == 0) {
      return 'Tạo thói quen mới để bắt đầu rèn luyện kỷ luật!';
    }
    if (completionRate == 0.0) {
      return 'Mỗi ngày mới là một cơ hội để tốt hơn hôm qua!';
    } else if (completionRate < 0.5) {
      return 'Khởi đầu tốt! Hãy tiếp tục duy trì đà tiến nhé.';
    } else if (completionRate < 1.0) {
      return 'Gần xong rồi! Cố gắng hoàn thành nốt các mục tiêu.';
    } else {
      return 'Xuất sắc! Bạn đã chinh phục 100% mục tiêu hôm nay 🎉';
    }
  }

  String _formatDateVietnamese(DateTime date) {
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    final dayOfWeek = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật'
    ][date.weekday - 1];

    final dateStr = DateFormat('dd/MM/yyyy').format(date);
    if (isToday) {
      return 'Hôm nay, $dayOfWeek ($dateStr)';
    }
    return '$dayOfWeek, $dateStr';
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (rate * 100).toInt();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F766E), // Deep Teal
            Color(0xFF0D9488), // Teal
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDateVietnamese(selectedDate),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  totalCount > 0 ? '$completedCount / $totalCount Hoàn thành' : 'Chưa có thói quen',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getMotivationalMessage(rate, totalCount),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Circular Progress Indicator
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  value: rate,
                  strokeWidth: 6,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              Text(
                '$percentage%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
