import 'package:bus_arrival_notification_app/transit/providers/hk/kmb_provider.dart';
import 'package:bus_arrival_notification_app/transit/providers/transit_provider.dart';
import 'package:bus_arrival_notification_app/transit/services/transit_cache_service.dart';
import 'package:bus_arrival_notification_app/transit/services/transit_update_scheduler.dart';

final TransitCacheService _cacheService = TransitCacheService();
final TransitUpdateScheduler _updateScheduler = TransitUpdateScheduler();

final Map<String, List<TransitProvider>> providersByLocale = {
  'hk': [
    KmbProvider(_cacheService, _updateScheduler)
  ],
  // 'nyc': [MtaProvider()],  // future
};

List<TransitProvider> get availableProviders => providersByLocale.values.expand((providers) => providers).toList();