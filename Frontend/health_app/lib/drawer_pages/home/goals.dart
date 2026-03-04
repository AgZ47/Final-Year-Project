import 'package:flutter/material.dart';
import '../../services/wellness_engine.dart';
import '../../widgets/wellness_widgets.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  static const _accent = Color(0xFF4DD0E1);
  static const _green = Color(0xFF66BB6A);

  late List<SmartGoal> _goals;

  @override
  void initState() {
    super.initState();
    _goals = WellnessEngine.generateGoals(WellnessEngine.currentMetrics);
  }

  int get _acceptedCount => _goals.where((g) => g.accepted).length;
  double get _avgProgress {
    final accepted = _goals.where((g) => g.accepted).toList();
    if (accepted.isEmpty) return 0;
    return accepted.map((g) => g.progress).reduce((a, b) => a + b) /
        accepted.length;
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
                'Smart Goals',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'AI-suggested goals for you',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 24),

              // ── Overall Progress ──
              _buildOverallProgress(),
              const SizedBox(height: 24),

              // ── Active Goals ──
              _sectionTitle('Active Goals'),
              const SizedBox(height: 12),
              ..._goals
                  .where((g) => g.accepted)
                  .map((g) => GoalProgressCard(goal: g)),

              // ── Suggested Goals ──
              if (_goals.any((g) => !g.accepted)) ...[
                const SizedBox(height: 24),
                _sectionTitle('Suggested for You'),
                const SizedBox(height: 12),
                ..._goals.where((g) => !g.accepted).map((g) {
                  return GoalProgressCard(
                    goal: g,
                    onAccept: () => setState(() => g.accepted = true),
                    onSkip: () => setState(() => _goals.remove(g)),
                  );
                }),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverallProgress() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_green.withOpacity(0.1), _accent.withOpacity(0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _green.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('$_acceptedCount', 'Active'),
              _statItem('${(_avgProgress * 100).round()}%', 'Avg Progress'),
              _statItem('${_goals.length}', 'Total'),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _avgProgress,
              backgroundColor: Colors.white.withOpacity(0.06),
              valueColor: AlwaysStoppedAnimation(_green),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
        ),
      ],
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
