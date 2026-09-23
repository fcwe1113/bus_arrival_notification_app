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
}