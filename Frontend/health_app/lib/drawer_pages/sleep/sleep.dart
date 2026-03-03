import 'package:flutter/material.dart';
import 'dart:math';

// ─── Data Model ────────────────────────────────────────────────────────────────
// When you connect SQLite later, just replace the hardcoded SleepData objects
// with data fetched from your database. The UI reads from this model.

class SleepStageEntry {
  final String label;       // "Awake", "REM", "Light", "Deep"
  final Color color;
  final double percentage;  // e.g. 0.05 for 5%
  final Duration duration;

  const SleepStageEntry({
    required this.label,
    required this.color,
    required this.percentage,
    required this.duration,
  });
}

class SleepData {
  final int score;              // 0–100
  final TimeOfDay bedtime;
  final TimeOfDay wakeTime;
  final Duration totalSleep;
  final String quality;         // "Great", "Good", "Fair", "Poor"
  final List<SleepStageEntry> stages;
  // Raw stage blocks for the chart (each block is a time-fraction → stage-level)
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
}

class _StageBlock {
  final double startFraction; // 0.0 – 1.0 across the sleep period
  final double endFraction;
  final int level;            // 0=Awake, 1=REM, 2=Light, 3=Deep

  const _StageBlock(this.startFraction, this.endFraction, this.level);
}

// ─── Sample Data (per day of week) ─────────────────────────────────────────────

