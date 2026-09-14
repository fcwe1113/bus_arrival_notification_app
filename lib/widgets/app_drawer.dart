import 'package:bus_arrival_notification_app/screens/loading_screen.dart';
import 'package:bus_arrival_notification_app/transit_bootstrap.dart';
import 'package:flutter/material.dart';

/// this is the actual menu object, with each menu entry
class AppDrawer extends StatelessWidget { // stateless bc the menu entrys are set
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer( // the built in side bar menu thing
        child: ListView( // make the menu scrollabel if needed
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
                padding: EdgeInsets.all(30),
                decoration: BoxDecoration(color: Colors.blue),
                child: Text("Bus Alarm", style: TextStyle(color: Colors.white, fontSize: 24),)),
            ListTile(leading: const Icon(Icons.alarm), title: const Text("Alarm List"), onTap: () { // List stile describes the actual buttons on the menu
              Navigator.pop(context); // dismiss the drawer (sidebar)
              Navigator.pushReplacementNamed(context, "/"); // jump to the screen linked to the path, pushNamed() would allow flutter to stack screen on top of each other which is wasteful
            },),
            ListTile(leading: const Icon(Icons.map), title: const Text("Map"), onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, "/map");
            },),
            ListTile(leading: const Icon(Icons.download), title: const Text("Reload Data"), onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (cocntext) => const LoadingScreen(operation: initializeTransitData,forceRefresh: true)));
            },),
            ListTile(leading: const Icon(Icons.refresh), title: const Text("Refresh Data"), onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (cocntext) => const LoadingScreen(operation: refreshStaleProviders,)));
            },),
            ListTile(leading: const Icon(Icons.settings), title: const Text("Settings"), onTap: () => Navigator.pop(context),),
          ],
        )
    );
  }
}