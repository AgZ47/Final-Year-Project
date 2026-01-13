import 'package:flutter/material.dart';
import 'drawer_pages/home.dart';
import 'drawer_pages/mental.dart';
import 'drawer_pages/physical.dart';
import 'drawer_pages/profile.dart';
import 'drawer_pages/sleep.dart';

// This acts exactly like the "MainWrapper" in the tutorial
class HomePage extends StatefulWidget {
  final String userSessionToken;
  final String username;

  const HomePage({
    super.key,
    required this.userSessionToken,
    required this.username,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // Define your 3 screens here
  final List<Widget> _pages = [
    Home(),
    Sleep(),
    Physical(),
    Mental(),
    Profile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: _pages[_selectedIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.bed_sharp), label: 'sleep'),
          NavigationDestination(
            icon: Icon(Icons.run_circle_rounded),
            label: 'Physical',
          ),
          NavigationDestination(
            icon: Icon(Icons.headphones_battery),
            label: 'Mental',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_2_sharp),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
