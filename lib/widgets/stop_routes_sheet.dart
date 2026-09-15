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
      padding: EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(stop.names["en"] ?? stop.id, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
        const SizedBox(height: 12,),
        Expanded(child: Scrollbar(child: ListView(children: [
          if (routes.isEmpty)
            const Text("No routes found for this stop.")
          else
            ...routes.map((route) => ListTile(
              title: Text(route.routeNumber),
              subtitle: Text(route.destinationText["en"] ?? ""),
              onTap: () {
                Navigator.pop(context);
                // add route map display here later
              },
            ))
        ],)))
      ],)
    ));
  }
}