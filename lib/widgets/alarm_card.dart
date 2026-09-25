import 'package:transport_alarm/models/bus_alarm.dart';
import 'package:transport_alarm/transit/services/gtfs_database.dart';
import 'package:transport_alarm/widgets/route_pill_strip.dart';
import 'package:flutter/material.dart';

import '../transit/models/gtfs_stop.dart';

/// the per alarm display on the alarm list screen
/// basically the gui template for each given alarm
class AlarmCard extends StatelessWidget { // note it takes the alarm object as required input
  final BusAlarm alarm;
  final ValueChanged<bool> onToggle; // callback for a value changing
  final bool _isEditing;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const AlarmCard({super.key, required this.alarm, required this.onToggle, this._isEditing = false, this.onDelete, this.onTap});

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
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), clipBehavior: Clip.antiAlias,
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [if (_isEditing) ...[
        Material(color: Theme.of(context).colorScheme.errorContainer, child: InkWell(onTap: onDelete, child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Center(child: Icon(Icons.remove_circle, color: Colors.red, size: 24,),),
        ),),)
      ], Expanded(
        child: InkWell(onTap: _isEditing ? onTap : null, child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text("${_formatTime(alarm.windowStart)} - ${_formatTime(alarm.windowEnd)}", style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: alarm.enabled ? Theme.of(context).colorScheme.onSurface : Colors.grey
            ),), const SizedBox(height: 2,),
            FutureBuilder(future: db.getGtfsStopById(alarm.gtfsStopId), builder: (context, snapshot) {
              final rawName = snapshot.data?.name;
              final name = rawName != null ? GtfsStop.cleanStopName(rawName) : "Loading...";
              return Text(name, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );
            })
          ],),
        ),),
      ), if (_isEditing) Material(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        child: InkWell(onTap: onTap, child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Center(child: Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 28,),),
        ),),) else Padding(padding: const EdgeInsets.only(right: 12), child: Switch(value: alarm.enabled, onChanged: onToggle),),
      ],),),
        Padding(padding: EdgeInsetsGeometry.all(12), child: Column(children: [
          const SizedBox(height: 12,),
          RoutePillStrip(gtfsStopId: alarm.gtfsStopId, routeNumberFilter: alarm.routeNumbers,),
          const SizedBox(height: 12,),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(alarm.repeat.toInfoString() ?? "")],)
          ],), if (alarm.enabled && isActive)...[
            const SizedBox(height: 4,),
            ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(minHeight: 6, value: null,),) // todo hook up to live arrival checker
          ]
        ])),
      ],)
    );
  }
}