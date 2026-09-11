class BusAlarm {
  final String id;
  final String routeName;
  final String stopId;
  final bool enabled;
  final String nextArrival;

  const BusAlarm({
    required this.id,
    required this.routeName,
    required this.stopId,
    required this.enabled,
    required this.nextArrival
  });

  BusAlarm copyWidth({
    String? id,
    String? routeName,
    String? stopId,
    bool? enabled,
    String? nextArrival
  }) {
    return BusAlarm(id: id ?? this.id, routeName: routeName ?? this.routeName, stopId: stopId ?? this.stopId, enabled: enabled ?? this.enabled, nextArrival: nextArrival ?? this.nextArrival);
  }
}