final List<SleepData> _weeklySleepData = [
  // Sunday
  SleepData(
    score: 78,
    bedtime: const TimeOfDay(hour: 23, minute: 45),
    wakeTime: const TimeOfDay(hour: 6, minute: 30),
    totalSleep: const Duration(hours: 6, minutes: 45),
    quality: 'Good',
    stages: [
      SleepStageEntry(label: 'Awake',  color: const Color(0xFFFFA726), percentage: 0.08, duration: const Duration(minutes: 32)),
      SleepStageEntry(label: 'REM',    color: const Color(0xFF4DD0E1), percentage: 0.20, duration: const Duration(hours: 1, minutes: 21)),
      SleepStageEntry(label: 'Light',  color: const Color(0xFF5C6BC0), percentage: 0.50, duration: const Duration(hours: 3, minutes: 23)),
      SleepStageEntry(label: 'Deep',   color: const Color(0xFF7E57C2), percentage: 0.22, duration: const Duration(hours: 1, minutes: 29)),
    ],
    stageBlocks: const [
      _StageBlock(0.00, 0.05, 0), _StageBlock(0.05, 0.18, 2), _StageBlock(0.18, 0.28, 3),
      _StageBlock(0.28, 0.35, 1), _StageBlock(0.35, 0.40, 0), _StageBlock(0.40, 0.55, 2),
      _StageBlock(0.55, 0.65, 3), _StageBlock(0.65, 0.78, 1), _StageBlock(0.78, 0.90, 2),
      _StageBlock(0.90, 0.95, 0), _StageBlock(0.95, 1.00, 2),
    ],
  ),
  // Monday
  SleepData(
    score: 85,
    bedtime: const TimeOfDay(hour: 23, minute: 15),
    wakeTime: const TimeOfDay(hour: 7, minute: 0),
    totalSleep: const Duration(hours: 7, minutes: 45),
    quality: 'Great',
    stages: [
      SleepStageEntry(label: 'Awake',  color: const Color(0xFFFFA726), percentage: 0.05, duration: const Duration(minutes: 23)),
      SleepStageEntry(label: 'REM',    color: const Color(0xFF4DD0E1), percentage: 0.23, duration: const Duration(hours: 1, minutes: 47)),
      SleepStageEntry(label: 'Light',  color: const Color(0xFF5C6BC0), percentage: 0.52, duration: const Duration(hours: 4, minutes: 2)),
      SleepStageEntry(label: 'Deep',   color: const Color(0xFF7E57C2), percentage: 0.20, duration: const Duration(hours: 1, minutes: 33)),
    ],
    stageBlocks: const [
      _StageBlock(0.00, 0.04, 0), _StageBlock(0.04, 0.15, 2), _StageBlock(0.15, 0.30, 3),
      _StageBlock(0.30, 0.42, 1), _StageBlock(0.42, 0.45, 0), _StageBlock(0.45, 0.60, 2),
      _StageBlock(0.60, 0.72, 3), _StageBlock(0.72, 0.85, 1), _StageBlock(0.85, 0.95, 2),
      _StageBlock(0.95, 1.00, 2),
    ],
  ),
  // Tuesday
  SleepData(
    score: 92,
    bedtime: const TimeOfDay(hour: 22, minute: 30),
    wakeTime: const TimeOfDay(hour: 6, minute: 45),
    totalSleep: const Duration(hours: 8, minutes: 15),
    quality: 'Great',
    stages: [
      SleepStageEntry(label: 'Awake',  color: const Color(0xFFFFA726), percentage: 0.03, duration: const Duration(minutes: 15)),
      SleepStageEntry(label: 'REM',    color: const Color(0xFF4DD0E1), percentage: 0.25, duration: const Duration(hours: 2, minutes: 4)),
      SleepStageEntry(label: 'Light',  color: const Color(0xFF5C6BC0), percentage: 0.48, duration: const Duration(hours: 3, minutes: 58)),
      SleepStageEntry(label: 'Deep',   color: const Color(0xFF7E57C2), percentage: 0.24, duration: const Duration(hours: 1, minutes: 58)),
    ],
    stageBlocks: const [
      _StageBlock(0.00, 0.03, 0), _StageBlock(0.03, 0.12, 2), _StageBlock(0.12, 0.25, 3),
      _StageBlock(0.25, 0.40, 1), _StageBlock(0.40, 0.55, 2), _StageBlock(0.55, 0.68, 3),
      _StageBlock(0.68, 0.82, 1), _StageBlock(0.82, 0.95, 2), _StageBlock(0.95, 1.00, 2),
    ],
  ),
  // Wednesday (today)
  SleepData(
    score: 88,
    bedtime: const TimeOfDay(hour: 23, minute: 0),
    wakeTime: const TimeOfDay(hour: 7, minute: 15),
    totalSleep: const Duration(hours: 8, minutes: 15),
    quality: 'Great',
    stages: [
      SleepStageEntry(label: 'Awake',  color: const Color(0xFFFFA726), percentage: 0.05, duration: const Duration(minutes: 25)),
      SleepStageEntry(label: 'REM',    color: const Color(0xFF4DD0E1), percentage: 0.22, duration: const Duration(hours: 1, minutes: 49)),
      SleepStageEntry(label: 'Light',  color: const Color(0xFF5C6BC0), percentage: 0.51, duration: const Duration(hours: 4, minutes: 12)),
      SleepStageEntry(label: 'Deep',   color: const Color(0xFF7E57C2), percentage: 0.22, duration: const Duration(hours: 1, minutes: 49)),
    ],
    stageBlocks: const [
      _StageBlock(0.00, 0.04, 0), _StageBlock(0.04, 0.16, 2), _StageBlock(0.16, 0.28, 3),
      _StageBlock(0.28, 0.38, 1), _StageBlock(0.38, 0.42, 0), _StageBlock(0.42, 0.58, 2),
      _StageBlock(0.58, 0.70, 3), _StageBlock(0.70, 0.83, 1), _StageBlock(0.83, 0.93, 2),
      _StageBlock(0.93, 0.97, 0), _StageBlock(0.97, 1.00, 2),
    ],
  ),
  // Thursday
  SleepData(
    score: 65,
    bedtime: const TimeOfDay(hour: 0, minute: 30),
    wakeTime: const TimeOfDay(hour: 6, minute: 0),
    totalSleep: const Duration(hours: 5, minutes: 30),
    quality: 'Fair',
    stages: [
      SleepStageEntry(label: 'Awake',  color: const Color(0xFFFFA726), percentage: 0.10, duration: const Duration(minutes: 33)),
      SleepStageEntry(label: 'REM',    color: const Color(0xFF4DD0E1), percentage: 0.18, duration: const Duration(hours: 1, minutes: 0)),
      SleepStageEntry(label: 'Light',  color: const Color(0xFF5C6BC0), percentage: 0.55, duration: const Duration(hours: 3, minutes: 2)),
      SleepStageEntry(label: 'Deep',   color: const Color(0xFF7E57C2), percentage: 0.17, duration: const Duration(minutes: 55)),
    ],
    stageBlocks: const [
      _StageBlock(0.00, 0.08, 0), _StageBlock(0.08, 0.22, 2), _StageBlock(0.22, 0.33, 3),
      _StageBlock(0.33, 0.45, 1), _StageBlock(0.45, 0.50, 0), _StageBlock(0.50, 0.68, 2),
      _StageBlock(0.68, 0.78, 1), _StageBlock(0.78, 0.90, 2), _StageBlock(0.90, 1.00, 0),
    ],
  ),
  // Friday
  SleepData(
    score: 72,
    bedtime: const TimeOfDay(hour: 1, minute: 0),
    wakeTime: const TimeOfDay(hour: 8, minute: 30),
    totalSleep: const Duration(hours: 7, minutes: 30),
    quality: 'Good',
    stages: [
      SleepStageEntry(label: 'Awake',  color: const Color(0xFFFFA726), percentage: 0.07, duration: const Duration(minutes: 32)),
      SleepStageEntry(label: 'REM',    color: const Color(0xFF4DD0E1), percentage: 0.21, duration: const Duration(hours: 1, minutes: 35)),
      SleepStageEntry(label: 'Light',  color: const Color(0xFF5C6BC0), percentage: 0.50, duration: const Duration(hours: 3, minutes: 45)),
      SleepStageEntry(label: 'Deep',   color: const Color(0xFF7E57C2), percentage: 0.22, duration: const Duration(hours: 1, minutes: 38)),
    ],
    stageBlocks: const [
      _StageBlock(0.00, 0.05, 0), _StageBlock(0.05, 0.18, 2), _StageBlock(0.18, 0.30, 3),
      _StageBlock(0.30, 0.43, 1), _StageBlock(0.43, 0.47, 0), _StageBlock(0.47, 0.62, 2),
      _StageBlock(0.62, 0.75, 3), _StageBlock(0.75, 0.88, 1), _StageBlock(0.88, 0.97, 2),
      _StageBlock(0.97, 1.00, 0),
    ],
  ),
  // Saturday
  SleepData(
    score: 95,
    bedtime: const TimeOfDay(hour: 22, minute: 0),
    wakeTime: const TimeOfDay(hour: 7, minute: 30),
    totalSleep: const Duration(hours: 9, minutes: 30),
    quality: 'Great',
    stages: [
      SleepStageEntry(label: 'Awake',  color: const Color(0xFFFFA726), percentage: 0.02, duration: const Duration(minutes: 11)),
      SleepStageEntry(label: 'REM',    color: const Color(0xFF4DD0E1), percentage: 0.26, duration: const Duration(hours: 2, minutes: 28)),
      SleepStageEntry(label: 'Light',  color: const Color(0xFF5C6BC0), percentage: 0.47, duration: const Duration(hours: 4, minutes: 28)),
      SleepStageEntry(label: 'Deep',   color: const Color(0xFF7E57C2), percentage: 0.25, duration: const Duration(hours: 2, minutes: 23)),
    ],
    stageBlocks: const [
      _StageBlock(0.00, 0.02, 0), _StageBlock(0.02, 0.14, 2), _StageBlock(0.14, 0.28, 3),
      _StageBlock(0.28, 0.42, 1), _StageBlock(0.42, 0.56, 2), _StageBlock(0.56, 0.70, 3),
      _StageBlock(0.70, 0.84, 1), _StageBlock(0.84, 0.97, 2), _StageBlock(0.97, 1.00, 2),
    ],
  ),
];

