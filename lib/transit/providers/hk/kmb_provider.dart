import 'dart:convert';

import 'package:bus_arrival_notification_app/transit/models/bus_route.dart';
import 'package:bus_arrival_notification_app/transit/services/transit_cache_service.dart';
import 'package:bus_arrival_notification_app/transit/services/transit_update_scheduler.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

import '../../models/bus_stop.dart';
import '../transit_provider.dart';

/// KMB's implementation of transit provider
/// includes all KMB related data and API handling
///
/// KMB offers a full stop list and full route list API endpoint so we will be using that
class KmbProvider implements TransitProvider { // implements means to follow the provided interface, not extending bc theres nothing to build upon
  final TransitCacheService _cache; // starting underscore marks variable being private to this FILE
  final TransitUpdateScheduler _scheduler;
  static const _stopsEndpointName = "stops"; // static meaning var belongs to class
  static const _stopsUrl = 'https://data.etabus.gov.hk/v1/transport/kmb/stop';
  static const _routeEndpointName = "routes";
  static const _routeUrl = "https://data.etabus.gov.hk/v1/transport/kmb/route";

  KmbProvider(this._cache, this._scheduler);

  @override
  String get providerCode => "kmb";

  @override
  String get providerName => "KMB";

  @override
  String get IconAsset => "assets/icons/kmb.png";

  /// Fetches the full KMB stop list, using cached data when available.
  ///
  /// Falls back to a live network call if no cache exists or the
  /// cached data is stale, per [TransitUpdateScheduler]. Results are
  /// parsed via [_parseStops], which contains no I/O of its own.
  @override
  Future<List<BusStop>> fetchStops() async { // api call function, checks if the refresh timer is up, reads from cache, and call api if either fails
    return _fetchWithCache(_stopsEndpointName, _stopsUrl, _parseStops);
  }

  /// Fetches the full KMB route list, using cached data when available.
  ///
  /// Falls back to a live network call if no cache exists or the
  /// cached data is stale, per [TransitUpdateScheduler]. Results are
  /// parsed via [_parseStops], which contains no I/O of its own.
  @override
  Future<List<BusRoute>> fetchRoute() async { // api call function, checks if the refresh timer is up, reads from cache, and call api if either fails
    return _fetchWithCache(_routeEndpointName, _routeUrl, _parseRoutes);
  }

  Future<List<T>> _fetchWithCache<T>(String endpointName, String url, List<T> Function(String rawJson) parse) async {
    final needsRefresh = await _scheduler.shouldRefresh(providerCode, _stopsEndpointName);
    String? rawJson;
    if (!needsRefresh) {
      rawJson = await _cache.loadRawResponse(providerCode, _stopsEndpointName);
    }

    if (rawJson == null) { // will run if need refreshing or the read above got nothing
      rawJson = await _fetchAndCacheRaw(_stopsEndpointName, _stopsUrl);
      await _scheduler.markUpdated(providerCode, _stopsEndpointName);
    }

    return parse(rawJson);
  }

  /// helper function for doing the API call and handles API errors
  Future<String> _fetchAndCacheRaw(String endpointName, String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception("${providerName} ${endpointName} fetch failed: ${response.statusCode}");
    }
    await _cache.saveRawResponse(providerCode, _stopsEndpointName, response.body);
    return response.body;
  }

  /// transforms data into forms the app requires
  List<BusStop> _parseStops(String rawJson) {
    final decoded = jsonDecode(rawJson);
    final List<dynamic> data = decoded["data"];
    
    return data.map((s) { // maps each json object (s) into a bus stop object
      return BusStop(
          id: "${providerCode}:${s["stop"]}",
          names: {"en": s["name_en"] ?? "", "zh-hant": s["name_tc"] ?? "", "zh-hans": s["nname_sc"] ?? ""}, // all the ?? is for in case anything changes it doesnt error and die
          lat: double.tryParse(s["lat"].toString()),
          lng: double.tryParse(s["lng"].toString()),
          providerCode: providerCode
      );
    }).toList(); // map returns an Iterable object and we need to toList
  }

  List<BusRoute> _parseRoutes(String rawJson) {
    final decoded = jsonDecode(rawJson);
    final List<dynamic> data = decoded["data"];

    return data.map((r) {
      final routeNumber = r["route"] as String;
      final bound = r["bound"] as String;
      final serviceType = r["service_type"] as String;

      return BusRoute(
          id: "${providerCode}:${routeNumber}_${bound}_${serviceType}",
          names: {"en": routeNumber, "zh-Hant": routeNumber},
          routeNumber: routeNumber,
          bound: bound,
          origin: BusStop.placeholder(
              id: "${providerCode}:origin_${routeNumber}${bound}",
              name: r["orig_en"] ?? "", providerCode: providerCode),
          destination: BusStop.placeholder(
              id: "${providerCode}:destination_${routeNumber}${bound}",
              name: r["dest_en"] ?? "", providerCode: providerCode),
          destinationText: {"en": r["dest_en"] ?? "", "zh-Hant": r["dest_tc"] ?? "", "zh-Hans": r["dest_sc"] ?? ""},
          providerCode: providerCode
      );
    }).toList();
  }
}