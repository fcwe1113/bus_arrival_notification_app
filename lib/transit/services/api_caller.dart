import 'package:bus_arrival_notification_app/transit/services/transit_cache_service.dart';
import 'package:http/http.dart' as http;

class BatchCallItem<K, T> {
  final K key;
  final String endpointName;
  final String url;
  final T Function(String rawJson) parseRaw;
  final Map<String, dynamic> Function(T) toJson;
  final T Function(Map<String, dynamic>) fromJson;

  const BatchCallItem({
    required this.key,
    required this.endpointName,
    required this.url,
    required this.parseRaw,
    required this.toJson,
    required this.fromJson
  });
}

class BatchCallResult<K, T> {
  final Map<K, T> results;
  final List<K> failedKeys;

  const BatchCallResult({required this.results, required this.failedKeys});
}

class ApiCaller {
  final TransitCacheService _cache;
  static const _defaultMaxAge = Duration(days: 7);

  ApiCaller(this._cache);

  Future<T> call<T>({
    required String providerCode,
    required String endpointName,
    required String url,
    required T Function(String rawJson) parseRaw,
    required Map<String, dynamic> Function(T) toJson,
    required T Function(Map<String, dynamic>) fromJson,
    bool forceRefresh = false,
    Duration maxAge = _defaultMaxAge
  }) async {
    if (!forceRefresh) {
      final cached = await _cache.load<T>(providerCode: providerCode, endpointName: endpointName, fromJson: fromJson);
      if (cached != null && !cached.isStale(maxAge)) return cached.data;
    }

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception("${endpointName} fetch failed: ${response.statusCode}");
    }

    final data = parseRaw(response.body);
    await _cache.save<T>(providerCode: providerCode, endpointName: endpointName, data: data, sourceUrl: url, toJson: toJson);
    return data;
  }

  Future<BatchCallResult<K, T>> callBatch<K, T>({
    required String providerCode,
    required List<BatchCallItem<K, T>> items,
    int batchSize = 20,
    int maxAttempts = 3,
    Duration retryDelay = const Duration(seconds: 5),
    bool forceRefresh = false,
    Duration maxAge = _defaultMaxAge,
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

        final batchResults = await Future.wait(batch.map((item) async {
          try {
            final value = await call<T>(
              providerCode: providerCode,
              endpointName: item.endpointName,
              url: item.url,
              parseRaw: item.parseRaw,
              toJson: item.toJson,
              fromJson: item.fromJson,
              forceRefresh: forceRefresh,
              maxAge: maxAge
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

  Future<void> saveComputed<T>({
    required String providerCode,
    required String endpointName,
    required T data,
    required String sourceUrl,
    required Map<String, dynamic> Function(T) toJson
  }) async {
    return _cache.save(providerCode: providerCode, endpointName: endpointName, data: data, sourceUrl: sourceUrl, toJson: toJson);
  }

  Future<CachedEntry<T>?> peek<T>({
    required String providerCode,
    required String endpointName,
    required T Function(Map<String, dynamic>) fromJson
  }) async {
    return _cache.load<T>(providerCode: providerCode, endpointName: endpointName, fromJson: fromJson);
  }
}