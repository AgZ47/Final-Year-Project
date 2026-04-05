import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart'; // 🎵 Audio package
import '../../services/watch_service.dart';
import '../../services/health_database_service.dart';
import '../../core/theme/app_theme.dart';

class Sleep extends StatefulWidget {
  const Sleep({super.key});

  @override
  State<Sleep> createState() => _SleepState();
}

class _SleepState extends State<Sleep> with SingleTickerProviderStateMixin {
  bool _isLoading = true;

  // ── Database State ──
  Map<String, dynamic>? _lastNightData;
  List<Map<String, dynamic>> _weeklyLogs = [];
  int _avgQuality = 0;

  // ── Animation ──
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // ── 🎵 Music Player State ──
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isMusicPlaying = false;
  int _currentTrackIndex = 0;

  final List<Map<String, dynamic>> _sleepTracks = [
    {
      'title': 'Deep Sleep Delta Waves',
      'subtitle': '432 Hz Binaural',
      'path': 'sounds/birds.mp3',
      'icon': Icons.waves_rounded,
      'color': AppTheme.indigo,
    },
    {
      'title': 'Heavy Rain on Leaves',
      'subtitle': 'Nature Sounds',
      'path': 'sounds/forest.mp3',
      'icon': Icons.water_drop_rounded,
      'color': AppTheme.accent,
    },
    {
      'title': 'Brown Noise',
      'subtitle': 'Continuous Ambient',
      'path': 'sounds/leaves.mp3',
      'icon': Icons.hearing_rounded,
      'color': AppTheme.purple,
    },
    {
      'title': 'Cosmic Dreams',
      'subtitle': 'Ambient Synth',
      'path': 'sounds/waves.mp3',
      'icon': Icons.auto_awesome_rounded,
      'color': AppTheme.gold,
    },
  ];

  @override
  void initState() {
    super.initState();
    WatchService().initialize();
    WatchService().syncTrigger.addListener(_loadSleepData);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);

