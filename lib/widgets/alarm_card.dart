import 'package:bus_arrival_notification_app/models/bus_alarm.dart';
import 'package:flutter/material.dart';

/// the per alarm display on the alarm list screen
/// basically the gui template for each given alarm
class AlarmCard extends StatelessWidget { // note it takes the alarm object as required input
  final BusAlarm alarm;
  final ValueChanged<bool> onToggle; // callback for a value changing

  const AlarmCard({
    super.key,
    required this.alarm,
    required this.onToggle
  });

  @override
  Widget build(BuildContext context) {
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
                    child: Column( // column inside row inside column
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(alarm.operatorRouteId),
                        Text(alarm.gtfsStopId),
                        Text("${alarm.nextArrival}")
                      ],
                    ),
                ),
                Switch(value: alarm.enabled, onChanged: onToggle), // hooking up the callback to the alarm's enabled bool
              ],
            ),
            if (alarm.enabled) ...[ // conditionally show elements within, ... indicates multiple elements were affected by this if
              // todo fix the condition once we got the time range down
              const SizedBox(height: 8,),
              LinearProgressIndicator(value: 0.7), // todo
              const SizedBox(height: 8,),
            ],
            Text("every fridays trust") // todo replace with actual setting
          ],
        ),
      ),
    );
  }
}