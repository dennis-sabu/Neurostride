import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/session_provider.dart';
import '../../providers/patient_provider.dart';
import '../../providers/app_settings_provider.dart';

class SessionSummaryScreen extends ConsumerWidget {
  const SessionSummaryScreen({super.key});

  String _fmt(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}m ${sec.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = ref.watch(liveSessionProvider);
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Summary'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Score badge
              Center(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                    border: Border.all(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.4),
                      width: 3,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        session.mobilityScore.toStringAsFixed(0),
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      Text(
                        '/ 100',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Mobility Index',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Stats grid
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.6,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _SummaryMetric(
                    label: 'DURATION',
                    value: _fmt(session.secondsElapsed),
                    icon: Icons.timer_outlined,
                  ),
                  _SummaryMetric(
                    label: 'STEPS',
                    value: '${session.stepCount}',
                    icon: Icons.directions_walk,
                  ),
                  _SummaryMetric(
                    label: 'PEAK ANGLE',
                    value: '${session.peakAngle.toStringAsFixed(1)}°',
                    icon: Icons.architecture,
                  ),
                  _SummaryMetric(
                    label: 'STABILITY',
                    value: session.stabilityLevel,
                    icon: Icons.balance,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Cadence full-width
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.07),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AVERAGE CADENCE',
                          style: theme.textTheme.bodySmall?.copyWith(
                            letterSpacing: 1,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.45,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${session.cadence.toStringAsFixed(0)} steps/min',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.speed,
                      size: 28,
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Save/Discard
              ElevatedButton(
                onPressed: () {
                  final patientId = settings.selectedPatientId;
                  if (patientId != null) {
                    ref
                        .read(patientListProvider.notifier)
                        .addSession(patientId, session.toPatientSession());
                  }
                  ref.read(liveSessionProvider.notifier).reset();
                  ref.read(appSettingsProvider.notifier).clearSelectedPatient();
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/dashboard',
                    (r) => false,
                  );
                },
                child: const Text('SAVE & FINISH'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  ref.read(liveSessionProvider.notifier).reset();
                  ref.read(appSettingsProvider.notifier).clearSelectedPatient();
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/dashboard',
                    (r) => false,
                  );
                },
                child: const Text('DISCARD SESSION'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
              Icon(
                icon,
                size: 18,
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
              ),
            ],
          ),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
