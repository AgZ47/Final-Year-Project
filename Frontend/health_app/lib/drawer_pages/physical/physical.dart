import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../services/watch_service.dart';
import '../../services/health_database_service.dart';

class Physical extends StatefulWidget {
  const Physical({super.key});

  @override
  State<Physical> createState() => _PhysicalState();
}

class _PhysicalState extends State<Physical>
    with SingleTickerProviderStateMixin {
  // ── Colors ──
  static const _bgCard = Color(0xFF152238);
  static const _accent = Color(0xFF4DD0E1);
  static const _purple = Color(0xFF7E57C2);
  static const _green = Color(0xFF66BB6A);
  static const _orange = Color(0xFFFFB74D);

  // ── Dynamic Data State ──
  List<double> _weeklySteps = List.filled(7, 0);
  int _todaySteps = 0;
  bool _isLoading = true;

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    WatchService().initialize();

    // ⚡ NEW: Listen to background syncs from the smartwatch!
    WatchService().syncTrigger.addListener(_loadPhysicalData);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    _loadPhysicalData();
  }

  @override
  void dispose() {
    // ⚡ Don't forget to remove the listener!
    WatchService().syncTrigger.removeListener(_loadPhysicalData);
    _animController.dispose();
    super.dispose();
  }

  // ==========================================
  // 📊 FETCH DATA FROM DATABASE
  // ==========================================
  Future<void> _loadPhysicalData() async {
    final logs = await HealthDatabaseService.instance.getRecords('step_logs');
    final now = DateTime.now();

    List<double> tempWeeklySteps = List.filled(7, 0);
    int tempTodaySteps = 0;

    for (var log in logs) {
      final logDate = DateTime.parse(log['timestamp'] as String);
      final steps = log['steps'] as int;

      // Check if log is from today
      if (logDate.year == now.year &&
          logDate.month == now.month &&
          logDate.day == now.day) {
        tempTodaySteps += steps;
      }

      // Populate weekly chart (simple check for logs within the last 7 days)
      final difference = now.difference(logDate).inDays;
      if (difference < 7) {
        // weekday is 1-7 (Mon-Sun). Subtract 1 for 0-6 index.
        int dayIndex = logDate.weekday - 1;
        tempWeeklySteps[dayIndex] += steps.toDouble();
      }
    }

    // Prevent completely empty graphs on fresh install by adding a baseline if empty
    if (tempWeeklySteps.every((element) => element == 0)) {
      tempWeeklySteps = [3200, 5400, 4320, 6100, 3800, 7200, 4800];
    }

    if (mounted) {
      setState(() {
        _weeklySteps = tempWeeklySteps;
        _todaySteps = tempTodaySteps > 0
            ? tempTodaySteps
            : 4320; // Fallback for UI if 0
        _isLoading = false;
      });
    }
  }

  // ==========================================
  // 🏃 LOG QUICK WORKOUT
  // ==========================================
  Future<void> _logQuickWalk() async {
    // Simulates a quick 1,000 step walk
    await HealthDatabaseService.instance.logSteps(1000, 800.0, 45.0);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Added 1,000 steps to today\'s log!'),
        backgroundColor: _accent,
        behavior: SnackBarBehavior.floating,
      ),
    );

    _loadPhysicalData();
  }

  String _getHeartRateStatus(int bpm) {
    if (bpm < 60) return 'Resting';
    if (bpm <= 85) return 'Active';
    if (bpm <= 120) return 'Exercising';
    return 'Stressed';
  }

  Color _getStatusColor(int bpm) {
    if (bpm <= 85) return _green;
    if (bpm <= 120) return _orange;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: const Color(0xFF0D1B2A),
        child: const Center(child: CircularProgressIndicator(color: _accent)),
      );
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Physical Health',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Monitor your activity & vitals',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: _logQuickWalk,
                      icon: const Icon(
                        Icons.add_circle,
                        color: _accent,
                        size: 32,
                      ),
                      tooltip: 'Log 1,000 Steps',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('Activity Summary'),
                const SizedBox(height: 14),
                _buildActivityCards(),
                const SizedBox(height: 28),

                _buildSectionTitle('Heart Rate'),
                const SizedBox(height: 14),
                _buildHeartRateCard(),
                const SizedBox(height: 28),

                _buildSectionTitle('Workout Suggestions'),
                const SizedBox(height: 14),
                _buildWorkoutSuggestions(),
                const SizedBox(height: 28),

                _buildSectionTitle('Weekly Activity'),
                const SizedBox(height: 14),
                _buildWeeklyGraph(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCards() {
    return Row(
      children: [
        Expanded(
          child: _metricCard(
            Icons.directions_walk_rounded,
            'Steps',
            '$_todaySteps',
            _accent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _metricCard(
            Icons.local_fire_department_rounded,
            'Calories',
            '${(_todaySteps * 0.04).round()} kcal',
            _orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _metricCard(
            Icons.timer_rounded,
            'Active',
            '${(_todaySteps / 100).round()} min',
            _green,
          ),
        ),
      ],
    );
  }

  Widget _metricCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeartRateCard() {
    return ValueListenableBuilder<List<int>>(
      valueListenable: WatchService().heartRateHistory,
      builder: (context, heartRateData, child) {
        final currentBpm = heartRateData.isNotEmpty ? heartRateData.last : 0;
        final statusText = _getHeartRateStatus(currentBpm);
        final statusColor = _getStatusColor(currentBpm);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.redAccent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$currentBpm bpm',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Current Heart Rate',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 100,
                child: CustomPaint(
                  size: const Size(double.infinity, 100),
                  painter: _HeartRateGraphPainter(data: heartRateData),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '12 AM',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    '6 AM',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    '12 PM',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    '6 PM',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    'Now',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWorkoutSuggestions() {
    final workouts = [
      {
        'icon': Icons.self_improvement,
        'title': 'Morning Stretch',
        'desc': '10 min · Flexibility',
        'color': _accent,
      },
      {
        'icon': Icons.spa_rounded,
        'title': 'Yoga',
        'desc': '20 min · Balance',
        'color': _purple,
      },
      {
        'icon': Icons.directions_run_rounded,
        'title': 'Light Cardio',
        'desc': '15 min · Endurance',
        'color': _orange,
      },
    ];
    return Column(
      children: workouts.map((w) {
        final c = w['color'] as Color;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _bgCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: c.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(w['icon'] as IconData, color: c, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      w['title'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      w['desc'] as String,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: c, size: 24),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWeeklyGraph() {
    final maxSteps = _weeklySteps.reduce(math.max);
    final safeMax = maxSteps == 0 ? 10000.0 : maxSteps;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final pct = _weeklySteps[i] / safeMax;
                final isToday = i == DateTime.now().weekday - 1;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${(_weeklySteps[i] / 1000).toStringAsFixed(1)}k',
                      style: TextStyle(
                        color: isToday ? _accent : Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 20,
                      height: 90 * pct,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isToday
                              ? [_accent, _accent.withOpacity(0.4)]
                              : [
                                  _purple.withOpacity(0.7),
                                  _purple.withOpacity(0.3),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: isToday
                            ? [
                                BoxShadow(
                                  color: _accent.withOpacity(0.3),
                                  blurRadius: 8,
                                ),
                              ]
                            : [],
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (i) {
              final isToday = i == DateTime.now().weekday - 1;
              return Text(
                _dayLabels[i],
                style: TextStyle(
                  color: isToday ? _accent : Colors.white54,
                  fontSize: 12,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                ),
              );
            }),
          ),
        ],
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
}

class _HeartRateGraphPainter extends CustomPainter {
  final List<int> data;
  _HeartRateGraphPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final minVal = data.reduce(math.min).toDouble() - 5;
    final maxVal = data.reduce(math.max).toDouble() + 5;
    final range = maxVal == minVal ? 1.0 : maxVal - minVal;
    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i] - minVal) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        final prevX = ((i - 1) / (data.length - 1)) * size.width;
        final prevY =
            size.height - ((data[i - 1] - minVal) / range) * size.height;
        final midX = (prevX + x) / 2;
        path.cubicTo(midX, prevY, midX, y, x, y);
        fillPath.cubicTo(midX, prevY, midX, y, x, y);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.redAccent.withOpacity(0.25),
          Colors.redAccent.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);
    final linePaint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    if (data.length > 1) {
      final lastX = size.width;
      final lastY = size.height - ((data.last - minVal) / range) * size.height;
      canvas.drawCircle(
        Offset(lastX, lastY),
        5,
        Paint()..color = Colors.redAccent,
      );
      canvas.drawCircle(Offset(lastX, lastY), 3, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _HeartRateGraphPainter oldDelegate) => true;
}
