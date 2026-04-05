import 'package:flutter/material.dart';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import '../../services/health_database_service.dart';
import '../../services/watch_service.dart'; // ⚡ NEW: Needed for syncTrigger

// ─── Data Models ──────────────────────────────────────────────────────────────
class SleepStageEntry {
  final String label;
  final Color color;
  final double percentage;
  final Duration duration;
  const SleepStageEntry({
    required this.label,
    required this.color,
    required this.percentage,
    required this.duration,
  });
}

class SleepData {
  final int score;
  final TimeOfDay bedtime;
  final TimeOfDay wakeTime;
  final Duration totalSleep;
  final String quality;
  final List<SleepStageEntry> stages;
  final List<_StageBlock> stageBlocks;
  const SleepData({
    required this.score,
    required this.bedtime,
    required this.wakeTime,
    required this.totalSleep,
    required this.quality,
    required this.stages,
    required this.stageBlocks,
  });
  factory SleepData.empty() => const SleepData(
    score: 0,
    bedtime: TimeOfDay(hour: 0, minute: 0),
    wakeTime: TimeOfDay(hour: 0, minute: 0),
    totalSleep: Duration.zero,
    quality: 'No Data',
    stages: [],
    stageBlocks: [],
  );
}

class _StageBlock {
  final double startFraction;
  final double endFraction;
  final int level;
  const _StageBlock(this.startFraction, this.endFraction, this.level);
}

// ─── Main Widget ───────────────────────────────────────────────────────────────
class Sleep extends StatefulWidget {
  const Sleep({super.key});
  @override
  State<Sleep> createState() => _SleepState();
}

class _SleepState extends State<Sleep> with SingleTickerProviderStateMixin {
  int _selectedDay = DateTime.now().weekday % 7;
  int _playingSoundIndex = -1;

  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _arcAnimController;
  late Animation<double> _arcAnim;
  bool _isLoading = true;

  List<SleepData> _weeklySleepData = List.filled(7, SleepData.empty());

  static const _bgDark = Color(0xFF0D1B2A);
  static const _bgCard = Color(0xFF152238);
  static const _accent = Color(0xFF4DD0E1);
  static const _purple = Color(0xFF7E57C2);
  static const _gold = Color(0xFFFFD54F);

  final _dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  final _sounds = [
    {'icon': Icons.water_drop, 'title': 'Rain', 'file': 'rain.mp3'},
    {'icon': Icons.waves, 'title': 'Ocean Waves', 'file': 'waves.mp3'},
    {'icon': Icons.forest, 'title': 'Forest Night', 'file': 'forest.mp3'},
    {'icon': Icons.flutter_dash, 'title': 'Birds', 'file': 'birds.mp3'},
    {'icon': Icons.eco, 'title': 'Leaves', 'file': 'leaves.mp3'},
    {'icon': Icons.local_fire_department, 'title': 'Fire', 'file': 'fire.mp3'},
  ];

  @override
  void initState() {
    super.initState();

    // ⚡ NEW: Listen to background syncs from the smartwatch!
    WatchService().syncTrigger.addListener(_loadSleepData);

    _arcAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _arcAnim = CurvedAnimation(
      parent: _arcAnimController,
      curve: Curves.easeOutCubic,
    );
    _arcAnimController.forward();
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
    _loadSleepData();
  }

