import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GaitData {
  final double leftKneeFlexion;
  final double rightKneeFlexion;
  final double leftHipExtension;
  final double rightHipExtension;
  final double cadence; // Steps per minute
  final double leftStepDuration; // in seconds
  final double rightStepDuration; // in seconds
  final bool stepDetected;

  // Raw mock IMU data
  final double accelX;
  final double accelY;
  final double accelZ;
  final double pitch;
  final double roll;
  final double yaw;

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
  });

  // Kinematic Symmetry %
  double get symmetry {
    // A simplified metric computing variance between left and right limb kinematics
    double angleVariance =
        ((leftKneeFlexion + leftHipExtension) -
                (rightKneeFlexion + rightHipExtension))
            .abs();
    double timingVariance =
        (leftStepDuration - rightStepDuration).abs() *
        100; // arbitrary multiplier

    double totalVariance = angleVariance + timingVariance;
    double symmetryPercent = 100.0 - totalVariance;
    return symmetryPercent.clamp(0.0, 100.0);
  }

  double get maxFlexionRange => max(leftKneeFlexion, rightKneeFlexion);

  // Stability Classification
  String get stabilityLevel {
    // Sudden acceleration spikes denote poor stability
    double avgAccelMag = sqrt(
      (accelX * accelX) + (accelY * accelY) + (accelZ * accelZ),
    );
    if (avgAccelMag > 1.8) return "Poor";
    if (avgAccelMag > 1.3) return "Moderate";
    return "Good";
  }

  double get mobilityScore {
    double sym = symmetry;
    double flexion = maxFlexionRange;
    // Score based on Symmetry, Flexion, and Cadence
    double score =
        (sym * 0.4) +
        ((flexion / 90).clamp(0.0, 1.0) * 100 * 0.4) +
        ((cadence / 110).clamp(0.0, 1.0) *
            100 *
            0.2); // Normal adult cadence ~100-110
    return score.clamp(0.0, 100.0);
  }
}

// A mock stream to simulate incoming IMU data from ESP32 sensors
Stream<GaitData> gaitDataStream() async* {
  final random = Random();
  double leftKnee = 50.0;
  double rightKnee = 52.0;

  double cadence = 95.0; // Baseline steps per min
  int ticks = 0;

  while (true) {
    await Future.delayed(
      const Duration(milliseconds: 200),
    ); // Faster 5Hz stream for kinematics
    ticks++;

    // Add noise to simulate human gait variability
    leftKnee += random.nextDouble() * 4 - 2;
    rightKnee += random.nextDouble() * 4 - 2;

    leftKnee = leftKnee.clamp(10.0, 75.0);
    rightKnee = rightKnee.clamp(10.0, 75.0);

    // Mock natural Cadence variations
    cadence += random.nextDouble() * 2 - 1;
    cadence = cadence.clamp(60.0, 130.0);

    // Step detection mock: A sudden extension followed by flexion triggers a "step"
    bool stepFlag = false;
    if (ticks % (1200 ~/ cadence) == 0) {
      stepFlag = true;
    }

    // Mock 1g gravity vector + some walking noise
    double baseAccelZ = 1.0;
    double noiseX = random.nextDouble() * 0.4 - 0.2;
    double noiseY = random.nextDouble() * 0.6 - 0.3;
    double noiseZ =
        (stepFlag ? 0.8 : 0.0) +
        (random.nextDouble() * 0.3 - 0.15); // Spike on heel strike

    yield GaitData(
      leftKneeFlexion: leftKnee,
      rightKneeFlexion: rightKnee,
      leftHipExtension: leftKnee * 0.4,
      rightHipExtension: rightKnee * 0.4,
      cadence: cadence,
      leftStepDuration: 60 / cadence + (random.nextDouble() * 0.1 - 0.05),
      rightStepDuration: 60 / cadence + (random.nextDouble() * 0.1 - 0.05),
      stepDetected: stepFlag,
      accelX: noiseX,
      accelY: noiseY,
      accelZ: baseAccelZ + noiseZ,
      pitch: random.nextDouble() * 10,
      roll: random.nextDouble() * 5,
      yaw: random.nextDouble() * 360,
    );
  }
}

final gaitDataProvider = StreamProvider<GaitData>((ref) {
  return gaitDataStream();
});
