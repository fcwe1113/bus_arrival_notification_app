import 'package:flutter/material.dart';

import 'app_drawer.dart';

/// this is a "shell" for screens under the side bar menu so when we add screens the side bar will always be accessible
class AppShell extends StatelessWidget { // nothing to change within appshell itself so stateless
  final String title;
  final Widget body;
  final List<Widget>? actions;

  const AppShell({
    super.key,
    required this.title,
    required this.body,
    this.actions
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold( // the default screen object
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      drawer: const AppDrawer(),
      body: body,
    );
  }
}