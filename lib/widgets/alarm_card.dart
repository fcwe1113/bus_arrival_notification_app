import 'package:bus_arrival_notification_app/models/bus_alarm.dart';
import 'package:bus_arrival_notification_app/transit/services/gtfs_database.dart';
import 'package:bus_arrival_notification_app/widgets/route_pill_strip.dart';
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
    final nowMin = now.hour * 60 + now.minute;
    final startMin = alarm.windowStart.hour * 60 + alarm.windowStart.minute;
    final endMin = alarm.windowEnd.hour * 60 + alarm.windowEnd.minute;

    if (startMin <= endMin) {
      return nowMin >= startMin && nowMin <= endMin;
    } else { // in case start and end cross midnight
      return nowMin >= startMin || nowMin <= endMin;
    }
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, "0");
    final m = t.minute.toString().padLeft(2, "0");
    return "${h}:${m}";
  }

  @override
  Widget build(BuildContext context) {
    final db = GtfsDatabase.forLocale("hk"); // todo fix locale hardcode
    final isActive = _withinActiveWindow;
    return Card( // groups up everything within visually
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), child: Padding(
        padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("${_formatTime(alarm.windowStart)} - ${_formatTime(alarm.windowEnd)}", style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: alarm.enabled ? Theme.of(context).colorScheme.onSurface : Colors.grey
              ),), const SizedBox(height: 2,),
              FutureBuilder(future: db.getGtfsStopById(alarm.gtfsStopId), builder: (context, snapshot) {
                final rawName = snapshot.data?.name;
                final name = rawName != null ? GtfsStop.cleanStopName(rawName) : "Loading...";
                return Text(
                  name,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              })
            ],),
          ), Switch(value: alarm.enabled, onChanged: onToggle), ], ),// hooking up the callback to the alarm's enabled bool
          const SizedBox(height: 12,),

          RoutePillStrip(gtfsStopId: alarm.gtfsStopId, routeNumberFilter: alarm.routeNumbers,),

          const SizedBox(height: 12,),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text(alarm.repeat.toInfoString() ?? "")],
          )],),

          if (alarm.enabled && isActive)...[
            const SizedBox(height: 4,),
            ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(minHeight: 6, value: null,),) // todo hook up to live arrival checker
          ],
        ],),
      ),
    );
  }
}