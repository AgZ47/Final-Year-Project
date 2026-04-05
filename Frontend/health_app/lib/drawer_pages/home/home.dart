import 'package:flutter/material.dart';
import 'package:watch_connectivity/watch_connectivity.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'support_page.dart';
import 'breathing_exercise.dart';
import '../../services/wellness_engine.dart';
import '../../widgets/wellness_widgets.dart';
import '../../services/watch_service.dart';
import '../../services/health_database_service.dart';

class _ActivityItemData {
  final IconData icon;
  final String activity;
  final DateTime timestamp;
  final Color color;

  _ActivityItemData({
    required this.icon,
    required this.activity,
    required this.timestamp,
    required this.color,
  });
}

class Home extends StatefulWidget {
  final String? userSessionToken;
  final String? username;
  final Function(int)? onNavigate;

  const Home({
    super.key,
    this.userSessionToken,
    this.username,
    this.onNavigate,
  });

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  final _storage = const FlutterSecureStorage();
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

  // ── Dynamic State ──
  WellnessMetrics? _metrics;
  int _wellnessScore = 0;
  int _recoveryScore = 0;
  String _recoveryStatus = 'Calculating...';
  List<HealthAlert> _alerts = [];
  List<WellnessRecommendation> _recommendations = [];
  List<String> _notifications = [];
  bool _isLoadingData = true;

  // ── Recent Activity & Mood State ──
  List<_ActivityItemData> _recentActivities = [];
  bool _isLoadingActivities = true;
  List<double> _weeklyMoodData = List.filled(7, 0.0);

  late AnimationController _scoreAnimController;
  late Animation<double> _scoreAnim;

  @override
  void initState() {
    super.initState();
    WatchService().initialize();
    _checkDiagnostics();
    WatchService().selectedColor.addListener(_onColorChanged);

    // ⚡ NEW: Listen for background database updates from the watch!
    WatchService().syncTrigger.addListener(_refreshAllData);

    _scoreAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scoreAnim = CurvedAnimation(
      parent: _scoreAnimController,
      curve: Curves.easeOutCubic,
    );

    _refreshAllData();
    _loadCheckboxStates();
  }

  // ⚡ Helper to fetch everything again
  void _refreshAllData() {
    _loadDynamicData();
    _loadRecentActivities();
    _loadWeeklyMoodData();
  }

  // ==========================================
  // 📊 FETCH MOOD DATA FROM SQLITE
  // ==========================================
  Future<void> _loadWeeklyMoodData() async {
    final logs = await HealthDatabaseService.instance.getRecords(
      'mental_health_logs',
    );
    final now = DateTime.now();
    List<double> tempMood = List.filled(7, 0.0);
    List<int> moodCounts = List.filled(7, 0);

    for (var log in logs) {
      final logDate = DateTime.parse(log['timestamp'] as String);
      final difference = now.difference(logDate).inDays;

      if (difference < 7) {
        int dayIndex = logDate.weekday - 1; // 0=Mon, 6=Sun
        int rawMood = log['mood_score'] as int;
        double score = 1.0 - (rawMood / 4.0);
        tempMood[dayIndex] += score;
        moodCounts[dayIndex]++;
      }
    }

    for (int i = 0; i < 7; i++) {
      if (moodCounts[i] > 0) {
        tempMood[i] = tempMood[i] / moodCounts[i];
      }
    }

    if (tempMood.every((e) => e == 0.0)) {
      tempMood = [0.6, 0.8, 0.5, 0.9, 0.7, 0.85, 0.6]; // Baseline fallback
    }

    if (mounted) {
      setState(() {
        _weeklyMoodData = tempMood;
      });
    }
  }

