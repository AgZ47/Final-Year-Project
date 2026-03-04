import 'package:flutter/material.dart';
import 'package:watch_connectivity/watch_connectivity.dart';
import 'support_page.dart';
import 'breathing_exercise.dart';
import '../../services/wellness_engine.dart';
import '../../widgets/wellness_widgets.dart';

class Home extends StatefulWidget {
  final String? userSessionToken;
  final String? username;

  const Home({super.key, this.userSessionToken, this.username});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  // ── Watch Connectivity ──
  final _watch = WatchConnectivity();
  String _receivedText = "Waiting for watch...";
  Color _watchColor = const Color(0xFF0D1B2A);

  // ── Checkbox states ──
  bool _waterChecked = false;
  bool _walkChecked = false;
  bool _sleepChecked = false;

  // ── Colors ──
  static const _bgCard = Color(0xFF152238);
  static const _accent = Color(0xFF4DD0E1);
  static const _purple = Color(0xFF7E57C2);
  static const _green = Color(0xFF66BB6A);

  // ── Wellness Engine data ──
  final _metrics = WellnessEngine.currentMetrics;
  late final int _wellnessScore = WellnessEngine.calculateWellnessScore(
    _metrics,
  );
  late final int _recoveryScore = WellnessEngine.calculateRecoveryScore(
    _metrics,
  );
  late final String _recoveryStatus = WellnessEngine.getRecoveryStatus(
    _recoveryScore,
  );
  late final List<HealthAlert> _alerts = WellnessEngine.detectHealthRisks(
    _metrics,
  );
  late final List<WellnessRecommendation> _recommendations =
      WellnessEngine.generateRecommendations(_metrics);
  late final List<String> _notifications = WellnessEngine.getSmartNotifications(
    _metrics,
  );

  // ── Animation ──
  late AnimationController _scoreAnimController;
  late Animation<double> _scoreAnim;

  @override
  void initState() {
    super.initState();
    _initWatchConnectivity();
    _scoreAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scoreAnim = CurvedAnimation(
      parent: _scoreAnimController,
      curve: Curves.easeOutCubic,
    );
    _scoreAnimController.forward();
  }

  @override
  void dispose() {
    _scoreAnimController.dispose();
    super.dispose();
  }

