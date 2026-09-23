enum RepeatFrequency { none, daily, weekly, monthly }

class RepeatPattern {
  final RepeatFrequency frequency;
  final List<int>? weekdays; // specifies which weekday when in week mode
  final List<int>? dayOfMonth; // specifies which day of month when in month mode

  const RepeatPattern({required this.frequency, this.weekdays, this.dayOfMonth});

  static const none = RepeatPattern(frequency: RepeatFrequency.none);

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