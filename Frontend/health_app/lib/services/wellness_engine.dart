import 'health_database_service.dart';

// ─── Data Models ───
class WellnessMetrics {
  final double sleepQuality; // 0.0–1.0
  final double moodScore; // 0.0–1.0
  final double stressLevel; // 0.0–1.0 (higher = more stressed)
  final double heartRateStability; // 0.0–1.0
  final double activityLevel; // 0.0–1.0
  final bool hasGHQToday; // ⚡ NEW: Track daily GHQ survey
  final bool hasMDQToday; // ⚡ NEW: Track daily MDQ survey

  const WellnessMetrics({
    required this.sleepQuality,
    required this.moodScore,
    required this.stressLevel,
    required this.heartRateStability,
    required this.activityLevel,
    required this.hasGHQToday,
    required this.hasMDQToday,
  });
}

class HealthAlert {
  final String title;
  final String message;
  final AlertSeverity severity;
  final String icon;

  const HealthAlert({
    required this.title,
    required this.message,
    required this.severity,
    this.icon = '⚠️',
  });
}

enum AlertSeverity { low, medium, high }

class WellnessRecommendation {
  final String title;
  final String description;
  final String category; // 'sleep', 'activity', 'mental', 'nutrition'
  final String iconName;

  const WellnessRecommendation({
    required this.title,
    required this.description,
    required this.category,
    required this.iconName,
  });
}

class WeeklyImprovement {
  final String metric;
  final double percentage; // positive = improved, negative = declined
  final String unit;

  const WeeklyImprovement({
    required this.metric,
    required this.percentage,
    required this.unit,
  });
}

class SmartGoal {
  final String title;
  final String description;
  final double progress; // 0.0–1.0
  final String category;
  bool accepted;

  SmartGoal({
    required this.title,
    required this.description,
    required this.progress,
    required this.category,
    this.accepted = false,
  });
}

class TimelineEntry {
  final String time;
  final String title;
  final String subtitle;
  final String iconName;
  final String color; // hex color string

  const TimelineEntry({
    required this.time,
    required this.title,
    required this.subtitle,
    required this.iconName,
    required this.color,
  });
}

class InsightItem {
  final String title;
  final String description;
  final String pattern;
  final double confidence; // 0.0–1.0

  const InsightItem({
    required this.title,
    required this.description,
    required this.pattern,
    required this.confidence,
  });
}

// ─── Wellness Engine ────────────────────────────────────────────────────────

class WellnessEngine {
  // Weight constants for score calculation
  static const _sleepWeight = 0.30;
  static const _moodWeight = 0.25;
  static const _stressWeight = 0.20;
  static const _heartWeight = 0.15;
  static const _activityWeight = 0.10;

  // Static Fallbacks
  static const currentMetrics = WellnessMetrics(
    sleepQuality: 0.82,
    moodScore: 0.75,
    stressLevel: 0.30,
    heartRateStability: 0.85,
    activityLevel: 0.60,
    hasGHQToday: false,
    hasMDQToday: false,
  );

  static const previousMetrics = WellnessMetrics(
    sleepQuality: 0.70,
    moodScore: 0.65,
    stressLevel: 0.45,
    heartRateStability: 0.80,
    activityLevel: 0.50,
    hasGHQToday: true,
    hasMDQToday: true,
  );

