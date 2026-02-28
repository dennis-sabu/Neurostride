import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/exercise_provider.dart';
import '../../providers/gait_provider.dart';

class ExerciseInstructionScreen extends ConsumerStatefulWidget {
  const ExerciseInstructionScreen({super.key});

  @override
  ConsumerState<ExerciseInstructionScreen> createState() =>
      _ExerciseInstructionScreenState();
}

class _ExerciseInstructionScreenState
    extends ConsumerState<ExerciseInstructionScreen> {
  bool _isCalibrating = false;
  int _calibrationCountdown = 3;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(exerciseSessionProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCalibration() {
    if (_isCalibrating) return;

    setState(() {
      _isCalibrating = true;
      _calibrationCountdown = 3;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_calibrationCountdown > 1) {
          _calibrationCountdown--;
        } else {
          timer.cancel();
          _finalizeCalibration();
        }
      });
    });
  }

  void _finalizeCalibration() {
    final gaitProviderState = ref.read(gaitDataProvider);
    final currentGaitData = gaitProviderState.value;

    final baselineData =
        currentGaitData ??
        GaitData(
          leftKneeFlexion: 0.0,
          rightKneeFlexion: 0.0,
          kneeAngle: 0.0,
          leftHipExtension: 0.0,
          rightHipExtension: 0.0,
          cadence: 0.0,
          leftStepDuration: 0.0,
          rightStepDuration: 0.0,
          stepDetected: false,
          accelX: 0.0,
          accelY: 0.0,
          accelZ: 0.0,
          pitch: 0.0,
          roll: 0.0,
          yaw: 0.0,
          stabilityLevel: 'Good',
        );

    ref.read(exerciseSessionProvider.notifier).calibrateBaseline(baselineData);
    setState(() {
      _isCalibrating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exerciseType =
        ModalRoute.of(context)!.settings.arguments as ExerciseType;
    final exerciseState = ref.watch(exerciseSessionProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Instructions'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──
              Text(
                exerciseType.name,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 28,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                exerciseType.instruction,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // ── Visualization Card ──
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Stack(
                      children: [
                        // Background Grid
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _GridPainter(
                              color: AppColors.greyLight.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                        // Leg Diagram
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: CustomPaint(
                              painter: _LegInstructionPainter(
                                targetAngle:
                                    exerciseType ==
                                        ExerciseType.straightLegRaise
                                    ? exerciseType.maxTargetAngle
                                    : exerciseType.minTargetAngle,
                                isDynamic:
                                    exerciseType == ExerciseType.holdPosition,
                              ),
                            ),
                          ),
                        ),
                        // Overlay info
                        Positioned(
                          top: 24,
                          right: 24,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.timer_outlined,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Hold ${exerciseType.requiredHoldSeconds}s',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
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
              ),
              const SizedBox(height: 32),

              // ── Target Info ──
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.track_changes,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Target Angle',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            exerciseType == ExerciseType.holdPosition
                                ? 'Current Position'
                                : '${exerciseType.minTargetAngle.toInt()}° – ${exerciseType.maxTargetAngle.toInt()}°',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Action Buttons ──
              if (!exerciseState.isCalibrated)
                Column(
                  children: [
                    Text(
                      'Stand straight and tap CALIBRATE',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.greyText,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _isCalibrating ? null : _startCalibration,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.8,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        minimumSize: const Size(double.infinity, 0),
                      ),
                      child: _isCalibrating
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  'CALIBRATING... $_calibrationCountdown',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'CALIBRATE',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Calibrated Successfully',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                          context,
                          '/live_exercise',
                          arguments: exerciseType,
                        );
                      },
                      style:
                          ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            elevation: 0,
                            minimumSize: const Size(double.infinity, 0),
                          ).copyWith(
                            shadowColor: WidgetStateProperty.all(
                              AppColors.primary.withValues(alpha: 0.4),
                            ),
                          ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_arrow_rounded, size: 28),
                          const SizedBox(width: 12),
                          Text(
                            'START EXERCISE',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Background Grid Painter ──
class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const double spacing = 30.0;

    // Vertical lines
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    // Horizontal lines
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Leg Diagram Painter ──
class _LegInstructionPainter extends CustomPainter {
  final double targetAngle;
  final bool isDynamic;

  _LegInstructionPainter({required this.targetAngle, required this.isDynamic});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.4, size.height * 0.3);
    final thighLength = size.height * 0.4;
    final shinLength = size.height * 0.4;

    // Paints
    final jointPaint = Paint()
      ..color = AppColors.textPrimary
      ..style = PaintingStyle.fill;

    final bonePaint = Paint()
      ..color = AppColors.textPrimary
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final targetBonePaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.6)
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final arcPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final arcStrokePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 1. Draw Hip Joint
    canvas.drawCircle(center, 12, jointPaint);

    // 2. Draw Thigh (straight down)
    final kneePos = Offset(center.dx, center.dy + thighLength);
    canvas.drawLine(center, kneePos, bonePaint);
    canvas.drawCircle(kneePos, 14, jointPaint);

    // 3. Draw Target Shin
    double displayAngleRange = isDynamic ? 30.0 : targetAngle;
    double rads = displayAngleRange * (math.pi / 180.0);

    // Calculate end position (pendulum math)
    final targetAnklePos = Offset(
      kneePos.dx - math.sin(rads) * shinLength,
      kneePos.dy + math.cos(rads) * shinLength,
    );

    // Draw the angle arc
    final rect = Rect.fromCircle(center: kneePos, radius: shinLength * 0.4);
    // Start from straight down (pi/2) and draw towards the angle
    canvas.drawArc(rect, math.pi / 2, -rads, true, arcPaint);
    canvas.drawArc(rect, math.pi / 2, -rads, false, arcStrokePaint);

    // Draw target line
    if (!isDynamic) {
      canvas.drawLine(kneePos, targetAnklePos, targetBonePaint);
      // Draw target ankle
      canvas.drawCircle(
        targetAnklePos,
        12,
        jointPaint..color = AppColors.primary,
      );
    } else {
      // For hold position, just draw a straight leg with dynamic arrows
      final straightAnklePos = Offset(kneePos.dx, kneePos.dy + shinLength);
      canvas.drawLine(kneePos, straightAnklePos, targetBonePaint);
      canvas.drawCircle(
        straightAnklePos,
        12,
        jointPaint..color = AppColors.primary,
      );

      // Draw dynamic indicator (arrows up/down)
      _drawHoldArrows(canvas, straightAnklePos);
    }

    // 4. Draw starting Shin (faded, straight down)
    if (!isDynamic) {
      final startAnklePos = Offset(kneePos.dx, kneePos.dy + shinLength);
      canvas.drawLine(
        kneePos,
        startAnklePos,
        bonePaint..color = AppColors.textPrimary.withValues(alpha: 0.3),
      );
      canvas.drawCircle(
        startAnklePos,
        12,
        jointPaint..color = AppColors.textPrimary.withValues(alpha: 0.3),
      );
    }
  }

  void _drawHoldArrows(Canvas canvas, Offset pos) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Up arrow
    canvas.drawLine(
      Offset(pos.dx + 25, pos.dy - 10),
      Offset(pos.dx + 25, pos.dy - 30),
      paint,
    );
    canvas.drawLine(
      Offset(pos.dx + 25, pos.dy - 30),
      Offset(pos.dx + 15, pos.dy - 20),
      paint,
    );
    canvas.drawLine(
      Offset(pos.dx + 25, pos.dy - 30),
      Offset(pos.dx + 35, pos.dy - 20),
      paint,
    );

    // Down arrow
    canvas.drawLine(
      Offset(pos.dx + 25, pos.dy + 10),
      Offset(pos.dx + 25, pos.dy + 30),
      paint,
    );
    canvas.drawLine(
      Offset(pos.dx + 25, pos.dy + 30),
      Offset(pos.dx + 15, pos.dy + 20),
      paint,
    );
    canvas.drawLine(
      Offset(pos.dx + 25, pos.dy + 30),
      Offset(pos.dx + 35, pos.dy + 20),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _LegInstructionPainter oldDelegate) {
    return oldDelegate.targetAngle != targetAngle ||
        oldDelegate.isDynamic != isDynamic;
  }
}
