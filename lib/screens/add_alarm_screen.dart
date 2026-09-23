import 'dart:ffi';

import 'package:bus_arrival_notification_app/models/bus_alarm.dart';
import 'package:bus_arrival_notification_app/transit/models/bus_route.dart';
import 'package:bus_arrival_notification_app/transit/models/gtfs_stop.dart';
import 'package:bus_arrival_notification_app/transit/models/repeat_pattern.dart';
import 'package:bus_arrival_notification_app/transit/models/threshold_state.dart';
import 'package:bus_arrival_notification_app/transit/services/gtfs_database.dart';
import 'package:bus_arrival_notification_app/widgets/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddAlarmScreen extends StatefulWidget{
  const AddAlarmScreen({super.key});

  @override
  State<AddAlarmScreen> createState() => _AddAlarmScreenState();
}

class _AddAlarmScreenState extends State<AddAlarmScreen> {
  DateTime _leftTime = DateTime.now();
  DateTime _rightTime = DateTime.now().add(Duration(minutes: 15));
  int _sliderMinutes = 15;

  bool _isLoadingStops = true;
  List<GtfsStop> _loadedStops = [];
  GtfsStop? _selectedStop;
  final TextEditingController _searchController = TextEditingController();

  Set<BusRoute> _selectedRoutes = {};
  Set<BusRoute> _availableRoutes = {};

  RepeatPattern _repeatPattern = RepeatPattern.none;
  final Set<int> _selectedWeekdays = {1, 2, 3, 4, 5}; // 1 = mon ... 7 = sun
  late TextEditingController _monthlyDayController;

  bool _liveOnly = false;

  @override
  void initState() {
    super.initState();
    _monthlyDayController = TextEditingController(text: DateTime.now().day.toString());
    _loadBusStops();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _monthlyDayController.dispose();
    super.dispose();
  }

  Future<void> _loadBusStops() async {
    final stopsList = await GtfsDatabase.forLocale("hk").getAllGtfsStops();
    setState(() {
      _loadedStops = stopsList;
      _isLoadingStops = false;
    });
  }

  void _onLeftTimeChanged(DateTime newLeft) {
    // if (newLeft.isAfter(_rightTime)) newLeft.subtract(Duration(days: 1));
    final diff = _rightTime.difference(_leftTime);
    setState(() {
      _rightTime = newLeft.add(diff);
      _leftTime = newLeft;
    });
  }

  void _onRightTimeChanged(DateTime newRight) {
    if (newRight.isBefore(_leftTime)) newRight = newRight.add(Duration(days: 1)); // add one day if newRight is "before" the left time
    final diff = _rightTime.difference(_leftTime);
    _onSliderChanged((diff.inMinutes.abs() > 60 ? 60 : diff.inMinutes.abs()) + 0.0);
    setState(() {
      _rightTime = newRight;
    });
  }

  void _onSliderChanged(double newMinutes) {
    setState(() {
      _sliderMinutes = newMinutes.round();
      _rightTime = _leftTime.add(Duration(minutes: _sliderMinutes));
    });
  }

