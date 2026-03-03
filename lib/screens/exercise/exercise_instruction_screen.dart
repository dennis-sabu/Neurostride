import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/bluetooth_provider.dart';
import '../../providers/exercise_provider.dart';
import '../../providers/gait_provider.dart';

class ExerciseInstructionScreen extends ConsumerStatefulWidget {
  const ExerciseInstructionScreen({super.key});

  @override
  ConsumerState<ExerciseInstructionScreen> createState() =>
      _ExerciseInstructionScreenState();
}

class _ExerciseInstructionScreenState
    extends ConsumerState<ExerciseInstructionScreen>
    with SingleTickerProviderStateMixin {
  ExerciseType? _exerciseType;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.97,
      end: 1.03,
    ).animate(_pulseController);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(exerciseSessionProvider.notifier).reset();
      // Read route arg once here
      if (mounted) {
        setState(() {
          _exerciseType =
              ModalRoute.of(context)!.settings.arguments as ExerciseType;
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onBegin() {
    final exerciseType = _exerciseType;
    if (exerciseType == null) return;

    // Guard: real sensor must be connected
    final btState = ref.read(bluetoothProvider);
    if (!btState.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No sensor connected. Please connect from Dashboard.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Stop the button animation immediately — reduces UI work during calibration
    _pulseController.stop();

    final stream = ref.read(gaitStreamProvider);
    ref
        .read(exerciseSessionProvider.notifier)
        .startCalibration(exerciseType, stream);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exerciseType = _exerciseType;
    if (exerciseType == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Only watch calibration-relevant fields — NOT the whole state.
    // This prevents the expensive full-screen rebuild on every sensor packet.
    final calibPhase = ref.watch(
      exerciseSessionProvider.select((s) => s.calibrationPhase),
    );
    final calibProgress = ref.watch(
      exerciseSessionProvider.select((s) => s.calibrationProgress),
    );
    final coachMsg = ref.watch(
      exerciseSessionProvider.select((s) => s.coachingMessage),
    );

    // Automatically navigate when exercise starts (after calibration)
    ref.listen<bool>(
      exerciseSessionProvider.select((s) => s.isRunning && s.isCalibrated),
      (_, isReady) {
        if (isReady) {
          Navigator.pushReplacementNamed(
            context,
            '/live_exercise',
            arguments: exerciseType,
          );
        }
      },
    );

    final isCalibrating = calibPhase == CalibrationPhase.collecting;

    return PopScope(
      canPop: !isCalibrating,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Instructions'),
          backgroundColor: Colors.transparent,
          leading: isCalibrating ? const SizedBox.shrink() : null,
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
                const SizedBox(height: 8),
                Text(
                  exerciseType.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.greyText,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // ── Visualization Card — static, never rebuilds ──
                Expanded(
                  child: _StaticVisualizationCard(exerciseType: exerciseType),
                ),
                const SizedBox(height: 24),

                // ── Target Info ──
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.track_changes,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TARGET ANGLE',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            exerciseType == ExerciseType.holdPosition ||
                                    exerciseType ==
                                        ExerciseType.singleLegBalance
                                ? 'Your current position ± 5°'
                                : '${exerciseType.minTargetAngle.toInt()}° – ${exerciseType.maxTargetAngle.toInt()}° from neutral',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Action area ──
                if (!isCalibrating) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: Colors.amber,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Stand in your resting position, then tap BEGIN. '
                            'The sensor calibrates automatically.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.greyText,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ScaleTransition(
                    scale: _pulseAnim,
                    child: ElevatedButton.icon(
                      onPressed: _onBegin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 22),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 0),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 28),
                      label: Text(
                        'BEGIN EXERCISE',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  _CalibrationProgressWidget(
                    progress: calibProgress,
                    message: coachMsg,
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Static Visualization Card ─────────────────────────────────────────────────
// Extracted as a plain StatelessWidget so it NEVER participates in any
// Riverpod-driven rebuild. The CustomPaint only repaints if exerciseType changes.
class _StaticVisualizationCard extends StatelessWidget {
  final ExerciseType exerciseType;
  const _StaticVisualizationCard({required this.exerciseType});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppTheme.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _GridPainter(
                  color: AppColors.greyLight.withValues(alpha: 0.5),
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _LegInstructionPainter(
                      targetAngle: exerciseType == ExerciseType.straightLegRaise
                          ? exerciseType.maxTargetAngle
                          : exerciseType.minTargetAngle,
                      isDynamic:
                          exerciseType == ExerciseType.holdPosition ||
                          exerciseType == ExerciseType.singleLegBalance,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
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
                      size: 16,
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
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.repeat_rounded,
                      size: 16,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${exerciseType.targetReps} reps',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.success,
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
    );
  }
}

// ── Calibration Progress Widget ───────────────────────────────────────────────
class _CalibrationProgressWidget extends StatelessWidget {
  final double progress;
  final String message;

  const _CalibrationProgressWidget({
    required this.progress,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 90,
                height: 90,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '$pct%',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'Keep still — do not move your leg',
            style: TextStyle(color: AppColors.greyText, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Grid Painter ──────────────────────────────────────────────────────────────
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
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Leg Diagram Painter ───────────────────────────────────────────────────────
class _LegInstructionPainter extends CustomPainter {
  final double targetAngle;
  final bool isDynamic;

  _LegInstructionPainter({required this.targetAngle, required this.isDynamic});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.4, size.height * 0.25);
    final thighLength = size.height * 0.38;
    final shinLength = size.height * 0.38;

    final jointPaint = Paint()
      ..color = AppColors.textPrimary
      ..style = PaintingStyle.fill;
    final bonePaint = Paint()
      ..color = AppColors.textPrimary
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final targetBonePaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.7)
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final arcPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    final arcStroke = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, 10, jointPaint);
    final kneePos = Offset(center.dx, center.dy + thighLength);
    canvas.drawLine(center, kneePos, bonePaint);
    canvas.drawCircle(kneePos, 12, jointPaint);

    if (!isDynamic) {
      final rads = targetAngle * (math.pi / 180.0);
      final targetAnkle = Offset(
        kneePos.dx - math.sin(rads) * shinLength,
        kneePos.dy + math.cos(rads) * shinLength,
      );
      final arcRect = Rect.fromCircle(
        center: kneePos,
        radius: shinLength * 0.35,
      );
      canvas.drawArc(arcRect, math.pi / 2, -rads, true, arcPaint);
      canvas.drawArc(arcRect, math.pi / 2, -rads, false, arcStroke);
      canvas.drawLine(kneePos, targetAnkle, targetBonePaint);
      canvas.drawCircle(targetAnkle, 10, jointPaint..color = AppColors.primary);

      final startAnkle = Offset(kneePos.dx, kneePos.dy + shinLength);
      canvas.drawLine(
        kneePos,
        startAnkle,
        bonePaint..color = AppColors.textPrimary.withValues(alpha: 0.25),
      );
      canvas.drawCircle(
        startAnkle,
        10,
        jointPaint..color = AppColors.textPrimary.withValues(alpha: 0.25),
      );
    } else {
      final straightAnkle = Offset(kneePos.dx, kneePos.dy + shinLength);
      canvas.drawLine(kneePos, straightAnkle, targetBonePaint);
      canvas.drawCircle(
        straightAnkle,
        10,
        jointPaint..color = AppColors.primary,
      );
      _drawHoldArrows(canvas, straightAnkle);
    }
  }

  void _drawHoldArrows(Canvas canvas, Offset pos) {
    final p = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(pos.dx + 22, pos.dy - 8),
      Offset(pos.dx + 22, pos.dy - 26),
      p,
    );
    canvas.drawLine(
      Offset(pos.dx + 22, pos.dy - 26),
      Offset(pos.dx + 13, pos.dy - 18),
      p,
    );
    canvas.drawLine(
      Offset(pos.dx + 22, pos.dy - 26),
      Offset(pos.dx + 31, pos.dy - 18),
      p,
    );
    canvas.drawLine(
      Offset(pos.dx + 22, pos.dy + 8),
      Offset(pos.dx + 22, pos.dy + 26),
      p,
    );
    canvas.drawLine(
      Offset(pos.dx + 22, pos.dy + 26),
      Offset(pos.dx + 13, pos.dy + 18),
      p,
    );
    canvas.drawLine(
      Offset(pos.dx + 22, pos.dy + 26),
      Offset(pos.dx + 31, pos.dy + 18),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant _LegInstructionPainter old) =>
      old.targetAngle != targetAngle || old.isDynamic != isDynamic;
}
