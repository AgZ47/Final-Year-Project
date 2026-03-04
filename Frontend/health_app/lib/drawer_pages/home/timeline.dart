import 'package:flutter/material.dart';
import '../../services/wellness_engine.dart';

class TimelinePage extends StatelessWidget {
  const TimelinePage({super.key});

  static const _bgCard = Color(0xFF152238);
  static const _accent = Color(0xFF4DD0E1);

  static final _colorMap = {
    '#FFD54F': const Color(0xFFFFD54F),
    '#4DD0E1': const Color(0xFF4DD0E1),
    '#EF5350': const Color(0xFFEF5350),
    '#7E57C2': const Color(0xFF7E57C2),
    '#66BB6A': const Color(0xFF66BB6A),
    '#42A5F5': const Color(0xFF42A5F5),
  };

  static final _iconMap = {
    'wb_sunny': Icons.wb_sunny_rounded,
    'mood': Icons.mood_rounded,
    'favorite': Icons.favorite_rounded,
    'air': Icons.air_rounded,
    'directions_walk': Icons.directions_walk_rounded,
    'water_drop': Icons.water_drop_rounded,
    'speed': Icons.speed_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final entries = WellnessEngine.getTodayTimeline();

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
                'Health Timeline',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your daily health history',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              // Date label
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      color: _accent,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Today',
                      style: TextStyle(
                        color: _accent.withOpacity(0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Timeline entries ──
              ...List.generate(entries.length, (i) {
                final entry = entries[i];
                final color = _colorMap[entry.color] ?? _accent;
                final icon = _iconMap[entry.iconName] ?? Icons.circle;
                final isLast = i == entries.length - 1;
                return _buildTimelineItem(entry, color, icon, isLast);
              }),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    TimelineEntry entry,
    Color color,
    IconData icon,
    bool isLast,
  ) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Timeline column (dot + line) ──
          SizedBox(
            width: 50,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: color.withOpacity(0.4), blurRadius: 8),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
              ],
            ),
          ),

          // ── Content card ──
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          entry.subtitle,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.55),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    entry.time,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
