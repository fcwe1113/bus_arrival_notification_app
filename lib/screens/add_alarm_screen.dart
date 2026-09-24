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
  TextEditingController? _searchController;

  Set<BusRoute> _selectedRoutes = {};
  Set<BusRoute> _availableRoutes = {};

  RepeatPattern _repeatPattern = RepeatPattern.none;
  final Set<int> _selectedWeekdays = {1, 2, 3, 4, 5}; // 1 = mon ... 7 = sun
  late TextEditingController _monthlyDayController;

  String _ringThreshold = "";
  String _maxRingAttempts = "10";
  String _customRingMessage = "Wake Up!";

  bool _liveOnly = false;

  final _thresholdKey = GlobalKey<FormFieldState<String>>();
  final _attemptsKey = GlobalKey<FormFieldState<String>>();
  final _messageKey = GlobalKey<FormFieldState<String>>();

  @override
  void initState() {
    super.initState();
    _monthlyDayController = TextEditingController(text: DateTime.now().day.toString());
    _loadBusStops();
  }

  @override
  void dispose() {
    // _searchController.dispose();
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
    final diff = _calculateDurationInMinutes(_leftTime, _rightTime);
    setState(() {
      _rightTime = _fromMinutes(_toMinutes(newLeft) + diff);
      _leftTime = newLeft;
    });
  }

  void _onRightTimeChanged(TimeOfDay newRight) {
    // if (newRight.isBefore(_leftTime)) newRight = newRight.add(Duration(days: 1)); // add one day if newRight is "before" the left time
    final diff = _calculateDurationInMinutes(_leftTime, newRight);
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
      // _searchController?.clear();
      _searchController?.text = GtfsStop.cleanStopName(_selectedStop!.name);
    });
  }

  Future<void> _compileAndSave() async { // todo hook up to actual alarm save function

    // errors
    bool error = false;
    String errorMsg = "";
    final days = _monthlyDayController.text;
    if (!_thresholdKey.currentState!.validate() || !_attemptsKey.currentState!.validate() || !_messageKey.currentState!.validate()){
      error = true;
    }
    if (_selectedStop == null) {
      error = true;
      errorMsg += "No stop selected\n";
    } else if (_selectedRoutes.isEmpty) {
      error = true;
      errorMsg += "No routes selected\n";
    }
    if (_repeatPattern.frequency == RepeatFrequency.weekly) {
      if (_selectedWeekdays.isEmpty) {
        error = true;
        errorMsg += "No weekdays selected\n";
      }
    } else if (_repeatPattern.frequency == RepeatFrequency.monthly){
      if (days == "") {
        error = true;
        errorMsg += "No days in month selected\n";
      } else {
        final invalidDays = days.split(",").where((d) => d == "" || (int.tryParse(d)! < 1 || int.tryParse(d)! > 31));
        if (invalidDays.isNotEmpty) {
          error = true;
          errorMsg += "Some days in month are invalid\n";
        }
      }
    }

    if (error) {
      if (errorMsg != "") {
        showDialog(context: context, builder: (context) => AlertDialog(
          title: const Text("Error"),
          content: Text(errorMsg),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
        ));
      }
      return;
    }

    // warnings, allow user to return but can proceed if desired

    if (_calculateDurationInMinutes(_leftTime, _rightTime) > 60) {
      final proceed = await _showWarning("Setting an alarm window of over 1 hour is not recommended, make sure you know what you are doing before continuing.");
      if (proceed != true) return;
    }

    final splitDays = days.split(",");
    if (splitDays.contains("29") || splitDays.contains("30") || splitDays.contains("31")) {
      final proceed = await _showWarning("You entered days not present in every month, the alarm will not trigger on months without those days.");
      if (proceed != true) return;
    }

    // return;

    final newAlarm = BusAlarm(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        gtfsStopId: _selectedStop!.id,
        routeNumbers: _selectedRoutes.map((r) => r.routeNumber).toList(),
        windowStart: _leftTime,
        windowEnd: _rightTime,
        thresholdStates: _ringThreshold.split(",").map<ThresholdState>((t) => ThresholdState(minutesBeforeArrival: int.tryParse(t)!, ringCount: int.tryParse(_maxRingAttempts)!)).toList(),
        repeat: RepeatPattern(
            frequency: _repeatPattern.frequency,
            weekdays: _repeatPattern.frequency == RepeatFrequency.weekly ? _selectedWeekdays.toList() : null,
            dayOfMonth: _repeatPattern.frequency == RepeatFrequency.monthly ? splitDays.map<int>((d) => int.tryParse(d)!).toList() : null
        ),
        liveOnly: _liveOnly,
        enabled: true
    );
    Navigator.pop(context, newAlarm);
  }

  Future<bool?> _showWarning(String text) async {
    return showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text("Warning"),
      content: Text(text),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Go back"),),
        TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Continue"))
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(title: "Add a new alarm", actions: [IconButton(onPressed: _compileAndSave, icon: const Icon(Icons.check))],
        body: ListView(padding: const EdgeInsets.all(16), children: [
          // time range selector slider
          Card(child: Padding(padding: const EdgeInsetsGeometry.all(16), child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("Alarm Time Window", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12,),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [

                // left time button
                OutlinedButton.icon(onPressed: () async {
                  final picked = await showTimePicker(context: context, initialTime: _leftTime);
                  if (picked != null) _onLeftTimeChanged(picked);
                }, label: Text("${_leftTime.hour.toString().padLeft(2, "0")}:${_leftTime.minute.toString().padLeft(2, "0")}"), icon: const Icon(Icons.access_time),),

                // middle arrow / time diff
                Column(mainAxisSize: MainAxisSize.min, children: [Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(10)),
                  child: Text("${_calculateDurationInMinutes(_leftTime, _rightTime)} min", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),),
                ), const SizedBox(height: 2,), const Icon(Icons.arrow_forward, size: 20,)
                ],),

                // right time button
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
          Row(children: [Expanded(child: _isLoadingStops ? TextFormField(
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
              _searchController = controller;
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
            Expanded(child: TextFormField(decoration: const InputDecoration(
                isDense: true, border: UnderlineInputBorder(),
                hintText: "e.g. \"8\" or \"15,12\""
            ), onChanged: (value) {setState(() {
              _ringThreshold = value;
            });},
              initialValue: _ringThreshold,
              keyboardType: TextInputType.text,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r"[0-9,]"))],
              key: _thresholdKey,
              validator: (val) {
                if (val == null || val == "") {
                  return "Required";
                }

                final currentWindow = _calculateDurationInMinutes(_leftTime, _rightTime);
                final items = val.split(",");

                for (final item in items) {
                  final minutes = int.tryParse(item);
                  if (minutes == null) {
                    return "Do not chain commas";
                  }
                  if (minutes >= currentWindow) {
                    return "number(s) exceed alarm active window";
                  }
                }

                return null;
              },
            ))
          ],),
          const SizedBox(height: 24,),

          // max ring attempts
          Row(children: [
            const Text("Max ring attempts: ", style: TextStyle(fontWeight: FontWeight.bold),),
            Expanded(child: TextFormField(decoration: const InputDecoration(
                isDense: true,
                border: UnderlineInputBorder()
            ), onChanged: (value) {setState(() {
              _maxRingAttempts = value;
            });},
              initialValue: _maxRingAttempts,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              key: _attemptsKey,
              validator: (val) => val == null || val == "" ? "Required" : int.parse(val) > 15 ? "Cannot exceed 15 times" : null,
            ))
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
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r"[0-9,]"))],
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
            Expanded(child: TextFormField(decoration: const InputDecoration(
                isDense: true,
                border: UnderlineInputBorder()
            ), onChanged: (value) {
              setState(() {
                _customRingMessage = value;
              });
            }, initialValue: _customRingMessage,
              key: _messageKey,
              validator: (val) => val == null || val == "" ? "Required" : null,
            ))
          ],),
        ],)
    );
  }

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;
  TimeOfDay _fromMinutes(int m) => TimeOfDay(hour: (m ~/ 60) % 24, minute: m % 60);

  int _calculateDurationInMinutes(TimeOfDay start, TimeOfDay end) {
    int duration = _toMinutes(end) - _toMinutes(start);
    if (duration < 0) {
      duration += 24 * 60;
    }
    return duration;
  }

}