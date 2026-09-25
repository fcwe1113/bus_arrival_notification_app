import 'package:transport_alarm/models/scheduled_departure.dart';
import 'package:transport_alarm/transit/models/bus_route.dart';
import 'package:transport_alarm/transit/models/route_arrival.dart';
import 'package:transport_alarm/transit/services/gtfs_database.dart';

import '../../provider_registry.dart';
import '../models/gtfs_stop.dart';
import '../models/live_eta.dart';

Future<List<RouteArrival>> resolveArrivals({
  required String gtfsStopId,
  List<String>? routeNumberFilter,
}) async {
  final db = GtfsDatabase.forLocale("hk"); // todo fix locale hardcode
  final allRoutes = await db.getRoutesForGtfsStop(gtfsStopId);
  final routes = routeNumberFilter == null ? allRoutes : allRoutes.where((r) => routeNumberFilter.contains(r.routeNumber)).toList();
  final results = await Future.wait([_fetchLiveEtaForStop((await db.getGtfsStopById(gtfsStopId))!), db.getUpcomingDepartures(gtfsStopId, limit: 50)]);
  final liveEtas = (results[0] as List<LiveEta>).where((e) => e.etaTime != null).toList();
  final scheduled = results[1] as List<ScheduledDeparture>;

  final routeGroups = <String, List<BusRoute>>{};
  for (final route in routes) {
    routeGroups.putIfAbsent(route.routeNumber, () => []).add(route);
  }

  final arrivals = <RouteArrival>[];
  for (final group in routeGroups.values) {
    final representative = group.first;
    final matchingLive = liveEtas.where((e) => group.any((r) => e.routeNumber == r.routeNumber)).toList()..sort((a, b) => a.etaTime!.compareTo(b.etaTime!));
    if (matchingLive.isNotEmpty) {
      arrivals.add(RouteArrival(route: representative, minutesFromNow: matchingLive.first.minutesFromNow!, isLive: true));
      continue;
    }

    final matchingScheduled = scheduled.where((d) => group.any((r) => d.routeShortName == r.routeNumber)).toList()..sort((a, b) => a.minutesFromNow.compareTo(b.minutesFromNow));
    if (matchingScheduled.isNotEmpty) {
      arrivals.add(RouteArrival(route: representative, minutesFromNow: matchingScheduled.first.minutesFromNow, isLive: false));
    }
  }

  arrivals.sort((a, b) => a.minutesFromNow.compareTo(b.minutesFromNow));
  return arrivals;
}

Future<List<LiveEta>> _fetchLiveEtaForStop(GtfsStop stop) async {
  final operatorStopIds = await GtfsDatabase.forLocale("hk").getOperatorStopIds(stop.id); // todo fix hardcode

  final idsByProvider = <String,List<String>>{};
  for (final operatorStopId in operatorStopIds) {
    final parts = operatorStopId.split(":");
    final providerCode = parts[0];
    final rawId = parts[1];
    idsByProvider.putIfAbsent(providerCode, () => []).add(rawId);
  }

  final allEtas = <LiveEta>[];

  for (final entry in idsByProvider.entries) {
    final providerCode = entry.key;
    final rawIds = entry.value;
    final provider = availableProviders.where((p) => p.providerCode == providerCode).firstOrNull;
    if (provider == null) continue; // skip stops with no valid providers
    for (final rawId in rawIds) {
      try {
        final etas = await provider.fetchLiveEta(rawId);
        allEtas.addAll(etas);
      } catch (_) {
        // do nothing
      }
    }
  }

  return allEtas;
}