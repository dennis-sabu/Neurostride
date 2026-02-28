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

class _BluetoothConnectScreenState
    extends ConsumerState<BluetoothConnectScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Wait for screen to fully build first
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        ref.read(bluetoothProvider.notifier).startScan();
      }
    });
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
          // Depending on where they came from...
          // "On connected → wait 1 second → navigate to /exercise_menu"
          // Wait, if they came from Live Exercise, they might want to pop.
          // But prompt says: "navigate to /exercise_menu".
          // We'll navigate back or replace. Wait, prompt says: "navigate to /exercise_menu"
          Navigator.pushReplacementNamed(context, '/exercise_menu');
        });
      }
    });

    String statusText = 'Not Connected';
    if (isScanning) {
      statusText = 'Looking for NuroStride Sensor...';
    } else if (isConnecting) {
      statusText = 'Connecting...';
    } else if (isConnected) {
      statusText = 'Connected!';
    } else if (isFailed) {
      statusText = 'Connection Failed';
    } else if (!btState.isBluetoothEnabled) {
      statusText = 'Bluetooth is OFF';
    } else if (btState.status == BluetoothConnectionStatus.disconnected &&
        btState.errorMessage == null) {
      statusText = 'Checking Permissions...';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Connect Sensor')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Large icon area
              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: isConnected
                      ? const Icon(
                          Icons.check_circle,
                          size: 100,
                          color: Colors.green,
                        )
                      : isScanning
                      ? const CircularProgressIndicator()
                      : Icon(
                          isFailed ? Icons.error : Icons.bluetooth,
                          size: 100,
                          color: Colors.blue,
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Status text
              Center(
                child: Text(
                  statusText,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),

              // Error messages
              if (btState.errorMessage != null && isFailed)
                Flexible(
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            btState.errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
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
                                backgroundColor: Colors.red.shade100,
                                foregroundColor: Colors.red.shade900,
                                elevation: 0,
                              ),
                            ),
                          ] else ...[
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "MAKE SURE:",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
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

              const SizedBox(height: 24),

              // Device List
              Expanded(
                child: Card(
                  child: ListView.builder(
                    itemCount: btState.availableDevices.length,
                    itemBuilder: (context, index) {
                      final device = btState.availableDevices[index];
                      final isTarget = device.name == 'NuroStride_ESP32';
                      return ListTile(
                        leading: Icon(
                          Icons.bluetooth,
                          color: isTarget ? Colors.blue : null,
                        ),
                        title: Text(
                          device.name ?? 'Unknown Device',
                          style: TextStyle(
                            fontWeight: isTarget
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isTarget ? Colors.blue : null,
                          ),
                        ),
                        subtitle: Text(device.address),
                        onTap: () {
                          ref
                              .read(bluetoothProvider.notifier)
                              .connectToDevice(device);
                        },
                      );
                    },
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
                  child: const Text('ENABLE BLUETOOTH'),
                )
              else ...[
                if (isFailed)
                  ElevatedButton(
                    onPressed: () {
                      ref.read(bluetoothProvider.notifier).startScan();
                    },
                    child: const Text('TRY AGAIN'),
                  )
                else
                  ElevatedButton(
                    onPressed: isScanning || isConnecting
                        ? null
                        : () {
                            ref.read(bluetoothProvider.notifier).startScan();
                          },
                    child: const Text('SCAN FOR SENSOR'),
                  ),
              ],
            ],
          ),
        ),
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
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6.0),
            child: Icon(Icons.circle, size: 6, color: Colors.red),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
