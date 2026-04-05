import 'package:flutter/material.dart';
import '../../services/wellness_engine.dart';
import '../../widgets/wellness_widgets.dart';
import '../../core/theme/app_theme.dart'; // ⚡ NEW: Centralized theme

class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final insights = WellnessEngine.getInsights();
    final improvements = WellnessEngine.getWeeklyImprovements();

    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.mainBackgroundGradient, // ⚡ Centralized Theme
      ),
      child: SafeArea(
        // ⚡ OPTIMIZATION: Converted to ListView
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            const Text(
              'Health Insights',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Patterns & correlations in your data',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 24),

            // ── Weekly Changes ──
            _sectionTitle('Weekly Changes'),
            const SizedBox(height: 12),
            _buildWeeklyChanges(improvements),
            const SizedBox(height: 24),

            // ── Pattern Insights ──
            _sectionTitle('Discovered Patterns'),
            const SizedBox(height: 12),
            ...insights.map((i) => InsightCard(insight: i)),

            // ── Summary ──
            const SizedBox(height: 16),
            _buildAISummary(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChanges(List<WeeklyImprovement> items) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((item) {
        // For stress and heart rate, negative is good
        final isStress = item.metric.toLowerCase().contains('stress');
        final isHR = item.metric.toLowerCase().contains('heart');
        final isPositive = (isStress || isHR)
            ? item.percentage < 0
            : item.percentage > 0;

        final color = isPositive ? AppTheme.green : AppTheme.red;
        final arrow = item.percentage > 0 ? '↑' : '↓';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPositive ? Icons.check_circle_rounded : Icons.warning_rounded,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                '${item.metric} $arrow ${item.percentage.abs()}${item.unit}',
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAISummary() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.accent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppTheme.accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'AI Summary',
                style: TextStyle(
                  color: AppTheme.accent,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Based on your data patterns, your wellness is on an upward trend. '
            'Sleep quality has the biggest positive impact on your overall score. '
            'Continuing breathing exercises will help reduce stress further.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
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
