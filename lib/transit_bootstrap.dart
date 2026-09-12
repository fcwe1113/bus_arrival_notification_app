import 'package:bus_arrival_notification_app/provider_registry.dart';
import 'package:bus_arrival_notification_app/transit/services/provider_selection_service.dart';

Future<void> initializeTransitData() async {
  final selectionService = ProviderSelectionService();
  final enabledCodes = await selectionService.getEnabledProviderCodes();
  final enabledProviders = availableProviders.where((p) => enabledCodes.contains(p.providerCode)).toList();
  for (final provider in enabledProviders) {
    await provider.fetchStops();
  }
}