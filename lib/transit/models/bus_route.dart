// bus route data struct definition file

import 'package:bus_arrival_notification_app/transit/models/bus_stop.dart';

class BusRoute {
  final String id;
  final Map<String, String> names; // may hv locale diffs, maybe remove if not needed
  final String routeNumber;
  final String bound; // change if not adapting to new apis
  final Map<String, String> originText;
  final Map<String, String> destinationText; // the destination showed normally
  final List<BusStop> stops;
  final String providerCode;

  const BusRoute({
    required this.id,
    required this.names,
    required this.routeNumber,
    required this.bound,
    required this.originText,
    required this.destinationText,
    required this.providerCode,
    this.stops = const [],
  });

  BusStop get origin => stops.isNotEmpty ? stops.first : BusStop.placeholder(id: "${providerCode}:origin_${routeNumber}${bound}", name: originText["en"] ?? "", providerCode: providerCode);
  BusStop get destination => stops.isNotEmpty ? stops.last : BusStop.placeholder(id: "${providerCode}:destination_${routeNumber}${bound}", name: destinationText["en"] ?? "", providerCode: providerCode);

  BusRoute copyWith({List<BusStop>? stops}) {
    return BusRoute(id: id, names: names, routeNumber: routeNumber, bound: bound, originText: originText, destinationText: destinationText, providerCode: providerCode, stops: stops ?? this.stops);
  }
}