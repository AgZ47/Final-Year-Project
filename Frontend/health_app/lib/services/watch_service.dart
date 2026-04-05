import 'package:flutter/foundation.dart';
import 'package:watch_connectivity/watch_connectivity.dart';
import 'health_database_service.dart';

class WatchService {
  static final WatchService _instance = WatchService._internal();
  factory WatchService() => _instance;
  WatchService._internal();

  final _watch = WatchConnectivity();
  bool _isListening = false;

  final ValueNotifier<int> currentBpm = ValueNotifier<int>(72);
  final ValueNotifier<List<int>> heartRateHistory = ValueNotifier<List<int>>([
    68,
    70,
    72,
    71,
    69,
    73,
    78,
    82,
    85,
    80,
    76,
    74,
    72,
    70,
    71,
    75,
    79,
    77,
    73,
    71,
    70,
    69,
    72,
    72,
  ]);
  final ValueNotifier<String> selectedColor = ValueNotifier<String>("");

  // ⚡ NEW: UI pages will listen to this to know when to refresh SQLite data
  final ValueNotifier<int> syncTrigger = ValueNotifier<int>(0);

  void initialize() {
    if (_isListening) return;
    _isListening = true;
    _watch.messageStream.listen(_processData);
    _watch.contextStream.listen(_processData);
  }

  void _processData(Map<String, dynamic> data) async {
    if (data.containsKey('bpm')) {
      final newBpm = (data['bpm'] as num).toInt();
      currentBpm.value = newBpm;

      final currentData = List<int>.from(heartRateHistory.value);
      currentData.add(newBpm);
      if (currentData.length > 24) currentData.removeAt(0);
      heartRateHistory.value = currentData;
    }

    if (data.containsKey('selected_color')) {
      selectedColor.value = data['selected_color'] as String;
    }

    if (data.containsKey('action')) {
      final action = data['action'];
      final db = HealthDatabaseService.instance;
      final now = DateTime.now().toIso8601String();

      try {
        if (action == 'sync_ghq') {
          final score = data['score'] as int;
          int stress = ((score / 12) * 100).round();
          int mood = (score / 3).floor().clamp(0, 4);

          await db.logMood(
            mood,
            stress,
            'GHQ Score: $score/12',
          ); // ⚡ Pass notes
          syncTrigger.value++; // ⚡ Trigger UI refresh
          debugPrint("📱 PHONE: Saved GHQ Sync (Mood: $mood, Stress: $stress)");
        } else if (action == 'sync_mdq') {
          final score = data['score'] as int;
          int stress = ((score / 5) * 100).round();
          int mood = score.clamp(0, 4);

          await db.logMood(mood, stress, 'MDQ Score: $score/5'); // ⚡ Pass notes
          syncTrigger.value++; // ⚡ Trigger UI refresh
          debugPrint("📱 PHONE: Saved MDQ Sync");
        } else if (action == 'sync_activity') {
          final steps = data['steps'] as int;
          final calories = (data['calories'] as num).toDouble();
          final distance = (data['distance'] as num).toDouble();

          await db.logSteps(steps, distance, calories);
          syncTrigger.value++; // ⚡ Trigger UI refresh
          debugPrint("📱 PHONE: Saved Activity Sync ($steps steps)");
        } else if (action == 'sync_sleep') {
          final score = data['score'] as int;
          final deepSleep = data['deep_sleep'] as int;
          final totalMins = data['total_mins'] as int;

          final wakeTime = DateTime.now();
          final bedTime = wakeTime.subtract(Duration(minutes: totalMins));

          await db.insertRecord('sleep_logs', {
            'bedtime': bedTime.toIso8601String(),
            'wake_time': wakeTime.toIso8601String(),
            'sleep_quality': score,
            'deep_sleep_minutes': deepSleep,
            'timestamp': now,
          });
          syncTrigger.value++; // ⚡ Trigger UI refresh
          debugPrint("📱 PHONE: Saved Sleep Sync ($totalMins mins)");
        }
      } catch (e) {
        debugPrint("📱 PHONE: Failed to save wearable sync data: $e");
      }
    }
  }
}
