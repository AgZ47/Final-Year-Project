import 'package:flutter/material.dart';
import 'package:watch_connectivity/watch_connectivity.dart';
import 'support_page.dart';
import 'breathing_exercise.dart';

class Home extends StatefulWidget {
  final String? userSessionToken;
  final String? username;

  const Home({super.key, this.userSessionToken, this.username});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // ── Watch Connectivity ──
  final _watch = WatchConnectivity();
  String _receivedText = "Waiting for watch...";
  Color _watchColor = const Color(0xFF0D1B2A);

  // ── Checkbox states ──
  bool _waterChecked = false;
  bool _walkChecked = false;
  bool _sleepChecked = false;

  @override
  void initState() {
    super.initState();
    _initWatchConnectivity();
  }

  // ── Watch helpers (preserved) ──
  void _initWatchConnectivity() async {
    bool isSupported = await _watch.isSupported;
    bool isPaired = await _watch.isPaired;
    bool isReachable = await _watch.isReachable;

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
      _watchColor = _getColorFromName(colorName);
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
        return const Color(0xFF0D1B2A);
    }
  }

  // ── Build ──
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final secondaryColor = theme.colorScheme.secondary;
    const textColor = Colors.white;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          // 1. Header
          Text(
            'Hi Emily,',
            style: theme.textTheme.displayLarge?.copyWith(
              fontSize: 28,
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'How are you doing today?',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 18,
              color: textColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 32),

          // 2. Daily Scores (Circular Progress)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildScoreCircle(
                label: 'Mental Score',
                score: '85',
                percent: 0.85,
                color: primaryColor,
                textColor: Colors.white,
              ),
              _buildScoreCircle(
                label: 'Physical Score',
                score: '70',
                percent: 0.70,
                color: secondaryColor,
                textColor: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // 3. Weekly Mood Graph (Bar Chart)
          Text(
            'Weekly Mood',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF152238),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildMoodBar('Mon', 0.6, primaryColor),
                _buildMoodBar('Tue', 0.8, primaryColor),
                _buildMoodBar('Wed', 0.5, primaryColor),
                _buildMoodBar('Thu', 0.9, secondaryColor),
                _buildMoodBar('Fri', 0.7, primaryColor),
                _buildMoodBar('Sat', 0.85, primaryColor),
                _buildMoodBar('Sun', 0.6, primaryColor),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 4. Daily Self Care Reminders
          Text(
            'Daily Self Care',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              _buildCheckbox('Drink 8 glasses of water', _waterChecked,
                  (v) => setState(() => _waterChecked = v!)),
              _buildCheckbox('Take a 15 min walk', _walkChecked,
                  (v) => setState(() => _walkChecked = v!)),
              _buildCheckbox('Sleep by 10 PM', _sleepChecked,
                  (v) => setState(() => _sleepChecked = v!)),
            ],
          ),
          const SizedBox(height: 32),

          // 5. Connect with Psychiatrist
          Text(
            'Support',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF152238),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: secondaryColor,
                  child: const Icon(Icons.medical_services,
                      color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dr. Sarah Kline',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Psychiatrist',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SupportPage()),
                    );
                  },
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF4DD0E1),
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.call, color: Color(0xFF0D1B2A)),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 6. Breathing Exercise Shortcut
          GestureDetector(
            onTap: () {
              BreathingExercise.show(context);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    secondaryColor,
                    secondaryColor.withOpacity(0.7)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.air,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Breathing',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Tap to start a 2-min session',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.play_circle_fill,
                      color: Colors.white, size: 40),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // 7. Upcoming Appointments
          Text(
            'Upcoming Appointments',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildAppointmentCard(
            title: 'Therapy Session',
            doctor: 'Dr. Sarah Kline',
            date: 'Tomorrow, 10:00 AM',
            icon: Icons.psychology,
            color: primaryColor,
          ),
          const SizedBox(height: 12),
          _buildAppointmentCard(
            title: 'General Checkup',
            doctor: 'Dr. Michael Chen',
            date: 'Jan 20, 3:30 PM',
            icon: Icons.local_hospital,
            color: secondaryColor,
          ),
          const SizedBox(height: 32),

          // 8. Recent Activity Timeline
          Text(
            'Recent Activity',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildActivityItem(
            icon: Icons.self_improvement,
            activity: 'Completed meditation',
            time: '2 hours ago',
            color: secondaryColor,
          ),
          _buildActivityItem(
            icon: Icons.directions_walk,
            activity: 'Walked 2,500 steps',
            time: '5 hours ago',
            color: primaryColor,
          ),
          _buildActivityItem(
            icon: Icons.check_circle,
            activity: 'Logged daily mood',
            time: 'Yesterday',
            color: Colors.green,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Helper Widgets ──

  Widget _buildScoreCircle({
    required String label,
    required String score,
    required double percent,
    required Color color,
    required Color textColor,
  }) {
    return Column(
      children: [
        SizedBox(
          height: 100,
          width: 100,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: percent,
                strokeWidth: 10,
                backgroundColor: color.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                strokeCap: StrokeCap.round,
              ),
              Center(
                child: Text(
                  score,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildMoodBar(String day, double heightPct, Color color) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 100 * heightPct,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildCheckbox(
      String title, bool value, ValueChanged<bool?> onChanged) {
    return Card(
      elevation: 0,
      color: const Color(0xFF152238),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: CheckboxListTile(
        tristate: false,
        activeColor: Theme.of(context).primaryColor,
        checkColor: Colors.black,
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            decoration: value ? TextDecoration.lineThrough : null,
            color: Colors.white,
          ),
        ),
        value: value,
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  Widget _buildAppointmentCard({
    required String title,
    required String doctor,
    required String date,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF152238),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  doctor,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(Icons.calendar_today, size: 14, color: color),
              const SizedBox(height: 4),
              Text(
                date,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String activity,
    required String time,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              activity,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}
