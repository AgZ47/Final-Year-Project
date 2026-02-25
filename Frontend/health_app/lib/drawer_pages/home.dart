import 'package:flutter/material.dart';
import 'package:watch_connectivity/watch_connectivity.dart';

class Home extends StatefulWidget {
  final String? userSessionToken;
  final String? username;

  const Home({super.key, this.userSessionToken, this.username});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // 1. Initialize the modern plugin
  final _watch = WatchConnectivity();

  String _receivedText = "Waiting for watch...";
  Color _bgColor = const Color(0xFFF7EBE1); // Default Aura Fit background

  @override
  void initState() {
    super.initState();
    _initWatchConnectivity();
  }

  void _initWatchConnectivity() async {
    bool isSupported = await _watch.isSupported;
    bool isPaired = await _watch.isPaired;
    bool isReachable = await _watch.isReachable; // ADD THIS

    print("--- AURA FIT DIAGNOSTICS ---");
    print("Supported: $isSupported");
    print("Paired: $isPaired");
    print("Reachable (Tunnel Open): $isReachable");
    print("----------------------------");

    setState(() => _receivedText = "Reachable: $isReachable");

    _watch.contextStream.listen((contextMap) {
      if (contextMap.containsKey("selected_color")) {
        _updateUI(contextMap["selected_color"]);
      }
    });

    _watch.messageStream.listen((messageMap) {
      if (messageMap.containsKey("selected_color")) {
        _updateUI(messageMap["selected_color"]);
      }
    });
  }

  void _updateUI(String colorName) {
    setState(() {
      _receivedText = "Watch Selected: $colorName";
      _bgColor = _getColorFromName(colorName);
    });
  }

  Color _getColorFromName(String name) {
    switch (name.toLowerCase()) {
      case 'red':
        return Colors.red.shade100;
      case 'green':
        return Colors.green.shade100;
      case 'blue':
        return Colors.blue.shade100;
      default:
        return const Color(0xFFF7EBE1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: Text("Welcome, ${widget.username ?? 'User'}"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xff132137),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.watch, size: 100, color: Color(0xff132137)),
            const SizedBox(height: 20),
            Text(
              _receivedText,
              style: const TextStyle(
                fontSize: 28,
                color: Color(0xff132137),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
