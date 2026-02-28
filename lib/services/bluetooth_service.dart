import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/gait_provider.dart';

/// Wraps flutter_bluetooth_serial for NuroStride ESP32 connectivity.
/// The ESP32 sends lines like: "S1:12.50,S2:45.60,KNEE:33.10\n"
class NuroBluetoothService {
  static final NuroBluetoothService _instance =
      NuroBluetoothService._internal();
  factory NuroBluetoothService() => _instance;
  NuroBluetoothService._internal();

  BluetoothConnection? _connection;
  final StreamController<GaitData> _gaitController =
      StreamController<GaitData>.broadcast();

  StringBuffer _buffer = StringBuffer();

  /// Currently connected device name, or null.
  String? get connectedDeviceName =>
      _connection?.isConnected == true ? _connectedDeviceName : null;
  String? _connectedDeviceName;

  bool get isConnected => _connection?.isConnected ?? false;

  // ── Permissions ────────────────────────────────────────────────────────

  /// Requests all Bluetooth permissions needed at runtime.
  /// Returns `true` if all required permissions are granted.
  Future<bool> requestPermissions() async {
    if (!Platform.isAndroid) return true;

    // Android 12+ (API 31+): need BLUETOOTH_SCAN + BLUETOOTH_CONNECT
    // Android ≤11: need ACCESS_FINE_LOCATION for Classic BT discovery
    final permissionsToRequest = <Permission>[
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ];

    debugPrint('[NuroBT] Requesting permissions: $permissionsToRequest');

    final statuses = await permissionsToRequest.request();

    // Log each status
    statuses.forEach((perm, status) {
      debugPrint('[NuroBT] $perm → $status');
    });

    // Check that critical permissions are granted
    final scanOk = statuses[Permission.bluetoothScan]?.isGranted ?? false;
    final connectOk = statuses[Permission.bluetoothConnect]?.isGranted ?? false;
    final locationOk = statuses[Permission.location]?.isGranted ?? false;

    // On Android 12+, scan + connect are essential; on older, location is essential
    if (scanOk && connectOk) return true;
    if (locationOk) return true; // fallback for Android ≤11

    debugPrint('[NuroBT] Permissions NOT fully granted');
    return false;
  }

  /// Ensures Bluetooth adapter is turned on. Returns true if enabled.
  Future<bool> ensureBluetoothEnabled() async {
    try {
      final isEnabled =
          await FlutterBluetoothSerial.instance.isEnabled ?? false;
      if (isEnabled) return true;

      debugPrint('[NuroBT] Bluetooth is off, requesting enable...');
      final result =
          await FlutterBluetoothSerial.instance.requestEnable() ?? false;
      debugPrint('[NuroBT] Bluetooth enable result: $result');
      return result;
    } catch (e) {
      debugPrint('[NuroBT] Error checking/enabling Bluetooth: $e');
      return false;
    }
  }

  // ── Device Discovery ──────────────────────────────────────────────────

  /// Returns paired Bluetooth devices. On Android, Classic BT devices that
  /// have been previously paired show up here without needing a scan.
  Future<List<BluetoothDevice>> getPairedDevices() async {
    try {
      debugPrint('[NuroBT] Getting bonded/paired devices...');
      final devices = await FlutterBluetoothSerial.instance.getBondedDevices();
      debugPrint('[NuroBT] Found ${devices.length} paired devices:');
      for (final d in devices) {
        debugPrint('[NuroBT]   - ${d.name} (${d.address})');
      }
      return devices;
    } catch (e) {
      debugPrint('[NuroBT] Error getting paired devices: $e');
      return [];
    }
  }

  /// Starts discovery of nearby (non-paired) Bluetooth devices.
  /// Returns a stream of discovered devices. Call `stopDiscovery()` when done.
  Stream<BluetoothDiscoveryResult> startDiscovery() {
    debugPrint('[NuroBT] Starting device discovery...');
    return FlutterBluetoothSerial.instance.startDiscovery();
  }

