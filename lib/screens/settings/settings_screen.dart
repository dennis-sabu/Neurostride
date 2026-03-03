import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/bluetooth_provider.dart';
import '../../providers/voice_coach_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final btState = ref.watch(bluetoothProvider);
    final voiceEnabled = ref.watch(voiceCoachProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Bluetooth Section ─────────────────────────────────────
            _SectionHeader('Bluetooth Sensor'),

            // Connected device card
            if (btState.isConnected) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.bluetooth_connected,
                      color: Colors.green,
                      size: 22,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            btState.connectedDeviceName ?? 'Unknown',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                          Text(
                            'Connected',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.green.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          ref.read(bluetoothProvider.notifier).disconnect(),
                      icon: const Icon(Icons.link_off, size: 16),
                      label: const Text('Disconnect'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              _SettingsTile(
                icon: Icons.bluetooth_searching,
                title: 'Scan for Devices',
                subtitle: btState.status == BluetoothConnectionStatus.scanning
                    ? 'Scanning…'
                    : btState.status == BluetoothConnectionStatus.failed
                    ? (btState.errorMessage ?? 'Error')
                    : 'Find & pair ESP32 sensor node',
                trailing: btState.status == BluetoothConnectionStatus.scanning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                onTap: () => ref.read(bluetoothProvider.notifier).startScan(),
              ),

              // Device list if scan returned results
              if (btState.availableDevices.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...btState.availableDevices.map(
                  (d) => _DeviceResultTile(
                    name: d.name ?? 'Unknown',
                    address: d.address,
                    onConnect: () =>
                        ref.read(bluetoothProvider.notifier).connectToDevice(d),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 20),

            // ── Voice Coach Section ───────────────────────────────────
            _SectionHeader('Exercise Coach'),
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.07),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    voiceEnabled
                        ? Icons.record_voice_over_rounded
                        : Icons.voice_over_off_rounded,
                    color: voiceEnabled
                        ? theme.colorScheme.primary.withValues(alpha: 0.7)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.35),
                    size: 22,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Voice Coach',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          voiceEnabled
                              ? 'Speaks coaching cues during exercise'
                              : 'Voice guidance is off',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: voiceEnabled,
                    onChanged: (_) =>
                        ref.read(voiceCoachProvider.notifier).toggle(),
                    activeColor: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── App Section ──────────────────────────────────────────
            _SectionHeader('Application'),
            _SettingsTile(
              icon: Icons.info_outline,
              title: 'About Nurostride',
              subtitle: 'Version 1.0.0',
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('About NuroStride'),
                    content: const Text(
                      'NuroStride is your personal fitness and rehabilitation tracking app.\n\n'
                      'It pairs via Bluetooth with the NuroStride ESP32 sensor to provide real-time gait analysis, '
                      'monitoring your walking patterns, cadence, and mobility symmetry.\n\n'
                      'The app also guides you through target-angle physiotherapy exercises, scoring your smoothness, '
                      'stability, and accuracy to help track your recovery journey seamlessly on your device.',
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
            _SettingsTile(
              icon: Icons.logout_rounded,
              title: 'Sign Out',
              subtitle: 'Return to login screen',
              onTap: () => Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (r) => false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _DeviceResultTile extends StatelessWidget {
  final String name;
  final String address;
  final VoidCallback onConnect;
  const _DeviceResultTile({
    required this.name,
    required this.address,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lowerName = name.toLowerCase();
    final isEsp =
        lowerName.contains('nurostride') ||
        lowerName.contains('esp32') ||
        lowerName.contains('esp_spp') ||
        lowerName.contains('hc-05') ||
        lowerName.contains('hc-06');
    return InkWell(
      onTap: onConnect,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isEsp
              ? theme.colorScheme.primary.withValues(alpha: 0.06)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEsp
                ? theme.colorScheme.primary.withValues(alpha: 0.3)
                : theme.colorScheme.onSurface.withValues(alpha: 0.07),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.bluetooth,
              size: 18,
              color: isEsp
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isEsp ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  Text(
                    address,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'CONNECT',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.bodySmall?.copyWith(
          letterSpacing: 1.5,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.07),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
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
            trailing ??
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
                  size: 18,
                ),
          ],
        ),
      ),
    );
  }
}
