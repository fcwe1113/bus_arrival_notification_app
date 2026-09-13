import 'dart:convert';

import 'package:bus_arrival_notification_app/transit/models/bus_route.dart';
import 'package:bus_arrival_notification_app/transit/services/transit_cache_service.dart';
import 'package:bus_arrival_notification_app/transit/services/transit_update_scheduler.dart';
import 'package:http/http.dart' as http;

import '../../models/bus_stop.dart';
import '../../models/enrichment_result.dart';
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
  static const _enrichedStopsEndpointName = "stops_enriched";

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
    print("fetchroute passed in endpointname $_routeEndpointName and url $_routeUrl");
    return _fetchWithCache(_routeEndpointName, _routeUrl, _parseRoutes, forceRefresh: forceRefresh);
  }

  /// Fetches the full list of stops for every route, using cached data when available.
  ///
  /// Falls back to live network call if no cache exists or the cached data is stale
  /// unlike [fetchStops] and [fetchRoutes] the parsing code is also here because we have to
  /// register routes into every stop and that requires looping through every route in the list
  Future<List<String>> fetchRouteStopIds(String route, String bound, String serviceType, {bool forceRefresh = false}) async {
    final endpointName = "route_stop_${route}_${bound}_$serviceType";
    final url = 'https://data.etabus.gov.hk/v1/transport/kmb/route-stop/$route/${bound == 'O' ? 'outbound' : 'inbound'}/$serviceType';

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

  /// Fetches a given endpoint, live calling the url if not cache is available
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
    print("calling API at: $url");
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception("$providerName $endpointName fetch failed: ${response.statusCode}");
    }
    await _cache.saveRawResponse(providerCode, endpointName, response.body);
    return response.body;
  }

  /// transforms stops data into forms the app requires
  /// in this case just slotting the different fields the api
  /// responded into the correct slot
  List<BusStop> _parseStops(String rawJson) {
    final decoded = jsonDecode(rawJson);
    final List<dynamic> data = decoded["data"];
    
    return data.map((s) { // maps each json object (s) into a bus stop object
      return BusStop(
          id: "$providerCode:${s["stop"]}",
          names: {"en": s["name_en"] ?? "", "zh-Hant": s["name_tc"] ?? "", "zh-Hans": s["name_sc"] ?? ""}, // all the ?? is for in case anything changes it doesnt error and die
          lat: double.tryParse(s["lat"].toString()),
          lng: double.tryParse(s["long"].toString()),
          providerCode: providerCode
      );
    }).toList(); // map returns an Iterable object and we need to toList
  }

  /// transforms route data into forms the app requires
  /// in this case in addition to slotting data into the correct var
  /// placeholder bus stop objects were created to fill origin and destination
  List<BusRoute> _parseRoutes(String rawJson) {
    final decoded = jsonDecode(rawJson);
    final List<dynamic> data = decoded["data"];

    return data.map((r) {
      final routeNumber = r["route"] as String? ?? "";
      final bound = r["bound"] as String? ?? "";
      final serviceType = r["service_type"] as String? ?? "";

      // print("${providerCode}:${routeNumber}_${bound}_${serviceType}");

      return BusRoute(
          id: "$providerCode:${routeNumber}_${bound}_$serviceType",
          names: {"en": routeNumber, "zh-Hant": routeNumber},
          routeNumber: routeNumber,
          bound: bound,
          originText: {"en": r["origin_en"] ?? "", "zh-Hant": r["origin_tc"] ?? "", "zh-Hans": r["origin_sc"] ?? ""},
          destinationText: {"en": r["dest_en"] ?? "", "zh-Hant": r["dest_tc"] ?? "", "zh-Hans": r["dest_sc"] ?? ""},
          providerCode: providerCode
      );
    }).toList();
  }

  ///
  @override
  Future<EnrichmentResult> buildStopsWithRoutes({void Function(int done, int total)? onProgress, bool forceRefresh = false}) async {
    if (!forceRefresh) { // will try to read from cache if its available
      final cached = await _cache.loadRawResponse(providerCode, _enrichedStopsEndpointName);
      if (cached != null) return EnrichmentResult(stops: _deserializeEnrichedStops(cached), failedRouteNumbers: []);
    }

    // get the full stop/route list
    final stops = await fetchStops();
    final routes = await fetchRoutes();
    final routeIdsByRawStopId = <String, Set<String>>{};

    const batchSize = 20; // controls how many calls the app tries at once
    var pendingRoutes = List<BusRoute>.from(routes); // populated at start with full route list
    var doneCount = 0; // progress report tally
    
    const maxAttempts = 3; // max attempts before giving up
    for (var attempt = 1; attempt <= maxAttempts && pendingRoutes.isNotEmpty; attempt++) {
      if (attempt > 1) { // reset progress counter and delays attempts past first try
        onProgress?.call(doneCount, routes.length);
        await Future.delayed(const Duration(seconds: 5));
      }
      
      final failedRoutes = <BusRoute>[]; // list to collect failed calls
      
      for (var i = 0; i< pendingRoutes.length; i += batchSize) { // loop through the list per batch size
        final batch = pendingRoutes.skip(i).take(batchSize).toList();
        final results = await Future.wait(batch.map((route) async {
          // creates a future per call and catches any individual errors
          try {
            final stopIds = await fetchRouteStopIds(route.routeNumber, route.bound, "1", forceRefresh: forceRefresh);
            return (route: route, stopIds: stopIds, failed: false);
          } catch (e) {
            return (route: route, stopIds: <String>[], failed: true);
          }
        }));

        // move data from sucessful calls into the correct place and failed calls into the failed list
        for (final result in results) {
          if (result.failed) {
            failedRoutes.add(result.route);
          } else {
            for (final rawStopId in result.stopIds) {
              routeIdsByRawStopId.putIfAbsent(rawStopId, () => {}).add(result.route.id);
            }
            doneCount++;
          }
        }
        onProgress?.call(doneCount, routes.length);
      }
      pendingRoutes = failedRoutes;
    }

    final enrichedStops = stops.map((stop) {
      final rawStopId = stop.id.split(":")[1];
      final routeIds = routeIdsByRawStopId[rawStopId] ?? <String>[];
      return stop.copyWith(servingRouteIds: routeIds.toList());
    }).toList();

    await _cache.saveRawResponse(providerCode, _enrichedStopsEndpointName, jsonEncode(enrichedStops.map(_serializeStop).toList()));

    return EnrichmentResult(stops: enrichedStops, failedRouteNumbers: pendingRoutes.map((r) => r.routeNumber).toList());
  }

  Map<String, dynamic> _serializeStop(BusStop stop) => {
    "id": stop.id,
    "names": stop.names,
    "lat": stop.lat,
    "lng": stop.lng,
    "providerCode": stop.providerCode,
    "servingRouteIds": stop.servingRouteIds
  };

  List<BusStop> _deserializeEnrichedStops(String rawJson) {
    final List<dynamic> data = jsonDecode(rawJson);
    return data.map((s) => BusStop(
        id: s["id"],
        names: Map<String, String>.from(s["names"]),
        lat: s["lat"],
        lng: s["lng"],
        providerCode: s["providerCode"],
        servingRouteIds: List<String>.from(s["servingRouteIds"]))
    ).toList();
  }
}