// bus route data struct definition file

import 'package:bus_arrival_notification_app/transit/models/bus_stop.dart';

class BusRoute {
  final String id;
  final Map<String, String> names; // may hv locale diffs, maybe remove if not needed
  final String routeNumber;
  final String bound; // change if not adapting to new apis
  final BusStop origin; // may be placeholder until resolved
  final BusStop destination; // same here
  final Map<String, String> destinationText; // the destination showed normally
  final String providerCode;

  const BusRoute({
    required this.id,
    required this.names,
    required this.routeNumber,
    required this.bound,
    required this.origin,
    required this.destination,
    required this.destinationText,
    required this.providerCode
  });
}