  // ── Watch helpers (preserved) ──
  void _initWatchConnectivity() async {
    bool isSupported = await _watch.isSupported;
    bool isPaired = await _watch.isPaired;
    bool isReachable = await _watch.isReachable;

    debugPrint("--- AURA FIT DIAGNOSTICS ---");
    debugPrint("Supported: $isSupported");
    debugPrint("Paired: $isPaired");
    debugPrint("Reachable (Tunnel Open): $isReachable");

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Greeting Header
              _buildGreeting(),
              const SizedBox(height: 16),

              // ── Smart Notification Banner ──
              if (_notifications.isNotEmpty) _buildNotificationBanner(),
              if (_notifications.isNotEmpty) const SizedBox(height: 20),

              // 2. Wellness Score Hero Card
              AnimatedBuilder(
                animation: _scoreAnim,
                builder: (_, __) => WellnessScoreCard(
                  score: _wellnessScore,
                  trend: WellnessEngine.getScoreTrend(),
                  animationValue: _scoreAnim.value,
                ),
              ),
              const SizedBox(height: 16),

              // ── Recovery Score ──
              RecoveryScoreCard(score: _recoveryScore, status: _recoveryStatus),
              const SizedBox(height: 20),

              // 3. Quick Metrics Row
              _buildQuickMetrics(),
              const SizedBox(height: 24),

              // ── Health Alerts ──
              if (_alerts.isNotEmpty) ...[
                _buildSectionTitle('Health Alerts'),
                const SizedBox(height: 12),
                ..._alerts.map((a) => HealthAlertCard(alert: a)),
                const SizedBox(height: 20),
              ],

              // ── Recommended for You ──
              _buildSectionTitle('Recommended for You'),
              const SizedBox(height: 12),
              _buildRecommendations(),
              const SizedBox(height: 24),

              // 4. AI Insight Card
              _buildAIInsight(),
              const SizedBox(height: 24),

              // 5. Quick Actions
              _buildSectionTitle('Quick Actions'),
              const SizedBox(height: 14),
              _buildQuickActions(),
              const SizedBox(height: 24),

              // 6. Daily Self Care
              _buildSectionTitle('Daily Self Care'),
              const SizedBox(height: 14),
              _buildSelfCare(),
              const SizedBox(height: 24),

              // 7. Support / Doctor
              _buildSectionTitle('Support'),
              const SizedBox(height: 14),
              _buildSupportCard(),
              const SizedBox(height: 24),

              // 8. Breathing Exercise
              _buildBreathingShortcut(),
              const SizedBox(height: 24),

              // 9. Upcoming Appointments
              _buildSectionTitle('Upcoming'),
              const SizedBox(height: 14),
              _buildAppointmentCard(
                title: 'Dr. Sarah Wilson',
                subtitle: 'Cardiologist',
                date: 'Tomorrow, 10:30 AM',
                icon: Icons.favorite_rounded,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 12),
              _buildAppointmentCard(
                title: 'Dr. Michael Chen',
                subtitle: 'General Checkup',
                date: 'Mar 8, 3:30 PM',
                icon: Icons.local_hospital_rounded,
                color: _purple,
              ),
              const SizedBox(height: 24),

              // 10. Weekly Mood
              _buildSectionTitle('Weekly Mood'),
              const SizedBox(height: 14),
              _buildWeeklyMood(),
              const SizedBox(height: 24),

              // 11. Recent Activity
              _buildSectionTitle('Recent Activity'),
              const SizedBox(height: 14),
              _buildActivityItem(
                icon: Icons.self_improvement,
                activity: 'Completed meditation',
                time: '2 hours ago',
                color: _purple,
              ),
              _buildActivityItem(
                icon: Icons.directions_walk,
                activity: 'Walked 2,500 steps',
                time: '5 hours ago',
                color: _accent,
              ),
              _buildActivityItem(
                icon: Icons.check_circle,
                activity: 'Logged daily mood',
                time: 'Yesterday',
                color: _green,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Greeting ─────────────────────────────────────────────────────────────

  Widget _buildGreeting() {
    final now = DateTime.now();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final dateStr =
        '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hi Alex 👋',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'How are you feeling today?',
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16),
        ),
        const SizedBox(height: 2),
        Text(
          dateStr,
          style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 13),
        ),
      ],
    );
  }

  // ─── Smart Notification Banner ──────────────────────────────────────────────

  Widget _buildNotificationBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _purple.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _purple.withOpacity(0.2)),
      ),
      child: Column(
        children: _notifications
            .map(
              (n) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications_active_rounded,
                      color: _purple,
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        n,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ─── Recommendations ──────────────────────────────────────────────────────

  Widget _buildRecommendations() {
    final iconMap = {
      'directions_walk': Icons.directions_walk_rounded,
      'air': Icons.air_rounded,
      'bedtime': Icons.bedtime_rounded,
      'favorite': Icons.favorite_rounded,
      'water_drop': Icons.water_drop_rounded,
    };
    final colorMap = {
      'activity': _green,
      'mental': _purple,
      'sleep': const Color(0xFF5C6BC0),
      'nutrition': _accent,
    };

    return Column(
      children: _recommendations.map((r) {
        final color = colorMap[r.category] ?? _accent;
        final icon = iconMap[r.iconName] ?? Icons.lightbulb_rounded;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      r.description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── Quick Metrics Row ────────────────────────────────────────────────────

  Widget _buildQuickMetrics() {
    return Row(
      children: [
        Expanded(
          child: _miniMetric(
            icon: Icons.psychology_rounded,
            label: 'Mental',
            value: '82',
            sub: 'Stable',
            color: _purple,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _miniMetric(
            icon: Icons.bedtime_rounded,
            label: 'Sleep',
            value: '7h 12m',
            sub: 'Good',
            color: const Color(0xFF5C6BC0),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _miniMetric(
            icon: Icons.favorite_rounded,
            label: 'Heart Rate',
            value: '72',
            sub: 'Resting',
            color: Colors.redAccent,
          ),
        ),
      ],
    );
  }

  Widget _miniMetric({
    required IconData icon,
    required String label,
    required String value,
    required String sub,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── AI Insight Card ──────────────────────────────────────────────────────

  Widget _buildAIInsight() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _accent.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.lightbulb_rounded,
              color: _accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Insight',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'You slept well today. Try light stretching to improve recovery.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Quick Actions ────────────────────────────────────────────────────────

  Widget _buildQuickActions() {
    final actions = [
      {'icon': Icons.mood_rounded, 'label': 'Log Mood', 'color': _purple},
      {'icon': Icons.air_rounded, 'label': 'Breathing', 'color': _green},
      {
        'icon': Icons.bedtime_rounded,
        'label': 'Sleep Stats',
        'color': const Color(0xFF5C6BC0),
      },
      {
        'icon': Icons.medical_services_rounded,
        'label': 'Book Doctor',
        'color': Colors.redAccent,
      },
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions.map((a) {
        final c = a['color'] as Color;
        return GestureDetector(
          onTap: () {
            if (a['label'] == 'Breathing') {
              BreathingExercise.show(context);
            }
          },
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.withOpacity(0.2)),
                ),
                child: Icon(a['icon'] as IconData, color: c, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                a['label'] as String,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── Daily Self Care ──────────────────────────────────────────────────────

  Widget _buildSelfCare() {
    return Column(
      children: [
        _buildCheckbox(
          'Drink 8 glasses of water',
          _waterChecked,
          (v) => setState(() => _waterChecked = v!),
        ),
        _buildCheckbox(
          'Take a 15 min walk',
          _walkChecked,
          (v) => setState(() => _walkChecked = v!),
        ),
        _buildCheckbox(
          'Sleep by 10 PM',
          _sleepChecked,
          (v) => setState(() => _sleepChecked = v!),
        ),
      ],
    );
  }

  // ─── Support Card ─────────────────────────────────────────────────────────

  Widget _buildSupportCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: _purple,
            child: const Icon(
              Icons.medical_services,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dr. Sarah Kline',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Psychiatrist',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SupportPage()),
              );
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: _accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.call, color: Color(0xFF0D1B2A), size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Breathing Shortcut ───────────────────────────────────────────────────

  Widget _buildBreathingShortcut() {
    return GestureDetector(
      onTap: () => BreathingExercise.show(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_purple, _purple.withOpacity(0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _purple.withOpacity(0.25),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.air, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Breathing',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Tap to start a 2-min session',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.play_circle_fill, color: Colors.white, size: 36),
          ],
        ),
      ),
    );
  }

  // ─── Weekly Mood ──────────────────────────────────────────────────────────

  Widget _buildWeeklyMood() {
    const moods = [0.6, 0.8, 0.5, 0.9, 0.7, 0.85, 0.6];
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (i) {
          final isToday = i == DateTime.now().weekday - 1;
          return Column(
            children: [
              Container(
                width: 12,
                height: 90 * moods[i],
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isToday
                        ? [_accent, _accent.withOpacity(0.4)]
                        : [
                            const Color(0xFF5C6BC0),
                            const Color(0xFF5C6BC0).withOpacity(0.3),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: isToday
                      ? [
                          BoxShadow(
                            color: _accent.withOpacity(0.4),
                            blurRadius: 6,
                          ),
                        ]
                      : [],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                labels[i],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                  color: isToday ? _accent : Colors.white54,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ─── Helper Widgets ───────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildCheckbox(
    String title,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    return Card(
      elevation: 0,
      color: _bgCard,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: CheckboxListTile(
        tristate: false,
        activeColor: _accent,
        checkColor: const Color(0xFF0D1B2A),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            decoration: value ? TextDecoration.lineThrough : null,
            color: value ? Colors.white38 : Colors.white,
            fontSize: 14,
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
    required String subtitle,
    required String date,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(Icons.calendar_today, size: 13, color: color),
              const SizedBox(height: 4),
              Text(
                date,
                style: TextStyle(
                  fontSize: 11,
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              activity,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.35),
            ),
          ),
        ],
      ),
    );
  }
}
