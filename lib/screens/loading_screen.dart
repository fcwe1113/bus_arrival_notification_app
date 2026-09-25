import 'package:transport_alarm/transit/progress_callback.dart';
import 'package:transport_alarm/transit_bootstrap.dart';
import 'package:flutter/material.dart';

class LoadingScreen extends StatefulWidget {
  final bool forceRefresh;
  final TransitOperation operation;
  const LoadingScreen({super.key, this.forceRefresh = false, this.operation = initializeTransitData});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  String _message = "Starting...";
  double? _progress;
  String? _error;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _runOperation();
  }

  Future<void> _runOperation() async {
    setState(() {
      _error = null;
      _finished = false;
    });
    try {
      final failures = await widget.operation(
        forceRefresh: widget.forceRefresh,
        onProgress: (message, progress) {
          setState(() {
            _message = message;
            _progress = progress;
          });
        },
      );
      
      if (mounted && failures.isNotEmpty) {
        await showDialog(context: context, builder: (context) => AlertDialog(
          title: const Text("Some data failed to update"),
          content: Text("${failures.length} item(s) failed:\n${failures.join(", ")}\n\n"),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
        ));
      }
      
      if (mounted) {
        setState(() {
          _message = "Operation completed";
          _progress = 1.0;
          _finished = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Setup failed: $e";
        });
      }
    }
  }

  void _onOkPressed() {
    Navigator.pushReplacementNamed(context, "/");
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
              onPressed: _runOperation,
              child: const Text("Retry")
            ),
          ] : [
            _progress != null ? LinearProgressIndicator(value: _progress,) : LinearProgressIndicator(),
            const SizedBox(height: 16,),
            Text(_message),
            if (_finished) ...[
              const SizedBox(height: 24,),
              ElevatedButton(onPressed: _onOkPressed, child: const Text("OK"))
            ]
          ],
        ),
      ),
    );
  }
}