import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:math'; // Needed for calculating initials safely
import '../../login_page.dart';
import '../../core/theme/app_theme.dart'; // ⚡ NEW: Centralized theme

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final _storage = const FlutterSecureStorage();

  // ── Toggle state ──
  bool _darkMode = true; // Visual only for now
  bool _notifications = true;
  bool _metricUnits = false;

  // ── User Data State ──
  String _username = "User";
  String _initials = "U";

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  // ==========================================
  // ⚙️ LOAD SAVED PREFERENCES & USER DATA
  // ==========================================
  Future<void> _loadPreferences() async {
    final notifs = await _storage.read(key: 'pref_notifications');
    final metrics = await _storage.read(key: 'pref_metrics');

    // Fetch the dynamic username saved during login/setup
    final savedName = await _storage.read(key: 'username') ?? 'User';

    // Generate initials safely (e.g., "Alex Johnson" -> "AJ", "Alex" -> "AL")
    String init = "U";
    if (savedName.isNotEmpty) {
      final nameParts = savedName.trim().split(' ');
      if (nameParts.length > 1) {
        init = '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
      } else {
        init = savedName.substring(0, min(2, savedName.length)).toUpperCase();
      }
    }

    if (!mounted) return; // ⚡ OPTIMIZATION: Safe async gap check

    setState(() {
      if (notifs != null) _notifications = notifs == 'true';
      if (metrics != null) _metricUnits = metrics == 'true';
      _username = savedName;
      _initials = init;
    });
  }

  // ==========================================
  // 💾 SAVE PREFERENCES ON TOGGLE
  // ==========================================
  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notifications = value);
    await _storage.write(key: 'pref_notifications', value: value.toString());
  }

  Future<void> _toggleMetrics(bool value) async {
    setState(() => _metricUnits = value);
    await _storage.write(key: 'pref_metrics', value: value.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.mainBackgroundGradient, // ⚡ Centralized Theme
      ),
      child: SafeArea(
        // ⚡ OPTIMIZATION: Converted to ListView
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            const SizedBox(height: 8),

            // ── Avatar Section ──
            _buildAvatarSection(),
            const SizedBox(height: 32),

            // ── Personal Information ──
            _buildSectionTitle('Personal Information'),
            const SizedBox(height: 12),
            _buildPersonalInfo(),
            const SizedBox(height: 28),

            // ── Preferences ──
            _buildSectionTitle('Preferences'),
            const SizedBox(height: 12),
            _buildPreferences(),
            const SizedBox(height: 28),

            // ── Settings ──
            _buildSectionTitle('Settings'),
            const SizedBox(height: 12),
            _buildSettings(),
            const SizedBox(height: 32),

            // ── Logout ──
            _buildLogoutButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppTheme.accent, AppTheme.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accent.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: AppTheme.bgDark,
            child: Text(
              _initials,
              style: const TextStyle(
                color: AppTheme.accent,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _username,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Wellness in progress ✨',
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildPersonalInfo() {
    final info = [
      {'icon': Icons.cake_rounded, 'label': 'Age', 'value': '28 years'},
      {
        'icon': Icons.person_outline_rounded,
        'label': 'Gender',
        'value': 'Male',
      },
      {
        'icon': Icons.height_rounded,
        'label': 'Height',
        'value': _metricUnits ? '178 cm' : '5\'10"',
      },
      {
        'icon': Icons.monitor_weight_outlined,
        'label': 'Weight',
        'value': _metricUnits ? '75 kg' : '165 lbs',
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: info.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      color: AppTheme.accent,
                      size: 20,
                    ),
                    const SizedBox(width: 14),
                    Text(
                      item['label'] as String,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      item['value'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (i < info.length - 1)
                Divider(color: Colors.white.withOpacity(0.05), height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPreferences() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          _toggleRow(
            Icons.dark_mode_rounded,
            'Dark Mode',
            _darkMode,
            (v) => setState(() => _darkMode = v),
          ),
          Divider(color: Colors.white.withOpacity(0.05), height: 1),
          _toggleRow(
            Icons.notifications_rounded,
            'Notifications',
            _notifications,
            _toggleNotifications,
          ),
          Divider(color: Colors.white.withOpacity(0.05), height: 1),
          _toggleRow(
            Icons.straighten_rounded,
            'Metric Units',
            _metricUnits,
            _toggleMetrics,
          ),
        ],
      ),
    );
  }

  Widget _toggleRow(
    IconData icon,
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.purple, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.accent,
            activeTrackColor: AppTheme.accent.withOpacity(0.3),
            inactiveThumbColor: Colors.white38,
            inactiveTrackColor: Colors.white12,
          ),
        ],
      ),
    );
  }

  Widget _buildSettings() {
    final settings = [
      {'icon': Icons.manage_accounts_rounded, 'label': 'Account Settings'},
      {'icon': Icons.shield_outlined, 'label': 'Data & Privacy'},
      {'icon': Icons.devices_rounded, 'label': 'Connected Devices'},
      {'icon': Icons.health_and_safety_rounded, 'label': 'Health Permissions'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: settings.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${item['label']} coming soon'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        color: AppTheme.accent,
                        size: 20,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          item['label'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white.withOpacity(0.3),
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
              if (i < settings.length - 1)
                Divider(color: Colors.white.withOpacity(0.05), height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppTheme.bgCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
              content: Text(
                'Are you sure you want to logout?',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppTheme.accent),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          );

          if (confirm == true && mounted) {
            const storage = FlutterSecureStorage();
            await storage.deleteAll(); // Safely wipes all data
            if (!mounted) return;

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
            );
          }
        },
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: const Text(
          'Log Out',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent.withOpacity(0.15),
          foregroundColor: Colors.redAccent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
