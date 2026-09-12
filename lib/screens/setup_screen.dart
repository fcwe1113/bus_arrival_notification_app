import 'package:bus_arrival_notification_app/provider_registry.dart';
import 'package:bus_arrival_notification_app/transit/services/provider_selection_service.dart';
import 'package:flutter/material.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("First time setup"),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          const Padding(padding: EdgeInsets.all(16),
            child: Text("Choose your transit networks",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
              child: ListView(
                children: availableProviders.map((provider) {
                  return CheckboxListTile(
                      title: Text(provider.providerName),
                      value: _selected.contains(provider.providerCode),
                      onChanged: (checked) {
                        setState(() {
                          checked == true ? _selected.add(provider.providerCode) : _selected.remove(provider.providerCode);
                        });
                      });
                }).toList(),
              ),)
        ],),
        floatingActionButton: _selected.isEmpty ? null : FloatingActionButton(onPressed: _confirmSelection, child: const Icon(Icons.check),),
    );
  }

  Future<void> _confirmSelection() async {
    await ProviderSelectionService().setEnabledProviderCodes(_selected.toList());
    if (mounted) Navigator.pushReplacementNamed(context, "/loading");
  }
}