import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/exercise_provider.dart';
import '../../providers/patient_provider.dart';

class ExerciseMenuScreen extends ConsumerWidget {
  const ExerciseMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final settings = ref.watch(appSettingsProvider);
    final patients = ref.watch(patientListProvider);
    final currentPatient = patients
        .where((p) => p.id == settings.selectedPatientId)
        .firstOrNull;

    // Helper to find best score for a specific exercise type
    int? getBestScore(ExerciseType type) {
      if (currentPatient == null || currentPatient.exerciseHistory.isEmpty) {
        return null;
      }

      final historyForType = currentPatient.exerciseHistory
          .where((e) => e.exerciseType == type)
          .toList();

      if (historyForType.isEmpty) {
        return null;
      }

      // Find max score
      double maxScore = 0;
      for (final result in historyForType) {
        if (result.finalScore > maxScore) {
          maxScore = result.finalScore;
        }
      }
      return maxScore.toInt();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Exercise Mode'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Rehabilitation Exercises',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Select an exercise to evaluate patient performance.',
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 24),

              // ── Free Walk Mode ──
              _ExerciseCard(
                type: null,
                customTitle: 'Free Walk Mode',
                customSubtitle:
                    'Walk freely while monitoring your gait in real-time.',
                iconData: LucideIcons.footprints,
                bestScore: null,
                iconColor: AppColors.success,
                onTap: () {
                  Navigator.pushNamed(context, '/free_walk');
                },
              ),
              const SizedBox(height: 16),

              // ── Knee Bend ──
              _ExerciseCard(
                type: ExerciseType.kneeBend,
                iconData: Icons.airline_seat_legroom_extra,
                bestScore: getBestScore(ExerciseType.kneeBend),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/exercise_instruction',
                    arguments: ExerciseType.kneeBend,
                  );
                },
              ),
              const SizedBox(height: 16),

              // ── Straight Leg Raise ──
              _ExerciseCard(
                type: ExerciseType.straightLegRaise,
                iconData: Icons.sports_gymnastics,
                bestScore: getBestScore(ExerciseType.straightLegRaise),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/exercise_instruction',
                    arguments: ExerciseType.straightLegRaise,
                  );
                },
              ),
              const SizedBox(height: 16),

              // ── Hold Position ──
              _ExerciseCard(
                type: ExerciseType.holdPosition,
                iconData: Icons.accessibility_new,
                bestScore: getBestScore(ExerciseType.holdPosition),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/exercise_instruction',
                    arguments: ExerciseType.holdPosition,
                  );
                },
              ),
              const SizedBox(height: 16),

              // ── Ankle Dorsiflexion ──
              _ExerciseCard(
                type: ExerciseType.ankleDorsiflexion,
                iconData: Icons.directions_walk_rounded,
                bestScore: getBestScore(ExerciseType.ankleDorsiflexion),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/exercise_instruction',
                    arguments: ExerciseType.ankleDorsiflexion,
                  );
                },
              ),
              const SizedBox(height: 16),

              // ── Terminal Knee Extension ──
              _ExerciseCard(
                type: ExerciseType.terminalKneeExtension,
                iconData: Icons.compress_rounded,
                bestScore: getBestScore(ExerciseType.terminalKneeExtension),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/exercise_instruction',
                    arguments: ExerciseType.terminalKneeExtension,
                  );
                },
              ),
              const SizedBox(height: 16),

              // ── Hip Abduction ──
              _ExerciseCard(
                type: ExerciseType.hipAbduction,
                iconData: Icons.swap_horiz_rounded,
                bestScore: getBestScore(ExerciseType.hipAbduction),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/exercise_instruction',
                    arguments: ExerciseType.hipAbduction,
                  );
                },
              ),
              const SizedBox(height: 16),

              // ── Calf Raise Hold ──
              _ExerciseCard(
                type: ExerciseType.calfRaiseHold,
                iconData: Icons.trending_up_rounded,
                bestScore: getBestScore(ExerciseType.calfRaiseHold),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/exercise_instruction',
                    arguments: ExerciseType.calfRaiseHold,
                  );
                },
              ),
              const SizedBox(height: 16),

              // ── Single Leg Balance ──
              _ExerciseCard(
                type: ExerciseType.singleLegBalance,
                iconData: Icons.self_improvement_rounded,
                bestScore: getBestScore(ExerciseType.singleLegBalance),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/exercise_instruction',
                    arguments: ExerciseType.singleLegBalance,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final ExerciseType? type;
  final String? customTitle;
  final String? customSubtitle;
  final IconData iconData;
  final Color? iconColor;
  final int? bestScore;
  final VoidCallback onTap;

  const _ExerciseCard({
    this.type,
    this.customTitle,
    this.customSubtitle,
    required this.iconData,
    this.iconColor,
    this.bestScore,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayColor = iconColor ?? AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: displayColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: displayColor, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customTitle ?? type?.name ?? '',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    customSubtitle ?? type?.description ?? '',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (bestScore != null) ...[
                  Text('Best', style: theme.textTheme.labelSmall),
                  Text(
                    // ✅ Show em-dash for 0 score (no completed exercises yet)
                    bestScore! > 0 ? '$bestScore' : '—',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ] else ...[
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.greyText.withValues(alpha: 0.5),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
