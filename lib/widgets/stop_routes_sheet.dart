import 'package:bus_arrival_notification_app/provider_registry.dart';
import 'package:bus_arrival_notification_app/transit/services/gtfs_database.dart';
import 'package:flutter/material.dart';

import '../transit/models/bus_route.dart';
import '../transit/models/bus_stop.dart';

class StopRoutesSheet extends StatelessWidget{
  final BusStop stop;
  final List<BusRoute> routes;

  const StopRoutesSheet({super.key, required this.stop, required this.routes});

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Container(
      height: MediaQuery.of(context).size.height * 0.5,
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(stop.names["en"] ?? stop.id, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
        const SizedBox(height: 12,),
        if (routes.isNotEmpty) ...[
          SizedBox(height: 28, child: ListView(
            scrollDirection: Axis.horizontal,
            children: routes.map((route) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _RoutePill(route: route))
            ).toList(),
          ),), const SizedBox(height: 12,)
        ],
        Expanded(
          child: FutureBuilder(
            future: GtfsDatabase.forLocale("hk").getUpcomingDepartures(stop.id), // todo fix test harcode later
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
              return Scrollbar(child: ListView(children: departures.map((d) {
                final mins = d.minutesFromNow;
                final label = mins <= 0 ? "Due" : "${mins} min";
                return ListTile(
                  title: Text(d.routeShortName),
                  subtitle: Text("Scheduled"),
                  trailing: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),)
                );
              }
              ).toList()));
            }
          ),
        )
        // Expanded(child: Scrollbar(child: ListView(children: [
        //   if (routes.isEmpty)
        //     const Text("No routes found for this stop.")
        //   else
        //     ...routes.map((route) => ListTile( // todo replace with live arrivals later
        //         leading: _RoutePill(route: route),
        //         title: Text(route.destinationText["en"] ?? ""),
        //         subtitle: Text(route.destinationText["en"] ?? ""),
        //         onTap: () {
        //           Navigator.pop(context);
        //         },
        //       )
        //     )
        // ],)))
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