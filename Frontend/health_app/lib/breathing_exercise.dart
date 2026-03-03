import 'package:flutter/material.dart';
import 'dart:math' as math;

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
      duration:
          Duration(seconds: _inhaleSeconds + _holdSeconds + _exhaleSeconds),
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
      if (mounted) {
        _startBreathingCycle();
      }
    });
  }

  void _startBreathingCycle() {
    if (_cycleCount >= _totalCycles) {
      setState(() {
        _instruction = 'Complete!';
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
      return;
    }

    setState(() {
      _isExerciseStarted = true;
      _instruction = 'Inhale';
    });

    // Inhale phase - expand
    _breathController.duration = Duration(seconds: _inhaleSeconds);
    _breathController.forward(from: 0.0).then((_) {
      if (!mounted) return;

      setState(() {
        _instruction = 'Hold';
      });

      // Hold phase
      Future.delayed(Duration(seconds: _holdSeconds), () {
        if (!mounted) return;

        setState(() {
          _instruction = 'Exhale';
        });

        // Exhale phase - contract
        _breathController.duration = Duration(seconds: _exhaleSeconds);
        _breathController.reverse().then((_) {
          if (!mounted) return;

          _cycleCount++;
          _startBreathingCycle();
        });
      });
    });
  }

  @override
  void dispose() {
    _breathController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final secondaryColor = theme.colorScheme.secondary;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Breathing Exercise',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: primaryColor),
                  ),
                ],
              ),
            ),

            // Main animation area
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation:
                      Listenable.merge([_breathAnimation, _pulseAnimation]),
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer pulsing ring
                        Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 240,
                            height: 240,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: secondaryColor.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                          ),
                        ),

                        // Breathing circle
                        Transform.scale(
                          scale: _breathAnimation.value,
                          child: Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  secondaryColor.withOpacity(0.8),
                                  primaryColor.withOpacity(0.6),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: secondaryColor.withOpacity(0.4),
                                  blurRadius: 30,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Inner circle with instruction
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          child: Center(
                            child: Text(
                              _instruction,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_totalCycles, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index < _cycleCount
                              ? secondaryColor
                              : primaryColor.withOpacity(0.2),
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
                      color: primaryColor.withOpacity(0.7),
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