  // ==========================================
  // 🕒 FETCH RECENT ACTIVITIES FROM SQLITE
  // ==========================================
  Future<void> _loadRecentActivities() async {
    final db = HealthDatabaseService.instance;
    List<_ActivityItemData> activities = [];

    // 1. Fetch recent steps
    final steps = await db.getRecords(
      'step_logs',
      orderBy: 'id DESC',
      limit: 3,
    );
    for (var s in steps) {
      activities.add(
        _ActivityItemData(
          icon: Icons.directions_walk_rounded,
          activity: 'Walked ${s['steps']} steps',
          timestamp: DateTime.parse(s['timestamp'] as String),
          color: _accent,
        ),
      );
    }

    // 2. Fetch recent mood logs
    final moods = await db.getRecords(
      'mental_health_logs',
      orderBy: 'id DESC',
      limit: 3,
    );
    for (var m in moods) {
      activities.add(
        _ActivityItemData(
          icon: Icons.mood_rounded,
          activity: 'Logged mental health',
          timestamp: DateTime.parse(m['timestamp'] as String),
          color: _purple,
        ),
      );
    }

    // 3. Fetch recent sleep logs
    final sleeps = await db.getRecords(
      'sleep_logs',
      orderBy: 'id DESC',
      limit: 3,
    );
    for (var s in sleeps) {
      activities.add(
        _ActivityItemData(
          icon: Icons.bedtime_rounded,
          activity: 'Logged sleep stats',
          timestamp: DateTime.parse(s['timestamp'] as String),
          color: const Color(0xFF5C6BC0),
        ),
      );
    }

    // Sort all combined activities by the newest timestamp first
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (mounted) {
      setState(() {
        // Take only the top 3 most recent actions overall
        _recentActivities = activities.take(3).toList();
        _isLoadingActivities = false;
      });
    }
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 2) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }

  // ==========================================
  // 💾 PERSIST CHECKBOXES
  // ==========================================
  String get _todayKeyPrefix =>
      DateTime.now().toIso8601String().substring(0, 10);

  Future<void> _loadCheckboxStates() async {
    final water = await _storage.read(key: '${_todayKeyPrefix}_water');
    final walk = await _storage.read(key: '${_todayKeyPrefix}_walk');
    final sleep = await _storage.read(key: '${_todayKeyPrefix}_sleep');

    if (mounted) {
      setState(() {
        _waterChecked = water == 'true';
        _walkChecked = walk == 'true';
        _sleepChecked = sleep == 'true';
      });
    }
  }

  Future<void> _saveCheckboxState(String keySuffix, bool value) async {
    await _storage.write(
      key: '${_todayKeyPrefix}_$keySuffix',
      value: value.toString(),
    );
  }

  Future<void> _loadDynamicData() async {
    final data = await WellnessEngine.getDynamicMetrics();
    if (!mounted) return;

    setState(() {
      _metrics = data;
      _wellnessScore = WellnessEngine.calculateWellnessScore(data);
      _recoveryScore = WellnessEngine.calculateRecoveryScore(data);
      _recoveryStatus = WellnessEngine.getRecoveryStatus(_recoveryScore);
      _alerts = WellnessEngine.detectHealthRisks(data);
      _recommendations = WellnessEngine.generateRecommendations(data);
      _notifications = WellnessEngine.getSmartNotifications(data);
      _isLoadingData = false;
    });

    _scoreAnimController.forward();
  }

  @override
  void dispose() {
    WatchService().selectedColor.removeListener(_onColorChanged);
    WatchService().syncTrigger.removeListener(
      _refreshAllData,
    ); // Don't forget to dispose!
    _scoreAnimController.dispose();
    super.dispose();
  }

  void _onColorChanged() {
    final colorName = WatchService().selectedColor.value;
    if (colorName.isNotEmpty && mounted) {
      setState(() {
        _receivedText = "Watch Selected: $colorName";
        _watchColor = _getColorFromName(colorName);
      });
    }
  }

  void _checkDiagnostics() async {
    final watch = WatchConnectivity();
    bool isReachable = await watch.isReachable;
    if (mounted) setState(() => _receivedText = "Reachable: $isReachable");
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

  String _getHeartRateStatus(int bpm) {
    if (bpm < 60) return 'Resting';
    if (bpm <= 85) return 'Active';
    if (bpm <= 120) return 'Exercising';
    return 'Stressed';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return Container(
        color: const Color(0xFF0D1B2A),
        child: const Center(child: CircularProgressIndicator(color: _accent)),
      );
    }

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
              _buildGreeting(),
              const SizedBox(height: 16),
              if (_notifications.isNotEmpty) _buildNotificationBanner(),
              if (_notifications.isNotEmpty) const SizedBox(height: 20),

              AnimatedBuilder(
                animation: _scoreAnim,
                builder: (_, __) => WellnessScoreCard(
                  score: _wellnessScore,
                  trend: WellnessEngine.getScoreTrend(),
                  animationValue: _scoreAnim.value,
                ),
              ),
              const SizedBox(height: 16),
              RecoveryScoreCard(score: _recoveryScore, status: _recoveryStatus),
              const SizedBox(height: 20),

              _buildQuickMetrics(),

              const SizedBox(height: 24),
              if (_alerts.isNotEmpty) ...[
                _buildSectionTitle('Health Alerts'),
                const SizedBox(height: 12),
                ..._alerts.map((a) => HealthAlertCard(alert: a)),
                const SizedBox(height: 20),
              ],

              _buildSectionTitle('Recommended for You'),
              const SizedBox(height: 12),
              _buildRecommendations(),
              const SizedBox(height: 24),

              _buildAIInsight(),
              const SizedBox(height: 24),
              _buildSectionTitle('Quick Actions'),
              const SizedBox(height: 14),
              _buildQuickActions(),
              const SizedBox(height: 24),
              _buildSectionTitle('Daily Self Care'),
              const SizedBox(height: 14),
              _buildSelfCare(),
              const SizedBox(height: 24),
              _buildSectionTitle('Support'),
              const SizedBox(height: 14),
              _buildSupportCard(),
              const SizedBox(height: 24),
              _buildBreathingShortcut(),
              const SizedBox(height: 24),
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
              _buildSectionTitle('Weekly Mood'),
              const SizedBox(height: 14),
              _buildWeeklyMood(),
              const SizedBox(height: 24),

              _buildSectionTitle('Recent Activity'),
              const SizedBox(height: 14),

              if (_isLoadingActivities)
                const Center(child: CircularProgressIndicator(color: _accent))
              else if (_recentActivities.isEmpty)
                Text(
                  'No recent activity yet. Go log something!',
                  style: TextStyle(color: Colors.white.withOpacity(0.5)),
                )
              else
                ..._recentActivities.map(
                  (a) => _buildActivityItem(
                    icon: a.icon,
                    activity: a.activity,
                    time: _formatTimeAgo(a.timestamp),
                    color: a.color,
                  ),
                ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickMetrics() {
    return Row(
      children: [
        Expanded(
          child: _miniMetric(
            icon: Icons.psychology_rounded,
            label: 'Mental',
            value: '${(_metrics!.moodScore * 100).round()}',
            sub: _metrics!.moodScore > 0.6 ? 'Stable' : 'Needs Care',
            color: _purple,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _miniMetric(
            icon: Icons.directions_walk_rounded,
            label: 'Activity',
            value: '${(_metrics!.activityLevel * 100).round()}%',
            sub: _metrics!.activityLevel > 0.5 ? 'Active' : 'Low',
            color: const Color(0xFF5C6BC0),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ValueListenableBuilder<int>(
            valueListenable: WatchService().currentBpm,
            builder: (context, bpm, child) {
              return _miniMetric(
                icon: Icons.favorite_rounded,
                label: 'Heart Rate',
                value: '$bpm',
                sub: _getHeartRateStatus(bpm),
                color: Colors.redAccent,
              );
            },
          ),
        ),
      ],
    );
  }

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
        Text(
          'Hi ${widget.username ?? "User"} 👋',
          style: const TextStyle(
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

  Widget _buildQuickActions() {
    final actions = [
      {
        'icon': Icons.mood_rounded,
        'label': 'Log Mood',
        'color': _purple,
        'targetIndex': 3,
      },
      {
        'icon': Icons.air_rounded,
        'label': 'Breathing',
        'color': _green,
        'targetIndex': -1,
      },
      {
        'icon': Icons.bedtime_rounded,
        'label': 'Sleep Stats',
        'color': const Color(0xFF5C6BC0),
        'targetIndex': 1,
      },
      {
        'icon': Icons.medical_services_rounded,
        'label': 'Book Doctor',
        'color': Colors.redAccent,
        'targetIndex': 6,
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
            } else if (widget.onNavigate != null) {
              widget.onNavigate!(a['targetIndex'] as int);
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

  Widget _buildSelfCare() {
    return Column(
      children: [
        _buildCheckbox('Drink 8 glasses of water', _waterChecked, (v) {
          setState(() => _waterChecked = v!);
          _saveCheckboxState('water', v!);
        }),
        _buildCheckbox('Take a 15 min walk', _walkChecked, (v) {
          setState(() => _walkChecked = v!);
          _saveCheckboxState('walk', v!);
        }),
        _buildCheckbox('Sleep by 10 PM', _sleepChecked, (v) {
          setState(() => _sleepChecked = v!);
          _saveCheckboxState('sleep', v!);
        }),
      ],
    );
  }

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
          const CircleAvatar(
            radius: 26,
            backgroundColor: _purple,
            child: Icon(Icons.medical_services, color: Colors.white, size: 26),
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

  Widget _buildWeeklyMood() {
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
                height: 90 * _weeklyMoodData[i],
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
