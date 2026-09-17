import 'package:bus_arrival_notification_app/provider_registry.dart';
import 'package:bus_arrival_notification_app/transit/progress_callback.dart';
import 'package:bus_arrival_notification_app/transit/services/locale_selection_service.dart';

/// runs the data refresh routine for a given provider
Future<List<String>> initializeTransitData({ProgressCallback? onProgress, bool forceRefresh = false}) async {
  final allFailures = <String>[];
  final selectionService = LocaleSelectionService();
  final enabledCodes = await selectionService.getEnabledLocales();
  final enabledProviders = availableProviders.where((p) => enabledCodes.contains(p.providerCode)).toList();

  for (final provider in enabledProviders) {
    final result = await provider.refresh(forceRefresh: forceRefresh, onProgress: onProgress);
    allFailures.addAll(result.failedItems.map((item) => "${provider.providerName}: ${item}"));
  }

  onProgress?.call("Setup complete", 1.0);
  return allFailures;
}

Future<List<String>> refreshStaleProviders({ProgressCallback? onProgress, bool forceRefresh = false}) async {
  final selectionService = LocaleSelectionService();
  final enabledLocales = await selectionService.getEnabledLocales();
  final enabledProviders = providersForLocales(enabledLocales);

  final allFailures = <String>[];

  for (final provider in enabledProviders) {
    final stale = forceRefresh || await provider.isStale();
    if (!stale) {
      onProgress?.call("${provider.providerName} is up to date", null);
      continue;
    }

    final result = await provider.refresh(onProgress: onProgress);
    allFailures.addAll(result.failedItems.map((item) => "${provider.providerName}: ${item}"));
  }

  onProgress?.call("refresh check complete", 1.0);
  return allFailures;
}