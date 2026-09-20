import 'package:bus_arrival_notification_app/widgets/alarm_card.dart';
import 'package:bus_arrival_notification_app/widgets/app_shell.dart';
import 'package:flutter/material.dart';

import '../models/bus_alarm.dart';

// this will be the main screen the app first goes to on first boot
// basically the iphone alarm screen with much more information per alarm (as theyre more complex)

/// StatefulWidget wrapper for the alarm list screen
class AlarmListScreen extends StatefulWidget {
  const AlarmListScreen({super.key});

  @override
  State<AlarmListScreen> createState() => _AlarmListScreenState();
}

/// State object within the alarm list screen
class _AlarmListScreenState extends State<AlarmListScreen> {
  List<BusAlarm> _alarms = [];

  @override
  void initState() {
    super.initState();
    _loadAlarms();
  }

  void _loadAlarms() { // todo make it read the alarm list once it exist
    // idk read from the alarm list json or something
    // for now we make a dummy alarm for testing purposes
    // throw UnimplementedError();

    _alarms = [BusAlarm(id: "00001", operatorRouteId: "41", gtfsStopId: "1234", enabled: false, nextArrival: 12)];
  }

  /// Event trigger for switching alarm enabled bool
  void _toggleAlarm(int index) { // this will trigger on alarm toggle change, and make a copy of the alarm but with the correct toggle state
    setState(() {
      _alarms[index] = _alarms[index].copyWith(enabled: !_alarms[index].enabled);
    });
  }

  /// Draws the screen
  @override
  Widget build(BuildContext context) {
    return AppShell(title: "Alarm List", body: ListView.builder(
        itemCount: _alarms.length,
        itemBuilder: (context, index) {
      final alarm = _alarms[index];
      return AlarmCard(
        alarm: alarm,
        onToggle: (_) => _toggleAlarm(index),
      );
    }));
  }
}