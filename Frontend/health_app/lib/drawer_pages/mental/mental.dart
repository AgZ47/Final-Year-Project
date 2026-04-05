import 'package:flutter/material.dart';
import '../home/breathing_exercise.dart';
import '../../services/health_database_service.dart';
import '../../core/theme/app_theme.dart'; // ⚡ NEW: Centralized theme

class Mental extends StatefulWidget {
  const Mental({super.key});

  @override
  State<Mental> createState() => _MentalState();
}

class _MentalState extends State<Mental> with SingleTickerProviderStateMixin {
  // ── State ──
  int _selectedMood = -1;
  double _stressLevel = 0.3;
  bool _isSaving = false;

  // ── Dynamic Chart Data ──
  List<double> _weeklyMoodData = List.filled(7, 0.0);

  // ── Mood data ──
  static const _moods = [
    {'emoji': '😄', 'label': 'Happy'},
    {'emoji': '🙂', 'label': 'Calm'},
    {'emoji': '😐', 'label': 'Neutral'},
    {'emoji': '😟', 'label': 'Stressed'},
    {'emoji': '😢', 'label': 'Sad'},
  ];

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    _loadWeeklyMoodData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
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
      tempMood = [0.6, 0.8, 0.5, 0.9, 0.7, 0.85, 0.6];
    }

    if (mounted) {
      setState(() {
        _weeklyMoodData = tempMood;
      });
    }
  }

  String get _stressLabel {
    if (_stressLevel < 0.33) return 'Low';
    if (_stressLevel < 0.66) return 'Medium';
    return 'High';
  }

  Color get _stressColor {
    if (_stressLevel < 0.33) return AppTheme.green;
    if (_stressLevel < 0.66) return AppTheme.orange;
    return AppTheme.red;
  }

  // ==========================================
  // 💾 SAVE LOG TO DATABASE
  // ==========================================
  Future<void> _saveMentalLog() async {
    if (_selectedMood == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a mood first!'),
          backgroundColor: AppTheme.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    int stressInt = (_stressLevel * 100).round();

    await HealthDatabaseService.instance.logMood(_selectedMood, stressInt);

    if (!mounted) return;

    setState(() {
      _isSaving = false;
      _selectedMood = -1; // Reset after saving
      _stressLevel = 0.3;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Mental health log saved successfully!'),
        backgroundColor: _stressColor,
        behavior: SnackBarBehavior.floating,
      ),
    );

    _loadWeeklyMoodData();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.mainBackgroundGradient, // ⚡ Centralized Theme
        ),
        child: SafeArea(
          // ⚡ OPTIMIZATION: Converted to ListView
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // ── Header ──
              const Text(
                'Mental Health',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Track your emotional well-being',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 28),

              // ── Mood Tracker ──
              _buildSectionTitle('How are you feeling?'),
              const SizedBox(height: 14),
              _buildMoodSelector(),
              const SizedBox(height: 28),

              // ── Stress Level ──
              _buildSectionTitle('Stress Level'),
              const SizedBox(height: 14),
              _buildStressSlider(),
              const SizedBox(height: 28),

              // ── Save Button ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveMentalLog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.purple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Save Daily Log',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Guided Breathing ──
              _buildBreathingButton(),
              const SizedBox(height: 28),

              // ── Weekly Mood Chart ──
              _buildSectionTitle('Weekly Mood'),
              const SizedBox(height: 14),
              _buildWeeklyChart(),
              const SizedBox(height: 28),

              // ── AI Mental Insight ──
              _buildAIInsight(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Mood Selector ────────────────────────────────────────────────────────

  Widget _buildMoodSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(_moods.length, (i) {
        final isSelected = _selectedMood == i;
        return GestureDetector(
          onTap: () => setState(() => _selectedMood = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            width: 62,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.accent.withOpacity(0.15)
                  : AppTheme.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppTheme.accent : Colors.white10,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.accent.withOpacity(0.3),
                        blurRadius: 12,
                      ),
                    ]
                  : [],
            ),
            child: Column(
              children: [
                Text(
                  _moods[i]['emoji'] as String,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(height: 6),
                Text(
                  _moods[i]['label'] as String,
                  style: TextStyle(
                    color: isSelected ? AppTheme.accent : Colors.white60,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ─── Stress Slider ────────────────────────────────────────────────────────

  Widget _buildStressSlider() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.speed_rounded, color: _stressColor, size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    'Current Level',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _stressColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _stressLabel,
                  style: TextStyle(
                    color: _stressColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: _stressColor,
              inactiveTrackColor: _stressColor.withOpacity(0.15),
              thumbColor: _stressColor,
              overlayColor: _stressColor.withOpacity(0.1),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: _stressLevel,
              onChanged: (v) => setState(() => _stressLevel = v),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Low',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 12,
                ),
              ),
              Text(
                'Medium',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 12,
                ),
              ),
              Text(
                'High',
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

  // ─── Breathing Button ─────────────────────────────────────────────────────

  Widget _buildBreathingButton() {
    return GestureDetector(
      onTap: () => BreathingExercise.show(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.purple, AppTheme.purple.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.purple.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.air, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Start Guided Breathing',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Calm your mind with a 2-min session',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.play_circle_fill, color: Colors.white, size: 40),
          ],
        ),
      ),
    );
  }

  // ─── Weekly Mood Chart ────────────────────────────────────────────────────

  Widget _buildWeeklyChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (i) {
          final h = _weeklyMoodData[i];
          final isToday = i == DateTime.now().weekday - 1;
          final barColor = isToday ? AppTheme.accent : AppTheme.indigo;

          return Column(
            children: [
              Container(
                width: 14,
                height: 100 * h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [barColor, barColor.withOpacity(0.5)],
                  ),
                  borderRadius: BorderRadius.circular(7),
                  boxShadow: isToday
                      ? [
                          BoxShadow(
                            color: AppTheme.accent.withOpacity(0.4),
                            blurRadius: 8,
                          ),
                        ]
                      : [],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _dayLabels[i],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                  color: isToday ? AppTheme.accent : Colors.white54,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ─── AI Insight ───────────────────────────────────────────────────────────

  Widget _buildAIInsight() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.purple.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.purple.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lightbulb_rounded,
              color: AppTheme.purple,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Mental Insight',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your stress levels decreased by 18% this week. Continue mindfulness exercises for best results.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

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
