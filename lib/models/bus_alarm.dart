import 'package:bus_arrival_notification_app/transit/models/threshold_state.dart';

import '../transit/models/repeat_pattern.dart';

/// Bus Alarm object definition
class BusAlarm {
  final String id; // maybe gen a uuid for it or something, this is local anyways so whatever
  final List<String> routeNumbers; // stores raw route numbers for deduping
  final String gtfsStopId;
  final DateTime windowStart;
  final DateTime windowEnd;
  final List<ThresholdState> thresholdStates; // ordered
  final int maxRingsPerThreshold;
  final RepeatPattern repeat;
  final bool liveOnly; // ignore schedule times if true
  final bool enabled; // indicates alarm enabled (similar to ios alarm ui alarm toggle)

  const BusAlarm({ //  constructor
    required this.id,
    required this.gtfsStopId,
    required this.routeNumbers,
    required this.windowStart,
    required this.windowEnd,
    required this.thresholdStates,
    this.maxRingsPerThreshold = 10,
    this.repeat = RepeatPattern.none,
    this.liveOnly = false,
    this.enabled = true,
  });

  BusAlarm copyWith({
    String? gtfsStopId,
    List<String>? routeNumbers,
    DateTime? windowStart,
    DateTime? windowEnd,
    int? maxRingsPerThreshold,
    List<ThresholdState>? thresholdStates,
    RepeatPattern? repeat,
    bool? liveOnly,
    bool? enabled
  }) {
    return BusAlarm(
        id: id,
        gtfsStopId: gtfsStopId ?? this.gtfsStopId,
        routeNumbers: routeNumbers ?? this.routeNumbers,
        windowStart: windowStart ?? this.windowStart,
        windowEnd: windowEnd ?? this.windowEnd,
        thresholdStates: thresholdStates ?? this.thresholdStates,
        repeat: repeat ?? this.repeat,
        liveOnly: liveOnly ?? this.liveOnly,
        enabled: enabled ?? this.enabled
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'gtfsStopId': gtfsStopId,
    'routeNumbers': routeNumbers,
    'windowStart': windowStart.toIso8601String(),
    'windowEnd': windowEnd.toIso8601String(),
    'maxRingsPerThreshold': maxRingsPerThreshold,
    'thresholdStates': thresholdStates.map((t) => t.toJson()).toList(),
    'repeat': repeat.toJson(),
    'liveOnly': liveOnly,
    'enabled': enabled,
  };

  static BusAlarm fromJson(Map<String, dynamic> json) => BusAlarm(
    id: json['id'] as String,
    gtfsStopId: json['gtfsStopId'] as String,
    routeNumbers: List<String>.from(json['routeNumbers']),
    windowStart: DateTime.parse(json['windowStart'] as String),
    windowEnd: DateTime.parse(json['windowEnd'] as String),
    maxRingsPerThreshold: json['maxRingsPerThreshold'] as int,
    thresholdStates: (json['thresholdStates'] as List).map((t) => ThresholdState.fromJson(t as Map<String, dynamic>)).toList(),
    repeat: RepeatPattern.fromJson(json['repeat'] as Map<String, dynamic>),
    liveOnly: json['liveOnly'] as bool,
    enabled: json['enabled'] as bool,
  );
}

// IOS alarm workflow
// 0. on alarm register send the next alarm duration start to server
// 1. server pings on alarm duration start
// 2. phone gets updated alarm ring estimate, pings server on next ping, either for estimate update (estimate >5 mins) or actual alarm ring(estimate <5 mins)
// 3. server pings on alarm ring
// 4. phone rings and set server ping in 1 min, if user acknowledge the send delete to remove repeat ring, user can define max rin tries (default 10)
// 5. any subsequent alarm rings would be set by phone calculating the next server ping time
// note: if server does not receive an ACK from phone on ping, it will retry in 1 min
// assuming that step 2 runs one estimate update in addition to final check before alarm, user acknowledges alarm on first ring, and all api packets arrive successfully
// each alarm would take 8 server invokations assuming invokations only counts sending/receiving api calls

// assuming each user would make 2 alarms with an average upper invokation count of 10 per alarm
// cloudflare offering 100k invokations per day
// 100000 / 20 (per user) = 5000 ios users per day cap, realistically 3.5k-4k ios users per day