// ─── Main Widget ───────────────────────────────────────────────────────────────

class Sleep extends StatefulWidget {
  const Sleep({super.key});

  @override
  State<Sleep> createState() => _SleepState();
}

class _SleepState extends State<Sleep> with SingleTickerProviderStateMixin {
  int _selectedDay = DateTime.now().weekday % 7; // 0=Sun..6=Sat
  int _playingSoundIndex = -1; // -1 means nothing playing
  late AnimationController _arcAnimController;
  late Animation<double> _arcAnim;

  static const _bgDark = Color(0xFF0D1B2A);
  static const _bgCard = Color(0xFF152238);
  static const _accent = Color(0xFF4DD0E1);
  static const _gold   = Color(0xFFFFD54F);

  final _dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  final _sounds = [
    {'icon': Icons.water_drop, 'title': 'Rain'},
    {'icon': Icons.waves,      'title': 'Ocean Waves'},
    {'icon': Icons.forest,     'title': 'Forest Night'},
    {'icon': Icons.flutter_dash, 'title': 'Birds'},
    {'icon': Icons.eco,       'title': 'leaves'},
    {'icon': Icons.local_fire_department, 'title': 'Fire'},
  ];

  @override
  void initState() {
    super.initState();
    _arcAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _arcAnim = CurvedAnimation(parent: _arcAnimController, curve: Curves.easeOutCubic);
    _arcAnimController.forward();
  }

