import 'package:bus_arrival_notification_app/transit/locale/hk/providers/kmb_provider.dart';
import 'package:bus_arrival_notification_app/transit/transit_provider.dart';
import 'package:bus_arrival_notification_app/transit/services/api_caller.dart';

final ApiCaller _apiCaller = ApiCaller();

final Map<String, List<TransitProvider>> providersByLocale = {
  'hk': [KmbProvider(_apiCaller)],
  // 'nyc': [MtaProvider()],  // future
};

const Map<String, String> localeDisplayNames = {
  "hk": "Hong Kong"
};

List<TransitProvider> get availableProviders => providersByLocale.values.expand((providers) => providers).toList();

List<TransitProvider> providersForLocales(List<String> locales) { // todo may fix later
  return locales.expand((locale) => providersByLocale[locale] ?? <TransitProvider>[]).toList();
}