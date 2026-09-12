import 'package:shared_preferences/shared_preferences.dart';

class TransitUpdateScheduler {
  static const _refreshInterval = Duration(days: 1);

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