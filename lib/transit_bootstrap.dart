import 'package:bus_arrival_notification_app/provider_registry.dart';
import 'package:bus_arrival_notification_app/transit/progress_callback.dart';
import 'package:bus_arrival_notification_app/transit/providers/hk/kmb_provider.dart';
import 'package:bus_arrival_notification_app/transit/services/provider_selection_service.dart';

Future<void> initializeTransitData({ProgressCallback? onProgress, bool forceRefresh = false}) async {
  final selectionService = ProviderSelectionService();
  final enabledCodes = await selectionService.getEnabledProviderCodes();
  final enabledProviders = availableProviders.where((p) => enabledCodes.contains(p.providerCode)).toList();

  for (var i = 0; i < enabledProviders.length; i++) {
    final provider = enabledProviders[i];
    onProgress?.call("Fetching stops for ${provider.providerName}...", null);
    await provider.fetchStops(forceRefresh: forceRefresh);
    onProgress?.call("Fetching routes for ${provider.providerName}...", null);
    await provider.fetchRoutes(forceRefresh: forceRefresh);

    // add in interface for checking later if needed
    if (provider is KmbProvider) {
      await provider.buildStopsWithRoutes(
        forceRefresh: forceRefresh,
        onProgress: (done, total) => onProgress?.call("Linking routes to stops for ${provider.providerName} (${done}/${total})", total > 0 ? done / total : null)
      );
    }
  }

  onProgress?.call("Setup complete", 1.0);
}