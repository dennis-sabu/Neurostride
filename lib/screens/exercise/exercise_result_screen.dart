import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/exercise_provider.dart';
import '../../providers/patient_provider.dart';
import '../../providers/workout_history_provider.dart';

class ExerciseResultScreen extends ConsumerWidget {
  const ExerciseResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final result = ModalRoute.of(context)!.settings.arguments as ExerciseResult;

    final settings = ref.watch(appSettingsProvider);
    final patientId = settings.selectedPatientId;
    final patientList = ref.watch(patientListProvider);

    Patient? activePatient;
    if (patientId != null) {
      final iter = patientList.where((p) => p.id == patientId);
      activePatient = iter.isNotEmpty ? iter.first : null;
    }

    // Completion category based on reps
    final repFraction = result.totalReps > 0
        ? result.completedReps / result.totalReps
        : 0.0;
    final completionColor = repFraction >= 1.0
        ? AppColors.success
        : (repFraction >= 0.6 ? AppColors.primary : Colors.orange);

    final completionLabel = repFraction >= 1.0
        ? 'Session Complete!'
        : (repFraction >= 0.6 ? 'Good Effort' : 'Keep Going');

    final encouragement = repFraction >= 1.0
        ? 'Excellent work — all reps completed.'
        : (repFraction >= 0.6
              ? 'You completed most of the session. Keep it up!'
              : 'Every rep counts. Try again to build strength.');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Session Summary'),
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Completion Badge ──────────────────────────────────────────
              Center(
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface,
                    boxShadow: [
                      BoxShadow(
                        color: completionColor.withValues(alpha: 0.2),
                        blurRadius: 32,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 150,
                        height: 150,
                        child: CircularProgressIndicator(
                          value: repFraction.clamp(0.0, 1.0),
                          strokeWidth: 10,
                          backgroundColor: AppColors.greyLight.withValues(
                            alpha: 0.5,
                          ),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            completionColor,
                          ),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            repFraction >= 1.0
                                ? Icons.check_circle_rounded
                                : Icons.directions_run_rounded,
                            color: completionColor,
                            size: 36,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${result.completedReps}/${result.totalReps}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'reps',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.greyText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Completion label & encouragement ─────────────────────────
              Text(
                completionLabel,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: completionColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                encouragement,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.greyText,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // ── Session Stats Card ───────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session Details',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.greyText,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _StatItem(
                            icon: Icons.arrow_upward_rounded,
                            label: 'Peak Angle',
                            value: '${result.peakAngle.toStringAsFixed(1)}°',
                            color: AppColors.primary,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 44,
                          color: AppColors.greyLight,
                        ),
                        Expanded(
                          child: _StatItem(
                            icon: Icons.repeat_rounded,
                            label: 'Reps Done',
                            value: '${result.completedReps}',
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: AppColors.greyLight),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _StatItem(
                            icon: Icons.timer_outlined,
                            label: 'Hold Time',
                            value: '${result.holdTime}s',
                            color: Colors.orange,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 44,
                          color: AppColors.greyLight,
                        ),
                        Expanded(
                          child: _StatItem(
                            icon: Icons.sensors,
                            label: 'Data Quality',
                            value: _qualityLabel(result.overallDataQuality),
                            color: _qualityColor(result.overallDataQuality),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Calibration quality note ─────────────────────────────────
              if (result.calibrationQuality == CalibrationQuality.poor) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Calibration was slightly unstable. For best accuracy, hold still during the calibration phase.',
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
              ],

              const SizedBox(height: 8),

              // ── Save & Finish ────────────────────────────────────────────
              ElevatedButton(
                onPressed: () {
                  try {
                    if (activePatient != null) {
                      ref
                          .read(patientListProvider.notifier)
                          .addExerciseResult(activePatient.id, result);
                    }

                    final entry = WorkoutHistoryEntry(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      startTime: result.date.subtract(
                        Duration(seconds: result.holdTime),
                      ),
                      endTime: result.date,
                      patientId: activePatient?.id ?? 'user_1',
                      patientName: activePatient?.name ?? 'My Profile',
                      type: WorkoutType.exercise,
                      durationSeconds: result.holdTime,
                      exerciseType: result.exerciseType,
                      finalScore: result.finalScore,
                      angleAccuracy: result.angleAccuracy,
                      stabilityScore: result.stabilityScore,
                      holdDurationScore: result.holdDurationScore,
                      smoothnessScore: result.smoothnessScore,
                      peakAngle: result.peakAngle,
                      totalReps: result.totalReps,
                      completedReps: result.completedReps,
                      repScores: result.repScores,
                    );

                    ref.read(workoutHistoryProvider.notifier).addEntry(entry);

                    // ✅ Show SnackBar before navigating so the context is still valid.
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Session saved successfully.'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/dashboard', (route) => false);
                    }
                  } catch (e) {
                    debugPrint('Save error: $e');
                    if (context.mounted) {
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/dashboard', (route) => false);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Save & Return to Dashboard'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                // ✅ Navigate to the instruction screen for the SAME exercise
                // instead of pop() which may go nowhere after pushReplacement.
                onPressed: () => Navigator.of(context).pushNamed(
                  '/exercise_instruction',
                  arguments: result.exerciseType,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.greyLight, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Try Again'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  String _qualityLabel(SensorQuality q) {
    switch (q) {
      case SensorQuality.good:
        return 'Good';
      case SensorQuality.degraded:
        return 'Fair';
      case SensorQuality.poor:
        return 'Poor';
      case SensorQuality.disconnected:
        return 'Lost';
    }
  }

  Color _qualityColor(SensorQuality q) {
    switch (q) {
      case SensorQuality.good:
        return AppColors.success;
      case SensorQuality.degraded:
        return Colors.orange;
      case SensorQuality.poor:
      case SensorQuality.disconnected:
        return AppColors.warning;
    }
  }
}

// ── Stat Item ────────────────────────────────────────────────────────────────
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.greyText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
