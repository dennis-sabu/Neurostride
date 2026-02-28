import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/bluetooth_provider.dart';
import '../../providers/patient_provider.dart';
import '../../providers/workout_history_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_colors.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isConnected = ref.watch(bluetoothProvider).isConnected;
    final history = ref.watch(workoutHistoryProvider);

    // Calculate greeting based on time of day
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning,';
    } else if (hour < 17) {
      greeting = 'Good Afternoon,';
    } else {
      greeting = 'Good Evening,';
    }

    // Calculate Movement Points (1 pt per 10 secs active)
    final points = history.fold<int>(
      0,
      (sum, item) => sum + (item.durationSeconds ~/ 10),
    );

    // Calculate Streak (consecutive days)
    int streak = 0;
    if (history.isNotEmpty) {
      streak = 1;
      DateTime currentDate = DateTime(
        history.first.endTime.year,
        history.first.endTime.month,
        history.first.endTime.day,
      );
      for (int i = 1; i < history.length; i++) {
        DateTime prevDate = DateTime(
          history[i].endTime.year,
          history[i].endTime.month,
          history[i].endTime.day,
        );
        final diff = currentDate.difference(prevDate).inDays;
        if (diff == 1) {
          streak++;
          currentDate = prevDate;
        } else if (diff > 1) {
          break; // Streak broken
        }
      }
    }

    // Calculate Today's Exercise Count
    final today = DateTime.now();
    final todaysExercises = history.where((item) {
      return item.endTime.year == today.year &&
          item.endTime.month == today.month &&
          item.endTime.day == today.day &&
          item.type == WorkoutType.exercise; // Only count actual exercises
    }).length;
    final dailyGoal = 10;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Premium Header ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.accent],
                        ),
                      ),
                      child: const CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.surface,
                        child: Icon(
                          LucideIcons.user,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Dennis Sabu',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            fontSize: 22,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/settings'),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.greyLight),
                          boxShadow: AppTheme.softShadows,
                        ),
                        child: const Icon(
                          LucideIcons.settings,
                          size: 20,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ).animate().fade(duration: 400.ms).slideY(begin: -0.2, end: 0),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── The "Pulse" Card (Hero Goal) ──────────────────────────
                  _PulseCard(completedCount: todaysExercises, goal: dailyGoal)
                      .animate()
                      .fade(duration: 500.ms, delay: 100.ms)
                      .slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 20),

                  // ── Bento Grid: Metrics ───────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child:
                            _BentoCard(
                                  title: 'Streak',
                                  value: '$streak',
                                  unit: 'Days',
                                  icon: LucideIcons.flame,
                                  color: AppColors.warning, // Orange/Rose
                                )
                                .animate()
                                .fade(duration: 500.ms, delay: 200.ms)
                                .slideY(begin: 0.1, end: 0),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child:
                            _BentoCard(
                                  title: 'Movement',
                                  value: '$points',
                                  unit: 'Pts',
                                  icon: LucideIcons.activity,
                                  color: AppColors.primary,
                                )
                                .animate()
                                .fade(duration: 500.ms, delay: 300.ms)
                                .slideY(begin: 0.1, end: 0),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Bento Grid: Weekly Progress Graph ─────────────────────
                  GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/history'),
                        child: const _ActivityGraphCard(),
                      )
                      .animate()
                      .fade(duration: 500.ms, delay: 400.ms)
                      .slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 28),

                  // ── Primary Call To Action (Focus Mode) ───────────────────
                  Text(
                    'Quick Start',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ).animate().fade(delay: 500.ms),
                  const SizedBox(height: 14),
                  _PrimaryAction(
                        title: isConnected ? 'Start Workout' : 'Connect Sensor',
                        subtitle: isConnected
                            ? 'Enter focus mode'
                            : 'Pair to track movement',
                        icon: isConnected
                            ? LucideIcons.play
                            : LucideIcons.bluetooth,
                        isConnected: isConnected,
                        onTap: () {
                          if (isConnected) {
                            Navigator.pushNamed(context, '/exercise_menu');
                          } else {
                            Navigator.pushNamed(context, '/bluetooth_connect');
                          }
                        },
                      )
                      .animate()
                      .fade(duration: 500.ms, delay: 600.ms)
                      .slideY(begin: 0.1, end: 0),

                  // ── Recent Sessions List ──
                  if (history.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    Text(
                      'Recent Sessions',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ).animate().fade(delay: 500.ms),
                    const SizedBox(height: 16),
                    ...history
                        .take(5)
                        .map((session) => _SessionListTile(session: session)),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── The "Pulse" Card (Today's Goal) ──────────────────────────────────────
class _PulseCard extends StatelessWidget {
  final int completedCount;
  final int goal;

  const _PulseCard({required this.completedCount, required this.goal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calculate progress fraction & percentage
    final double progressStr = (completedCount / goal).clamp(0.0, 1.0);
    final int displayPercent = (progressStr * 100).toInt();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.textPrimary, // Slate 900
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Today\'s Goal',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$displayPercent',
                    style: theme.textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                      fontSize: 48,
                      height: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6, left: 4),
                    child: Text(
                      '%',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                displayPercent >= 100
                    ? 'Goal Achieved! Amazing work.'
                    : displayPercent == 0
                    ? 'Start your first session!'
                    : 'Almost there! Keep moving.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),

          // Apple Watch style ring wrapper
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 8,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                CircularProgressIndicator(
                  value: progressStr,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                  color: AppColors.accent, // Sage / Emerald
                ).animate().custom(
                  duration: 1.seconds,
                  builder: (context, value, child) {
                    return CircularProgressIndicator(
                      value: progressStr * value,
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                      color: AppColors.accent,
                    );
                  },
                ),
                Center(
                  child:
                      const Icon(
                            LucideIcons.target,
                            color: Colors.white,
                            size: 28,
                          )
                          .animate(
                            onPlay: (controller) =>
                                controller.repeat(reverse: true),
                          )
                          .scaleXY(end: 1.1, duration: 1.seconds),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bento Card ───────────────────────────────────────────────────────────
class _BentoCard extends StatelessWidget {
  final String title, value, unit;
  final IconData icon;
  final Color color;

  const _BentoCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.greyLight, width: 1),
        boxShadow: AppTheme.softShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Activity Graph Bento ──────────────────────────────────────────────────
class _ActivityGraphCard extends StatelessWidget {
  const _ActivityGraphCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Original motivating mock data
    List<FlSpot> mockData = const [
      FlSpot(0, 20),
      FlSpot(1, 45),
      FlSpot(2, 35),
      FlSpot(3, 80),
      FlSpot(4, 60),
      FlSpot(5, 90),
      FlSpot(6, 75),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.greyLight, width: 1),
        boxShadow: AppTheme.softShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Progress',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Icon(
                LucideIcons.trendingUp,
                color: AppColors.primary,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 100,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: mockData,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 4,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ],
                minY: 0,
                maxY: 100,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Primary Action Card ───────────────────────────────────────────────────
class _PrimaryAction extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final bool isConnected;
  final VoidCallback onTap;

  const _PrimaryAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isConnected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isConnected ? AppColors.primary : AppColors.textPrimary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                LucideIcons.chevronRight,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
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
