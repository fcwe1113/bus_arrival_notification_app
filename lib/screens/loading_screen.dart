import 'package:bus_arrival_notification_app/transit_bootstrap.dart';
import 'package:flutter/material.dart';

class LoadingScreen extends StatefulWidget {
  final bool forceRefresh;
  const LoadingScreen({super.key, this.forceRefresh = false});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  String _message = "Loading...";
  double? _progress;
  String? _error;

  @override
  void initState() {
    super.initState();
    _runSetup();
  }

  Future<void> _runSetup() async {
    setState(() {
      _error = null;
    });
    try {
      await initializeTransitData(
        forceRefresh: widget.forceRefresh,
        onProgress: (message, progress) {
          setState(() {
            _message = message;
            _progress = progress;
          });
        },
      );
      if (mounted) Navigator.pushReplacementNamed(context, "/");
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Setup failed: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _error != null ? [
            const Icon(Icons.error_outline, color: Colors.red, size: 48,),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _runSetup,
              child: const Text("Retry")
            ),
          ] : [
            _progress != null ? LinearProgressIndicator(value: _progress,) : LinearProgressIndicator(),
            const SizedBox(height: 16,),
            Text(_message)
          ],
        ),
      ),
    );
  }
}