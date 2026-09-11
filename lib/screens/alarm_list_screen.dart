import 'package:bus_arrival_notification_app/widgets/app_shell.dart';
import 'package:flutter/material.dart';

import '../models/bus_alarm.dart';

// this will be the main screen the app first goes to on first boot
// basically the iphone alarm screen with much more information per alarm (as theyre more complex)

class AlarmListScreen extends StatefulWidget {
  const AlarmListScreen({super.key});

  @override
  State<AlarmListScreen> createState() => _AlarmListScreenState();
}

class _AlarmListScreenState extends State<AlarmListScreen> {
  List<BusAlarm> _alarms = [];

  @override
  void initState() {
    super.initState();
    _loadAlarms();
  }

  void _loadAlarms() { // todo
    // idk read from the alarm list json or something
    throw UnimplementedError();
  }

  void _toggleAlarm(int index) {
    setState(() {
      _alarms[index] = _alarms[index].copyWith(enabled: !_alarms[index].enabled);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return AppShell(title: "Alarm List", body: ListView.builder(
        itemCount: _alarms.length,
        itemBuilder: (context, index) {
      final alarm = _alarms[index];
      return SwitchListTile(
        title: Text(alarm.routeName),
        subtitle: Text(alarm.nextArrival),
        value: alarm.enabled,
        onChanged: (_) => _toggleAlarm(index),
      );
    }));
  }
}