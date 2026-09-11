import 'package:bus_arrival_notification_app/models/bus_alarm.dart';
import 'package:flutter/material.dart';

class AlarmCard extends StatelessWidget {
  final BusAlarm alarm;
  final ValueChanged<bool> onToggle;

  const AlarmCard({
    super.key,
    required this.alarm,
    required this.onToggle
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(alarm.routeName),
                        Text(alarm.stopId),
                        Text("${alarm.nextArrival}")
                      ],
                    ),
                ),
                Switch(value: alarm.enabled, onChanged: onToggle),
              ],
            ),
            if (alarm.enabled) ...[ // conditionally show elements within, ... indicates multiple elements were affected by this if
              // todo fix the condition once we got the time range down
              const SizedBox(height: 8,),
              LinearProgressIndicator(value: 0.7), // todo
              const SizedBox(height: 8,),
            ],
            Text("every fridays trust")
          ],
        ),
      ),
    );
  }
}