import 'package:transport_alarm/provider_registry.dart';
import 'package:transport_alarm/transit/services/locale_selection_service.dart';
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
            child: Text("Choose your country/region",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
              child: ListView(
                children: providersByLocale.keys.map((locale) {
                  return CheckboxListTile(
                      title: Text(localeConfigs[locale]?.displayName ?? locale),
                      value: _selected.contains(locale),
                      onChanged: (checked) {
                        setState(() {
                          checked == true ? _selected.add(locale) : _selected.remove(locale);
                        });
                      });
                }).toList(),
              ),)
        ],),
        floatingActionButton: _selected.isEmpty ? null : FloatingActionButton(onPressed: _confirmSelection, child: const Icon(Icons.check),),
    );
  }

  Future<void> _confirmSelection() async {
    final shouldProceed = await _showWifiReminder();
    if (shouldProceed != true) return; // user clicked no on the popup

    await LocaleSelectionService().setEnabledLocales(_selected.toList());
    if (mounted) Navigator.pushReplacementNamed(context, "/loading");
  }

  Future<bool?> _showWifiReminder() {
    return showDialog(context: context, barrierDismissible: false, builder: (context) => AlertDialog(
      title: const Text("Heads up!"),
      content: const Text("Downloading the required data can take a while and use a fair amount of data. You may want to connect to Wi-Fi before proceeding."),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Go back")),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Continue")),
      ],
    ));
  }
}