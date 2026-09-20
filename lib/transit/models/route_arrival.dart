import 'package:bus_arrival_notification_app/transit/models/bus_route.dart';

class RouteArrival {
  final BusRoute route;
  final int minutesFromNow;
  final bool isLive;

  const RouteArrival({required this.route, required this.minutesFromNow, required this.isLive});
}