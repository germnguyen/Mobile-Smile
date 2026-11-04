class HabitLog {
  final String id;
  final String habitId;
  final String date; // Format: 'yyyy-MM-dd'
  final DateTime completedAt;

  HabitLog({
    required this.id,
    required this.habitId,
    required this.date,
    DateTime? completedAt,
  }) : completedAt = completedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'habitId': habitId,
      'date': date,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  factory HabitLog.fromJson(Map<String, dynamic> json) {
    return HabitLog(
      id: json['id'] as String,
      habitId: json['habitId'] as String,
      date: json['date'] as String,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : DateTime.now(),
    );
  }

  /// Helper to format a DateTime into 'yyyy-MM-dd' string
  static String formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
