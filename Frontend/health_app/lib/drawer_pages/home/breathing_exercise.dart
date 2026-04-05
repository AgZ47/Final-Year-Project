import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart'; // ⚡ NEW: Centralized theme

class BreathingExercise extends StatefulWidget {
  const BreathingExercise({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const BreathingExercise(),
    );
  }

  @override
  State<BreathingExercise> createState() => _BreathingExerciseState();
}

class _BreathingExerciseState extends State<BreathingExercise>
    with TickerProviderStateMixin {
  late AnimationController _breathController;
  late AnimationController _pulseController;
  late Animation<double> _breathAnimation;
  late Animation<double> _pulseAnimation;

  String _instruction = 'Get Ready';
  int _cycleCount = 0;
  final int _totalCycles = 3;
  bool _isExerciseStarted = false;

  // 4-4-4 breathing pattern
  final int _inhaleSeconds = 4;
  final int _holdSeconds = 4;
  final int _exhaleSeconds = 4;

  @override
  void initState() {
    super.initState();

    // Main breath animation
    _breathController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _inhaleSeconds),
    );

    _breathAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    // Subtle pulse animation for the outer ring
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _startBreathingCycle();
    });
  }

  // ⚡ OPTIMIZATION: Converted messy nested callbacks into a clean async loop
  Future<void> _startBreathingCycle() async {
    while (_cycleCount < _totalCycles) {
      if (!mounted) return;

      setState(() {
        _isExerciseStarted = true;
        _instruction = 'Inhale';
      });

      // Inhale phase
      _breathController.duration = Duration(seconds: _inhaleSeconds);
      await _breathController.forward(from: 0.0);
      if (!mounted) return;

      // Hold phase
      setState(() => _instruction = 'Hold');
      await Future.delayed(Duration(seconds: _holdSeconds));
      if (!mounted) return;

      // Exhale phase
      setState(() => _instruction = 'Exhale');
      _breathController.duration = Duration(seconds: _exhaleSeconds);
      await _breathController.reverse();
      if (!mounted) return;

      _cycleCount++;
    }

    // Complete
    setState(() => _instruction = 'Complete!');
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _breathController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: AppTheme.bgDark,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppTheme.accent.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Breathing Exercise',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accent,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppTheme.accent),
                  ),
                ],
              ),
            ),

            // ── Main animation area ──
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // ⚡ OPTIMIZATION: Scoped Animation Builders
                    // Outer pulsing ring
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        width: 240,
                        height: 240,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.purple.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                      ),
                    ),

                    // Breathing circle
                    ScaleTransition(
                      scale: _breathAnimation,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppTheme.purple.withOpacity(0.8),
                              AppTheme.accent.withOpacity(0.6),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.purple.withOpacity(0.4),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Inner static circle with text
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.9),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _instruction,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.bgDark,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Progress indicator ──
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_totalCycles, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index < _cycleCount
                              ? AppTheme.purple
                              : AppTheme.accent.withOpacity(0.2),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isExerciseStarted
                        ? 'Cycle ${_cycleCount + 1} of $_totalCycles'
                        : 'Preparing...',
                    style: TextStyle(
                      color: AppTheme.accent.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
