import 'package:flutter/material.dart';
import '../../services/wellness_engine.dart';
import '../../widgets/wellness_widgets.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  // ── Colors ──
  static const _bgCard = Color(0xFF152238);
  static const _accent = Color(0xFF4DD0E1);
  static const _purple = Color(0xFF7E57C2);
  static const _indigo = Color(0xFF5C6BC0);
  static const _green = Color(0xFF66BB6A);

  @override
  Widget build(BuildContext context) {
    final improvements = WellnessEngine.getWeeklyImprovements();
    final score = WellnessEngine.calculateWellnessScore(
      WellnessEngine.currentMetrics,
    );
    final trend = WellnessEngine.getScoreTrend();

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
                'Weekly Report',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your wellness summary this week',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 24),

              // ── Wellness Score ──
              WellnessScoreCard(score: score, trend: trend),
              const SizedBox(height: 20),

              // ── Weekly Improvements ──
              _sectionTitle('Weekly Improvements'),
              const SizedBox(height: 12),
              _buildImprovementChips(improvements),
              const SizedBox(height: 24),

              // ── Charts ──
              ReportChartCard(
                title: 'Mood Trend',
                improvement: '10%',
                isPositive: true,
                data: const [0.6, 0.8, 0.5, 0.9, 0.7, 0.85, 0.65],
                color: _purple,
              ),
              ReportChartCard(
                title: 'Sleep Duration',
                improvement: '12%',
                isPositive: true,
                data: const [0.7, 0.85, 0.6, 0.9, 0.55, 0.8, 0.75],
                color: _indigo,
              ),
              ReportChartCard(
                title: 'Heart Rate Avg',
                improvement: '2 bpm',
                isPositive: true,
                data: const [0.72, 0.68, 0.75, 0.7, 0.65, 0.73, 0.71],
                color: Colors.redAccent,
              ),
              ReportChartCard(
                title: 'Activity Level',
                improvement: '15%',
                isPositive: true,
                data: const [0.4, 0.5, 0.3, 0.6, 0.45, 0.7, 0.55],
                color: _green,
              ),

              // ── AI Health Summary ──
              const SizedBox(height: 8),
              _buildAIHealthSummary(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Improvement Chips ─────────────────────────────────────────────────

  Widget _buildImprovementChips(List<WeeklyImprovement> items) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isStress = item.metric.toLowerCase().contains('stress');
        final isHR = item.metric.toLowerCase().contains('heart');
        final isPositive = (isStress || isHR)
            ? item.percentage < 0
            : item.percentage > 0;
        final color = isPositive ? _green : const Color(0xFFEF5350);
        final arrow = item.percentage > 0 ? '↑' : '↓';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPositive
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: color,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                '${item.metric} $arrow ${item.percentage.abs()}${item.unit}',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── AI Health Summary ─────────────────────────────────────────────────

  Widget _buildAIHealthSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accent.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome, color: _accent, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'AI Weekly Summary',
                style: TextStyle(
                  color: _accent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _insightBullet(
            'Your overall wellness improved compared to last week.',
          ),
          const SizedBox(height: 8),
          _insightBullet('Sleep consistency increased by 12%.'),
          const SizedBox(height: 8),
          _insightBullet(
            'Stress reduced by 8% — keep up the breathing exercises.',
          ),
          const SizedBox(height: 8),
          _insightBullet('Heart rate variability remains stable.'),
          const SizedBox(height: 8),
          _insightBullet('Consider adding 10 more minutes of daily activity.'),
        ],
      ),
    );
  }

  Widget _insightBullet(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: _accent.withOpacity(0.6),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
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
