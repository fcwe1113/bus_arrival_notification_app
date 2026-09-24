import 'package:bus_arrival_notification_app/models/bus_alarm.dart';
import 'package:bus_arrival_notification_app/screens/map_screen.dart';
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
  TimeOfDay _leftTime = TimeOfDay.now();
  TimeOfDay _rightTime = TimeOfDay.now().replacing(
      minute: (TimeOfDay.now().minute + 15) % 60,
      hour: TimeOfDay.now().hour + (TimeOfDay.now().minute + 15 >= 60 ? 1 : 0)
  );
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

  void _onLeftTimeChanged(TimeOfDay newLeft) {
    // if (newLeft.isAfter(_rightTime)) newLeft.subtract(Duration(days: 1));
    final diff = _toMinutes(_rightTime) - _toMinutes(_leftTime);
    setState(() {
      _rightTime = _fromMinutes(_toMinutes(newLeft) + diff);
      _leftTime = newLeft;
    });
  }

  void _onRightTimeChanged(TimeOfDay newRight) {
    // if (newRight.isBefore(_leftTime)) newRight = newRight.add(Duration(days: 1)); // add one day if newRight is "before" the left time
    final diff = (_toMinutes(newRight) - _toMinutes(_leftTime)) < 0 ? 1440 + (_toMinutes(newRight) - _toMinutes(_leftTime)) : (_toMinutes(newRight) - _toMinutes(_leftTime));
    _onSliderChanged((diff > 60 ? 60 : diff) + 0.0);
    setState(() {
      _rightTime = newRight;
    });
  }

  void _onSliderChanged(double newMinutes) {
    setState(() {
      _sliderMinutes = newMinutes.round();
      _rightTime = _fromMinutes(_toMinutes(_leftTime) + _sliderMinutes ~/ 1);
    });
  }

  void _openMapPicker() async {
    final picked = await Navigator.push<GtfsStop>(context, MaterialPageRoute(builder: (context) => const MapScreen(pickerMode: true,)));
    if (picked == null) return; // user did not select stop
    final routeList = Set<BusRoute>.from(await GtfsDatabase.forLocale("hk").getRoutesForGtfsStop(picked.id));
    setState(() {
      _selectedStop = picked;
      _availableRoutes = routeList;
      _selectedRoutes = {};
    });
  }

  void _compileAndSave() { // todo hook up to actual alarm save function

    final newAlarm = BusAlarm(
        id: "000001", // todo define later
        gtfsStopId: _selectedStop!.id,
        routeNumbers: _selectedRoutes.map((r) => r.routeNumber).toList(),
        windowStart: _leftTime,
        windowEnd: _rightTime,
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
                  final picked = await showTimePicker(context: context, initialTime: _leftTime);
                  if (picked != null) _onLeftTimeChanged(picked);
                }, label: Text("${_leftTime.hour.toString().padLeft(2, "0")}:${_leftTime.minute.toString().padLeft(2, "0")}"), icon: const Icon(Icons.access_time),),
                const Icon(Icons.arrow_forward, size: 20,),
                OutlinedButton.icon(onPressed: () async {
                  final picked = await showTimePicker(context: context, initialTime: _rightTime);
                  if (picked != null) _onRightTimeChanged(picked);
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
              final query = value.text.toLowerCase().trim();
              return _loadedStops.where((s) => GtfsStop.cleanStopName(s.name).toLowerCase().contains(query));
            },
            onSelected: (GtfsStop selection) async {
              final Set<BusRoute> _routeList = Set.from(await GtfsDatabase.forLocale("hk").getRoutesForGtfsStop(selection.id));
              setState(() {
                _selectedStop = selection;
                _availableRoutes = _routeList;
                _selectedRoutes = {};
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
              onPressed: _openMapPicker,
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

          // how early to ring
          Row(children: [
            const Text("Minutes away to ring: ", style: TextStyle(fontWeight: FontWeight.bold),),
            Expanded(child: TextFormField(decoration: const InputDecoration(isDense: true, border: UnderlineInputBorder(), hintText: "e.g. \"8\" or \"15, 12\""),))
          ],),
          const SizedBox(height: 24,),

          // max ring attempts
          Row(children: [
            const Text("Max ring attempts: ", style: TextStyle(fontWeight: FontWeight.bold),),
            Expanded(child: TextFormField(decoration: const InputDecoration(isDense: true, border: UnderlineInputBorder()), initialValue: "10",))
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
          ),
          const SizedBox(height: 12,),

          // max ring attempts
          Row(children: [
            const Text("Custom Message: ", style: TextStyle(fontWeight: FontWeight.bold),),
            Expanded(child: TextFormField(
              decoration: const InputDecoration(isDense: true, border: UnderlineInputBorder()), initialValue: "Wake Up!",))
          ],),
        ],)
    );
  }

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;
  TimeOfDay _fromMinutes(int m) => TimeOfDay(hour: (m ~/ 60) % 24, minute: m % 60);

}