import 'package:flutter/material.dart';
import '../home/breathing_exercise.dart';

class Mental extends StatefulWidget {
  const Mental({super.key});

  @override
  State<Mental> createState() => _MentalState();
}

class _MentalState extends State<Mental> with SingleTickerProviderStateMixin {
  // ── State ──
  int _selectedMood = -1;
  double _stressLevel = 0.3;

  // ── Mood data ──
  static const _moods = [
    {'emoji': '😄', 'label': 'Happy'},
    {'emoji': '🙂', 'label': 'Calm'},
    {'emoji': '😐', 'label': 'Neutral'},
    {'emoji': '😟', 'label': 'Stressed'},
    {'emoji': '😢', 'label': 'Sad'},
  ];

  // ── Weekly mood data (0.0–1.0 scale) ──
  static const _weeklyMood = [0.8, 0.6, 0.9, 0.5, 0.7, 0.85, 0.65];
  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  // ── Colors ──
  static const _bgDark = Color(0xFF0D1B2A);
  static const _bgCard = Color(0xFF152238);
  static const _accent = Color(0xFF4DD0E1);
  static const _purple = Color(0xFF7E57C2);
  static const _indigo = Color(0xFF5C6BC0);

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
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  String get _stressLabel {
    if (_stressLevel < 0.33) return 'Low';
    if (_stressLevel < 0.66) return 'Medium';
    return 'High';
  }

  Color get _stressColor {
    if (_stressLevel < 0.33) return const Color(0xFF66BB6A);
    if (_stressLevel < 0.66) return const Color(0xFFFFB74D);
    return const Color(0xFFEF5350);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B1527), _bgDark, Color(0xFF132E4A)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
              color: isSelected ? _accent.withOpacity(0.15) : _bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? _accent : Colors.white10,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: _accent.withOpacity(0.3), blurRadius: 12)]
                  : [],
            ),
            child: Column(
              children: [
                Text(_moods[i]['emoji']!, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 6),
                Text(
                  _moods[i]['label']!,
                  style: TextStyle(
                    color: isSelected ? _accent : Colors.white60,
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
        color: _bgCard,
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
            colors: [_purple, _purple.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _purple.withOpacity(0.3),
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
        color: _bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (i) {
          final h = _weeklyMood[i];
          final isToday = i == DateTime.now().weekday - 1;
          final barColor = isToday ? _accent : _indigo;
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
                            color: _accent.withOpacity(0.4),
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
                  color: isToday ? _accent : Colors.white54,
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
        color: _bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _purple.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _purple.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lightbulb_rounded,
              color: _purple,
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
                  'Your stress levels decreased by 18% this week. '
                  'Continue mindfulness exercises for best results.',
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
