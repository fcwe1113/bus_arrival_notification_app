import 'dart:convert';

import 'package:bus_arrival_notification_app/transit/services/transit_cache_service.dart';
import 'package:bus_arrival_notification_app/transit/services/transit_update_scheduler.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

import '../../models/bus_stop.dart';
import '../transit_provider.dart';

/// KMB's implementation of transit provider
/// includes all KMB related data and API handling
class KmbProvider implements TransitProvider { // implements means to follow the provided interface, not extending bc theres nothing to build upon
  final TransitCacheService _cache; // starting underscore marks variable being private to this FILE
  final TransitUpdateScheduler _scheduler;
  static const _endpointName = "stops"; // static meaning var belongs to class
  static const _url = 'https://data.etabus.gov.hk/v1/transport/kmb/stop';

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
    final needsRefresh = await _scheduler.shouldRefresh(providerCode, _endpointName);
    String? rawJson;
    if (!needsRefresh) {
      rawJson = await _cache.loadRawResponse(providerCode, _endpointName);
    }

    if (rawJson == null) { // will run if need refreshing or the read above got nothing
      rawJson = await _fetchAndCacheRaw();
      await _scheduler.markUpdated(providerCode, _endpointName);
    }

    return _parseStops(rawJson);
  }

  /// helper function for doing the API call and handles API errors
  Future<String> _fetchAndCacheRaw() async {
    final response = await http.get(Uri.parse(_url));
    if (response.statusCode != 200) {
      throw Exception("${providerName} stop fetch failed: ${response.statusCode}");
    }
    await _cache.saveRawResponse(providerCode, _endpointName, response.body);
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
}