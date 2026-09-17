// abstract class for transit provider
// todo make a provider template once the structure is set in stone

import 'dart:ui';

import 'package:bus_arrival_notification_app/transit/models/bus_stop.dart';
import 'package:bus_arrival_notification_app/transit/models/route_colour_scheme.dart';
import 'package:bus_arrival_notification_app/transit/progress_callback.dart';
import 'package:bus_arrival_notification_app/transit/refresh_result.dart';

import 'models/bus_route.dart';

abstract class TransitProvider {
  String get providerCode;
  String get providerName;
  String get IconAsset; // contains the link to the icon
  Color get defaultIconColor;
  Color get defaultTextColor;

  Future<List<BusStop>> fetchStops({bool forceRefresh});
  Future<List<BusRoute>> fetchRoutes({bool forceRefresh});
  Future<RefreshResult> refresh({bool forceRefresh = false, ProgressCallback? onProgress});
  Future<bool> isStale();
  RouteColourScheme coloursForRoute(BusRoute route) => RouteColourScheme(iconColour: defaultIconColor, textColour: defaultTextColor);

  // Future<List<StopPrediciton>> fetchPredicitons(String stopID);

}