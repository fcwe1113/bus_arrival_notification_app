import 'package:bus_arrival_notification_app/transit/models/bus_stop.dart';

class EnrichmentResult {
  final List<BusStop> stops;
  final List<String> failedRouteNumbers;

  const EnrichmentResult({required this.stops, required this.failedRouteNumbers});
}