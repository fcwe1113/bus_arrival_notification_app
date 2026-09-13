import 'package:bus_arrival_notification_app/transit/providers/hk/kmb_provider.dart';
import 'package:bus_arrival_notification_app/transit/providers/transit_provider.dart';
import 'package:bus_arrival_notification_app/transit/services/api_caller.dart';
import 'package:bus_arrival_notification_app/transit/services/transit_cache_service.dart';
import 'package:bus_arrival_notification_app/transit/services/transit_update_scheduler.dart';

final TransitCacheService _cacheService = TransitCacheService();
final TransitUpdateScheduler _updateScheduler = TransitUpdateScheduler();
final ApiCaller _apiCaller = ApiCaller(_cacheService, _updateScheduler);

final Map<String, List<TransitProvider>> providersByLocale = {
  'hk': [
    KmbProvider(_apiCaller, _cacheService)
  ],
  // 'nyc': [MtaProvider()],  // future
};

List<TransitProvider> get availableProviders => providersByLocale.values.expand((providers) => providers).toList();