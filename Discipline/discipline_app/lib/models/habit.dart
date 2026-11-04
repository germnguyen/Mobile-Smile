class Habit {
  final String id;
  final String title;
  final String description;
  final String frequency; // 'daily', 'weekdays', 'weekends'
  final String reminderTime; // e.g. "07:00"
  final DateTime createdAt;
  final int? colorValue;

  Habit({
    required this.id,
    required this.title,
    this.description = '',
    this.frequency = 'daily',
    this.reminderTime = '08:00',
    DateTime? createdAt,
    this.colorValue,
  }) : createdAt = createdAt ?? DateTime.now();

  Habit copyWith({
    String? id,
    String? title,
    String? description,
    String? frequency,
    String? reminderTime,
    DateTime? createdAt,
    int? colorValue,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      reminderTime: reminderTime ?? this.reminderTime,
      createdAt: createdAt ?? this.createdAt,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'frequency': frequency,
      'reminderTime': reminderTime,
      'createdAt': createdAt.toIso8601String(),
      'colorValue': colorValue,
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      title: json['title'] as String,
      description: (json['description'] as String?) ?? '',
      frequency: (json['frequency'] as String?) ?? 'daily',
      reminderTime: (json['reminderTime'] as String?) ?? '08:00',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      colorValue: json['colorValue'] as int?,
    );
  }

  /// Helper to get user-friendly frequency label in Vietnamese
  String get frequencyLabel {
    switch (frequency) {
      case 'weekdays':
        return 'Thứ 2 - Thứ 6';
      case 'weekends':
        return 'Cuối tuần';
      case 'daily':
      default:
        return 'Mỗi ngày';
    }
  }
}

