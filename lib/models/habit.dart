class HabitStats {
  final double consistency; // 0.0–1.0
  final int currentStreak;
  final int longestStreak;
  final int totalDone;
  final int totalActive;

  const HabitStats({
    required this.consistency,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalDone,
    required this.totalActive,
  });

  int get consistencyPercent => (consistency * 100).round();
}

class Habit {
  final String id;
  final String name;
  final int? activeDays;
  final int? restDays;
  final DateTime startDate;
  final Map<String, bool> completions;
  final int? reminderHour;
  final int? reminderMinute;

  const Habit({
    required this.id,
    required this.name,
    this.activeDays,
    this.restDays,
    required this.startDate,
    this.completions = const {},
    this.reminderHour,
    this.reminderMinute,
  });

  bool get hasFrequency => activeDays != null && restDays != null;
  bool get hasReminder => reminderHour != null;

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  int _daysSinceStart(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final s = DateTime(startDate.year, startDate.month, startDate.day);
    return d.difference(s).inDays;
  }

  bool isBeforeStart(DateTime date) => _daysSinceStart(date) < 0;

  bool isRestDay(DateTime date) {
    if (!hasFrequency) return false;
    final days = _daysSinceStart(date);
    if (days < 0) return false;
    return days % (activeDays! + restDays!) >= activeDays!;
  }

  bool isRestTomorrow(DateTime date) {
    if (!hasFrequency) return false;
    final days = _daysSinceStart(date);
    if (days < 0) return false;
    final pos = days % (activeDays! + restDays!);
    return pos == activeDays! - 1;
  }

  bool isCompleted(DateTime date) => completions[_dateKey(date)] ?? false;

  Habit withCompletion(DateTime date, bool value) {
    final updated = Map<String, bool>.from(completions);
    updated[_dateKey(date)] = value;
    return copyWith(completions: updated);
  }

  HabitStats stats(DateTime upTo) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(upTo.year, upTo.month, upTo.day);

    if (end.isBefore(start)) {
      return const HabitStats(
        consistency: 0,
        currentStreak: 0,
        longestStreak: 0,
        totalDone: 0,
        totalActive: 0,
      );
    }

    int totalActive = 0;
    int totalDone = 0;
    int longestStreak = 0;
    int tempStreak = 0;

    DateTime d = start;
    while (!d.isAfter(end)) {
      if (!isRestDay(d)) {
        totalActive++;
        if (isCompleted(d)) {
          totalDone++;
          tempStreak++;
          if (tempStreak > longestStreak) longestStreak = tempStreak;
        } else {
          tempStreak = 0;
        }
      }
      d = d.add(const Duration(days: 1));
    }

    int currentStreak = 0;
    d = end;
    while (!d.isBefore(start)) {
      if (isRestDay(d)) {
        d = d.subtract(const Duration(days: 1));
        continue;
      }
      if (!isCompleted(d)) break;
      currentStreak++;
      d = d.subtract(const Duration(days: 1));
    }

    return HabitStats(
      consistency: totalActive > 0 ? totalDone / totalActive : 0,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      totalDone: totalDone,
      totalActive: totalActive,
    );
  }

  Habit copyWith({
    String? name,
    DateTime? startDate,
    int? activeDays,
    int? restDays,
    bool clearFrequency = false,
    int? reminderHour,
    int? reminderMinute,
    bool clearReminder = false,
    Map<String, bool>? completions,
  }) => Habit(
    id: id,
    name: name ?? this.name,
    activeDays: clearFrequency ? null : (activeDays ?? this.activeDays),
    restDays: clearFrequency ? null : (restDays ?? this.restDays),
    startDate: startDate ?? this.startDate,
    completions: completions ?? this.completions,
    reminderHour: clearReminder ? null : (reminderHour ?? this.reminderHour),
    reminderMinute: clearReminder
        ? null
        : (reminderMinute ?? this.reminderMinute),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'activeDays': activeDays,
    'restDays': restDays,
    'startDate': startDate.toIso8601String(),
    'completions': completions,
    'reminderHour': reminderHour,
    'reminderMinute': reminderMinute,
  };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
    id: json['id'] as String,
    name: json['name'] as String,
    activeDays: json['activeDays'] as int?,
    restDays: json['restDays'] as int?,
    startDate: DateTime.parse(json['startDate'] as String),
    completions: Map<String, bool>.from((json['completions'] as Map?) ?? {}),
    reminderHour: json['reminderHour'] as int?,
    reminderMinute: json['reminderMinute'] as int?,
  );
}