  // ==========================================
  // 🚀 DYNAMIC DATA FETCHING
  // ==========================================
  static Future<WellnessMetrics> getDynamicMetrics() async {
    final db = HealthDatabaseService.instance;
    final now = DateTime.now();
    final todayStr = now.toIso8601String().substring(0, 10);

    // 1. Fetch Today's Steps
    final stepLogs = await db.getRecords('step_logs');
    int totalSteps = 0;
    for (var log in stepLogs) {
      if (log['timestamp'].toString().startsWith(todayStr)) {
        totalSteps += (log['steps'] as int);
      }
    }
    double activityLevel = (totalSteps / 8000.0).clamp(0.0, 1.0);

    // 2. Fetch Mental Health Logs (Expanded limit to scan today's tests)
    final moodLogs = await db.getRecords(
      'mental_health_logs',
      orderBy: 'id DESC',
      limit: 20,
    );

    double moodScore = 0.75; // Default Baseline
    double stressLevel = 0.30; // Default Baseline
    bool hasGHQ = false;
    bool hasMDQ = false;

    if (moodLogs.isNotEmpty) {
      // Use the most recent log for general mood/stress levels
      final latest = moodLogs.first;
      int rawMood = latest['mood_score'] as int;
      moodScore = 1.0 - (rawMood / 4.0);

      int rawStress = latest['stress_level'] as int;
      stressLevel = (rawStress / 100.0).clamp(0.0, 1.0);

      // ⚡ Check if GHQ/MDQ tests were taken today by looking at the journal entries
      for (var log in moodLogs) {
        if (log['timestamp'].toString().startsWith(todayStr)) {
          final entry = (log['journal_entry'] ?? '') as String;
          if (entry.contains('GHQ')) hasGHQ = true;
          if (entry.contains('MDQ')) hasMDQ = true;
        }
      }
    }

    return WellnessMetrics(
      sleepQuality: 0.82,
      moodScore: moodScore,
      stressLevel: stressLevel,
      heartRateStability: 0.85,
      activityLevel: activityLevel > 0 ? activityLevel : 0.4,
      hasGHQToday: hasGHQ,
      hasMDQToday: hasMDQ,
    );
  }

  // ── Wellness Score ──
  static int calculateWellnessScore(WellnessMetrics m) {
    final raw =
        (m.sleepQuality * _sleepWeight) +
        (m.moodScore * _moodWeight) +
        ((1 - m.stressLevel) * _stressWeight) +
        (m.heartRateStability * _heartWeight) +
        (m.activityLevel * _activityWeight);

    return (raw * 100).round().clamp(0, 100);
  }

  static String getScoreTrend() {
    final current = calculateWellnessScore(currentMetrics);
    final previous = calculateWellnessScore(previousMetrics);
    if (current > previous + 3) return 'Improving';
    if (current < previous - 3) return 'Needs Attention';
    return 'Stable';
  }

  // ── Recovery Score ──
  static int calculateRecoveryScore(WellnessMetrics m) {
    final raw =
        (m.sleepQuality * 0.45) +
        ((1 - m.stressLevel) * 0.30) +
        (m.heartRateStability * 0.25);

    return (raw * 100).round().clamp(0, 100);
  }

  static String getRecoveryStatus(int score) {
    if (score >= 75) return 'Ready for Activity';
    if (score >= 50) return 'Moderate Recovery';
    return 'Rest Recommended';
  }

  // ── Health Risk Detection ──
  static List<HealthAlert> detectHealthRisks(WellnessMetrics m) {
    final alerts = <HealthAlert>[];

    if (m.sleepQuality < 0.5) {
      alerts.add(
        const HealthAlert(
          title: 'Poor Sleep Pattern',
          message:
              'Your sleep quality dropped significantly. Consider adjusting your bedtime routine.',
          severity: AlertSeverity.high,
          icon: '😴',
        ),
      );
    }
    if (m.stressLevel > 0.7) {
      alerts.add(
        const HealthAlert(
          title: 'High Stress Levels',
          message:
              'Your stress has been elevated. Try breathing exercises or a short walk.',
          severity: AlertSeverity.high,
          icon: '😰',
        ),
      );
    }
    if (m.heartRateStability < 0.6) {
      alerts.add(
        const HealthAlert(
          title: 'Elevated Heart Rate',
          message:
              'Your resting heart rate has increased for 3 days. You may need rest.',
          severity: AlertSeverity.medium,
          icon: '❤️',
        ),
      );
    }
    if (m.activityLevel < 0.3) {
      alerts.add(
        const HealthAlert(
          title: 'Low Activity',
          message:
              'You haven\'t been very active lately. Even a 10-minute walk helps.',
          severity: AlertSeverity.medium,
          icon: '🚶',
        ),
      );
    }
    if (m.moodScore < 0.4) {
      alerts.add(
        const HealthAlert(
          title: 'Mood Decline',
          message:
              'Your mood has been lower than usual. Consider talking to someone or journaling.',
          severity: AlertSeverity.medium,
          icon: '😔',
        ),
      );
    }
    return alerts;
  }

