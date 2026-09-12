import 'dart:convert';

import 'package:bus_arrival_notification_app/transit/services/transit_cache_service.dart';
import 'package:bus_arrival_notification_app/transit/services/transit_update_scheduler.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

import '../../models/bus_stop.dart';
import '../transit_provider.dart';

class KmbProvider implements TransitProvider {
  final TransitCacheService _cache;
  final TransitUpdateScheduler _scheduler;
  static const _endpointName = "stops";
  static const _url = 'https://data.etabus.gov.hk/v1/transport/kmb/stop';

  KmbProvider(this._cache, this._scheduler);

  @override
  String get providerCode => "kmb";

  @override
  String get providerName => "KMB";

  @override
  String get IconAsset => "assets/icons/kmb.png";

  @override
  Future<List<BusStop>> fetchStops() async {
    final needsRefresh = await _scheduler.shouldRefresh(providerCode, _endpointName);
    String? rawJson;
    if (!needsRefresh) {
      rawJson = await _cache.loadRawResponse(providerCode, _endpointName);
    }

    if (rawJson == null) { // it need refreshing or the read above got nothing
      rawJson = await _fetchAndCacheRaw();
      await _scheduler.markUpdated(providerCode, _endpointName);
    }

    return _parseStops(rawJson);
  }

  Future<String> _fetchAndCacheRaw() async {
    final response = await http.get(Uri.parse(_url));
    if (response.statusCode != 200) {
      throw Exception("${providerName} stop fetch failed: ${response.statusCode}");
    }
    await _cache.saveRawResponse(providerCode, _endpointName, response.body);
    return response.body;
  }

  List<BusStop> _parseStops(String rawJson) {
    final decoded = jsonDecode(rawJson);
    final List<dynamic> data = decoded["data"];
    
    return data.map((s) {
      return BusStop(
          id: "${providerCode}:${s["stop"]}",
          names: {"en": s["name_en"] ?? "", "zh-hant": s["name_tc"] ?? "", "zh-hans": s["nname_sc"] ?? ""},
          lat: double.tryParse(s["lat"].toString()),
          lng: double.tryParse(s["lng"].toString()),
          providerCode: providerCode
      );
    }).toList();
  }
}