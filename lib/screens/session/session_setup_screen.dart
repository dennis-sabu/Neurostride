import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/session_provider.dart';

class SessionSetupScreen extends ConsumerStatefulWidget {
  const SessionSetupScreen({super.key});

  @override
  ConsumerState<SessionSetupScreen> createState() => _SessionSetupScreenState();
}

class _SessionSetupScreenState extends ConsumerState<SessionSetupScreen> {
  bool _calibrated = false;
  bool _calibrating = false;

  Future<void> _runCalibration() async {
    setState(() => _calibrating = true);
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      setState(() {
        _calibrating = false;
        _calibrated = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(appSettingsProvider);
    final patientName = settings.selectedPatientName ?? 'Unknown Patient';
    final isMock = settings.isMockMode;

    return Scaffold(
      appBar: AppBar(title: const Text('Session Setup')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Patient Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Patient', style: theme.textTheme.bodySmall),
                          Text(
                            patientName,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Mode selector
              Text(
                'Data Source',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _ModeToggle(isMock: isMock),
              const SizedBox(height: 28),

              // Sensor calibration
              Text(
                'Sensor Calibration',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _calibrated
                        ? theme.colorScheme.secondary.withValues(alpha: 0.4)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _calibrated
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: _calibrated
                              ? theme.colorScheme.secondary
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.35,
                                ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _calibrated
                              ? 'Calibration Complete'
                              : 'Not Calibrated',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: _calibrated
                                ? theme.colorScheme.secondary
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (!_calibrated) ...[
                      const SizedBox(height: 14),
                      Text(
                        'Ask the patient to stand still and level the sensor. Then tap Calibrate.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: _calibrating ? null : _runCalibration,
                        child: _calibrating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('CALIBRATE SENSOR'),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Start CTA
              ElevatedButton(
                onPressed: _calibrated
                    ? () {
                        ref.read(liveSessionProvider.notifier).reset();
                        ref.read(liveSessionProvider.notifier).startSession();
                        Navigator.pushNamed(context, '/live_session');
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  disabledBackgroundColor: theme.colorScheme.onSurface
                      .withValues(alpha: 0.12),
                ),
                child: const Text('START SESSION'),
              ),
              const SizedBox(height: 12),
              if (!_calibrated)
                Center(
                  child: Text(
                    'Complete calibration to start',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
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

class _ModeToggle extends ConsumerWidget {
  final bool isMock;
  const _ModeToggle({required this.isMock});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          _ModeOption(
            selected: isMock,
            icon: Icons.developer_mode,
            title: 'Mock / Demo Mode',
            subtitle: 'Simulated realistic gait data',
            onTap: () =>
                ref.read(appSettingsProvider.notifier).setMockMode(true),
          ),
          Divider(
            height: 1,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
          ),
          _ModeOption(
            selected: !isMock,
            icon: Icons.bluetooth,
            title: 'Live BLE Mode',
            subtitle: 'Data from ESP32 Bluetooth sensor',
            onTap: () =>
                ref.read(appSettingsProvider.notifier).setMockMode(false),
          ),
        ],
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const _ModeOption({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.35),
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}
