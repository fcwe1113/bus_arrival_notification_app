import 'package:bus_arrival_notification_app/provider_registry.dart';
import 'package:bus_arrival_notification_app/transit/services/gtfs_database.dart';
import 'package:flutter/material.dart';

import '../transit/models/bus_route.dart';
import '../transit/models/bus_stop.dart';
import '../transit/models/gtfs_stop.dart';

class StopRoutesSheet extends StatelessWidget{
  final GtfsStop stop;

  const StopRoutesSheet({super.key, required this.stop});

  @override
  Widget build(BuildContext context) {
    final db = GtfsDatabase.forLocale("hk"); // todo remove hardcode
    return SafeArea(child: Container(
      height: MediaQuery.of(context).size.height * 0.5,
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(stop.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),), // todo check names locale
        const SizedBox(height: 12,),
        FutureBuilder(future: db.getRoutesForGtfsStop(stop.id), builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(height: 32, child: Center(child: CircularProgressIndicator(),),);
          }
          final routes = snapshot.data ?? [];
          if (routes.isEmpty) return const SizedBox.shrink();

          return SizedBox(height: 32, child: ListView(
            scrollDirection: Axis.horizontal,
            children: routes.map((route) => Padding(
              padding: const EdgeInsetsGeometry.only(right: 8),
              child: _RoutePill(route: route),)).toList(),
          ),);
        }),
        Expanded(
          child: FutureBuilder(
            future: db.getUpcomingDepartures(stop.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(),);
              }
              if (snapshot.hasError) {
                return Text("Error loading schedule: ${snapshot.error}");
              }
              final departures = snapshot.data ?? [];
              if (departures.isEmpty) {
                return Text("no scheduled departures found");
              }

              return FutureBuilder(future: db.getRoutesForGtfsStop(stop.id), builder: (context, routesSnapshot) {
                // skipping null check as all clickable map icons should already have valid routes within
                final routes = routesSnapshot.data ?? [];
                final displayDepartures = departures.where((d) { return routes.any((r) => r.routeNumber == d.routeShortName);}).toList();

                return Scrollbar(child: ListView(children: displayDepartures.map((d) {
                  final mins = d.minutesFromNow;
                  final label = mins <= 0 ? "Due" : mins > 60 ? "${(mins / 60).toStringAsFixed(2)} hr" : "${mins} min";
                  final matchRoute = routes.firstWhere((r) => r.routeNumber == d.routeShortName);

                  return ListTile(
                      leading: _RoutePill(route: matchRoute),
                      title: Text("Scheduled"),
                      trailing: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),)
                  );
                }
                ).toList()));
              });
            }
          ),
        )
      ],)
    ));
  }
}

class _RoutePill extends StatelessWidget {
  final BusRoute route;

  const _RoutePill({required this.route});

  @override
  Widget build(BuildContext context) {
    final provider = availableProviders.firstWhere((p) => p.providerCode == route.providerCode);
    final colours = provider.coloursForRoute(route);

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: colours.iconColour, borderRadius: BorderRadius.circular(11)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(route.routeNumber, style: TextStyle(color: colours.textColour, fontWeight: FontWeight.bold, fontSize: 13),)
      ],),
    );
  }
}