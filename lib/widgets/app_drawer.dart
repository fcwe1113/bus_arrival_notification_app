import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(decoration: BoxDecoration(color: Colors.blue), child: Text("menu", style: TextStyle(color: Colors.white, fontSize: 24),)),
            ListTile(leading: const Icon(Icons.alarm), title: const Text("Alarm List"), onTap: () {
              Navigator.pop(context); // dismiss the drawer (sidebar)
              Navigator.pushReplacementNamed(context, "/"); // jump to the screen linked to the path, pushNamed() would allow flutter to stack screen on top of each other which is wasteful
            },),
            ListTile(leading: const Icon(Icons.map), title: const Text("Map"), onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, "/map");
            },),
            ListTile(leading: const Icon(Icons.settings), title: const Text("Settings"), onTap: () => Navigator.pop(context),),
          ],
        )
    );
  }
}