import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nurostride_app/core/permissions/permission_handler.dart';

enum BluetoothConnectionStatus {
  disconnected,
  scanning,
  connecting,
  connected,
  failed,
}

class BluetoothState {
  final BluetoothConnectionStatus status;
  final String? connectedDeviceName;
  final List<BluetoothDevice> availableDevices;
  final String? errorMessage;
  final bool isBluetoothEnabled;

  const BluetoothState({
    this.status = BluetoothConnectionStatus.disconnected,
    this.connectedDeviceName,
    this.availableDevices = const [],
    this.errorMessage,
    this.isBluetoothEnabled = false,
  });

  bool get isConnected => status == BluetoothConnectionStatus.connected;
  bool get isScanning => status == BluetoothConnectionStatus.scanning;

  BluetoothState copyWith({
    BluetoothConnectionStatus? status,
    String? connectedDeviceName,
    bool clearDeviceName = false,
    List<BluetoothDevice>? availableDevices,
    String? errorMessage,
    bool clearError = false,
    bool? isBluetoothEnabled,
  }) {
    return BluetoothState(
      status: status ?? this.status,
      connectedDeviceName: clearDeviceName
          ? null
          : (connectedDeviceName ?? this.connectedDeviceName),
      availableDevices: availableDevices ?? this.availableDevices,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isBluetoothEnabled: isBluetoothEnabled ?? this.isBluetoothEnabled,
    );
  }
}

class BluetoothNotifier extends Notifier<BluetoothState> {
  StreamSubscription<BluetoothDiscoveryResult>? _discoverySub;
  BluetoothConnection? _connection;
  StreamSubscription<Uint8List>? _dataSub;

  final _dataController = StreamController<String>.broadcast();
  Stream<String> get dataStream => _dataController.stream;

  @override
  BluetoothState build() {
    // Initial check
    checkBluetoothEnabled();

    ref.onDispose(() {
      _discoverySub?.cancel();
      _dataSub?.cancel();
      _connection?.dispose();
      _dataController.close();
    });

    return const BluetoothState();
  }

  Future<void> checkBluetoothEnabled() async {
    try {
      final isEnabled =
          await FlutterBluetoothSerial.instance.isEnabled ?? false;
      state = state.copyWith(isBluetoothEnabled: isEnabled);

      if (!isEnabled) {
        // Will prompt natively if requested, but checking state doesn't prompt automatically
        // using requestEnable() to actually prompt
      }
    } catch (e) {
      state = state.copyWith(isBluetoothEnabled: false);
    }
  }

  Future<void> requestEnable() async {
    try {
      await FlutterBluetoothSerial.instance.requestEnable();
      await checkBluetoothEnabled();
    } catch (e) {
      // User cancelled or failed
      state = state.copyWith(isBluetoothEnabled: false);
    }
  }

