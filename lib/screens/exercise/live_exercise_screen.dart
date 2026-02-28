import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/exercise_provider.dart';
import '../../providers/bluetooth_provider.dart';
import '../../providers/gait_provider.dart';

class LiveExerciseScreen extends ConsumerStatefulWidget {
  const LiveExerciseScreen({super.key});

  @override
  ConsumerState<LiveExerciseScreen> createState() => _LiveExerciseScreenState();
}

class _LiveExerciseScreenState extends ConsumerState<LiveExerciseScreen> {
  late ExerciseType _exerciseType;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _exerciseType =
          ModalRoute.of(context)!.settings.arguments as ExerciseType;

      // Start the exercise session logic using the gait stream
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final btState = ref.read(bluetoothProvider);
        if (!btState.isConnected) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No sensor connected. Please connect from Dashboard.',
              ),
              backgroundColor: AppColors.warning,
            ),
          );
        }

        final stream = ref.read(gaitStreamProvider);
        ref
            .read(exerciseSessionProvider.notifier)
            .startExercise(_exerciseType, stream);
      });

      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessionState = ref.watch(exerciseSessionProvider);

    Color feedbackColor = AppColors.warning;
    String feedbackText = "Move to target";

    // Define phase labels based on state
    if (sessionState.isResting) {
      feedbackColor = AppColors.primary;
      feedbackText = "Rest: ${sessionState.restSecondsRemaining}s";
    } else {
      switch (sessionState.currentPhase) {
        case RepPhase.movingToTarget:
          feedbackColor = AppColors.warning;
          feedbackText = _exerciseType == ExerciseType.kneeBend
              ? "Bend to target"
              : "Move to target";
          break;
        case RepPhase.holdingTarget:
          feedbackColor = AppColors.success;
          feedbackText = "Hold steady!";
          break;
        case RepPhase.returning:
          feedbackColor = Colors.orange;
          feedbackText = "Return to start";
          break;
        case RepPhase.resting:
          feedbackColor = AppColors.primary;
          feedbackText = "Rest: ${sessionState.restSecondsRemaining}s";
          break;
      }
    }

    ref.listen<BluetoothState>(bluetoothProvider, (previous, next) {
      if (previous?.status == BluetoothConnectionStatus.connected &&
          next.status == BluetoothConnectionStatus.disconnected) {
        // Immediately pause exercise
        ref.read(exerciseSessionProvider.notifier).pauseExercise();

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctxDialog) => AlertDialog(
                  title: const Text('End Exercise?'),
                  content: const Text(
                    'Your current progress will be scored and saved. Are you sure?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctxDialog).pop(),
                      child: const Text('CONTINUE EXERCISE'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctxDialog).pop();
                        final notifier = ref.read(
                          exerciseSessionProvider.notifier,
                        );
                        final resultDTO = notifier.calculateFinalScore();
                        notifier.stopExercise();
                        Navigator.pushReplacementNamed(
                          context,
                          '/exercise_result',
                          arguments: resultDTO,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                      ),
                      child: const Text('END & SAVE SCORE'),
                    ),
                  ],
                ),
              );
            },
            child: AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Text('Sensor Disconnected'),
                ],
              ),
              content: const Text(
                'The sensor connection was lost during exercise.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    final result = ref
                        .read(exerciseSessionProvider.notifier)
                        .calculateFinalScore();
                    ref.read(exerciseSessionProvider.notifier).stopExercise();
                    Navigator.pushReplacementNamed(
                      context,
                      '/exercise_result',
                      arguments: result,
                    );
                  },
                  child: const Text(
                    'END EXERCISE',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushNamed(context, '/bluetooth_connect');
                  },
                  child: const Text('RECONNECT'),
                ),
              ],
            ),
          ),
        );
      }
    });

    int remainingHold =
        _exerciseType.requiredHoldSeconds - sessionState.holdSeconds;
    if (remainingHold < 0) remainingHold = 0;

    final isWaitingForData =
        sessionState.angleHistory.isEmpty && sessionState.currentAngle == 0.0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctxDialog) => AlertDialog(
            title: const Text('End Exercise?'),
            content: const Text(
              'Your current progress will be scored and saved. Are you sure?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctxDialog).pop(),
                child: const Text('CONTINUE EXERCISE'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctxDialog).pop();
                  final notifier = ref.read(exerciseSessionProvider.notifier);
                  final resultDTO = notifier.calculateFinalScore();
                  notifier.stopExercise();
                  Navigator.pushReplacementNamed(
                    context,
                    '/exercise_result',
                    arguments: resultDTO,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                ),
                child: const Text('END & SAVE SCORE'),
              ),
            ],
          ),
        );
      },
      child: Scaffold(
        backgroundColor:
            AppColors.textPrimary, // Dark background for Focus Mode
        appBar: AppBar(
          title: Text(
            _exerciseType.name,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false, // Hide back button
          actions: [
            if (sessionState.isPaused)
              TextButton.icon(
                onPressed: () {
                  // Resume logic
                },
                icon: const Icon(Icons.play_arrow, color: Colors.white),
                label: const Text(
                  'RESUME',
                  style: TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // ── Top Feedback Banner ──
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                color: feedbackColor.withValues(alpha: 0.15),
                alignment: Alignment.center,
                child: Text(
                  feedbackText.toUpperCase(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                    color: feedbackColor, // Bright colors pop on dark bg
                  ),
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // ── Rep Progress Info ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _MetricPill(
                            icon: Icons.repeat,
                            label: 'Reps',
                            value:
                                '${sessionState.completedReps} / ${sessionState.totalReps}',
                            valueColor: Colors.white,
                          ),
                          _MetricPill(
                            icon: Icons.timer,
                            label: 'Hold',
                            value: sessionState.isResting
                                ? '${sessionState.restSecondsRemaining}s'
                                : '${sessionState.holdSeconds} / ${_exerciseType.requiredHoldSeconds}s',
                            valueColor: sessionState.isResting
                                ? AppColors
                                      .primaryLight // lighter for dark mode
                                : (sessionState.holdSeconds >=
                                          _exerciseType.requiredHoldSeconds
                                      ? AppColors.success
                                      : Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Rep Dots ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(sessionState.totalReps, (
                          index,
                        ) {
                          Color dotColor = Colors.white.withValues(alpha: 0.2);
                          if (index < sessionState.completedReps) {
                            double score = sessionState.repScores[index];
                            if (score > 70) {
                              dotColor = AppColors.success;
                            } else if (score >= 50) {
                              dotColor = Colors.orange;
                            } else {
                              dotColor = AppColors.warning;
                            }
                          }
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: dotColor,
                              shape: BoxShape.circle,
                            ),
                          );
                        }),
                      ),

                      const Spacer(flex: 1),

                      // ── Central Angle Gauge ──
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Gauge arc
                            SizedBox(
                              width: 280,
                              height: 280,
                              child: CustomPaint(
                                painter: _TargetGaugePainter(
                                  currentAngle: sessionState.currentAngle,
                                  minTarget: sessionState.minTarget,
                                  maxTarget: sessionState.maxTarget,
                                  color: feedbackColor,
                                ),
                              ),
                            ),
                            // Center Content
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isWaitingForData)
                                  const Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(height: 16),
                                      Text(
                                        'Waiting for sensor...',
                                        style: TextStyle(
                                          color: AppColors.greyText,
                                        ),
                                      ),
                                    ],
                                  )
                                else ...[
                                  Text(
                                    'ANGLE',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                      letterSpacing: 2.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${sessionState.currentAngle.toStringAsFixed(1)}°',
                                    style: theme.textTheme.displayLarge
                                        ?.copyWith(
                                          fontSize: 64,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          height: 1.1,
                                        ),
                                  ),
                                ],
                                // Show large countdown when in range
                                if (sessionState.isInTargetRange &&
                                    remainingHold > 0)
                                  Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Hold: ${remainingHold}s left',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            color: AppColors.success,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  )
                                else if (remainingHold == 0)
                                  Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.success,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'GOAL REACHED! 🎉',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Spacer(flex: 1),

                      // ── Stability Meter ──
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Stability',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                              Text(
                                '${sessionState.stabilityRaw.toInt()}%',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: sessionState.stabilityRaw > 80
                                      ? AppColors.success
                                      : (sessionState.stabilityRaw > 50
                                            ? Colors.orange
                                            : AppColors.warning),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: sessionState.stabilityRaw / 100,
                              minHeight: 8,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.1,
                              ),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                sessionState.stabilityRaw > 80
                                    ? AppColors.success
                                    : (sessionState.stabilityRaw > 50
                                          ? Colors.orange
                                          : AppColors.warning),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // ── STOP Button ──
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            // Calculate score and build result object
                            final notifier = ref.read(
                              exerciseSessionProvider.notifier,
                            );
                            final result = notifier.calculateFinalScore();
                            notifier.stopExercise();

                            Navigator.pushReplacementNamed(
                              context,
                              '/exercise_result',
                              arguments: result,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: AppColors.warning.withValues(
                              alpha: 0.1,
                            ),
                            side: BorderSide(
                              color: AppColors.warning.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 20),
                          ),
                          child: const Text('FINISH EXERCISE'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Metric Pill Widget ──
class _MetricPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _MetricPill({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: Colors.white.withValues(alpha: 0.6)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Glowing Gauge Arc Painter ──
class _TargetGaugePainter extends CustomPainter {
  final double currentAngle;
  final double minTarget;
  final double maxTarget;
  final Color color;

  _TargetGaugePainter({
    required this.currentAngle,
    required this.minTarget,
    required this.maxTarget,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background track
    final trackPaint = Paint()
      ..color = AppColors.greyLight.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 28
      ..strokeCap = StrokeCap.round;

    // Target zone indicator
    final targetZonePaint = Paint()
      ..color = AppColors.success.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 28
      ..strokeCap = StrokeCap.butt;

    // Glow paint for current value
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 36
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    // Active value arc
    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 28
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Draw background track (270 degrees total span)
    const startAngle = math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;
    canvas.drawArc(rect, startAngle, sweepAngle, false, trackPaint);

    // Draw target zone
    const maxScale = 120.0;
    double targetStartPercent = (minTarget / maxScale).clamp(0.0, 1.0);
    double targetSweepPercent = ((maxTarget - minTarget) / maxScale).clamp(
      0.0,
      1.0,
    );

    if (minTarget == maxTarget && minTarget != 0) {
      targetStartPercent = ((minTarget - 5) / maxScale).clamp(0.0, 1.0);
      targetSweepPercent = (10 / maxScale).clamp(0.0, 1.0);
    }

    double tStartRad = startAngle + (targetStartPercent * sweepAngle);
    double tSweepRad = targetSweepPercent * sweepAngle;

    if (tSweepRad > 0) {
      canvas.drawArc(rect, tStartRad, tSweepRad, false, targetZonePaint);
    }

    // Draw current value
    double currentPercent = (currentAngle / maxScale).clamp(0.0, 1.0);
    double currentSweepRad = currentPercent * sweepAngle;

    if (currentSweepRad > 0) {
      // Draw glow first, then the solid path
      canvas.drawArc(rect, startAngle, currentSweepRad, false, glowPaint);
      canvas.drawArc(rect, startAngle, currentSweepRad, false, valuePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TargetGaugePainter oldDelegate) {
    return oldDelegate.currentAngle != currentAngle ||
        oldDelegate.color != color ||
        oldDelegate.minTarget != minTarget;
  }
}
