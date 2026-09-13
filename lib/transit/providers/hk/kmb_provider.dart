import 'dart:convert';

import 'package:bus_arrival_notification_app/transit/models/bus_route.dart';
import 'package:bus_arrival_notification_app/transit/providers/refresh_result.dart';
import 'package:bus_arrival_notification_app/transit/services/api_caller.dart';
import 'package:bus_arrival_notification_app/transit/services/transit_cache_service.dart';
import 'package:bus_arrival_notification_app/transit/services/transit_update_scheduler.dart';
import 'package:http/http.dart' as http;

import '../../models/bus_stop.dart';
import '../../models/enrichment_result.dart';
import '../../progress_callback.dart';
import '../transit_provider.dart';

/// KMB's implementation of transit provider
/// includes all KMB related data and API handling
///
/// KMB offers a full stop list and full route list API endpoint so we will be using that
class KmbProvider implements TransitProvider { // implements means to follow the provided interface, not extending bc theres nothing to build upon
  final TransitCacheService _cache; // starting underscore marks variable being private to this FILE
  final ApiCaller _apiCaller;
  static const _stopsEndpointName = "stops"; // static meaning var belongs to class
  static const _stopsUrl = 'https://data.etabus.gov.hk/v1/transport/kmb/stop';
  static const _routeEndpointName = "routes";
  static const _routeUrl = "https://data.etabus.gov.hk/v1/transport/kmb/route";
  static const _enrichedStopsEndpointName = "stops_enriched";

  KmbProvider(this._apiCaller, this._cache);

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
    return _apiCaller.call(providerCode: providerCode, endpointName: _stopsEndpointName, url: _stopsUrl, parse: _parseStops, forceRefresh: forceRefresh);
  }

  /// Fetches the full KMB route list, using cached data when available.
  ///
  /// Falls back to a live network call if no cache exists or the
  /// cached data is stale, per [TransitUpdateScheduler]. Results are
  /// parsed via [_parseStops], which contains no I/O of its own.
  @override
  Future<List<BusRoute>> fetchRoutes({bool forceRefresh = false}) async { // api call function, checks if the refresh timer is up, reads from cache, and call api if either fails
    return _apiCaller.call(providerCode: providerCode, endpointName: _routeEndpointName, url: _routeUrl, parse: _parseRoutes, forceRefresh: forceRefresh);
  }

  @override
  Future<RefreshResult> refresh({bool forceRefresh = false, ProgressCallback? onProgress}) async {
    if (!forceRefresh) {
      final cached = await _cache.loadRawResponse(providerCode, _enrichedStopsEndpointName);
      if (cached != null) return const RefreshResult();
    }

    onProgress?.call("Fetching KMB stops...", null);
    final stops  = await fetchStops(forceRefresh: forceRefresh);

    onProgress?.call("Fetching KMB routes...", null);
    final routes  = await fetchRoutes(forceRefresh: forceRefresh);

    final items = routes.map((route) => BatchCallItem(
        key: route,
        endpointName: "route_stop_${route.routeNumber}_${route.bound}_1",
        url: 'https://data.etabus.gov.hk/v1/transport/kmb/route-stop/',
        parse: ((rawJson) {
          final decoded = jsonDecode(rawJson);
          final data = decoded["data"] as List;
          return data.map((s) => s["stop"] as String).toList();
        }))).toList();

    final batchResult = await _apiCaller.callBatch<BusRoute, List<String>>(
        providerCode: providerCode,
        items: items,
        forceRefresh: forceRefresh,
        onProgress: (done, total) => onProgress?.call("Linking routes to stops (${done}/${total})", total > 0 ? done / total : null)
    );

    final routeIdsByRawStopId = <String, Set<String>>{};
    batchResult.results.forEach((route, rawStopsIds) {
      for (final rawStopId in rawStopsIds) {
        routeIdsByRawStopId.putIfAbsent(rawStopId, () => {}).add(route.id);
      }
    });

    final enrichedStops = stops.map((stop) {
      final rawStopIds = stop.id.split(":")[1];
      final routeIds = routeIdsByRawStopId[rawStopIds] ?? <String>[];
      return stop.copyWith(servingRouteIds: routeIds.toList());
    }).toList();

    await _cache.saveRawResponse(providerCode, _enrichedStopsEndpointName, jsonEncode(enrichedStops.map(_serializeStop).toList()));

    onProgress?.call("KMB setup complete", 1.0);

    return RefreshResult(failedItems: batchResult.failedKeys.map((r) => r.routeNumber).toList());
  }

  /// transforms stops data into forms the app requires
  /// in this case just slotting the different fields the api
  /// responded into the correct slot
  List<BusStop> _parseStops(String rawJson) {
    final decoded = jsonDecode(rawJson);
    final List<dynamic> data = decoded["data"];
    
    return data.map((s) => BusStop(
        id: "${providerCode}:${s["stop"]}",
        names: {"en": s["name_en"] as String? ?? "", "zh-Hant": s["name_tc"] as String? ?? "", "zh-Hans": s["name_sc"] as String? ?? ""},
        lat: double.tryParse(s["lat"].toString()),
        lng: double.tryParse(s["long"].toString()),
        providerCode: providerCode)).toList();
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
      return BusRoute(
        id: "${providerCode}:${routeNumber}_${bound}_${serviceType}",
        names: {"en": routeNumber, "zh-Hant": routeNumber},
        routeNumber: routeNumber,
        bound: bound,
        originText: {"en": r["orig_en"], "zh-Hant": r["orig_tc"], "zh-Hans": r["orig_sc"]},
        destinationText: {"en": r["dest_en"], "zh-Hant": r["dest_tc"], "zh-Hans": r["dest_sc"]},
        providerCode: providerCode
      );
    }).toList();
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