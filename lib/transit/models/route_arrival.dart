import 'package:transport_alarm/transit/models/bus_route.dart';

class RouteArrival {
  final BusRoute route;
  final int minutesFromNow;
  final bool isLive;

  const RouteArrival({required this.route, required this.minutesFromNow, required this.isLive});
}