import 'package:bus_arrival_notification_app/transit/providers/transit_provider.dart';
import 'package:bus_arrival_notification_app/transit/services/transit_cache_service.dart';
import 'package:bus_arrival_notification_app/transit/services/transit_update_scheduler.dart';
import 'package:http/http.dart' as http;

class BatchCallItem<K, T> {
  final K key;
  final String endpointName;
  final String url;
  final T Function(String rawJson) parse;

  const BatchCallItem({
    required this.key,
    required this.endpointName,
    required this.url,
    required this.parse
  });
}

class BatchCallResult<K, T> {
  final Map<K, T> results;
  final List<K> failedKeys;

  const BatchCallResult({required this.results, required this.failedKeys});
}

class ApiCaller {
  final TransitCacheService _cache;
  final TransitUpdateScheduler _scheduler;

  ApiCaller(this._cache, this._scheduler);

  Future<T> call<T>({required String providerCode, required String endpointName, required String url, required T Function(String rawJson) parse, bool forceRefresh = false}) async {
    final needsRefresh = forceRefresh || await _scheduler.shouldRefresh(providerCode, endpointName);
    String? rawJson;

    if (!needsRefresh) {
      rawJson = await _cache.loadRawResponse(providerCode, endpointName);
    }

    if (rawJson == null) {
      rawJson = await _fetchAndCacheRaw(providerCode, endpointName, url);
      await _scheduler.markUpdated(providerCode, endpointName);
    }

    return parse(rawJson!);
  }

  Future<BatchCallResult<K, T>> callBatch<K, T>({
    required String providerCode,
    required List<BatchCallItem<K, T>> items,
    int batchSize = 20,
    int maxAttempts = 3,
    Duration retryDelay = const Duration(seconds: 5),
    bool forceRefresh = false,
    void Function(int done, int total)? onProgress
  }) async {
    final results = <K, T>{};
    var pending = List<BatchCallItem<K, T>>.from(items);
    var doneCount = 0;

    for (var attempt = 1; attempt <= maxAttempts && pending.isNotEmpty; attempt++) {
      if (attempt > 1) {
        onProgress?.call(doneCount, items.length);
        await Future.delayed(retryDelay);
      }

      final failed = <BatchCallItem<K, T>>[];

      for (var i = 0; i < pending.length; i += batchSize) {
        final batch = pending.skip(i).take(batchSize).toList();

        final batchResults = await Future.wait(
          batch.map((item) async {
            try {
              final value = await call<T>(
                providerCode: providerCode,
                endpointName: item.endpointName,
                url: item.url,
                parse: item.parse,
                forceRefresh: forceRefresh
              );
              return (item: item, value: value, failed: false);
            } catch (e) {
              return (item: item, value: null, failed: true);
            }
          })
        );

        for (final r in batchResults) {
          if (r.failed) {
            failed.add(r.item);
          } else {
            results[r.item.key] = r.value as T;
            doneCount++;
          }
        }
        onProgress?.call(doneCount, items.length);
      }
      pending = failed;
    }
    return BatchCallResult(results: results, failedKeys: pending.map((i) => i.key).toList());
  }

  Future<String> _fetchAndCacheRaw(String providerCode, String endpointName, String url) async {
    print("fetching from ${url} for ${endpointName}");
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception("${endpointName} fetch failed: ${response.statusCode}");
    }
    await _cache.saveRawResponse(providerCode, endpointName, response.body);
    return response.body;
  }
}