import 'package:bus_arrival_notification_app/models/bus_alarm.dart';
import 'package:bus_arrival_notification_app/transit/services/gtfs_database.dart';
import 'package:flutter/material.dart';

import '../transit/models/gtfs_stop.dart';

/// the per alarm display on the alarm list screen
/// basically the gui template for each given alarm
class AlarmCard extends StatelessWidget { // note it takes the alarm object as required input
  final BusAlarm alarm;
  final ValueChanged<bool> onToggle; // callback for a value changing

  const AlarmCard({super.key, required this.alarm, required this.onToggle});

  bool get _withinActiveWindow {
    final now = TimeOfDay.now();
    return now.isAfter(alarm.windowStart) && now.isBefore(alarm.windowEnd);
  }

  @override
  Widget build(BuildContext context) {
    final db = GtfsDatabase.forLocale("hk"); // todo fix locale hardcode
    return Card( // groups up everything within visually
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column( // outermost column
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row( // ros inside column
              children: [
                Expanded(
                    child: FutureBuilder<GtfsStop?>(future: db.getGtfsStopById(alarm.gtfsStopId), builder: (context, snapshot) {
                      final name = snapshot.data?.name ?? "...";
                      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold,)),
                        Text("${alarm.windowStart.toString()} - ${alarm.windowEnd.toString()}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12),)
                      ],);
                    })
                ),
                Switch(value: alarm.enabled, onChanged: onToggle), // hooking up the callback to the alarm's enabled bool
              ],
            ),
            const SizedBox(height: 8,),
            
          ],
        ),
      ),
    );
  }
}