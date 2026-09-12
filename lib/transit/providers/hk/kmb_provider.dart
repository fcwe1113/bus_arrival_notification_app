import 'dart:convert';

import 'package:bus_arrival_notification_app/transit/models/bus_route.dart';
import 'package:bus_arrival_notification_app/transit/services/transit_cache_service.dart';
import 'package:bus_arrival_notification_app/transit/services/transit_update_scheduler.dart';
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
  Future<List<BusStop>> fetchStops({bool forceRefresh = false}) async { // api call function, checks if the refresh timer is up, reads from cache, and call api if either fails
    return _fetchWithCache(_stopsEndpointName, _stopsUrl, _parseStops, forceRefresh: forceRefresh);
  }

  /// Fetches the full KMB route list, using cached data when available.
  ///
  /// Falls back to a live network call if no cache exists or the
  /// cached data is stale, per [TransitUpdateScheduler]. Results are
  /// parsed via [_parseStops], which contains no I/O of its own.
  @override
  Future<List<BusRoute>> fetchRoutes({bool forceRefresh = false}) async { // api call function, checks if the refresh timer is up, reads from cache, and call api if either fails
    print("fetchroute passed in endpointname ${_routeEndpointName} and url ${_routeUrl}");
    return _fetchWithCache(_routeEndpointName, _routeUrl, _parseRoutes, forceRefresh: forceRefresh);
  }

  Future<List<String>> fetchRouteStopIds(String route, String bound, String serviceType, {bool forceRefresh = false}) async {
    final endpointName = "route_stop_${route}_${bound}_${serviceType}";
    final url = 'https://data.etabus.gov.hk/v1/transport/kmb/route-stop/${route}/${bound == 'O' ? 'outbound' : 'inbound'}/${serviceType}';

    final needsRefresh = forceRefresh || await _scheduler.shouldRefresh(providerCode, endpointName);
    String? rawJson;
    if (!needsRefresh) {
      rawJson = await _cache.loadRawResponse(providerCode, endpointName);
    }

    if (rawJson == null) { // will run if need refreshing or the read above got nothing
      rawJson = await _fetchAndCacheRaw(endpointName, url);
      await _scheduler.markUpdated(providerCode, endpointName);
    }

    final decoded = jsonDecode(rawJson);
    final data = decoded["data"] as List;
    return data.map((s) => s["stop"] as String).toList();
  }

  Future<List<T>> _fetchWithCache<T>(String endpointName, String url, List<T> Function(String rawJson) parse, {bool forceRefresh = false}) async {
    final needsRefresh = forceRefresh || await _scheduler.shouldRefresh(providerCode, endpointName);
    String? rawJson;
    if (!needsRefresh) {
      rawJson = await _cache.loadRawResponse(providerCode, endpointName);
    }

    if (rawJson == null) { // will run if need refreshing or the read above got nothing
      rawJson = await _fetchAndCacheRaw(endpointName, url);
      await _scheduler.markUpdated(providerCode, endpointName);
    }

    return parse(rawJson);
  }

  /// helper function for doing the API call and handles API errors
  Future<String> _fetchAndCacheRaw(String endpointName, String url) async {
    print("calling API at: ${url}");
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception("${providerName} ${endpointName} fetch failed: ${response.statusCode}");
    }
    await _cache.saveRawResponse(providerCode, endpointName, response.body);
    return response.body;
  }

  /// transforms data into forms the app requires
  List<BusStop> _parseStops(String rawJson) {
    final decoded = jsonDecode(rawJson);
    final List<dynamic> data = decoded["data"];
    
    return data.map((s) { // maps each json object (s) into a bus stop object
      return BusStop(
          id: "${providerCode}:${s["stop"]}",
          names: {"en": s["name_en"] ?? "", "zh-Hant": s["name_tc"] ?? "", "zh-Hans": s["name_sc"] ?? ""}, // all the ?? is for in case anything changes it doesnt error and die
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
      final routeNumber = r["route"] as String? ?? "";
      final bound = r["bound"] as String? ?? "";
      final serviceType = r["service_type"] as String? ?? "";

      // print("${providerCode}:${routeNumber}_${bound}_${serviceType}");

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

  Future<List<BusStop>> buildStopsWithRoutes({void Function(int done, int total)? onProgress, bool forceRefresh = false}) async {
    final stops = await fetchStops();
    final routes = await fetchRoutes();

    final routeIdsByRawStopId = <String, Set<String>>{};

    for (var i = 0; i < routes.length; i++) {
      final route = routes[i];
      final rawStopIds = await fetchRouteStopIds(route.routeNumber, route.bound, "1", forceRefresh: forceRefresh); // replace 1 later
      for (final rawStopId in rawStopIds) {
        routeIdsByRawStopId.putIfAbsent(rawStopId, () => {}).add(route.id);
      }
      onProgress?.call(i + 1, routes.length);
    }

    return stops.map((stop) {
      final rawStopId = stop.id.split(":")[1]; // strips the "kmb:" prefix
      final routeIds = routeIdsByRawStopId[rawStopId] ?? {};
      return stop.copyWith(servingRouteIds: routeIds.toList());
    }).toList();
  }
}