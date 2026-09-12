// service to cache the api outputs
// transition to caching the dataclass themselves later

import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Persists and retrieves raw (unparsed) API response bodies for
/// each transit provider, keyed by [providerCode] and [endpoint].
///
/// Storing raw responses — rather than parsed model objects — means
/// changes to model classes (e.g. [BusStop]) never invalidate the
/// cache; only actual data staleness does, tracked separately by
/// [TransitUpdateScheduler].
class TransitCacheService {
  Future<void> saveRawResponse(String providerCode, String endpoint, String rawJson) async {
    final file = await _fileFor(providerCode, endpoint);
    await file.create(recursive: true);
    await file.writeAsString(rawJson);
  }

  Future<String?> loadRawResponse(String providerCode, String endpoint) async {
    final file = await _fileFor(providerCode, endpoint);
    if (!await file.exists()) return null;
    return file.readAsString();
  }

  Future<File> _fileFor(String providerCode, String endpoint) async { // the code that enforces file structure
    final dir = await getApplicationDocumentsDirectory(); // dir.path likely /data/data/com.fcwe1113.bus_arrival_notification_app/app_flutter
    return File("${dir.path}/transit_cache/${providerCode}/${endpoint}.json");
  }
}