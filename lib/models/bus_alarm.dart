// actual alarm object definition
// todo add api check cycle here maybe?

class BusAlarm {
  final String id; // maybe gen a uuid for it or something, this is local anyways so whatever
  final String routeName; // linked to the future all routes database with prepended loc code?
  final String stopId; // same as above
  final bool enabled; // indicates alarm enabled (similar to ios alarm ui alarm toggle)
  final int nextArrival; // maybe hook this up to a periodic updater?

  const BusAlarm({ //  constructor
    required this.id,
    required this.routeName,
    required this.stopId,
    required this.enabled,
    required this.nextArrival
  });

  BusAlarm copyWith({ // object copy function, required because dart does not hv a update immutable object default so we r implementing one here
    String? id,
    String? routeName,
    String? stopId,
    bool? enabled,
    int? nextArrival
  }) {
    return BusAlarm(id: id ?? this.id, routeName: routeName ?? this.routeName, stopId: stopId ?? this.stopId, enabled: enabled ?? this.enabled, nextArrival: nextArrival ?? this.nextArrival);
  }
}