  Future<void> stopDiscovery() async {
    debugPrint('[NuroBT] Stopping discovery');
    await FlutterBluetoothSerial.instance.cancelDiscovery();
  }

  // ── Connection ────────────────────────────────────────────────────────

  /// Connect to a given BluetoothDevice. Throws on failure.
  Future<void> connect(BluetoothDevice device) async {
    await disconnect(); // clean up any existing connection
    debugPrint('[NuroBT] Connecting to ${device.name} (${device.address})...');

    // Add a 15-second timeout so it doesn't hang forever
    _connection = await BluetoothConnection.toAddress(device.address).timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw TimeoutException(
          'Connection timed out after 15 seconds',
          const Duration(seconds: 15),
        );
      },
    );

    _connectedDeviceName = device.name ?? device.address;
    _buffer = StringBuffer();
    debugPrint('[NuroBT] Connected to $_connectedDeviceName');
    _listenToStream();
  }

  void _listenToStream() {
    _connection?.input?.listen(
      (data) {
        final chunk = utf8.decode(data);
        _buffer.write(chunk);
        final buffered = _buffer.toString();
        final lines = buffered.split('\n');

        // All complete lines (everything except last element)
        for (int i = 0; i < lines.length - 1; i++) {
          final line = lines[i].trim();
          if (line.isNotEmpty) {
            final gait = _parseLine(line);
            if (gait != null) _gaitController.add(gait);
          }
        }

        // Keep incomplete line in buffer
        _buffer = StringBuffer(lines.last);
      },
      onDone: () {
        debugPrint('[NuroBT] Connection stream done');
        _connectedDeviceName = null;
        _connection = null;
      },
      onError: (e) {
        debugPrint('[NuroBT] Connection stream error: $e');
        _connectedDeviceName = null;
        _connection = null;
      },
    );
  }

  /// Disconnect from current device.
  Future<void> disconnect() async {
    debugPrint('[NuroBT] Disconnecting...');
    await _connection?.close();
    _connection = null;
    _connectedDeviceName = null;
    _buffer = StringBuffer();
  }

  // ── Data Parsing ──────────────────────────────────────────────────────

  /// Parses "S1:12.50,S2:45.60,KNEE:33.10" into GaitData.
  GaitData? _parseLine(String line) {
    try {
      final parts = line.split(',');
      if (parts.length < 3) return null;

      double? s1, s2, knee;
      String stab = "Good"; // default

      for (final part in parts) {
        final kv = part.split(':');
        if (kv.length != 2) continue;

        final key = kv[0].trim().toUpperCase();
        final rawVal = kv[1].trim();

        if (key == 'STAB') {
          stab = rawVal;
          continue;
        }

        final val = double.tryParse(rawVal);
        if (val == null) continue;

        if (key == 'S1') s1 = val;
        if (key == 'S2') s2 = val;
        if (key == 'KNEE') knee = val;
      }

      if (s1 == null || s2 == null || knee == null) return null;

      // S1 = thigh (leftKneeFlexion proxy), S2 = shin (rightKneeFlexion proxy)
      // KNEE = main knee flexion angle
      return GaitData(
        leftKneeFlexion: s1,
        rightKneeFlexion: s2,
        leftHipExtension: s1 * 0.4,
        rightHipExtension: s2 * 0.4,
        cadence: 95.0, // Not directly sent; use default until ESP32 sends it
        leftStepDuration: 0.6,
        rightStepDuration: 0.6,
        stepDetected: false,
        accelX: 0.0,
        accelY: 0.0,
        accelZ: 1.0,
        pitch: knee, // Store KNEE angle in pitch for display
        roll: 0.0,
        yaw: 0.0,
        kneeAngle: knee,
        stabilityLevel: stab,
      );
    } catch (_) {
      return null;
    }
  }

  // ── Stream ────────────────────────────────────────────────────────────

  /// Live stream of parsed GaitData from the connected ESP32.
  Stream<GaitData> get gaitStream => _gaitController.stream;

  void dispose() {
    disconnect();
    _gaitController.close();
  }
}