  @override
  void dispose() {
    _arcAnimController.dispose();
    super.dispose();
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
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}min';
    if (h > 0) return '${h}h';
    return '${m}min';
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

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
      child: CustomPaint(
        painter: _StarsPainter(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─ Day Selector ─
                _buildDaySelector(),
                const SizedBox(height: 24),

                // ─ Arc Dial ─
                _buildArcDial(),
                const SizedBox(height: 24),

                // ─ Summary Cards ─
                _buildSummaryCards(),
                const SizedBox(height: 28),

                // ─ Sleep Stages Chart ─
                _buildSectionTitle('Sleep Stages'),
                const SizedBox(height: 12),
                _buildStagesChart(),
                const SizedBox(height: 20),

                // ─ Stages Breakdown ─
                _buildStagesBreakdown(),
                const SizedBox(height: 28),

                // ─ Sounds for Sleep ─
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

  // ─── Day Selector ──────────────────────────────────────────────────────────

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
                    ? [BoxShadow(color: _accent.withOpacity(0.4), blurRadius: 10)]
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

  // ─── Arc Dial ──────────────────────────────────────────────────────────────

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
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
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

  // ─── Summary Cards ─────────────────────────────────────────────────────────

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

  Widget _infoCard({required IconData icon, required String label, required String value}) {
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
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
        ],
      ),
    );
  }

  // ─── Sleep Stages Chart ────────────────────────────────────────────────────

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

  // ─── Stages Breakdown ──────────────────────────────────────────────────────

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
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(width: 8),
              Text(
                '${(stage.percentage * 100).round()}%',
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
              ),
              const Spacer(),
              Text(
                _formatDuration(stage.duration),
                style: TextStyle(color: stage.color, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── Sounds Section ────────────────────────────────────────────────────────

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
            onTap: () => setState(() => _playingSoundIndex = isPlaying ? -1 : i),
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
                    ? [BoxShadow(color: _accent.withOpacity(0.25), blurRadius: 16)]
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
                    isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
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

  // ─── Helpers ───────────────────────────────────────────────────────────────

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
}

// ─── Custom Painters ─────────────────────────────────────────────────────────

/// Paints tiny white dots as stars
class _StarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42); // fixed seed for consistency
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

/// Semicircular arc with gradient, moon & sun icons at ends
class _SleepArcPainter extends CustomPainter {
  final int score;
  final double progress;

  _SleepArcPainter({required this.score, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.65);
    final radius = size.width * 0.38;

    // Background arc track
    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi, // start at left
      pi, // sweep half circle
      false,
      trackPaint,
    );

    // Gradient arc (progress)
    final sweepAngle = pi * (score / 100.0) * progress;
    final gradientPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: pi,
        endAngle: 2 * pi,
        colors: const [
          Color(0xFF7E57C2), // purple
          Color(0xFF4DD0E1), // cyan
          Color(0xFFFFD54F), // gold
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      sweepAngle,
      false,
      gradientPaint,
    );

    // Small dots along the arc for flair
    final dotPaint = Paint()..color = Colors.white.withOpacity(0.3);
    for (int i = 0; i <= 10; i++) {
      final angle = pi + (pi * i / 10);
      final dx = center.dx + radius * cos(angle);
      final dy = center.dy + radius * sin(angle);
      canvas.drawCircle(Offset(dx, dy), 1.5, dotPaint);
    }

