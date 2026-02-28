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
    double? previousBest;

    if (patientId != null) {
      final iter = patientList.where((p) => p.id == patientId);
      activePatient = iter.isNotEmpty ? iter.first : null;

      if (activePatient != null) {
        // Find previous best for this exercise type
        final pastResults = activePatient.exerciseHistory
            .where((r) => r.exerciseType == result.exerciseType)
            .toList();

        if (pastResults.isNotEmpty) {
          previousBest = pastResults
              .map((r) => r.finalScore)
              .reduce((a, b) => a > b ? a : b);
        }
      }
    }

    // Determine color based on final score
    Color scoreColor = AppColors.success;
    String scoreText = "Excellent";

    if (result.finalScore < 50) {
      scoreColor = AppColors.warning;
      scoreText = "Needs Improvement";
    } else if (result.finalScore < 70) {
      scoreColor = Colors.orange;
      scoreText = "Fair";
    } else if (result.finalScore < 90) {
      scoreColor = AppColors.primary;
      scoreText = "Good";
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Exercise Result'),
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false, // Don't allow normal back navigation
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Top Score Badge ──
              Center(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface,
                    boxShadow: [
                      BoxShadow(
                        color: scoreColor.withValues(alpha: 0.2),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 170,
                        height: 170,
                        child: CircularProgressIndicator(
                          value: result.finalScore / 100,
                          strokeWidth: 12,
                          backgroundColor: AppColors.greyLight.withValues(
                            alpha: 0.5,
                          ),
                          valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${result.finalScore.toInt()}',
                            style: theme.textTheme.displayLarge?.copyWith(
                              fontSize: 64,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              height: 1.0,
                            ),
                          ),
                          Text(
                            scoreText.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scoreColor,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              Text(
                'Performance Breakdown',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),

              // ── Score Breakdown Card ──
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  children: [
                    _ScoreBar(
                      label: 'Angle Accuracy (40%)',
                      value: result.angleAccuracy,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 20),
                    _ScoreBar(
                      label: 'Stability (30%)',
                      value: result.stabilityScore,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 20),
                    _ScoreBar(
                      label: 'Hold Duration (20%)',
                      value: result.holdDurationScore,
                      color: AppColors.success,
                    ),
                    const SizedBox(height: 20),
                    _ScoreBar(
                      label: 'Smoothness (10%)',
                      value: result.smoothnessScore,
                      color: Colors.purple,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Session Stats Card ──
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.arrow_upward,
                                size: 16,
                                color: AppColors.greyText,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Peak Angle',
                                style: theme.textTheme.labelMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${result.peakAngle.toStringAsFixed(1)}°',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 40, color: AppColors.greyLight),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  size: 16,
                                  color: AppColors.greyText,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Hold Time',
                                  style: theme.textTheme.labelMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${result.holdTime}s',
                              style: theme.textTheme.titleLarge?.copyWith(
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

              // ── Previous Best Comparison Card (Fix 8) ──
              if (previousBest != null)
                Container(
                  margin: const EdgeInsets.only(top: 24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: result.finalScore > previousBest
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: result.finalScore >= previousBest
                          ? AppColors.success.withValues(alpha: 0.5)
                          : AppColors.greyLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        result.finalScore >= previousBest
                            ? Icons.trending_up
                            : Icons.history,
                        color: result.finalScore >= previousBest
                            ? AppColors.success
                            : AppColors.greyText,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              result.finalScore > previousBest
                                  ? 'New Personal Best!'
                                  : (result.finalScore == previousBest
                                        ? 'Tied Personal Best!'
                                        : 'Previous Best'),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: result.finalScore >= previousBest
                                    ? AppColors.success
                                    : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Your previous highest score was ${previousBest.toInt()}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.greyText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${(result.finalScore - previousBest).abs().toInt()}${result.finalScore >= previousBest ? ' pts ↑' : ' pts ↓'}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: result.finalScore >= previousBest
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 32),

              // ── Actions ──
              ElevatedButton(
                onPressed: () {
                  try {
                    // Save local exercise result
                    if (activePatient != null) {
                      ref
                          .read(patientListProvider.notifier)
                          .addExerciseResult(activePatient.id, result);
                    }

                    // Fix 10: Store full history entry
                    final entry = WorkoutHistoryEntry(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      startTime: result.date.subtract(
                        Duration(seconds: result.holdTime),
                      ), // Approx start time
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

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Workout saved successfully!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  } catch (e) {
                    debugPrint('Save error: $e');
                  } finally {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/dashboard', (route) => false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('SAVE & FINISH'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  // Pop back to the specific exercise instruction
                  Navigator.of(context).pop();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.greyLight, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('TRY AGAIN'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _ScoreBar({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.greyText,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${value.toInt()}%',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 10,
            backgroundColor: AppColors.greyLight.withValues(alpha: 0.5),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
