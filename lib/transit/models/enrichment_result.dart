import 'package:transport_alarm/transit/models/bus_stop.dart';

class EnrichmentResult {
  final List<BusStop> stops;
  final List<String> failedRouteNumbers;

  const EnrichmentResult({required this.stops, required this.failedRouteNumbers});
}