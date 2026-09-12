import 'package:shared_preferences/shared_preferences.dart';

/// Tracks when each provider's data was last fetched, and decides
/// whether cached data is stale enough to warrant a live refetch.
///
/// Stores only small timestamp metadata — actual cached payloads
/// live separately in [TransitCacheService].
class TransitUpdateScheduler {
  static const _refreshInterval = Duration(days: 7); // todo make this configurable later

  // SharedPreferences is a wrapper for SharedPreferences(android) and UserDefaults(IOS)

  Future<bool> shouldRefresh(String providerCode, String endpoint) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _keyFor(providerCode, endpoint);
    final lastUpdatedMillis = prefs.getInt(key);

    if (lastUpdatedMillis == null) return true; // this will trigger if never fetched

    final lastUpdated = DateTime.fromMillisecondsSinceEpoch(lastUpdatedMillis);
    return DateTime.now().difference(lastUpdated) > _refreshInterval;
  }

  Future<void> markUpdated(String providerCode, String endpoint) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _keyFor(providerCode, endpoint);
    await prefs.setInt(key, DateTime.now().millisecondsSinceEpoch);
  }

  String _keyFor(String providerCode, String endpoint) => "${providerCode}_${endpoint}_last_updated";
}