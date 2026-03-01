import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart'
    hide BluetoothState;
import '../../providers/bluetooth_provider.dart';

class BluetoothConnectScreen extends ConsumerStatefulWidget {
  const BluetoothConnectScreen({super.key});

  @override
  ConsumerState<BluetoothConnectScreen> createState() =>
      _BluetoothConnectScreenState();
}

class _BluetoothConnectScreenState extends ConsumerState<BluetoothConnectScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Wait for screen to fully build first
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        ref.read(bluetoothProvider.notifier).startScan();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final btState = ref.watch(bluetoothProvider);
    final isConnected = btState.isConnected;
    final isScanning = btState.status == BluetoothConnectionStatus.scanning;
    final isConnecting = btState.status == BluetoothConnectionStatus.connecting;
    final isFailed = btState.status == BluetoothConnectionStatus.failed;

    // Handle auto-navigation on success
    ref.listen<BluetoothState>(bluetoothProvider, (previous, next) {
      if (previous?.status != BluetoothConnectionStatus.connected &&
          next.status == BluetoothConnectionStatus.connected) {
        Future.delayed(const Duration(seconds: 1), () {
          if (!context.mounted) return;
          Navigator.pushReplacementNamed(context, '/exercise_menu');
        });
      }
    });

    String statusText = 'Not Connected';
    String subStatusText = 'Tap scan to search for your sensor';
    if (isScanning) {
      statusText = 'Looking for NuroStride...';
      subStatusText = 'Please keep your sensor nearby';
    } else if (isConnecting) {
      statusText = 'Connecting...';
      subStatusText = 'Establishing connection';
    } else if (isConnected) {
      statusText = 'Connected!';
      subStatusText = 'Ready for exercise';
    } else if (isFailed) {
      statusText = 'Connection Failed';
      subStatusText = 'Please try again';
    } else if (!btState.isBluetoothEnabled) {
      statusText = 'Bluetooth is OFF';
      subStatusText = 'Please enable Bluetooth to continue';
    } else if (btState.status == BluetoothConnectionStatus.disconnected &&
        btState.errorMessage == null) {
      statusText = 'Checking Permissions...';
      subStatusText = 'Requesting necessary access';
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Connect Sensor',
          style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
        backgroundColor: Colors.grey[50],
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Large icon area with animation
              Center(
                child: SizedBox(
                  height: 180,
                  width: 180,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isScanning || isConnecting)
                        ScaleTransition(
                          scale: _pulseAnimation,
                          child: Container(
                            height: 160,
                            width: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isConnected
                              ? Colors.green.withValues(alpha: 0.15)
                              : isFailed
                              ? Colors.red.withValues(alpha: 0.1)
                              : Colors.blue.withValues(alpha: 0.1),
                          border: Border.all(
                            color: isConnected
                                ? Colors.green.withValues(alpha: 0.4)
                                : isFailed
                                ? Colors.red.withValues(alpha: 0.3)
                                : Colors.blue.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: isConnected
                                ? const Icon(
                                    Icons.check_rounded,
                                    size: 60,
                                    color: Colors.green,
                                    key: ValueKey('connected'),
                                  )
                                : isFailed
                                ? const Icon(
                                    Icons.error_outline_rounded,
                                    size: 60,
                                    color: Colors.red,
                                    key: ValueKey('failed'),
                                  )
                                : const Icon(
                                    Icons.bluetooth_rounded,
                                    size: 50,
                                    color: Colors.blue,
                                    key: ValueKey('bluetooth'),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Status text
              Center(
                child: Column(
                  children: [
                    Text(
                      statusText,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subStatusText,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Error messages
              if (btState.errorMessage != null && isFailed)
                Flexible(
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            btState.errorMessage!,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          if (btState.errorMessage!.toLowerCase().contains(
                            'pair',
                          )) ...[
                            ElevatedButton.icon(
                              onPressed: () {
                                FlutterBluetoothSerial.instance.openSettings();
                              },
                              icon: const Icon(Icons.settings_bluetooth),
                              label: const Text('OPEN BLUETOOTH SETTINGS'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade50,
                                foregroundColor: Colors.red.shade700,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16,
                                ),
                              ),
                            ),
                          ] else ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "TROUBLESHOOTING TIPS:",
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const _ChecklistItem("ESP32 is powered on"),
                            const _ChecklistItem("You are within 5 meters"),
                            const _ChecklistItem(
                              "ESP32 is not connected to another device",
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

              // Device List
              if (btState.availableDevices.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
                    child: Text(
                      'AVAILABLE DEVICES',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: btState.availableDevices.length,
                    itemBuilder: (context, index) {
                      final device = btState.availableDevices[index];
                      final isTarget = device.name == 'NuroStride_ESP32';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: isTarget
                              ? Border.all(
                                  color: Colors.blue.shade200,
                                  width: 2,
                                )
                              : Border.all(
                                  color: Colors.grey.shade100,
                                  width: 1,
                                ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              ref
                                  .read(bluetoothProvider.notifier)
                                  .connectToDevice(device);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isTarget
                                          ? Colors.blue.shade50
                                          : Colors.grey.shade50,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.bluetooth_rounded,
                                      color: isTarget
                                          ? Colors.blue.shade700
                                          : Colors.grey.shade500,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          device.name ?? 'Unknown Device',
                                          style: TextStyle(
                                            fontWeight: isTarget
                                                ? FontWeight.w700
                                                : FontWeight.w600,
                                            fontSize: 16,
                                            color: isTarget
                                                ? Colors.blue.shade900
                                                : Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          device.address,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: Colors.grey.shade300,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ] else if (btState.errorMessage == null && !isFailed)
                const Expanded(
                  child: Center(
                    child: Text(
                      "Searching for devices...",
                      style: TextStyle(color: Colors.black54, fontSize: 15),
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Action Buttons
              if (!btState.isBluetoothEnabled)
                ElevatedButton(
                  onPressed: () {
                    ref.read(bluetoothProvider.notifier).requestEnable();
                  },
                  style: _actionButtonStyle(Colors.blue),
                  child: const Text('ENABLE BLUETOOTH'),
                )
              else ...[
                if (isFailed)
                  ElevatedButton(
                    onPressed: () {
                      ref.read(bluetoothProvider.notifier).startScan();
                    },
                    style: _actionButtonStyle(Colors.blue),
                    child: const Text('TRY AGAIN'),
                  )
                else
                  ElevatedButton(
                    onPressed: isScanning || isConnecting
                        ? null
                        : () {
                            ref.read(bluetoothProvider.notifier).startScan();
                          },
                    style: _actionButtonStyle(Colors.blue),
                    child: Text(isScanning ? 'SCANNING...' : 'SCAN FOR SENSOR'),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  ButtonStyle _actionButtonStyle(Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      disabledBackgroundColor: Colors.grey.shade300,
      disabledForegroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 18),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  final String text;
  const _ChecklistItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Icon(Icons.circle, size: 6, color: Colors.red.shade400),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.red.shade700,
                height: 1.3,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
