import 'package:bus_arrival_notification_app/provider_registry.dart';
import 'package:bus_arrival_notification_app/locale_gtfs_registry.dart';
import 'package:bus_arrival_notification_app/transit/progress_callback.dart';
import 'package:bus_arrival_notification_app/transit/services/gtfs_database.dart';
import 'package:bus_arrival_notification_app/transit/services/locale_selection_service.dart';

/// runs the data refresh routine for a given provider
Future<List<String>> initializeTransitData({ProgressCallback? onProgress, bool forceRefresh = false}) async {
  final allFailures = <String>[];
  final selectionService = LocaleSelectionService();
  final enabledLocales = await selectionService.getEnabledLocales();
  final enabledProviders = providersForLocales(enabledLocales);
  final gtfsProviders = LocaleGtfsRegistry.getProvidersForLocale(enabledLocales);

  for (final provider in gtfsProviders) {
    await provider.syncFeed(onProgress: onProgress);
  }

  for (final provider in enabledProviders) {
    final result = await provider.refresh(forceRefresh: forceRefresh, onProgress: onProgress);
    allFailures.addAll(result.failedItems.map((item) => "${provider.providerName}: $item"));
  }

  for (final locale in enabledLocales) {
    onProgress?.call("Matching stops for $locale...", null);
    await GtfsDatabase.forLocale(locale).matchOperatorStopsToGtfs();
  }

  onProgress?.call("Setup complete", 1.0);
  return allFailures;
}

Future<List<String>> refreshStaleProviders({ProgressCallback? onProgress, bool forceRefresh = false}) async {
  final selectionService = LocaleSelectionService();
  final enabledLocales = await selectionService.getEnabledLocales();
  final gtfsProviders = LocaleGtfsRegistry.getProvidersForLocale(enabledLocales);
  final enabledProviders = providersForLocales(enabledLocales);

  final allFailures = <String>[];

  for (final provider in gtfsProviders) {
    if (await provider.checkIsStale()) {
      await provider.syncFeed(onProgress: onProgress);
    }
  }

  for (final provider in enabledProviders) {
    final stale = forceRefresh || await provider.isStale();
    if (!stale) {
      onProgress?.call("${provider.providerName} is up to date", null);
      continue;
    }

    final result = await provider.refresh(onProgress: onProgress);
    allFailures.addAll(result.failedItems.map((item) => "${provider.providerName}: $item"));
  }

  for (final locale in enabledLocales) {
    onProgress?.call("Matching stops for $locale...", null);
    await GtfsDatabase.forLocale(locale).matchOperatorStopsToGtfs();
  }

  onProgress?.call("refresh check complete", 1.0);
  return allFailures;
}