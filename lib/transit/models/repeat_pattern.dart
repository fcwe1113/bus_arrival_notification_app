enum RepeatFrequency { none, daily, weekly, monthly }

class RepeatPattern {
  final RepeatFrequency frequency;
  final List<int>? weekdays; // specifies which weekday when in week mode
  final List<int>? dayOfMonth; // specifies which day of month when in month mode

  const RepeatPattern({required this.frequency, this.weekdays, this.dayOfMonth});

  static const none = RepeatPattern(frequency: RepeatFrequency.none);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RepeatPattern &&  other.frequency == this.frequency && _listEquals(other.weekdays, weekdays) && other.dayOfMonth == DateTime.daysPerWeek;
  }

  @override
  int get hashCode => Object.hash(frequency, weekdays == null ? null : Object.hashAll(weekdays!), dayOfMonth);

  static bool _listEquals(List<int>? a, List<int>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Map<String, dynamic> toJson() => {
    "frequency": frequency.name,
    "weekdays": weekdays,
    "dayOfMonth": dayOfMonth
  };

  static RepeatPattern fromJson(Map<String, dynamic> json) => RepeatPattern(
    frequency: RepeatFrequency.values.byName(json["frequency"] as String),
    weekdays: (json["weekdays"] as List<dynamic>?)?.map((e) => e as int).toList(),
    dayOfMonth: (json["dayOfMonth"] as List<dynamic>?)?.map((e) => e as int).toList(),
  );

  String formatWeekdays(Set<int> days) {
    if (days.isEmpty) return "Never"; // should never happen
    if (days.length == 7) return "Everyday"; // should never happen
    if (days.length == 5 && days.containsAll({1, 2, 3, 4, 5})) return "Weekdays";
    if (days.length == 2 && days.containsAll({6, 7})) return "Weekends";

    const dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    final sortedDays = days.toList()..sort();
    return sortedDays.map((day) => dayNames[day - 1]).join(", ");
  }

  String getOrdinalDay(int day) {
    if (day >= 11 && day <= 13) {
      return "${day}th";
    }
    switch (day) {
      case 1:
        return "${day}st";
      case 2:
        return "${day}nd";
      case 3:
        return "${day}rd";
      default:
        return "${day}th";
    }
  }

  String formatMonthlyDays(Set<int> days) {
    if (days.isEmpty) return "Never"; //should never happen
    final sortedDays = days.toList()..sort();
    final formattedDays = sortedDays.map((d) => getOrdinalDay(d)).join(", ");

    if (sortedDays.length == 1) return "Monthly on the ${formattedDays}";
    return "Monthly on ${formattedDays}";
  }

  String? toInfoString() {
    switch (frequency) {
      case RepeatFrequency.none:
        return null;
      case RepeatFrequency.daily:
        return "Daily";
      case RepeatFrequency.weekly:
        return formatWeekdays({...?weekdays});
      case RepeatFrequency.monthly:
        return formatMonthlyDays({...?dayOfMonth});
    }
  }
}