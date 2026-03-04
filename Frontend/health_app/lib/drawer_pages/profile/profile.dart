import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../login_page.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  // ── Colors ──
  static const _bgCard = Color(0xFF152238);
  static const _accent = Color(0xFF4DD0E1);
  static const _purple = Color(0xFF7E57C2);

  // ── Toggle state ──
  bool _darkMode = true;
  bool _notifications = true;
  bool _metricUnits = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B1527), Color(0xFF0D1B2A), Color(0xFF132E4A)],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
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
      ),
    );
  }

  // ─── Avatar Section ───────────────────────────────────────────────────────

  Widget _buildAvatarSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [_accent, _purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _accent.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const CircleAvatar(
            radius: 50,
            backgroundColor: Color(0xFF1A2A40),
            child: Text(
              'AJ',
              style: TextStyle(
                color: _accent,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Alex Johnson',
          style: TextStyle(
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

  // ─── Personal Information ─────────────────────────────────────────────────

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
        'value': '5\'10" (178 cm)',
      },
      {
        'icon': Icons.monitor_weight_outlined,
        'label': 'Weight',
        'value': '165 lbs (75 kg)',
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: _bgCard,
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
                    Icon(item['icon'] as IconData, color: _accent, size: 20),
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

  // ─── Preferences ──────────────────────────────────────────────────────────

  Widget _buildPreferences() {
    return Container(
      decoration: BoxDecoration(
        color: _bgCard,
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
            (v) => setState(() => _notifications = v),
          ),
          Divider(color: Colors.white.withOpacity(0.05), height: 1),
          _toggleRow(
            Icons.straighten_rounded,
            'Metric Units',
            _metricUnits,
            (v) => setState(() => _metricUnits = v),
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
          Icon(icon, color: _purple, size: 20),
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
            activeColor: _accent,
            activeTrackColor: _accent.withOpacity(0.3),
            inactiveThumbColor: Colors.white38,
            inactiveTrackColor: Colors.white12,
          ),
        ],
      ),
    );
  }

  // ─── Settings ─────────────────────────────────────────────────────────────

  Widget _buildSettings() {
    final settings = [
      {'icon': Icons.manage_accounts_rounded, 'label': 'Account Settings'},
      {'icon': Icons.shield_outlined, 'label': 'Data & Privacy'},
      {'icon': Icons.devices_rounded, 'label': 'Connected Devices'},
      {'icon': Icons.health_and_safety_rounded, 'label': 'Health Permissions'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: _bgCard,
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
                      Icon(item['icon'] as IconData, color: _accent, size: 20),
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

  // ─── Logout ───────────────────────────────────────────────────────────────

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: _bgCard,
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
                  child: const Text('Cancel', style: TextStyle(color: _accent)),
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
            await storage.deleteAll();
            if (!mounted) return;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => LoginPage()),
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

  // ─── Helpers ──────────────────────────────────────────────────────────────

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
