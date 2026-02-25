import 'package:flutter/material.dart';
import 'package:watch_connectivity/watch_connectivity.dart';

void main() {
  runApp(const AuraFitWatchApp());
}

class AuraFitWatchApp extends StatefulWidget {
  const AuraFitWatchApp({super.key});

  @override
  State<AuraFitWatchApp> createState() => _AuraFitWatchAppState();
}

class _AuraFitWatchAppState extends State<AuraFitWatchApp> {
  // Initialize the exact same plugin used on the phone
  final _watch = WatchConnectivity();

  void _sendToPhone(String colorName) {
    final payload = {'selected_color': colorName};

    // 1. Context Stream (Persistent data, syncs when connected)
    _watch.updateApplicationContext(payload);

    // 2. Message Stream (Real-time data, requires active connection)
    _watch.sendMessage(payload);

    print("FLUTTER WATCH: Sent $colorName to phone!");
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        // SingleChildScrollView ensures it works on round screens
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Aura Fit Sync",
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 10),
                _buildColorButton('Red', Colors.red),
                _buildColorButton('Green', Colors.green),
                _buildColorButton('Blue', Colors.blue),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorButton(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          minimumSize: const Size(120, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: () => _sendToPhone(label),
        child: Text(label, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}
