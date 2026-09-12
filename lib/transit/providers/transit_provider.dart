// abstract class for transit provider
// todo make a provider template once the structure is set in stone

import 'package:bus_arrival_notification_app/transit/models/bus_stop.dart';

abstract class TransitProvider {
  String get providerCode;
  String get providerName;
  String get IconAsset; // contains the link to the icon

  Future<List<BusStop>> fetchStops();
  // Future<List<StopPrediciton>> fetchPredicitons(String stopID);
}