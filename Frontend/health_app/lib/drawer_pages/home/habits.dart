import 'package:flutter/material.dart';
import '../../widgets/wellness_widgets.dart';

class HabitsPage extends StatefulWidget {
  const HabitsPage({super.key});

  @override
  State<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage>
    with SingleTickerProviderStateMixin {
  static const _bgCard = Color(0xFF152238);
  static const _accent = Color(0xFF4DD0E1);
  static const _green = Color(0xFF66BB6A);
  static const _orange = Color(0xFFFFB74D);

  late AnimationController _ringController;
  late Animation<double> _ringAnim;

  // ── Habit state ──
  final List<Map<String, dynamic>> _habits = [
    {
      'title': 'Drink 8 glasses of water',
      'emoji': '💧',
      'done': true,
      'streak': 7,
    },
    {
      'title': 'Complete breathing exercise',
      'emoji': '🧘',
      'done': true,
      'streak': 5,
    },
    {'title': 'Walk 5,000 steps', 'emoji': '🚶', 'done': false, 'streak': 3},
    {'title': 'Sleep 7+ hours', 'emoji': '😴', 'done': true, 'streak': 4},
    {'title': 'Meditate 5 minutes', 'emoji': '🧠', 'done': false, 'streak': 2},
    {'title': 'Eat a healthy meal', 'emoji': '🥗', 'done': false, 'streak': 0},
    {
      'title': 'Stretch for 10 minutes',
      'emoji': '🤸',
      'done': false,
      'streak': 1,
    },
  ];

  int get _completedCount => _habits.where((h) => h['done'] as bool).length;
  double get _completionPct =>
      _habits.isEmpty ? 0 : _completedCount / _habits.length;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _ringAnim = CurvedAnimation(
      parent: _ringController,
      curve: Curves.easeOutCubic,
    );
    _ringController.forward();
  }

  @override
  void dispose() {
    _ringController.dispose();
    super.dispose();
  }

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
              const Text(
                'Daily Habits',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Build healthy routines',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 24),

              // ── Completion Ring ──
              _buildCompletionCard(),
              const SizedBox(height: 24),

              // ── Streak Highlights ──
              _buildStreakHighlights(),
              const SizedBox(height: 24),

              // ── Habit List ──
              _sectionTitle('Today\'s Goals'),
              const SizedBox(height: 12),
              ...List.generate(_habits.length, (i) {
                final h = _habits[i];
                return HabitTrackerCard(
                  title: h['title'] as String,
                  emoji: h['emoji'] as String,
                  completed: h['done'] as bool,
                  streak: h['streak'] as int,
                  onToggle: (v) {
                    setState(() {
                      _habits[i]['done'] = v;
                      _ringController.reset();
                      _ringController.forward();
                    });
                  },
                );
              }),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_accent.withOpacity(0.1), _green.withOpacity(0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _accent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _ringAnim,
            builder: (_, __) {
              return SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: _completionPct * _ringAnim.value,
                      strokeWidth: 8,
                      backgroundColor: Colors.white.withOpacity(0.06),
                      valueColor: AlwaysStoppedAnimation(
                        _completionPct >= 1.0 ? _green : _accent,
                      ),
                      strokeCap: StrokeCap.round,
                    ),
                    Center(
                      child: Text(
                        '${(_completionPct * 100 * _ringAnim.value).round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Progress',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_completedCount of ${_habits.length} completed',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                if (_completionPct >= 1.0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '🎉 All done!',
                      style: TextStyle(
                        color: _green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakHighlights() {
    final topStreaks = _habits.where((h) => (h['streak'] as int) > 0).toList()
      ..sort((a, b) => (b['streak'] as int).compareTo(a['streak'] as int));
    if (topStreaks.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: topStreaks.length > 4 ? 4 : topStreaks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final h = topStreaks[i];
          return Container(
            width: 110,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _orange.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  h['emoji'] as String,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 3),
                    Text(
                      '${h['streak']} days',
                      style: const TextStyle(
                        color: _orange,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(
    t,
    style: const TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  );
}