  Future<void> startScan() async {
    if (state.isConnected) return;
    if (state.isScanning) return;

    // Step 1: Check permissions first
    final hasPermission =
        await AppPermissionHandler.requestBluetoothPermissions();

    if (!hasPermission) {
      state = state.copyWith(
        status: BluetoothConnectionStatus.failed,
        errorMessage: "Bluetooth permission denied",
      );
      return;
    }

    // Step 2: Check Bluetooth is enabled
    final isEnabled = await FlutterBluetoothSerial.instance.isEnabled ?? false;

    if (!isEnabled) {
      await FlutterBluetoothSerial.instance.requestEnable();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // After requesting enable, check again
    final isStillEnabled =
        await FlutterBluetoothSerial.instance.isEnabled ?? false;
    if (!isStillEnabled) {
      state = state.copyWith(
        status: BluetoothConnectionStatus.failed,
        errorMessage: 'Bluetooth is OFF',
      );
      return;
    }

    // Step 3: NOW safe to scan
    state = state.copyWith(
      status: BluetoothConnectionStatus.scanning,
      availableDevices: [],
      clearError: true,
    );

    try {
      // First get bonded devices
      final bondedDevices = await FlutterBluetoothSerial.instance
          .getBondedDevices();
      final List<BluetoothDevice> allDevices = List.from(bondedDevices);

      state = state.copyWith(availableDevices: allDevices);

      await _discoverySub?.cancel();
      _discoverySub = FlutterBluetoothSerial.instance.startDiscovery().listen(
        (result) {
          final currentMap = {
            for (var d in state.availableDevices) d.address: d,
          };
          if (!currentMap.containsKey(result.device.address)) {
            final updated = List<BluetoothDevice>.from(state.availableDevices)
              ..add(result.device);
            state = state.copyWith(availableDevices: updated);
          }

          // Auto-detect NuroStride_ESP32
          if (result.device.name == 'NuroStride_ESP32' &&
              state.status == BluetoothConnectionStatus.scanning) {
            connectToDevice(result.device);
          }
        },
        onDone: () {
          if (state.status == BluetoothConnectionStatus.scanning) {
            state = state.copyWith(
              status: BluetoothConnectionStatus.disconnected,
            );
          }
        },
        onError: (e) {
          state = state.copyWith(
            status: BluetoothConnectionStatus.failed,
            errorMessage: e.toString(),
          );
        },
      );

      // Also check bonded devices immediately
      for (var device in bondedDevices) {
        if (device.name == 'NuroStride_ESP32' &&
            state.status == BluetoothConnectionStatus.scanning) {
          connectToDevice(device);
          break;
        }
      }
    } catch (e) {
      state = state.copyWith(
        status: BluetoothConnectionStatus.failed,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    await stopScan();

    if (!device.isBonded) {
      state = state.copyWith(
        status: BluetoothConnectionStatus.failed,
        errorMessage:
            'Please pair NuroStride_ESP32 in your\nphone Bluetooth settings first',
      );
      return;
    }

    state = state.copyWith(
      status: BluetoothConnectionStatus.connecting,
      errorMessage: 'Connecting...',
    );

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      // Connect with a strict 5-second timeout
      _connection = await BluetoothConnection.toAddress(
        device.address,
      ).timeout(const Duration(seconds: 5));

      state = state.copyWith(
        status: BluetoothConnectionStatus.connected,
        connectedDeviceName: device.name ?? device.address,
        clearError: true,
      );

      listenForDisconnection();
      return; // Success, exit method
    } on TimeoutException {
      state = state.copyWith(
        status: BluetoothConnectionStatus.failed,
        errorMessage:
            'Connection timed out after 5 seconds.\nPlease try again.',
      );
    } on PlatformException catch (e) {
      if (e.code == 'connect_error') {
        state = state.copyWith(
          status: BluetoothConnectionStatus.failed,
          errorMessage:
              'Could not reach sensor. Make sure ESP32 is on and nearby.',
        );
      } else {
        state = state.copyWith(
          status: BluetoothConnectionStatus.failed,
          errorMessage:
              'Connection failed: ${e.message ?? 'Unknown error'}\nPlease try again.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: BluetoothConnectionStatus.failed,
        errorMessage: 'Connection failed.\nPlease try again.',
      );
    }
  }

  Future<void> autoConnect() async {
    if (state.isConnected) return;
    if (state.isScanning) return;

    try {
      final hasPermission =
          await AppPermissionHandler.requestBluetoothPermissions();
      if (!hasPermission) return;

      final isEnabled =
          await FlutterBluetoothSerial.instance.isEnabled ?? false;
      if (isEnabled && state.status != BluetoothConnectionStatus.connected) {
        startScan();
      }
    } catch (e) {
      state = state.copyWith(
        status: BluetoothConnectionStatus.failed,
        errorMessage: 'AutoConnect failed: $e',
      );
    }
  }

  Future<void> stopScan() async {
    await _discoverySub?.cancel();
    if (state.status == BluetoothConnectionStatus.scanning) {
      state = state.copyWith(status: BluetoothConnectionStatus.disconnected);
    }
  }

  Future<void> disconnect() async {
    await stopScan();
    await _dataSub?.cancel();
    await _connection?.close();
    _connection = null;

    state = state.copyWith(
      status: BluetoothConnectionStatus.disconnected,
      clearDeviceName: true,
      clearError: true,
    );
  }

  String _buffer = '';

  void listenForDisconnection() {
    _dataSub?.cancel();
    _buffer = ''; // ✅ always clear stale bytes before starting a new stream
    _dataSub = _connection?.input?.listen(
      (Uint8List data) {
        final stringData = String.fromCharCodes(data);
        _buffer += stringData;

        while (_buffer.contains('\n')) {
          final index = _buffer.indexOf('\n');
          final line = _buffer.substring(0, index).trim();
          _buffer = _buffer.substring(index + 1);

          if (line.isNotEmpty) {
            _dataController.add(line);
          }
        }
      },
      onDone: () {
        // Disconnected remotely
        state = state.copyWith(
          status: BluetoothConnectionStatus.disconnected,
          clearDeviceName: true,
          errorMessage: 'Sensor disconnected unexpectedly',
        );
      },
      onError: (e) {
        state = state.copyWith(
          status: BluetoothConnectionStatus.disconnected,
          clearDeviceName: true,
          errorMessage: 'Connection error: $e',
        );
      },
    );
  }
}

final bluetoothProvider = NotifierProvider<BluetoothNotifier, BluetoothState>(
  BluetoothNotifier.new,
);
