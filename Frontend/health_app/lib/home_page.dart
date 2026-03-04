import 'package:flutter/material.dart';
import 'drawer_pages/home/home.dart';
import 'drawer_pages/mental/mental.dart';
import 'drawer_pages/physical/physical.dart';
import 'drawer_pages/profile/profile.dart';
import 'drawer_pages/sleep/sleep.dart';
import 'drawer_pages/home/reports.dart';
import 'drawer_pages/home/doctors.dart';
import 'drawer_pages/home/support_page.dart';
import 'drawer_pages/home/habits.dart';
import 'drawer_pages/home/goals.dart';
import 'drawer_pages/home/timeline.dart';
import 'drawer_pages/home/insights.dart';

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

  // ── Colors ──
  static const _bgDark = Color(0xFF0D1B2A);
  static const _accent = Color(0xFF4DD0E1);
  static const _purple = Color(0xFF7E57C2);

  // All navigable pages (bottom nav + drawer-only)
  final List<Widget> _pages = [
    const Home(), // 0 - Home
    const Sleep(), // 1 - Sleep
    const Physical(), // 2 - Physical
    const Mental(), // 3 - Mental
    const Profile(), // 4 - Profile
    const ReportsPage(), // 5 - Reports
    const DoctorsPage(), // 6 - Doctors
    const SupportPage(), // 7 - Support
    const HabitsPage(), // 8 - Habits
    const GoalsPage(), // 9 - Goals
    const TimelinePage(), // 10 - Timeline
    const InsightsPage(), // 11 - Insights
  ];

  void _navigateToPage(int index) {
    setState(() => _selectedIndex = index);
    Navigator.pop(context); // close drawer
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      drawer: _buildDrawer(),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex < 5 ? _selectedIndex : 0,
        onDestinationSelected: (int index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.bedtime_rounded),
            label: 'Sleep',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_rounded),
            label: 'Physical',
          ),
          NavigationDestination(
            icon: Icon(Icons.psychology_rounded),
            label: 'Mental',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // ─── Drawer ───────────────────────────────────────────────────────────────

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: _bgDark,
      child: SafeArea(
        child: Column(
          children: [
            // ── Drawer Header ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_accent.withOpacity(0.1), _purple.withOpacity(0.08)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [_accent, _purple]),
                    ),
                    child: const CircleAvatar(
                      radius: 30,
                      backgroundColor: Color(0xFF1A2A40),
                      child: Text(
                        'AJ',
                        style: TextStyle(
                          color: _accent,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Alex Johnson',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Synergy AI',
                    style: TextStyle(
                      color: _accent.withOpacity(0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Nav Items ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _drawerLabel('MAIN'),
                  _drawerItem(Icons.home_rounded, 'Home', 0),
                  _drawerItem(Icons.psychology_rounded, 'Mental Health', 3),
                  _drawerItem(
                    Icons.fitness_center_rounded,
                    'Physical Health',
                    2,
                  ),
                  _drawerItem(Icons.bedtime_rounded, 'Sleep', 1),

                  const SizedBox(height: 8),
                  _drawerLabel('WELLNESS'),
                  _drawerItem(Icons.check_circle_rounded, 'Daily Habits', 8),
                  _drawerItem(Icons.flag_rounded, 'Smart Goals', 9),
                  _drawerItem(Icons.timeline_rounded, 'Health Timeline', 10),
                  _drawerItem(Icons.auto_awesome_rounded, 'Insights', 11),

                  const SizedBox(height: 8),
                  _drawerLabel('MORE'),
                  _drawerItem(Icons.bar_chart_rounded, 'Weekly Report', 5),
                  _drawerItem(Icons.medical_services_rounded, 'Doctors', 6),
                  _drawerItem(Icons.support_agent_rounded, 'Support', 7),
                  _drawerItem(Icons.person_rounded, 'Profile', 4),
                ],
              ),
            ),

            // ── Footer ──
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Synergy AI v2.0',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.2),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 0, 6),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withOpacity(0.25),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, int pageIndex) {
    final isSelected = _selectedIndex == pageIndex;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          color: isSelected ? _accent : Colors.white54,
          size: 21,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? _accent : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        selected: isSelected,
        selectedTileColor: _accent.withOpacity(0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () => _navigateToPage(pageIndex),
      ),
    );
  }
}