  void _openMapPicker() {
    // todo hook up map
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("to be implemented lol")));
  }

  void _compileAndSave() { // todo hook up to actual alarm save function
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, _leftTime.hour, _leftTime.minute, 0);
    final end = DateTime(now.year, now.month, now.day, _rightTime.hour, _rightTime.minute, 0);

    final newAlarm = BusAlarm(
        id: "000001", // todo define later
        gtfsStopId: _selectedStop!.id,
        routeNumbers: _selectedRoutes.map((r) => r.routeNumber).toList(),
        windowStart: start,
        windowEnd: end,
        thresholdStates: [ThresholdState(minutesBeforeArrival: 5)],
        repeat: _repeatPattern,
        liveOnly: _liveOnly,
        enabled: true
    );
    Navigator.pop(context, newAlarm);
  }

  @override
  Widget build(BuildContext context) { // todo write alarm validity check
    return AppShell(title: "Add a new alarm", actions: [IconButton(onPressed: () => {}, icon: const Icon(Icons.check))],
        body: ListView(padding: const EdgeInsets.all(16), children: [
          // time range selector slider
          Card(child: Padding(padding: const EdgeInsetsGeometry.all(16), child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("Alarm Time Window", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12,),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                OutlinedButton.icon(onPressed: () async {
                  final picked = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_leftTime));
                  final now = DateTime.now();
                  if (picked != null) _onLeftTimeChanged(DateTime(now.year, now.month, now.day, picked.hour, picked.minute, 0));
                }, label: Text("${_leftTime.hour.toString().padLeft(2, "0")}:${_leftTime.minute.toString().padLeft(2, "0")}"), icon: const Icon(Icons.access_time),),
                const Icon(Icons.arrow_forward, size: 20,),
                OutlinedButton.icon(onPressed: () async {
                  final picked = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_rightTime));
                  final now = DateTime.now();
                  if (picked != null) _onRightTimeChanged(DateTime(now.year, now.month, now.day, picked.hour, picked.minute, 0));
                }, label: Text("${_rightTime.hour.toString().padLeft(2, "0")}:${_rightTime.minute.toString().padLeft(2, "0")}"), icon: const Icon(Icons.access_time))
              ],),
              const SizedBox(height: 12,),
              Row(children: [const Text("0m"), Expanded(child: Slider(
                value: _sliderMinutes + 0.0,
                onChanged: _onSliderChanged,
                min: 0,
                max: 60,
                divisions: 60,
                label: "+${_sliderMinutes}m",
              )), const Text("+60m")],)
            ],)
          ,),),

          const SizedBox(height: 12,),

          // bus stop search bar
          Row(children: [Expanded(child: _isLoadingStops ? TextField(
            enabled: false,
            decoration: InputDecoration(hintText: "Loading...", prefixIcon: const SizedBox(
              width: 20,
              height: 20,
              child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2,),),
            ), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))
          ) : Autocomplete<GtfsStop>(
            displayStringForOption: (GtfsStop option) => GtfsStop.cleanStopName(option.name),
            optionsBuilder: (TextEditingValue value) {
              if (value.text.isEmpty) return _loadedStops;
              return _loadedStops.where((s) => GtfsStop.cleanStopName(s.name).toLowerCase().contains(GtfsStop.cleanStopName(value.text).toLowerCase()));
            },
            onSelected: (GtfsStop selection) async {
              final Set<BusRoute> _routeList = Set.from(await GtfsDatabase.forLocale("hk").getRoutesForGtfsStop(selection.id));
              setState(() {
                _selectedStop = selection;
                _availableRoutes = _routeList;
                print("state set");
              });
            },
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                    hintText: "Search Bus Stop...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))
                ),
              );
            },
          )),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: () => {},
              icon: const Icon(Icons.location_searching),
              tooltip: "Choose on map",
            )],),
          const SizedBox(height: 16,),

          // routes checkbox list
          if (_selectedStop != null) ...[
            Card(clipBehavior: Clip.antiAlias, child: ExpansionTile(
              initiallyExpanded: true,
              title: Text(
                "Routes serving ${GtfsStop.cleanStopName(_selectedStop!.name)}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: Text(_selectedRoutes.isEmpty
                  ? "No routes selected"
                  : "${_selectedRoutes.length} route${_selectedRoutes.length > 1 ? "s" : ""} selected",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),),
              children: _availableRoutes.map((r) {
                return CheckboxListTile(title: Text(r.routeNumber), subtitle: Text(r.destinationText["en"]!) ,value: _selectedRoutes.contains(r), onChanged: (bool? checked) {
                  setState(() {
                    if (checked == true) {
                      _selectedRoutes.add(r);
                    } else {
                      _selectedRoutes.remove(r);
                    }
                  });
                });
              }).toList(),
            ),),
            const SizedBox(height: 16,)
          ],
          // max ring attempts
          Row(children: [
            const Text("Max ring attempts: ", style: TextStyle(fontWeight: FontWeight.bold),),
            Expanded(child: TextField(decoration: const InputDecoration(isDense: true, border: UnderlineInputBorder()),))
          ],),
          const SizedBox(height: 24,),
          // horizontal 4 way repeat selector
          const Text("Repeat Pattern", style: TextStyle(fontWeight: FontWeight.bold),),
          const SizedBox(height: 8,),
          SegmentedButton(segments: const[
            ButtonSegment(value: RepeatPattern.none, label: Text("None")),
            ButtonSegment(value: RepeatPattern(frequency: RepeatFrequency.daily), label: Text("Daily")),
            ButtonSegment(value: RepeatPattern(frequency: RepeatFrequency.weekly), label: Text("Weekly")),
            ButtonSegment(value: RepeatPattern(frequency: RepeatFrequency.monthly), label: Text("Monthly")),
          ], selected: {_repeatPattern}, onSelectionChanged: (Set<RepeatPattern> selected) {
            setState(() {
              _repeatPattern = selected.first;
            });
          },),

          // weekly options
          if (_repeatPattern.frequency == RepeatFrequency.weekly) ...[
            const SizedBox(height: 12,),
            Wrap(
              spacing: 4,
              children: List.generate(7, (i) {
                final day = i + 1;
                final labels = ["M", "T", "W", "T", "F", "S", "S"];
                final isSelected = _selectedWeekdays.contains(day);
                return FilterChip(label: Text(labels[i]), selected: isSelected, onSelected: (bool selected) {
                  setState(() {
                    if (selected) {
                      _selectedWeekdays.add(day);
                    } else {
                      _selectedWeekdays.remove(day);
                    }
                  });
                });
              }),
            )
          ],

          // const SizedBox(height: 12,),

          // monthly options
          if (_repeatPattern.frequency == RepeatFrequency.monthly) ...[
            const SizedBox(height: 12,),
            Row(children: [
              const Text("Day of month: "),
              Expanded(child: SizedBox(child: TextField(
                controller: _monthlyDayController,
                keyboardType: TextInputType.text,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r"[0-9, ]"))],
                // textAlign: TextAlign.center,
                decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), hintText: "e.g. \"11,25\""),
              ),))
            ],)
          ],

          const SizedBox(height: 12,),

          // ignore schedule checkbox
          SwitchListTile(
            title: const Text("Ignore scheduled times"),
            subtitle: const Text("Only rely on real-time live GPS arrival data"),
            value: _liveOnly,
            onChanged: (bool val) {
              setState(() {
                _liveOnly = val;
              });
            }
          )
        ],)
    );
  }

}