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
            ListTile(leading: const Icon(Icons.settings), title: const Text("Settings"), onTap: () => Navigator.pop(context),)
          ],
        )
    );
  }
}