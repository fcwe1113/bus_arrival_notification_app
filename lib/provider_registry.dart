import 'package:bus_arrival_notification_app/transit/locale/hk/providers/kmb_provider.dart';
import 'package:bus_arrival_notification_app/transit/transit_provider.dart';
import 'package:bus_arrival_notification_app/transit/services/api_caller.dart';
import 'package:bus_arrival_notification_app/transit/services/transit_cache_service.dart';
import 'package:bus_arrival_notification_app/transit/services/transit_update_scheduler.dart';

final TransitCacheService _cacheService = TransitCacheService();
final ApiCaller _apiCaller = ApiCaller(_cacheService);

final Map<String, List<TransitProvider>> providersByLocale = {
  'hk': [
    KmbProvider(_apiCaller)
  ],
  // 'nyc': [MtaProvider()],  // future
};

const Map<String, String> localeDisplayNames = {
  "hk": "Hong Kong"
};

List<TransitProvider> get availableProviders => providersByLocale.values.expand((providers) => providers).toList();

List<dynamic> providersForLocales(List<String> locales) { // todo may fix later
  return locales.expand((locale) => providersByLocale[locale] ?? []).toList();
}