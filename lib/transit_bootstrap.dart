import 'package:bus_arrival_notification_app/provider_registry.dart';
import 'package:bus_arrival_notification_app/transit/progress_callback.dart';
import 'package:bus_arrival_notification_app/transit/providers/hk/kmb_provider.dart';
import 'package:bus_arrival_notification_app/transit/services/provider_selection_service.dart';

/// runs the data refresh routine for a given provider
Future<List<String>> initializeTransitData({ProgressCallback? onProgress, bool forceRefresh = false}) async {
  final allFailures = <String>[];
  final selectionService = ProviderSelectionService();
  final enabledCodes = await selectionService.getEnabledProviderCodes();
  final enabledProviders = availableProviders.where((p) => enabledCodes.contains(p.providerCode)).toList();

  for (final provider in enabledProviders) {
    final result = await provider.refresh(forceRefresh: forceRefresh, onProgress: onProgress);
    allFailures.addAll(result.failedItems.map((item) => "${provider.providerName}: ${item}"));
  }

  onProgress?.call("Setup complete", 1.0);
  return allFailures;
}