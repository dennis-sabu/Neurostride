import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/patient_provider.dart';
import '../../providers/workout_history_provider.dart';
import '../../core/theme/app_colors.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final history = ref.watch(workoutHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Movement History',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: history.isEmpty
            ? Center(
                child: Text(
                  'No sessions completed yet.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.greyText,
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  return _SessionListTile(session: history[index]);
                },
              ),
      ),
    );
  }
}

class _SessionListTile extends StatelessWidget {
  final WorkoutHistoryEntry session;
  const _SessionListTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGait = session.exerciseType == null;
    final title = isGait ? 'Free Walk Mode' : session.exerciseType!.name;
    final scoreText = isGait
        ? '${session.peakAngle?.toStringAsFixed(1) ?? '0'}° Peak'
        : '${session.finalScore?.toInt() ?? 0} Score';

    final minutes = session.durationSeconds ~/ 60;
    final seconds = session.durationSeconds % 60;
    final timeString = minutes > 0 ? '${minutes}m ${seconds}s' : '${seconds}s';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.greyLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isGait ? LucideIcons.footprints : LucideIcons.activity,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  DateFormat('MMM d, h:mm a').format(session.endTime),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.greyText,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                scoreText,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                timeString,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.greyText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
