import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/free_walk_provider.dart';
import '../../providers/gait_provider.dart';
import '../../providers/patient_provider.dart';
import '../../providers/workout_history_provider.dart';

class FreeWalkScreen extends ConsumerWidget {
  const FreeWalkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final walkState = ref.watch(freeWalkProvider);
    final notifier = ref.read(freeWalkProvider.notifier);

    // ✅ Use the real selected patient from settings
    final settings = ref.watch(appSettingsProvider);
    final patients = ref.watch(patientListProvider);
    final currentPatient = patients
        .where((p) => p.id == settings.selectedPatientId)
        .firstOrNull;

    // ✅ Get live heart rate from sensor (null = not available)
    final liveGait = ref.watch(gaitDataProvider);
    final heartRate = liveGait.whenOrNull(data: (g) => g.heartRate);

    // Format duration helper
    String formatDuration(int seconds) {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      final remainingSeconds = seconds % 60;
      if (hours > 0) {
        return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
      }
      return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }

    return Scaffold(
      backgroundColor: AppColors.textPrimary, // Dark Mode for Focus
      appBar: AppBar(
        title: const Text(
          'Free Walk Mode',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // ✅ Only show heart rate when sensor actually reports it
          if (heartRate != null)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.favorite,
                      color: Colors.redAccent,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$heartRate bpm',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bento Metrics ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: _MiniMetric(
                      title: 'Current',
                      value: '${walkState.currentAngle.toStringAsFixed(1)}°',
                      iconData: LucideIcons.activity,
                      color: AppColors.primaryLight,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MiniMetric(
                      title: 'Peak',
                      value: '${walkState.peakAngle.toStringAsFixed(1)}°',
                      iconData: LucideIcons.trendingUp,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MiniMetric(
                      title: 'Time',
                      value: formatDuration(walkState.durationSeconds),
                      iconData: LucideIcons.clock,
                      color: Colors.orangeAccent,
                    ),
                  ),
                ],
              ),
            ),

            // ── Live Graph Area ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 8.0,
                ),
                child: Container(
                  padding: const EdgeInsets.only(
                    top: 32,
                    right: 16,
                    left: 0,
                    bottom: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: walkState.dataPoints.isEmpty
                      ? Center(
                          child: Text(
                            walkState.isRecording
                                ? 'Waiting for sensor data...'
                                : 'Press Start to track motion',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        )
                      : LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 20,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  strokeWidth: 1,
                                );
                              },
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        right: 8.0,
                                      ),
                                      child: Text(
                                        '${value.toInt()}°',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.5,
                                          ),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: walkState.dataPoints,
                                isCurved: true,
                                curveSmoothness: 0.35,
                                color: AppColors.primaryLight,
                                barWidth: 4,
                                dotData: const FlDotData(
                                  show: false,
                                ), // Hide dots for smoothness
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primaryLight.withValues(
                                        alpha: 0.3,
                                      ),
                                      AppColors.primaryLight.withValues(
                                        alpha: 0.0,
                                      ),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ],
                            // Auto scale Y axis
                            minY: 0,
                            maxY: math.max(100.0, walkState.peakAngle + 20),
                            // Auto scale X axis for a rolling window look
                            minX: walkState.dataPoints.isEmpty
                                ? 0
                                : walkState.dataPoints.first.x,
                            maxX: walkState.dataPoints.isEmpty
                                ? 10
                                : walkState.dataPoints.last.x,
                          ),
                        ),
                ),
              ),
            ),

            // ── Bottom Action Area ──
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (walkState.isRecording) {
                      notifier.stopRecording();

                      // ✅ Save with real patient name and ID from settings
                      final entry = WorkoutHistoryEntry(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        startTime: DateTime.now().subtract(
                          Duration(seconds: walkState.durationSeconds),
                        ),
                        endTime: DateTime.now(),
                        patientId: currentPatient?.id ?? 'local_user',
                        patientName: currentPatient?.name ?? 'My Profile',
                        type: WorkoutType.exercise,
                        durationSeconds: walkState.durationSeconds,
                        peakAngle: walkState.peakAngle,
                      );

                      ref.read(workoutHistoryProvider.notifier).addEntry(entry);

                      // Mock save success
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Session saved to Movement History!',
                          ),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                      Navigator.pop(context);
                    } else {
                      notifier.startRecording();
                    }
                  },
                  icon: Icon(
                    walkState.isRecording
                        ? LucideIcons.square
                        : LucideIcons.play,
                    color: Colors.white,
                  ),
                  label: Text(
                    walkState.isRecording ? 'STOP & SAVE' : 'START WALKING',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: walkState.isRecording
                        ? AppColors.warning
                        : AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String title;
  final String value;
  final IconData iconData;
  final Color color;

  const _MiniMetric({
    required this.title,
    required this.value,
    required this.iconData,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(iconData, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                title,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
