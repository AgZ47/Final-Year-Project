import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:watch_connectivity/watch_connectivity.dart';

void main() {
  runApp(const AuraFitWatchApp());
}

// ⚡ OPTIMIZATION: Centralized Watch Palette
class _WatchColors {
  static const Color bgDark = Colors.black;
  static const Color accent = Color(0xFF4DD0E1);
  static const Color purple = Color(0xFF7E57C2);
  static const Color indigo = Color(0xFF5C6BC0);
  static const Color green = Color(0xFF66BB6A);
  static const Color surface = Color(0xFF152238);
}

class AuraFitWatchApp extends StatefulWidget {
  const AuraFitWatchApp({super.key});

  @override
  State<AuraFitWatchApp> createState() => _AuraFitWatchAppState();
}

class _AuraFitWatchAppState extends State<AuraFitWatchApp> {
  final _watch = WatchConnectivity();
  Timer? _heartRateTimer;

  @override
  void initState() {
    super.initState();
    // Simulate heart rate sensor reading every 2 seconds
    _heartRateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      final mockBpm = 60 + Random().nextInt(40); // 60 - 100 bpm
      _watch.sendMessage({'bpm': mockBpm});
    });
  }

  @override
  void dispose() {
    _heartRateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _WatchColors.bgDark,
      ),
      home: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isSmall = constraints.maxWidth < 180;
            final iconSize = isSmall ? 24.0 : 32.0;
            final titleSize = isSmall ? 14.0 : 16.0;
            final padding = isSmall ? 8.0 : 12.0;

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(padding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.health_and_safety,
                      color: _WatchColors.accent,
                      size: iconSize,
                    ),
                    SizedBox(height: isSmall ? 4 : 8),
                    Text(
                      "Aura Fit Sync",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: titleSize,
                      ),
                    ),
                    SizedBox(height: isSmall ? 12 : 20),

                    _MenuButton(
                      icon: Icons.psychology,
                      label: 'GHQ Survey',
                      color: _WatchColors.purple,
                      targetScreen: const GHQScreen(),
                      isSmall: isSmall,
                    ),
                    SizedBox(height: isSmall ? 6 : 10),

                    _MenuButton(
                      icon: Icons.mood,
                      label: 'MDQ Survey',
                      color: _WatchColors.indigo,
                      targetScreen: const MDQScreen(),
                      isSmall: isSmall,
                    ),
                    SizedBox(height: isSmall ? 6 : 10),

                    _MenuButton(
                      icon: Icons.directions_walk,
                      label: 'Activity',
                      color: _WatchColors.accent,
                      targetScreen: const ActivityWatchScreen(),
                      isSmall: isSmall,
                    ),
                    SizedBox(height: isSmall ? 6 : 10),

                    _MenuButton(
                      icon: Icons.bedtime,
                      label: 'Sleep',
                      color: _WatchColors.purple, // Using purple for sleep
                      targetScreen: const SleepWatchScreen(),
                      isSmall: isSmall,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Widget targetScreen;
  final bool isSmall;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.targetScreen,
    required this.isSmall,
  });

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.2),
          foregroundColor: color,
          minimumSize: Size(double.infinity, isSmall ? 36 : 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: EdgeInsets.symmetric(horizontal: isSmall ? 8 : 16),
          elevation: 0,
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => targetScreen),
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: isSmall ? 16 : 18),
            SizedBox(width: isSmall ? 4 : 8),
            Text(
              label,
              style: TextStyle(
                fontSize: isSmall ? 12 : 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 1. GHQ Questionnaire (General Health)
// ═══════════════════════════════════════════════════════════════════════════
class GHQScreen extends StatefulWidget {
  const GHQScreen({super.key});

  @override
  State<GHQScreen> createState() => _GHQScreenState();
}

class _GHQScreenState extends State<GHQScreen> {
  final _watch = WatchConnectivity();
  int _currentQuestionIndex = 0;
  int _totalScore = 0;

  final List<Map<String, dynamic>> _questions = [
    {
      'q': 'Been able to concentrate?',
      'options': ['Better', 'Same', 'Less', 'Much Less'],
    },
    {
      'q': 'Lost sleep over worry?',
      'options': ['Not at all', 'No more', 'Rather more', 'Much more'],
    },
    {
      'q': 'Felt under strain?',
      'options': ['Not at all', 'No more', 'Rather more', 'Much more'],
    },
    {
      'q': 'Enjoy normal activities?',
      'options': ['More so', 'Same', 'Less', 'Much Less'],
    },
  ];

  void _answerQuestion(int scoreValue) {
    setState(() {
      _totalScore += scoreValue;
      _currentQuestionIndex++;
    });

    if (_currentQuestionIndex >= _questions.length) {
      _watch.sendMessage({'action': 'sync_ghq', 'score': _totalScore});

      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return; // ⚡ OPTIMIZATION: Prevent crash on quick exit
        Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentQuestionIndex >= _questions.length) {
      return const _SuccessScreen(message: 'Score Sent!');
    }

    final currentQ = _questions[_currentQuestionIndex];
    final options = currentQ['options'] as List<String>;
    final isSmall = MediaQuery.of(context).size.width < 180;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'GHQ Q${_currentQuestionIndex + 1}/${_questions.length}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 10,
                ),
              ),
              SizedBox(height: isSmall ? 2 : 4),
              Text(
                currentQ['q'],
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmall ? 12 : 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isSmall ? 8 : 16),
              ...List.generate(options.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _WatchColors.surface,
                      minimumSize: Size(double.infinity, isSmall ? 32 : 44),
                      elevation: 0,
                    ),
                    onPressed: () => _answerQuestion(index),
                    child: Text(
                      options[index],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmall ? 11 : 12,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 2. MDQ Questionnaire (Mood Disorder)
// ═══════════════════════════════════════════════════════════════════════════
class MDQScreen extends StatefulWidget {
  const MDQScreen({super.key});

  @override
  State<MDQScreen> createState() => _MDQScreenState();
}

class _MDQScreenState extends State<MDQScreen> {
  final _watch = WatchConnectivity();
  int _currentQuestionIndex = 0;
  int _totalScore = 0;

  final List<String> _questions = [
    'Felt so good or hyper that others thought you were not your normal self?',
    'Been so irritable that you shouted at people or started fights?',
    'Felt much more self-confident than usual?',
    'Got much less sleep than usual and found you didn’t really miss it?',
    'Been much more talkative or spoke much faster than usual?',
  ];

  void _answerQuestion(bool isYes) {
    setState(() {
      if (isYes) _totalScore += 1;
      _currentQuestionIndex++;
    });

    if (_currentQuestionIndex >= _questions.length) {
      _watch.sendMessage({'action': 'sync_mdq', 'score': _totalScore});

      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return; // ⚡ OPTIMIZATION: Prevent crash on quick exit
        Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentQuestionIndex >= _questions.length) {
      return const _SuccessScreen(message: 'MDQ Sent!');
    }

    final isSmall = MediaQuery.of(context).size.width < 180;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'MDQ Q${_currentQuestionIndex + 1}/${_questions.length}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 10,
                ),
              ),
              SizedBox(height: isSmall ? 4 : 8),
              Text(
                _questions[_currentQuestionIndex],
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmall ? 12 : 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isSmall ? 10 : 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent.withOpacity(0.2),
                        foregroundColor: Colors.redAccent,
                        minimumSize: Size(double.infinity, isSmall ? 36 : 48),
                        elevation: 0,
                      ),
                      onPressed: () => _answerQuestion(false),
                      child: Text(
                        'NO',
                        style: TextStyle(fontSize: isSmall ? 12 : 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _WatchColors.green.withOpacity(0.2),
                        foregroundColor: _WatchColors.green,
                        minimumSize: Size(double.infinity, isSmall ? 36 : 48),
                        elevation: 0,
                      ),
                      onPressed: () => _answerQuestion(true),
                      child: Text(
                        'YES',
                        style: TextStyle(fontSize: isSmall ? 12 : 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 3. Activity Tracker Sync
// ═══════════════════════════════════════════════════════════════════════════
class ActivityWatchScreen extends StatelessWidget {
  const ActivityWatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final watch = WatchConnectivity();
    final isSmall = MediaQuery.of(context).size.width < 180;

    const steps = 6420;
    const calories = 310.5;
    const distance = 4.2;

    return Scaffold(
      appBar: AppBar(
        title: Text('Activity', style: TextStyle(fontSize: isSmall ? 12 : 14)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_walk,
              color: _WatchColors.accent,
              size: isSmall ? 30 : 40,
            ),
            SizedBox(height: isSmall ? 4 : 8),
            Text(
              '$steps',
              style: TextStyle(
                fontSize: isSmall ? 22 : 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Steps Today',
              style: TextStyle(
                fontSize: isSmall ? 10 : 12,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            SizedBox(height: isSmall ? 8 : 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _WatchColors.accent,
                foregroundColor: Colors.black,
                minimumSize: Size(isSmall ? 100 : 120, isSmall ? 36 : 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                watch.sendMessage({
                  'action': 'sync_activity',
                  'steps': steps,
                  'calories': calories,
                  'distance': distance,
                });
                Navigator.pop(context);
              },
              icon: Icon(Icons.sync, size: isSmall ? 14 : 16),
              label: Text(
                'Sync to Phone',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isSmall ? 10 : 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 4. Sleep Tracker Sync
// ═══════════════════════════════════════════════════════════════════════════
class SleepWatchScreen extends StatelessWidget {
  const SleepWatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final watch = WatchConnectivity();
    final isSmall = MediaQuery.of(context).size.width < 180;

    const hours = 7;
    const mins = 30;
    const qualityScore = 88;
    const deepSleepMins = 120;

    return Scaffold(
      appBar: AppBar(
        title: Text('Sleep', style: TextStyle(fontSize: isSmall ? 12 : 14)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bedtime,
              color: _WatchColors.purple,
              size: isSmall ? 30 : 40,
            ),
            SizedBox(height: isSmall ? 4 : 8),
            Text(
              '${hours}h ${mins}m',
              style: TextStyle(
                fontSize: isSmall ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Score: $qualityScore/100',
              style: TextStyle(
                fontSize: isSmall ? 10 : 12,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            SizedBox(height: isSmall ? 8 : 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _WatchColors.purple,
                foregroundColor: Colors.white,
                minimumSize: Size(isSmall ? 100 : 120, isSmall ? 36 : 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                watch.sendMessage({
                  'action': 'sync_sleep',
                  'score': qualityScore,
                  'deep_sleep': deepSleepMins,
                  'total_mins': (hours * 60) + mins,
                });
                Navigator.pop(context);
              },
              icon: Icon(Icons.sync, size: isSmall ? 14 : 16),
              label: Text(
                'Sync to Phone',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isSmall ? 10 : 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Success Screen Helper ───
class _SuccessScreen extends StatelessWidget {
  final String message;
  const _SuccessScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: _WatchColors.green, size: 40),
            const SizedBox(height: 10),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
