import 'package:bus_arrival_notification_app/provider_registry.dart';
import 'package:bus_arrival_notification_app/transit/progress_callback.dart';
import 'package:bus_arrival_notification_app/transit/providers/hk/kmb_provider.dart';
import 'package:bus_arrival_notification_app/transit/services/provider_selection_service.dart';
import 'package:flutter/cupertino.dart';

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

Future<List<String>> refreshStaleProviders({ProgressCallback? onProgress, bool forceRefresh = false}) async {
  final selectionService = ProviderSelectionService();
  final enabledCodes = await selectionService.getEnabledProviderCodes();
  final enabledProviders = availableProviders.where((p) => enabledCodes.contains(p.providerCode)).toList();

  final allFailures = <String>[];

  for (final provider in enabledProviders) {
    final stale = await provider.isStale();
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