  @override
  void dispose() {
    // ⚡ Don't forget to remove the listener!
    WatchService().syncTrigger.removeListener(_loadSleepData);
    _arcAnimController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ==========================================
  // 🎵 AUDIO CONTROL
  // ==========================================
  Future<void> _toggleAudio(int index) async {
    try {
      if (_playingSoundIndex == index) {
        await _audioPlayer.pause();
        setState(() => _playingSoundIndex = -1);
      } else {
        await _audioPlayer.stop();
        final fileName = _sounds[index]['file'] as String;
        await _audioPlayer.play(AssetSource('sounds/$fileName'));
        setState(() => _playingSoundIndex = index);
      }
    } catch (e) {
      debugPrint("Audio Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ensure mp3 files are in assets/sounds/"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ==========================================
  // 🌙 FETCH & PARSE SLEEP DATA
  // ==========================================
  Future<void> _loadSleepData() async {
    final logs = await HealthDatabaseService.instance.getRecords('sleep_logs');
    List<SleepData> tempWeek = List.filled(7, SleepData.empty());
    final now = DateTime.now();

    if (logs.isEmpty) {
      tempWeek = _getFallbackBaseline();
    } else {
      for (var log in logs) {
        final logTimestamp = DateTime.parse(log['timestamp'] as String);
        final difference = now.difference(logTimestamp).inDays;

        if (difference < 7) {
          int dayIndex = logTimestamp.weekday % 7;
          tempWeek[dayIndex] = _parseDbLogToSleepData(log);
        }
      }
    }

    if (mounted) {
      setState(() {
        _weeklySleepData = tempWeek;
        _isLoading = false;
      });
      _arcAnimController.reset();
      _arcAnimController.forward();
    }
  }

  SleepData _parseDbLogToSleepData(Map<String, dynamic> log) {
    final bedDateTime = DateTime.parse(log['bedtime'] as String);
    final wakeDateTime = DateTime.parse(log['wake_time'] as String);

    final bedtime = TimeOfDay(
      hour: bedDateTime.hour,
      minute: bedDateTime.minute,
    );
    final wakeTime = TimeOfDay(
      hour: wakeDateTime.hour,
      minute: wakeDateTime.minute,
    );
    final totalSleep = wakeDateTime.difference(bedDateTime);
    final deepSleepMins = log['deep_sleep_minutes'] as int;
    final score = log['sleep_quality'] as int;

    final totalMins = totalSleep.inMinutes;
    final deepPct = (deepSleepMins / totalMins).clamp(0.0, 1.0);
    final awakePct = 0.05;
    final remPct = 0.22;
    final lightPct = (1.0 - deepPct - awakePct - remPct).clamp(0.0, 1.0);

    String quality = 'Good';
    if (score >= 85)
      quality = 'Great';
    else if (score < 60)
      quality = 'Poor';
    else if (score < 75)
      quality = 'Fair';

    return SleepData(
      score: score,
      bedtime: bedtime,
      wakeTime: wakeTime,
      totalSleep: totalSleep,
      quality: quality,
      stages: [
        SleepStageEntry(
          label: 'Awake',
          color: const Color(0xFFFFA726),
          percentage: awakePct,
          duration: Duration(minutes: (totalMins * awakePct).round()),
        ),
        SleepStageEntry(
          label: 'REM',
          color: const Color(0xFF4DD0E1),
          percentage: remPct,
          duration: Duration(minutes: (totalMins * remPct).round()),
        ),
        SleepStageEntry(
          label: 'Light',
          color: const Color(0xFF5C6BC0),
          percentage: lightPct,
          duration: Duration(minutes: (totalMins * lightPct).round()),
        ),
        SleepStageEntry(
          label: 'Deep',
          color: const Color(0xFF7E57C2),
          percentage: deepPct,
          duration: Duration(minutes: deepSleepMins),
        ),
      ],
      stageBlocks: const [
        _StageBlock(0.00, 0.05, 0),
        _StageBlock(0.05, 0.18, 2),
        _StageBlock(0.18, 0.28, 3),
        _StageBlock(0.28, 0.35, 1),
        _StageBlock(0.35, 0.40, 0),
        _StageBlock(0.40, 0.55, 2),
        _StageBlock(0.55, 0.65, 3),
        _StageBlock(0.65, 0.78, 1),
        _StageBlock(0.78, 0.90, 2),
        _StageBlock(0.90, 0.95, 0),
        _StageBlock(0.95, 1.00, 2),
      ],
    );
  }

  Future<void> _logQuickSleep() async {
    final now = DateTime.now();
    final bedtime = DateTime(now.year, now.month, now.day - 1, 23, 0);
    final waketime = DateTime(now.year, now.month, now.day, 7, 30);

    await HealthDatabaseService.instance.insertRecord('sleep_logs', {
      'bedtime': bedtime.toIso8601String(),
      'wake_time': waketime.toIso8601String(),
      'sleep_quality': 92,
      'deep_sleep_minutes': 120,
      'timestamp': now.toIso8601String(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logged 8.5 hours of sleep for last night!'),
        backgroundColor: _accent,
        behavior: SnackBarBehavior.floating,
      ),
    );
    _loadSleepData();
  }

  SleepData get _data => _weeklySleepData[_selectedDay];

  void _selectDay(int index) {
    setState(() => _selectedDay = index);
    _arcAnimController.reset();
    _arcAnimController.forward();
  }

  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final min = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$min $period';
  }

  String _formatDuration(Duration d) {
    if (d == Duration.zero) return '0h 0m';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: _bgDark,
        child: const Center(child: CircularProgressIndicator(color: _accent)),
      );
    }

    final hasData = _data.totalSleep > Duration.zero;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B1527), Color(0xFF0D1B2A), Color(0xFF132E4A)],
        ),
      ),
      child: CustomPaint(
        painter: _StarsPainter(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Sleep Analysis',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: _logQuickSleep,
                      icon: const Icon(
                        Icons.add_circle,
                        color: _accent,
                        size: 32,
                      ),
                      tooltip: 'Log Sleep',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildDaySelector(),
                const SizedBox(height: 24),

                if (!hasData)
                  _buildEmptyState()
                else ...[
                  _buildArcDial(),
                  const SizedBox(height: 24),
                  _buildSummaryCards(),
                  const SizedBox(height: 28),
                  _buildSectionTitle('Weekly Sleep Duration'),
                  const SizedBox(height: 12),
                  _buildWeeklyGraph(),
                  const SizedBox(height: 28),
                  _buildSectionTitle('Sleep Stages'),
                  const SizedBox(height: 12),
                  _buildStagesChart(),
                  const SizedBox(height: 20),
                  _buildStagesBreakdown(),
                  const SizedBox(height: 28),
                ],

                _buildSectionTitle('Sounds for Sleep'),
                const SizedBox(height: 12),
                _buildSoundsSection(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyGraph() {
    final maxMinutes = _weeklySleepData
        .map((d) => d.totalSleep.inMinutes)
        .reduce(max)
        .toDouble();
    final safeMax = maxMinutes == 0 ? 480.0 : maxMinutes;

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
                final mins = _weeklySleepData[i].totalSleep.inMinutes
                    .toDouble();
                final pct = mins / safeMax;
                final isSelected = i == _selectedDay;
                final hoursStr = mins == 0
                    ? '0h'
                    : '${(mins / 60).toStringAsFixed(1)}h';

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      hoursStr,
                      style: TextStyle(
                        color: isSelected ? _accent : Colors.white38,
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
                          colors: isSelected
                              ? [_accent, _accent.withOpacity(0.4)]
                              : [
                                  _purple.withOpacity(0.7),
                                  _purple.withOpacity(0.3),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: isSelected
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
              final isSelected = i == _selectedDay;
              return Text(
                _dayLabels[i],
                style: TextStyle(
                  color: isSelected ? _accent : Colors.white54,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Icon(
            Icons.bedtime_off_rounded,
            size: 60,
            color: Colors.white.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          const Text(
            "No Sleep Data",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "There is no sleep log recorded for this day.",
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: _bgCard.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (i) {
          final isSelected = i == _selectedDay;
          return GestureDetector(
            onTap: () => _selectDay(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? _accent : Colors.transparent,
                border: Border.all(
                  color: isSelected ? _accent : Colors.white24,
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: _accent.withOpacity(0.4),
                          blurRadius: 10,
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: Text(
                  _dayLabels[i],
                  style: TextStyle(
                    color: isSelected ? _bgDark : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildArcDial() {
    return SizedBox(
      height: 240,
      child: AnimatedBuilder(
        animation: _arcAnim,
        builder: (context, _) {
          return CustomPaint(
            painter: _SleepArcPainter(
              score: _data.score,
              progress: _arcAnim.value,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatDuration(_data.totalSleep),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ASLEEP',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _scoreColor(_data.score).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Score ${_data.score}',
                        style: TextStyle(
                          color: _scoreColor(_data.score),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _infoCard(
                icon: Icons.nightlight_round,
                label: 'Bedtime',
                value: _formatTime(_data.bedtime),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _infoCard(
                icon: Icons.wb_sunny_rounded,
                label: 'Wake up',
                value: _formatTime(_data.wakeTime),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _infoCard(
                icon: Icons.access_time_filled,
                label: 'Time Asleep',
                value: _formatDuration(_data.totalSleep),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _infoCard(
                icon: Icons.star_rounded,
                label: 'Quality',
                value: _data.quality,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Icon(icon, color: _gold, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
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

  Widget _buildStagesChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: SizedBox(
        height: 170,
        child: CustomPaint(
          size: const Size(double.infinity, 170),
          painter: _StageChartPainter(
            blocks: _data.stageBlocks,
            stages: _data.stages,
            bedtime: _data.bedtime,
            wakeTime: _data.wakeTime,
          ),
        ),
      ),
    );
  }

  Widget _buildStagesBreakdown() {
    return Column(
      children: _data.stages.map((stage) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: stage.color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: stage.color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                stage.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(stage.percentage * 100).round()}%',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                _formatDuration(stage.duration),
                style: TextStyle(
                  color: stage.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSoundsSection() {
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _sounds.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final sound = _sounds[i];
          final isPlaying = _playingSoundIndex == i;
          return GestureDetector(
            onTap: () => _toggleAudio(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 130,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isPlaying ? _accent.withOpacity(0.15) : _bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isPlaying ? _accent : Colors.white10,
                  width: isPlaying ? 1.5 : 1,
                ),
                boxShadow: isPlaying
                    ? [
                        BoxShadow(
                          color: _accent.withOpacity(0.25),
                          blurRadius: 16,
                        ),
                      ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    sound['icon'] as IconData,
                    color: isPlaying ? _accent : Colors.white54,
                    size: 32,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    sound['title'] as String,
                    style: TextStyle(
                      color: isPlaying ? _accent : Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Icon(
                    isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill,
                    color: isPlaying ? _accent : Colors.white30,
                    size: 22,
                  ),
                ],
              ),
            ),
          );
        },
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

  Color _scoreColor(int score) {
    if (score >= 85) return const Color(0xFF66BB6A);
    if (score >= 70) return _accent;
    if (score >= 50) return _gold;
    return const Color(0xFFEF5350);
  }

  List<SleepData> _getFallbackBaseline() {
    List<SleepData> week = List.filled(7, SleepData.empty());
    final now = DateTime.now();
    int dayIndex = now.weekday % 7;
    week[dayIndex] = const SleepData(
      score: 85,
      bedtime: TimeOfDay(hour: 23, minute: 15),
      wakeTime: TimeOfDay(hour: 7, minute: 0),
      totalSleep: Duration(hours: 7, minutes: 45),
      quality: 'Great',
      stages: [
        SleepStageEntry(
          label: 'Awake',
          color: Color(0xFFFFA726),
          percentage: 0.05,
          duration: Duration(minutes: 23),
        ),
        SleepStageEntry(
          label: 'REM',
          color: Color(0xFF4DD0E1),
          percentage: 0.23,
          duration: Duration(hours: 1, minutes: 47),
        ),
        SleepStageEntry(
          label: 'Light',
          color: Color(0xFF5C6BC0),
          percentage: 0.52,
          duration: Duration(hours: 4, minutes: 2),
        ),
        SleepStageEntry(
          label: 'Deep',
          color: Color(0xFF7E57C2),
          percentage: 0.20,
          duration: Duration(hours: 1, minutes: 33),
        ),
      ],
      stageBlocks: [
        _StageBlock(0.00, 0.04, 0),
        _StageBlock(0.04, 0.15, 2),
        _StageBlock(0.15, 0.30, 3),
        _StageBlock(0.30, 0.42, 1),
        _StageBlock(0.42, 0.45, 0),
        _StageBlock(0.45, 0.60, 2),
        _StageBlock(0.60, 0.72, 3),
        _StageBlock(0.72, 0.85, 1),
        _StageBlock(0.85, 0.95, 2),
        _StageBlock(0.95, 1.00, 2),
      ],
    );
    return week;
  }
}

// ─── Custom Painters ─────────────────────────────────────────────────────────

class _StarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42);
    final paint = Paint()..color = Colors.white;
    for (int i = 0; i < 80; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = rng.nextDouble() * 1.3 + 0.3;
      paint.color = Colors.white.withOpacity(rng.nextDouble() * 0.5 + 0.15);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SleepArcPainter extends CustomPainter {
  final int score;
  final double progress;
  _SleepArcPainter({required this.score, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.65);
    final radius = size.width * 0.38;

    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi,
      false,
      trackPaint,
    );

    final sweepAngle = pi * (score / 100.0) * progress;
    final gradientPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: pi,
        endAngle: 2 * pi,
        colors: const [Color(0xFF7E57C2), Color(0xFF4DD0E1), Color(0xFFFFD54F)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      sweepAngle,
      false,
      gradientPaint,
    );

    final dotPaint = Paint()..color = Colors.white.withOpacity(0.3);
    for (int i = 0; i <= 10; i++) {
      final angle = pi + (pi * i / 10);
      final dx = center.dx + radius * cos(angle);
      final dy = center.dy + radius * sin(angle);
      canvas.drawCircle(Offset(dx, dy), 1.5, dotPaint);
    }
    _drawMoonIcon(canvas, Offset(center.dx - radius - 6, center.dy + 18));
    _drawSunIcon(canvas, Offset(center.dx + radius + 6, center.dy + 18));
  }

  void _drawMoonIcon(Canvas canvas, Offset pos) {
    canvas.drawCircle(pos, 8, Paint()..color = const Color(0xFFB0BEC5));
    canvas.drawCircle(
      Offset(pos.dx + 4, pos.dy - 3),
      7,
      Paint()..color = const Color(0xFF0D1B2A),
    );
  }

  void _drawSunIcon(Canvas canvas, Offset pos) {
    canvas.drawCircle(pos, 7, Paint()..color = const Color(0xFFFFD54F));
    for (int i = 0; i < 8; i++) {
      final angle = (pi * 2 * i / 8);
      canvas.drawLine(
        Offset(pos.dx + 10 * cos(angle), pos.dy + 10 * sin(angle)),
        Offset(pos.dx + 13 * cos(angle), pos.dy + 13 * sin(angle)),
        Paint()
          ..color = const Color(0xFFFFD54F)
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SleepArcPainter old) =>
      old.score != score || old.progress != progress;
}

class _StageChartPainter extends CustomPainter {
  final List<_StageBlock> blocks;
  final List<SleepStageEntry> stages;
  final TimeOfDay bedtime;
  final TimeOfDay wakeTime;
  _StageChartPainter({
    required this.blocks,
    required this.stages,
    required this.bedtime,
    required this.wakeTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (blocks.isEmpty) return;

    final stageColors = {
      0: const Color(0xFFFFA726),
      1: const Color(0xFF4DD0E1),
      2: const Color(0xFF5C6BC0),
      3: const Color(0xFF7E57C2),
    };
    final chartBottom = size.height - 28;
    final levelY = {
      0: chartBottom * 0.05,
      1: chartBottom * 0.30,
      2: chartBottom * 0.58,
      3: chartBottom * 0.85,
    };

    final guidePaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1;
    for (var entry in levelY.entries) {
      canvas.drawLine(
        Offset(0, entry.value),
        Offset(size.width, entry.value),
        guidePaint,
      );
    }

    final labels = ['Awake', 'REM', 'Light', 'Deep'];
    for (int i = 0; i < 4; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, levelY[i]! - 14));
    }

    final chartLeft = 42.0;
    final chartWidth = size.width - chartLeft;

    for (int i = 0; i < blocks.length; i++) {
      final b = blocks[i];
      final x1 = chartLeft + b.startFraction * chartWidth;
      final x2 = chartLeft + b.endFraction * chartWidth;
      final y = levelY[b.level]!;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(x1, y - 4, x2, y + 4),
          const Radius.circular(2),
        ),
        Paint()..color = stageColors[b.level]!,
      );
      if (i < blocks.length - 1) {
        canvas.drawLine(
          Offset(x2, y),
          Offset(x2, levelY[blocks[i + 1].level]!),
          Paint()
            ..color = Colors.white.withOpacity(0.15)
            ..strokeWidth = 1,
        );
      }
    }

    int bedHour = bedtime.hour;
    int wakeHour = wakeTime.hour;
    int totalHours = wakeHour - bedHour;
    if (totalHours <= 0) totalHours += 24;

    final tickPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;
    for (int h = 0; h <= totalHours; h++) {
      final fraction = h / totalHours;
      final x = chartLeft + fraction * chartWidth;
      final hour = (bedHour + h) % 24;

      canvas.drawLine(
        Offset(x, chartBottom),
        Offset(x, chartBottom + 5),
        tickPaint,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: hour.toString().padLeft(2, '0'),
          style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, chartBottom + 8));
    }
  }

  @override
  bool shouldRepaint(covariant _StageChartPainter old) => true;
}
