import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'bluetooth_provider.dart';

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
    double? kneeAngle,
  }) : kneeAngle = kneeAngle ?? ((leftKneeFlexion + rightKneeFlexion) / 2);

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
final gaitStreamProvider = Provider<Stream<GaitData>>((ref) {
  final dataStream = ref.watch(bluetoothProvider.notifier).dataStream;
  return dataStream
      .map((line) => _parseLine(line))
      .where((gait) => gait != null)
      .cast<GaitData>();
});

final gaitDataProvider = StreamProvider<GaitData>((ref) {
  return ref.watch(gaitStreamProvider);
});

/// Parses "S1:12.50,S2:45.60,KNEE:33.10" into GaitData.
GaitData? _parseLine(String line) {
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

    // Step 4: Must have at least 3 parts (S1, S2, KNEE)
    if (parts.length < 3) return null;

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
    final knee = double.tryParse(values['KNEE']!) ?? 0.0;
    final stab = values['STAB'] ?? 'Good';

    // Step 8: Return GaitData object
    return GaitData(
      leftKneeFlexion: s1,
      rightKneeFlexion: s2,
      kneeAngle: knee,
      stabilityLevel: stab,
      // Set other fields with defaults
      leftHipExtension: s1 * 0.4,
      rightHipExtension: s2 * 0.4,
      cadence: 95.0,
      leftStepDuration: 0.6,
      rightStepDuration: 0.6,
      stepDetected: false,
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