  // ── Recommendations ──
  static List<WellnessRecommendation> generateRecommendations(
    WellnessMetrics m,
  ) {
    final recs = <WellnessRecommendation>[];

    if (m.activityLevel < 0.5) {
      recs.add(
        const WellnessRecommendation(
          title: 'Take a short walk',
          description:
              'A 15-minute walk can boost your mood and activity level.',
          category: 'activity',
          iconName: 'directions_walk',
        ),
      );
    }
    if (m.stressLevel > 0.4) {
      recs.add(
        const WellnessRecommendation(
          title: 'Try breathing exercises',
          description:
              'A 2-minute guided breathing session can reduce stress by 20%.',
          category: 'mental',
          iconName: 'air',
        ),
      );
    }
    if (m.sleepQuality < 0.8) {
      recs.add(
        const WellnessRecommendation(
          title: 'Sleep earlier tonight',
          description:
              'Going to bed 30 minutes earlier can improve recovery by 15%.',
          category: 'sleep',
          iconName: 'bedtime',
        ),
      );
    }
    if (m.moodScore < 0.7) {
      recs.add(
        const WellnessRecommendation(
          title: 'Practice gratitude',
          description:
              'Write down 3 things you\'re grateful for. It shifts perspective.',
          category: 'mental',
          iconName: 'favorite',
        ),
      );
    }
    recs.add(
      const WellnessRecommendation(
        title: 'Stay hydrated',
        description:
            'Drink at least 8 glasses of water to maintain energy levels.',
        category: 'nutrition',
        iconName: 'water_drop',
      ),
    );
    return recs;
  }

  // ── Weekly Improvements ──
  static List<WeeklyImprovement> getWeeklyImprovements() {
    return const [
      WeeklyImprovement(metric: 'Sleep Quality', percentage: 12.0, unit: '%'),
      WeeklyImprovement(metric: 'Stress Level', percentage: -8.0, unit: '%'),
      WeeklyImprovement(metric: 'Activity', percentage: 15.0, unit: '%'),
      WeeklyImprovement(metric: 'Heart Rate', percentage: -2.0, unit: 'bpm'),
      WeeklyImprovement(metric: 'Mood Score', percentage: 10.0, unit: '%'),
    ];
  }

  // ── Smart Goals ──
  static List<SmartGoal> generateGoals(WellnessMetrics m) {
    return [
      SmartGoal(
        title: 'Increase sleep by 30 minutes',
        description: 'Your recovery improves significantly with more sleep.',
        progress: 0.6,
        category: 'sleep',
        accepted: true,
      ),
      SmartGoal(
        title: 'Walk 6,000 steps daily',
        description:
            'You\'re averaging 4,300 steps. A small increase goes a long way.',
        progress: 0.72,
        category: 'activity',
        accepted: true,
      ),
      SmartGoal(
        title: 'Practice breathing exercises',
        description:
            'Complete a 2-minute breathing exercise 5 times this week.',
        progress: 0.4,
        category: 'mental',
        accepted: true,
      ),
      SmartGoal(
        title: 'Reduce screen time before bed',
        description:
            'Avoid screens 30 minutes before sleep for better rest quality.',
        progress: 0.3,
        category: 'sleep',
      ),
      SmartGoal(
        title: 'Meditate for 5 minutes daily',
        description: 'Even 5 minutes of meditation reduces stress hormones.',
        progress: 0.0,
        category: 'mental',
      ),
    ];
  }