    _loadSleepData();
  }

  @override
  void dispose() {
    WatchService().syncTrigger.removeListener(_loadSleepData);
    _animController.dispose();
    _audioPlayer.dispose(); // ⚡ Prevent memory leaks from the audio engine
    super.dispose();
  }

  // ==========================================
  // 🛏️ FETCH SLEEP DATA
  // ==========================================
  Future<void> _loadSleepData() async {
    final logs = await HealthDatabaseService.instance.getRecords(
      'sleep_logs',
      orderBy: 'timestamp DESC',
      limit: 7,
    );

    if (logs.isNotEmpty) {
      _lastNightData = logs.first;
      _weeklyLogs = logs;

      int totalQuality = 0;
      for (var log in logs) {
        totalQuality += (log['sleep_quality'] as int?) ?? 0;
      }
      _avgQuality = (totalQuality / logs.length).round();
    } else {
      _lastNightData = null;
      _weeklyLogs = [];
      _avgQuality = 0;
    }

    if (mounted) {
      setState(() => _isLoading = false);
      _animController.forward(from: 0.0);
    }
  }

  Future<void> _logManualSleep() async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    await HealthDatabaseService.instance.insertRecord('sleep_logs', {
      'bedtime': DateTime(
        yesterday.year,
        yesterday.month,
        yesterday.day,
        23,
        30,
      ).toIso8601String(),
      'wake_time': DateTime(
        now.year,
        now.month,
        now.day,
        7,
        15,
      ).toIso8601String(),
      'sleep_quality': 85,
      'deep_sleep_minutes': 110,
      'timestamp': now.toIso8601String(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Manual sleep record added.'),
        backgroundColor: AppTheme.indigo,
        behavior: SnackBarBehavior.floating,
      ),
    );
    _loadSleepData();
  }

  String _formatTime(String? isoString) {
    if (isoString == null) return '--:--';
    final date = DateTime.tryParse(isoString);
    if (date == null) return '--:--';
    return DateFormat.jm().format(date);
  }

  String _calculateDuration(String? startIso, String? endIso) {
    if (startIso == null || endIso == null) return '0h 0m';
    final start = DateTime.tryParse(startIso);
    final end = DateTime.tryParse(endIso);
    if (start == null || end == null) return '0h 0m';

    final diff = end.difference(start);
    final hours = diff.inHours;
    final mins = diff.inMinutes.remainder(60);
    return '${hours}h ${mins}m';
  }

  // ==========================================
  // 🎵 MUSIC PLAYER LOGIC
  // ==========================================

  Future<void> _playCurrentTrack() async {
    final path = _sleepTracks[_currentTrackIndex]['path'] as String;
    await _audioPlayer.setReleaseMode(
      ReleaseMode.loop,
    ); // Loop infinitely for sleep
    await _audioPlayer.play(AssetSource(path));
  }

  void _togglePlay() async {
    if (_isMusicPlaying) {
      await _audioPlayer.pause();
    } else {
      await _playCurrentTrack();
    }
    setState(() => _isMusicPlaying = !_isMusicPlaying);
  }

  void _nextTrack() async {
    setState(() {
      _currentTrackIndex = (_currentTrackIndex + 1) % _sleepTracks.length;
      _isMusicPlaying = true;
    });
    await _playCurrentTrack();
  }

  void _prevTrack() async {
    setState(() {
      _currentTrackIndex = (_currentTrackIndex - 1 < 0)
          ? _sleepTracks.length - 1
          : _currentTrackIndex - 1;
      _isMusicPlaying = true;
    });
    await _playCurrentTrack();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: AppTheme.bgDark,
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.indigo),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.mainBackgroundGradient,
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              _buildHeader(),
              const SizedBox(height: 24),

              if (_lastNightData == null)
                _buildEmptyState()
              else ...[
                _buildLastNightSummary(),
                const SizedBox(height: 28),

                _buildSectionTitle('Sleep Cycles'),
                const SizedBox(height: 14),
                _buildSleepGraphCard(),
                const SizedBox(height: 28),

                _buildSectionTitle('Details'),
                const SizedBox(height: 14),
                _buildDetailsGrid(),
                const SizedBox(height: 28),

                _buildSectionTitle('Weekly Average'),
                const SizedBox(height: 14),
                _buildWeeklyCard(),
                const SizedBox(height: 28),
              ],

              // ⚡ Relaxing Music Section
              _buildSectionTitle('Relaxing Sounds'),
              const SizedBox(height: 14),
              _buildMusicPlayer(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Component Builders ───────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sleep Tracker',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Rest and recovery insights',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 15,
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: _logManualSleep,
          icon: const Icon(Icons.add_circle, color: AppTheme.indigo, size: 32),
          tooltip: 'Add Manual Log',
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.bedtime_off_rounded,
            color: Colors.white38,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'No sleep data yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Wear your watch to bed tonight to start tracking your sleep cycles and recovery.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastNightSummary() {
    final quality = (_lastNightData?['sleep_quality'] as int?) ?? 0;
    final duration = _calculateDuration(
      _lastNightData?['bedtime'],
      _lastNightData?['wake_time'],
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.indigo, AppTheme.indigo.withOpacity(0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.indigo.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last Night',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                duration,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Column(
              children: [
                Text(
                  '$quality',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Score',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepGraphCard() {
    final mockStages = [3, 1, 0, 0, 1, 2, 1, 0, 1, 2, 1, 3];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildGraphLegend('Awake', AppTheme.orange),
              _buildGraphLegend('REM', AppTheme.accent),
              _buildGraphLegend('Light', AppTheme.purple),
              _buildGraphLegend('Deep', AppTheme.indigo),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 120,
            width: double.infinity,
            child: CustomPaint(painter: _SleepStagesPainter(data: mockStages)),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatTime(_lastNightData?['bedtime']),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 12,
                ),
              ),
              Text(
                _formatTime(_lastNightData?['wake_time']),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGraphLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildDetailsGrid() {
    return Row(
      children: [
        Expanded(
          child: _detailCard(
            Icons.bedtime_rounded,
            'Bedtime',
            _formatTime(_lastNightData?['bedtime']),
            AppTheme.purple,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _detailCard(
            Icons.wb_sunny_rounded,
            'Wake Time',
            _formatTime(_lastNightData?['wake_time']),
            AppTheme.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _detailCard(
            Icons.waves_rounded,
            'Deep Sleep',
            '${_lastNightData?['deep_sleep_minutes'] ?? 0}m',
            AppTheme.indigo,
          ),
        ),
      ],
    );
  }

  Widget _detailCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.indigo.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: AppTheme.indigo,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '7-Day Quality Avg',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your sleep is relatively stable.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$_avgQuality',
            style: const TextStyle(
              color: AppTheme.accent,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ─── 🎵 Music Player Widget ───────────────────────────────────────────────

  Widget _buildMusicPlayer() {
    final track = _sleepTracks[_currentTrackIndex];
    final color = track['color'] as Color;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Rotating/Static Disc Icon
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                  boxShadow: _isMusicPlaying
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 12,
                          ),
                        ]
                      : [],
                ),
                child: Icon(track['icon'] as IconData, color: color, size: 32),
              ),
              const SizedBox(width: 16),

              // Track Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track['title'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      track['subtitle'] as String,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // Animated Equalizer (Simulated)
              if (_isMusicPlaying)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    3,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 4,
                      height: 12.0 + (index * 4),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _prevTrack,
                icon: const Icon(
                  Icons.skip_previous_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isMusicPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: AppTheme.bgDark,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: _nextTrack,
                icon: const Icon(
                  Icons.skip_next_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
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

// ─── Painter Logic ───

class _SleepStagesPainter extends CustomPainter {
  final List<int> data;
  _SleepStagesPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final path = Path();
    final fillPath = Path();

    double getY(int stage) {
      switch (stage) {
        case 3:
          return size.height * 0.1;
        case 2:
          return size.height * 0.4;
        case 1:
          return size.height * 0.7;
        case 0:
          return size.height * 0.95;
        default:
          return size.height;
      }
    }

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = getY(data[i]);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        final prevX = ((i - 1) / (data.length - 1)) * size.width;
        final prevY = getY(data[i - 1]);

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
          AppTheme.indigo.withOpacity(0.4),
          AppTheme.indigo.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = AppTheme.indigo
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(0, size.height * 0.1),
      Offset(size.width, size.height * 0.1),
      gridPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.4),
      Offset(size.width, size.height * 0.4),
      gridPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.7),
      Offset(size.width, size.height * 0.7),
      gridPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.95),
      Offset(size.width, size.height * 0.95),
      gridPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SleepStagesPainter oldDelegate) {
    if (oldDelegate.data.length != data.length) return true;
    for (int i = 0; i < data.length; i++) {
      if (oldDelegate.data[i] != data[i]) return true;
    }
    return false;
  }
}
