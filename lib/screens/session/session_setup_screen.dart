import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/bluetooth_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/gait_provider.dart';

class SessionSetupScreen extends ConsumerStatefulWidget {
  const SessionSetupScreen({super.key});

  @override
  ConsumerState<SessionSetupScreen> createState() => _SessionSetupScreenState();
}

class _SessionSetupScreenState extends ConsumerState<SessionSetupScreen> {
  bool _calibrated = false;
  bool _calibrating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final btState = ref.read(bluetoothProvider);

      // Only connect if NOT already connected
      if (!btState.isConnected) {
        // Show warning but do NOT auto-connect here
        // User can start session setup regardless
      }
      // If already connected → do nothing, just show screen
    });
  }

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

  void _startSession() {
    final btState = ref.read(bluetoothProvider);
    if (!btState.isConnected) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("No Sensor Connected"),
          content: const Text(
            "Session will run without live sensor data.\nDo you want to continue?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, '/bluetooth_connect');
              },
              child: const Text("CONNECT SENSOR"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _continueStartSession();
              },
              child: const Text("CONTINUE ANYWAY"),
            ),
          ],
        ),
      );
      return;
    }
    _continueStartSession();
  }

  void _continueStartSession() {
    final stream = ref.read(gaitStreamProvider);
    ref.read(liveSessionProvider.notifier).reset();
    ref.read(liveSessionProvider.notifier).startSession(dataStream: stream);
    Navigator.pushNamed(context, '/live_session');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(appSettingsProvider);
    final patientName = settings.selectedPatientName ?? 'Unknown Patient';
    final btState = ref.watch(bluetoothProvider);

    // START SESSION is enabled when calibrated
    final isConnected = btState.isConnected;
    final canStart = _calibrated;

    return Scaffold(
      appBar: AppBar(title: const Text('Session Setup')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Patient Banner ──────────────────────────────────────
              _PatientBanner(patientName: patientName),
              const SizedBox(height: 16),

              // Connection Status Banner
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: isConnected
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isConnected ? Colors.green : Colors.orange,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isConnected
                          ? Icons.check_circle
                          : Icons.warning_amber_rounded,
                      color: isConnected ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isConnected
                            ? "Sensor Connected ✓"
                            : "Sensor not connected — Exercise scoring unavailable",
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: isConnected ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (!isConnected) ...[
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/bluetooth_connect'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text("CONNECT"),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Bluetooth Panel ────────────────────────────────────
              _BluetoothPanel(btState: btState),
              const SizedBox(height: 20),

              // ── Sensor Calibration ──────────────────────────────────
              Text(
                'Sensor Calibration',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _CalibrationCard(
                calibrated: _calibrated,
                calibrating: _calibrating,
                onCalibrate: () {
                  if (!isConnected) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "No sensor connected. Tap CONNECT to pair sensor.",
                        ),
                      ),
                    );
                    return;
                  }
                  _runCalibration();
                },
              ),
              const SizedBox(height: 40),

              // ── Start CTA ───────────────────────────────────────────
              ElevatedButton(
                onPressed: canStart ? _startSession : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  disabledBackgroundColor: theme.colorScheme.onSurface
                      .withValues(alpha: 0.12),
                ),
                child: const Text('START SESSION'),
              ),
              const SizedBox(height: 12),
              if (!canStart)
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

// ── Bluetooth Panel ──────────────────────────────────────────────────────────
class _BluetoothPanel extends ConsumerWidget {
  final BluetoothState btState;
  const _BluetoothPanel({required this.btState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isConnected = btState.isConnected;
    final isScanning = btState.status == BluetoothConnectionStatus.scanning;
    final isConnecting = btState.status == BluetoothConnectionStatus.connecting;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isConnected
              ? Colors.green.withValues(alpha: 0.5)
              : theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                Icon(
                  isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                  color: isConnected ? Colors.green : theme.colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bluetooth Sensor',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isConnected
                            ? '✓ Connected: ${btState.connectedDeviceName}'
                            : isConnecting
                            ? 'Connecting…'
                            : isScanning
                            ? 'Searching for devices…'
                            : 'Not connected',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isConnected
                              ? Colors.green
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.55,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Scan / Stop / Disconnect button
                if (isConnected)
                  TextButton.icon(
                    onPressed: () =>
                        ref.read(bluetoothProvider.notifier).disconnect(),
                    icon: const Icon(Icons.link_off, size: 16),
                    label: const Text('Disconnect'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade400,
                    ),
                  )
                else if (isScanning || isConnecting)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  TextButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/bluetooth_connect'),
                    icon: const Icon(Icons.bluetooth, size: 16),
                    label: const Text('Connect'),
                  ),
              ],
            ),
          ),

          // Error message
          if (btState.errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
              child: Text(
                btState.errorMessage!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.red.shade400,
                ),
              ),
            ),

          // Device list (only when scanning or devices found)
          if (!isConnected && (btState.availableDevices.isNotEmpty)) ...[
            Divider(
              height: 1,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.07),
            ),
            _DeviceSectionHeader(label: 'DEVICES'),
            ...btState.availableDevices.map(
              (d) => _DeviceTile(
                name: d.name ?? 'Unknown',
                address: d.address,
                isPaired: true, // simplified for ui
                onTap: () => Navigator.pushNamed(context, '/bluetooth_connect'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _DeviceSectionHeader extends StatelessWidget {
  final String label;
  const _DeviceSectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          letterSpacing: 1.2,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final String name;
  final String address;
  final bool isPaired;
  final VoidCallback onTap;
  const _DeviceTile({
    required this.name,
    required this.address,
    required this.isPaired,
    required this.onTap,
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
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Row(
          children: [
            Icon(
              isPaired ? Icons.bluetooth : Icons.bluetooth_searching,
              color: isEsp
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.45),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isEsp ? FontWeight.bold : FontWeight.normal,
                      color: isEsp
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
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

// ── Patient Banner ────────────────────────────────────────────────────────────
class _PatientBanner extends StatelessWidget {
  final String patientName;
  const _PatientBanner({required this.patientName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
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
            child: const Icon(Icons.person, color: Colors.white, size: 24),
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
    );
  }
}

// ── Calibration Card ──────────────────────────────────────────────────────────
class _CalibrationCard extends StatelessWidget {
  final bool calibrated;
  final bool calibrating;
  final VoidCallback onCalibrate;
  const _CalibrationCard({
    required this.calibrated,
    required this.calibrating,
    required this.onCalibrate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: calibrated
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
                calibrated ? Icons.check_circle : Icons.radio_button_unchecked,
                color: calibrated
                    ? theme.colorScheme.secondary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.35),
              ),
              const SizedBox(width: 12),
              Text(
                calibrated ? 'Calibration Complete' : 'Not Calibrated',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: calibrated
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (!calibrated) ...[
            const SizedBox(height: 14),
            Text(
              'Ask the patient to stand still and level the sensor. Then tap Calibrate.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: calibrating ? null : onCalibrate,
              child: calibrating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('CALIBRATE SENSOR'),
            ),
          ],
        ],
      ),
    );
  }
}