  // ── Timeline ──
  static List<TimelineEntry> getTodayTimeline() {
    return const [
      TimelineEntry(
        time: '7:15 AM',
        title: 'Woke Up',
        subtitle: 'Sleep: 7h 12m • Score: 82',
        iconName: 'wb_sunny',
        color: '#FFD54F',
      ),
      TimelineEntry(
        time: '7:30 AM',
        title: 'Mood Logged',
        subtitle: 'Feeling: Calm 🙂',
        iconName: 'mood',
        color: '#4DD0E1',
      ),
      TimelineEntry(
        time: '8:00 AM',
        title: 'Heart Rate Check',
        subtitle: '72 bpm • Resting',
        iconName: 'favorite',
        color: '#EF5350',
      ),
      TimelineEntry(
        time: '9:30 AM',
        title: 'Breathing Exercise',
        subtitle: 'Completed 2-min guided breathing',
        iconName: 'air',
        color: '#7E57C2',
      ),
      TimelineEntry(
        time: '12:15 PM',
        title: 'Activity Update',
        subtitle: '2,100 steps • 90 cal burned',
        iconName: 'directions_walk',
        color: '#66BB6A',
      ),
      TimelineEntry(
        time: '2:00 PM',
        title: 'Hydration Reminder',
        subtitle: 'Drank 4th glass of water',
        iconName: 'water_drop',
        color: '#42A5F5',
      ),
      TimelineEntry(
        time: '4:30 PM',
        title: 'Stress Check',
        subtitle: 'Level: Low ✓',
        iconName: 'speed',
        color: '#66BB6A',
      ),
    ];
  }

  // ── Insights ──
  static List<InsightItem> getInsights() {
    return const [
      InsightItem(
        title: 'Sleep & Exercise Connection',
        description:
            'Your sleep quality improves by 18% on days you exercise before 6 PM.',
        pattern: 'exercise → better sleep',
        confidence: 0.87,
      ),
      InsightItem(
        title: 'Breathing & Stress',
        description:
            'Stress levels drop 22% within an hour after breathing exercises.',
        pattern: 'breathing → lower stress',
        confidence: 0.92,
      ),
      InsightItem(
        title: 'Mood Patterns',
        description:
            'Your mood is consistently higher on days with 7+ hours of sleep.',
        pattern: 'sleep duration → mood',
        confidence: 0.85,
      ),
      InsightItem(
        title: 'Activity Impact',
        description:
            'Walking 5,000+ steps correlates with a 15% higher wellness score.',
        pattern: 'steps → wellness score',
        confidence: 0.78,
      ),
      InsightItem(
        title: 'Hydration Effect',
        description:
            'Days with adequate water intake show 12% better heart rate stability.',
        pattern: 'hydration → heart rate',
        confidence: 0.74,
      ),
    ];
  }

  // ── Smart Notifications ──
  static List<String> getSmartNotifications(WellnessMetrics m) {
    final notifications = <String>[];

    // ⚡ NEW: Prompt user to take tests if they haven't yet
    if (!m.hasGHQToday) {
      notifications.add('📋 Take your daily GHQ survey on your watch');
    }
    if (!m.hasMDQToday) {
      notifications.add('🧠 Quick MDQ mental check-in pending');
    }

    if (m.stressLevel > 0.4) {
      notifications.add('🧘 Time for your breathing exercise');
    }
    if (m.moodScore < 0.7) {
      notifications.add('📝 You haven\'t logged your mood today');
    }
    if (m.sleepQuality < 0.75) {
      notifications.add('🌙 Try going to bed earlier tonight');
    }
    if (m.activityLevel < 0.5) {
      notifications.add('🚶 A short walk could boost your energy');
    }

    return notifications;
  }
}
