import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'bluetooth_provider.dart';
import 'sensor_data_provider.dart';

// ─── GaitData Model ────────────────────────────────────────────────────────
class GaitData {
  final double leftKneeFlexion;
  final double rightKneeFlexion;
  final double leftHipExtension;
  final double rightHipExtension;
  final double cadence; // Steps per minute
  final double leftStepDuration; // in seconds
  final double rightStepDuration; // in seconds
  final bool stepDetected;
  final String stabilityLevel;

  // Raw IMU data
  final double accelX;
  final double accelY;
  final double accelZ;
  final double pitch;
  final double roll;
  final double yaw;

  /// Main knee flexion angle (from ESP32 KNEE field)
  final double kneeAngle;

  // Optional Telemetry (Phase 0)
  final int? heartRate;
  final double? signalStrengthS1;
  final double? signalStrengthS2;
  final int? packetSequence;
  final DateTime timestamp;

  GaitData({
    required this.leftKneeFlexion,
    required this.rightKneeFlexion,
    required this.leftHipExtension,
    required this.rightHipExtension,
    required this.cadence,
    required this.leftStepDuration,
    required this.rightStepDuration,
    required this.stepDetected,
    required this.accelX,
    required this.accelY,
    required this.accelZ,
    required this.pitch,
    required this.roll,
    required this.yaw,
    required this.stabilityLevel,
    this.heartRate,
    this.signalStrengthS1,
    this.signalStrengthS2,
    this.packetSequence,
    DateTime? timestamp,
    double? kneeAngle,
  }) : kneeAngle = kneeAngle ?? ((leftKneeFlexion + rightKneeFlexion) / 2),
       timestamp = timestamp ?? DateTime.now();

  // Kinematic Symmetry %
  double get symmetry {
    double angleVariance =
        ((leftKneeFlexion + leftHipExtension) -
                (rightKneeFlexion + rightHipExtension))
            .abs();
    double timingVariance = (leftStepDuration - rightStepDuration).abs() * 100;
    double totalVariance = angleVariance + timingVariance;
    double symmetryPercent = 100.0 - totalVariance;
    return symmetryPercent.clamp(0.0, 100.0);
  }

  double get maxFlexionRange => max(leftKneeFlexion, rightKneeFlexion);

  double get mobilityScore {
    double sym = symmetry;
    double flexion = maxFlexionRange;
    double score =
        (sym * 0.4) +
        ((flexion / 90).clamp(0.0, 1.0) * 100 * 0.4) +
        ((cadence / 110).clamp(0.0, 1.0) * 100 * 0.2);
    return score.clamp(0.0, 100.0);
  }
}

// ─── Live Gait Stream Provider ────────────────────────────────────────────
/// Streams live GaitData from the connected ESP32 via Bluetooth.
/// The kneeAngle in each GaitData packet is offset-corrected so that the
/// user's standing position always reads as 0°.
final gaitStreamProvider = Provider<Stream<GaitData>>((ref) {
  final dataStream = ref.watch(bluetoothProvider.notifier).dataStream;
  final sensorNotifier = ref.watch(sensorDataProvider.notifier);
  return dataStream
      .map((line) => _parseLine(line, sensorNotifier.calibrationOffset))
      .where((gait) => gait != null)
      .cast<GaitData>();
});

final gaitDataProvider = StreamProvider<GaitData>((ref) {
  return ref.watch(gaitStreamProvider);
});

/// Parses "S1:12.50,S2:45.60,KNEE:33.10" into GaitData.
/// [calibrationOffset] is subtracted from the KNEE value so all downstream
/// consumers (exercise engine) work in standing-position-relative degrees.
GaitData? _parseLine(String line, [double calibrationOffset = 0.0]) {
  try {
    // Step 1: Clean the string
    // Remove \n, \r, spaces
    final clean = line
        .trim()
        .replaceAll('\n', '')
        .replaceAll('\r', '')
        .replaceAll(' ', '');

    // Step 2: Skip empty lines
    if (clean.isEmpty) return null;

    // Step 3: Split by comma
    final parts = clean.split(',');

    // Step 4: Must have 3 required keys (S1, S2, KNEE) — extra fields are OK
    // ✅ Check key presence, not part count — real ESP32 output may have
    // extra optional fields (CAD, STEP, HR, etc.) that would bump parts > 3.

    // Step 5: Build key-value map
    final Map<String, String> values = {};
    for (final part in parts) {
      final kv = part.split(':');
      if (kv.length == 2) {
        values[kv[0].trim().toUpperCase()] = kv[1].trim();
      }
    }

    // Step 6: Check required keys exist
    if (!values.containsKey('S1') ||
        !values.containsKey('S2') ||
        !values.containsKey('KNEE')) {
      // debugPrint('Missing keys in: $clean'); // Uncomment for debugging
      return null;
    }

    // Step 7: Parse values safely
    final s1 = double.tryParse(values['S1']!) ?? 0.0;
    final s2 = double.tryParse(values['S2']!) ?? 0.0;
    // Subtract the standing-position offset so 0° = standing rest
    final knee = (double.tryParse(values['KNEE']!) ?? 0.0) - calibrationOffset;
    final stab = values['STAB'] ?? 'Good';

    final hr = values.containsKey('HR') ? int.tryParse(values['HR']!) : null;
    final rssi1 = values.containsKey('RSSI1')
        ? double.tryParse(values['RSSI1']!)
        : null;
    final rssi2 = values.containsKey('RSSI2')
        ? double.tryParse(values['RSSI2']!)
        : null;
    final seq = values.containsKey('SEQ') ? int.tryParse(values['SEQ']!) : null;
    // ✅ Parse cadence and step fields when present
    final cadenceVal = values.containsKey('CAD')
        ? double.tryParse(values['CAD']!) ?? 95.0
        : 95.0;
    final stepVal = values.containsKey('STEP')
        ? (values['STEP'] == '1')
        : false;

    // Step 8: Return GaitData object
    return GaitData(
      leftKneeFlexion: s1,
      rightKneeFlexion: s2,
      kneeAngle: knee,
      stabilityLevel: stab,
      heartRate: hr,
      signalStrengthS1: rssi1,
      signalStrengthS2: rssi2,
      packetSequence: seq,
      timestamp: DateTime.now(),
      // Set other fields with defaults
      leftHipExtension: s1 * 0.4,
      rightHipExtension: s2 * 0.4,
      cadence: cadenceVal,
      leftStepDuration: 0.6,
      rightStepDuration: 0.6,
      stepDetected: stepVal,
      accelX: 0.0,
      accelY: 0.0,
      accelZ: 1.0,
      pitch: knee,
      roll: 0.0,
      yaw: 0.0,
    );
  } catch (e) {
    // debugPrint('Parse error: $e for line: $line');
    return null;
  }
}