    // Moon icon (left)
    final moonPos = Offset(center.dx - radius - 6, center.dy + 18);
    _drawMoonIcon(canvas, moonPos);

    // Sun icon (right)
    final sunPos = Offset(center.dx + radius + 6, center.dy + 18);
    _drawSunIcon(canvas, sunPos);
  }

  void _drawMoonIcon(Canvas canvas, Offset pos) {
    final paint = Paint()..color = const Color(0xFFB0BEC5);
    canvas.drawCircle(pos, 8, paint);
    final cutPaint = Paint()..color = const Color(0xFF0D1B2A);
    canvas.drawCircle(Offset(pos.dx + 4, pos.dy - 3), 7, cutPaint);
  }

  void _drawSunIcon(Canvas canvas, Offset pos) {
    final paint = Paint()..color = const Color(0xFFFFD54F);
    canvas.drawCircle(pos, 7, paint);
    // Small rays
    for (int i = 0; i < 8; i++) {
      final angle = (pi * 2 * i / 8);
      final start = Offset(pos.dx + 10 * cos(angle), pos.dy + 10 * sin(angle));
      final end = Offset(pos.dx + 13 * cos(angle), pos.dy + 13 * sin(angle));
      canvas.drawLine(start, end, Paint()..color = const Color(0xFFFFD54F)..strokeWidth = 1.5..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(covariant _SleepArcPainter old) =>
      old.score != score || old.progress != progress;
}

/// Stepped sleep stages timeline chart
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
      0: const Color(0xFFFFA726), // Awake
      1: const Color(0xFF4DD0E1), // REM
      2: const Color(0xFF5C6BC0), // Light
      3: const Color(0xFF7E57C2), // Deep
    };

    // Reserve space at bottom for hourly labels
    final chartBottom = size.height - 28;

    // Y positions for each level (0=top → 3=bottom)
    final levelY = {
      0: chartBottom * 0.05,
      1: chartBottom * 0.30,
      2: chartBottom * 0.58,
      3: chartBottom * 0.85,
    };

    // Draw horizontal guide lines
    final guidePaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1;
    for (var entry in levelY.entries) {
      canvas.drawLine(Offset(0, entry.value), Offset(size.width, entry.value), guidePaint);
    }

    // Draw stage labels on the left
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

    // Chart drawing area
    final chartLeft = 42.0;
    final chartWidth = size.width - chartLeft;

    // Draw blocks + connecting steps
    for (int i = 0; i < blocks.length; i++) {
      final b = blocks[i];
      final x1 = chartLeft + b.startFraction * chartWidth;
      final x2 = chartLeft + b.endFraction * chartWidth;
      final y = levelY[b.level]!;
      final color = stageColors[b.level]!;

      // Block bar
      final barPaint = Paint()..color = color;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(x1, y - 4, x2, y + 4),
          const Radius.circular(2),
        ),
        barPaint,
      );

      // Vertical connector to next block
      if (i < blocks.length - 1) {
        final nextY = levelY[blocks[i + 1].level]!;
        final connPaint = Paint()
          ..color = Colors.white.withOpacity(0.15)
          ..strokeWidth = 1;
        canvas.drawLine(Offset(x2, y), Offset(x2, nextY), connPaint);
      }
    }

    // ─── Hourly time labels at the bottom ───
    // Calculate total hours spanned
    int bedHour = bedtime.hour;
    int wakeHour = wakeTime.hour;
    // Handle overnight (e.g. 23 → 7)
    int totalHours = wakeHour - bedHour;
    if (totalHours <= 0) totalHours += 24;

    final tickPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;

    for (int h = 0; h <= totalHours; h++) {
      final fraction = h / totalHours;
      final x = chartLeft + fraction * chartWidth;
      final hour = (bedHour + h) % 24;
      final label = hour.toString().padLeft(2, '0');

      // Tick mark
      canvas.drawLine(
        Offset(x, chartBottom),
        Offset(x, chartBottom + 5),
        tickPaint,
      );

      // Hour label
      final tp = TextPainter(
        text: TextSpan(
          text: label,
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