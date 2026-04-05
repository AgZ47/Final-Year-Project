import 'package:flutter/material.dart';
import '../../services/wellness_engine.dart';
import '../../services/health_database_service.dart';
import '../../widgets/wellness_widgets.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  static const _accent = Color(0xFF4DD0E1);
  static const _green = Color(0xFF66BB6A);

  List<Map<String, dynamic>> _goals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final dbGoals = await HealthDatabaseService.instance.getGoals();

    // If empty, generate AI goals and save to DB
    if (dbGoals.isEmpty) {
      final initialGoals = WellnessEngine.generateGoals(
        WellnessEngine.currentMetrics,
      );
      for (var goal in initialGoals) {
        await HealthDatabaseService.instance.insertRecord('goals', {
          'title': goal.title,
          'description': goal.description,
          'progress': goal.progress,
          'category': goal.category,
          'is_accepted': goal.accepted ? 1 : 0,
        });
      }
      // Re-fetch to get IDs
      final newGoals = await HealthDatabaseService.instance.getGoals();
      setState(() {
        _goals = newGoals.map((e) => Map<String, dynamic>.from(e)).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _goals = dbGoals.map((e) => Map<String, dynamic>.from(e)).toList();
        _isLoading = false;
      });
    }
  }

  int get _acceptedCount => _goals.where((g) => g['is_accepted'] == 1).length;

  double get _avgProgress {
    final accepted = _goals.where((g) => g['is_accepted'] == 1).toList();
    if (accepted.isEmpty) return 0;
    return accepted
            .map((g) => (g['progress'] as num).toDouble())
            .reduce((a, b) => a + b) /
        accepted.length;
  }

  Future<void> _acceptGoal(int index) async {
    final id = _goals[index]['id'] as int;
    await HealthDatabaseService.instance.acceptGoal(id);
    setState(() {
      _goals[index]['is_accepted'] = 1;
    });
  }

  Future<void> _skipGoal(int index) async {
    final id = _goals[index]['id'] as int;
    await HealthDatabaseService.instance.deleteRecord('goals', id);
    setState(() {
      _goals.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _accent));
    }

    final acceptedGoals = _goals.asMap().entries.where(
      (e) => e.value['is_accepted'] == 1,
    );
    final suggestedGoals = _goals.asMap().entries.where(
      (e) => e.value['is_accepted'] == 0,
    );

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

              _buildOverallProgress(),
              const SizedBox(height: 24),

              _sectionTitle('Active Goals'),
              const SizedBox(height: 12),
              ...acceptedGoals.map(
                (entry) => GoalProgressCard(
                  goal: SmartGoal(
                    title: entry.value['title'],
                    description: entry.value['description'],
                    progress: (entry.value['progress'] as num).toDouble(),
                    category: entry.value['category'],
                    accepted: true,
                  ),
                ),
              ),

              if (suggestedGoals.isNotEmpty) ...[
                const SizedBox(height: 24),
                _sectionTitle('Suggested for You'),
                const SizedBox(height: 12),
                ...suggestedGoals.map(
                  (entry) => GoalProgressCard(
                    goal: SmartGoal(
                      title: entry.value['title'],
                      description: entry.value['description'],
                      progress: (entry.value['progress'] as num).toDouble(),
                      category: entry.value['category'],
                      accepted: false,
                    ),
                    onAccept: () => _acceptGoal(entry.key),
                    onSkip: () => _skipGoal(entry.key),
                  ),
                ),
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
