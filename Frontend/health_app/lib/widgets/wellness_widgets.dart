import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/wellness_engine.dart';
import '../core/theme/app_theme.dart'; // ⚡ NEW: Centralized theme

// ═══════════════════════════════════════════════════════════════════════════
// 1. WellnessScoreCard
// ═══════════════════════════════════════════════════════════════════════════

class WellnessScoreCard extends StatelessWidget {
  final int score;
  final String trend;
  final double animationValue;

  const WellnessScoreCard({
    super.key,
    required this.score,
    required this.trend,
    this.animationValue = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accent.withOpacity(0.12),
            AppTheme.purple.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.accent.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            'Overall Wellness Score',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            width: 130,
            child: CustomPaint(
              painter: _GradientRingPainter(
                progress: (score / 100.0) * animationValue,
                score: (score * animationValue).round(),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _trendBadge(trend),
        ],
      ),
    );
  }

  Widget _trendBadge(String trend) {
    final isGood = trend == 'Improving';
    final color = isGood
        ? AppTheme.green
        : (trend == 'Stable' ? AppTheme.accent : AppTheme.orange);
    final icon = isGood
        ? Icons.trending_up_rounded
        : (trend == 'Stable'
              ? Icons.trending_flat_rounded
              : Icons.trending_down_rounded);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            trend,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientRingPainter extends CustomPainter {
  final double progress;
  final int score;

  _GradientRingPainter({required this.progress, required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withOpacity(0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 11,
    );

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 11
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: 3 * math.pi / 2,
          colors: const [
            AppTheme.accent,
            AppTheme.green,
            AppTheme.gold,
            AppTheme.purple,
            AppTheme.accent,
          ],
        ).createShader(rect),
    );

    final tp = TextPainter(
      text: TextSpan(
        text: '$score',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 36,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2 - 4),
    );

    final sub = TextPainter(
      text: TextSpan(
        text: '/ 100',
        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    sub.paint(
      canvas,
      Offset(center.dx - sub.width / 2, center.dy + tp.height / 2 - 6),
    );
  }

  @override
  bool shouldRepaint(covariant _GradientRingPainter old) =>
      old.progress != progress || old.score != score;
}

// ═══════════════════════════════════════════════════════════════════════════
// 2. HealthAlertCard
// ═══════════════════════════════════════════════════════════════════════════

class HealthAlertCard extends StatelessWidget {
  final HealthAlert alert;

  const HealthAlertCard({super.key, required this.alert});

  Color get _severityColor {
    switch (alert.severity) {
      case AlertSeverity.high:
        return AppTheme.red;
      case AlertSeverity.medium:
        return AppTheme.orange;
      case AlertSeverity.low:
        return AppTheme.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _severityColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _severityColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(alert.icon, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: TextStyle(
                    color: _severityColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert.message,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 3. HabitTrackerCard
// ═══════════════════════════════════════════════════════════════════════════

class HabitTrackerCard extends StatelessWidget {
  final String title;
  final String emoji;
  final bool completed;
  final int streak;
  final ValueChanged<bool> onToggle;

  const HabitTrackerCard({
    super.key,
    required this.title,
    required this.emoji,
    required this.completed,
    required this.streak,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: completed ? AppTheme.accent.withOpacity(0.08) : AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: completed ? AppTheme.accent.withOpacity(0.3) : Colors.white10,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => onToggle(!completed),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: completed ? AppTheme.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: completed ? AppTheme.accent : Colors.white30,
                  width: 2,
                ),
              ),
              child: completed
                  ? const Icon(Icons.check, color: AppTheme.bgDark, size: 18)
                  : null,
            ),
          ),
          const SizedBox(width: 14),
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: completed ? Colors.white54 : Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                decoration: completed ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          if (streak > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 3),
                  Text(
                    '$streak',
                    style: const TextStyle(
                      color: AppTheme.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 4. GoalProgressCard
// ═══════════════════════════════════════════════════════════════════════════

class GoalProgressCard extends StatelessWidget {
  final SmartGoal goal;
  final VoidCallback? onAccept;
  final VoidCallback? onSkip;

  const GoalProgressCard({
    super.key,
    required this.goal,
    this.onAccept,
    this.onSkip,
  });

  Color get _categoryColor {
    switch (goal.category) {
      case 'sleep':
        return AppTheme.indigo;
      case 'activity':
        return AppTheme.green;
      case 'mental':
        return AppTheme.purple;
      default:
        return AppTheme.accent;
    }
  }

  IconData get _categoryIcon {
    switch (goal.category) {
      case 'sleep':
        return Icons.bedtime_rounded;
      case 'activity':
        return Icons.directions_walk_rounded;
      case 'mental':
        return Icons.self_improvement_rounded;
      default:
        return Icons.flag_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _categoryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _categoryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_categoryIcon, color: _categoryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      goal.description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (goal.accepted) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: goal.progress,
                      backgroundColor: _categoryColor.withOpacity(0.12),
                      valueColor: AlwaysStoppedAnimation(_categoryColor),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${(goal.progress * 100).round()}%',
                  style: TextStyle(
                    color: _categoryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onSkip,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white54,
                      side: const BorderSide(color: Colors.white12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Skip'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _categoryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 5. InsightCard
// ═══════════════════════════════════════════════════════════════════════════

class InsightCard extends StatelessWidget {
  final InsightItem insight;

  const InsightCard({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.purple.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.purple.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppTheme.purple,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  insight.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(insight.confidence * 100).round()}%',
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            insight.description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 6. RecoveryScoreCard
// ═══════════════════════════════════════════════════════════════════════════

class RecoveryScoreCard extends StatelessWidget {
  final int score;
  final String status;

  const RecoveryScoreCard({
    super.key,
    required this.score,
    required this.status,
  });

  Color get _scoreColor {
    if (score >= 75) return AppTheme.green;
    if (score >= 50) return AppTheme.orange;
    return AppTheme.red;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _scoreColor.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: score / 100.0,
                  strokeWidth: 6,
                  backgroundColor: _scoreColor.withOpacity(0.12),
                  valueColor: AlwaysStoppedAnimation(_scoreColor),
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: Text(
                    '$score%',
                    style: TextStyle(
                      color: _scoreColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recovery Score',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: TextStyle(
                    color: _scoreColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _scoreColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              score >= 75
                  ? Icons.bolt_rounded
                  : (score >= 50
                        ? Icons.access_time_rounded
                        : Icons.hotel_rounded),
              color: _scoreColor,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 7. ReportChartCard
// ═══════════════════════════════════════════════════════════════════════════

class ReportChartCard extends StatelessWidget {
  final String title;
  final String improvement;
  final bool isPositive;
  final List<double> data;
  final Color color;

  const ReportChartCard({
    super.key,
    required this.title,
    required this.improvement,
    required this.isPositive,
    required this.data,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final todayIdx = DateTime.now().weekday - 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isPositive ? AppTheme.green : AppTheme.red)
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      color: isPositive ? AppTheme.green : AppTheme.red,
                      size: 12,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      improvement,
                      style: TextStyle(
                        color: isPositive ? AppTheme.green : AppTheme.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(data.length > 7 ? 7 : data.length, (i) {
                final isToday = i == todayIdx;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 14,
                      height: 65 * data[i],
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isToday
                              ? [
                                  AppTheme.accent,
                                  AppTheme.accent.withOpacity(0.3),
                                ]
                              : [color, color.withOpacity(0.3)],
                        ),
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 10,
                        color: isToday ? AppTheme.accent : Colors.white38,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
