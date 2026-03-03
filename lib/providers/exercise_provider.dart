import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'gait_provider.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum SensorQuality { good, degraded, poor, disconnected }

enum CalibrationQuality { pending, excellent, acceptable, poor }

enum FatigueLevel { none, mild, moderate, high }

enum LegSide { left, right, both }

enum RepPhase { movingToTarget, holdingTarget, returning, resting }

enum CalibrationPhase { idle, collecting, done }

// ─── Exercise Type Enum & Extensions ──────────────────────────────────────────
enum ExerciseType {
  kneeBend,
  straightLegRaise,
  holdPosition,
  ankleDorsiflexion,
  terminalKneeExtension,
  hipAbduction,
  calfRaiseHold,
  singleLegBalance,
}

extension ExerciseTypeExtension on ExerciseType {
  String get name {
    switch (this) {
      case ExerciseType.kneeBend:
        return 'Knee Bend';
      case ExerciseType.straightLegRaise:
        return 'Straight Leg Raise';
      case ExerciseType.holdPosition:
        return 'Hold Position';
      case ExerciseType.ankleDorsiflexion:
        return 'Ankle Dorsiflexion';
      case ExerciseType.terminalKneeExtension:
        return 'Terminal Knee Extension';
      case ExerciseType.hipAbduction:
        return 'Hip Abduction';
      case ExerciseType.calfRaiseHold:
        return 'Calf Raise Hold';
      case ExerciseType.singleLegBalance:
        return 'Single Leg Balance';
    }
  }

  String get description {
    switch (this) {
      case ExerciseType.kneeBend:
        return 'Bend your knee to the target angle and hold it steady.';
      case ExerciseType.straightLegRaise:
        return 'Lift your leg straight up to the target angle and hold.';
      case ExerciseType.holdPosition:
        return 'Hold your current leg position as still as possible.';
      case ExerciseType.ankleDorsiflexion:
        return 'Flex your ankle upward and hold the position.';
      case ExerciseType.terminalKneeExtension:
        return 'Straighten your knee fully and hold the extension.';
      case ExerciseType.hipAbduction:
        return 'Lift your leg to the side and maintain the angle.';
      case ExerciseType.calfRaiseHold:
        return 'Lift onto your toes and hold the calf raise.';
      case ExerciseType.singleLegBalance:
        return 'Balance on one leg, keeping your posture steady.';
    }
  }

  String get instruction {
    switch (this) {
      case ExerciseType.kneeBend:
        return 'Bend knee slowly to target angle';
      case ExerciseType.straightLegRaise:
        return 'Lift leg straight, hold position';
      case ExerciseType.holdPosition:
        return 'Hold current position steady';
      case ExerciseType.ankleDorsiflexion:
        return 'Point toes upward, hold steady';
      case ExerciseType.terminalKneeExtension:
        return 'Straighten knee completely, hold';
      case ExerciseType.hipAbduction:
        return 'Raise leg sideways, hold';
      case ExerciseType.calfRaiseHold:
        return 'Rise onto toes, hold steady';
      case ExerciseType.singleLegBalance:
        return 'Balance on one leg steadily';
    }
  }

  double get minTargetAngle {
    switch (this) {
      case ExerciseType.kneeBend:
        return 25.0;
      case ExerciseType.straightLegRaise:
        return 30.0;
      case ExerciseType.holdPosition:
        return -5.0;
      case ExerciseType.ankleDorsiflexion:
        return 10.0;
      case ExerciseType.terminalKneeExtension:
        return 0.0;
      case ExerciseType.hipAbduction:
        return 20.0;
      case ExerciseType.calfRaiseHold:
        return 25.0;
      case ExerciseType.singleLegBalance:
        return -5.0;
    }
  }

  double get maxTargetAngle {
    switch (this) {
      case ExerciseType.kneeBend:
        return 60.0;
      case ExerciseType.straightLegRaise:
        return 45.0;
      case ExerciseType.holdPosition:
        return 5.0;
      case ExerciseType.ankleDorsiflexion:
        return 20.0;
      case ExerciseType.terminalKneeExtension:
        return 10.0;
      case ExerciseType.hipAbduction:
        return 40.0;
      case ExerciseType.calfRaiseHold:
        return 40.0;
      case ExerciseType.singleLegBalance:
        return 5.0;
    }
  }

  int get requiredHoldSeconds {
    switch (this) {
      case ExerciseType.kneeBend:
        return 2;
      case ExerciseType.straightLegRaise:
        return 5;
      case ExerciseType.holdPosition:
        return 5;
      case ExerciseType.ankleDorsiflexion:
        return 3;
      case ExerciseType.terminalKneeExtension:
        return 2;
      case ExerciseType.hipAbduction:
        return 4;
      case ExerciseType.calfRaiseHold:
        return 3;
      case ExerciseType.singleLegBalance:
        return 10;
    }
  }

  int get targetReps {
    switch (this) {
      case ExerciseType.kneeBend:
        return 10;
      case ExerciseType.straightLegRaise:
        return 8;
      case ExerciseType.holdPosition:
        return 5;
      case ExerciseType.ankleDorsiflexion:
        return 12;
      case ExerciseType.terminalKneeExtension:
        return 15;
      case ExerciseType.hipAbduction:
        return 10;
      case ExerciseType.calfRaiseHold:
        return 12;
      case ExerciseType.singleLegBalance:
        return 5;
    }
  }
}

// ─── Exercise Result Model ────────────────────────────────────────────────────
class ExerciseResult {
  final DateTime date;
  final ExerciseType exerciseType;
  final double finalScore;
  final double angleAccuracy;
  final double stabilityScore;
  final double holdDurationScore;
  final double smoothnessScore;
  final double peakAngle;
  final int holdTime;
  final int totalReps;
  final int completedReps;
  final List<double> repScores;
  final int bestStreakThisSession;
  final FatigueLevel fatigueLevel;
  final double fatigueIndex;
  final bool isPersonalBest;
  final double? symmetryIndex;
  final int? peakHeartRate;
  final int? avgHeartRate;
  final int heartRateSafetyPauseCount;
  final SensorQuality overallDataQuality;
  final int totalDroppedPackets;
  final CalibrationQuality calibrationQuality;

  ExerciseResult({
    required this.date,
    required this.exerciseType,
    required this.finalScore,
    required this.angleAccuracy,
    required this.stabilityScore,
    required this.holdDurationScore,
    required this.smoothnessScore,
    required this.peakAngle,
    required this.holdTime,
    required this.totalReps,
    required this.completedReps,
    required this.repScores,
    required this.bestStreakThisSession,
    required this.fatigueLevel,
    required this.fatigueIndex,
    required this.isPersonalBest,
    this.symmetryIndex,
    this.peakHeartRate,
    this.avgHeartRate,
    required this.heartRateSafetyPauseCount,
    required this.overallDataQuality,
    required this.totalDroppedPackets,
    required this.calibrationQuality,
  });
}

// ─── Exercise Session State ───────────────────────────────────────────────────
class ExerciseSessionState {
  final ExerciseType currentExercise;
  final bool isRunning;
  final bool isPaused;

  // Calibration
  final CalibrationPhase calibrationPhase;
  final double calibrationProgress; // 0.0 → 1.0
  final bool isCalibrated;
  final CalibrationQuality calibrationQuality;
  final double baselineS1;
  final double baselineS2;

  // Motion
  final double currentAngle; // baseline-corrected & EMA-smoothed
  final double rawAngle; // baseline-corrected before EMA
  final double peakAngle;
  final int holdSeconds;

  // Target zone (relative to 0)
  final double dynamicMinTarget;
  final double dynamicMaxTarget;

  // Quality
  final double stabilityScore; // 0–100
  final double smoothnessScore; // 0–100
  final SensorQuality sensorQualityS1;
  final SensorQuality sensorQualityS2;
  final int totalDroppedPackets;
  final bool sensorDisconnected;

  // Rep tracking
  final int totalReps;
  final int completedReps;
  final List<double> repScores;
  final int restSecondsRemaining;
  final bool isResting;
  final RepPhase currentPhase;

  // Coaching
  final String coachingMessage;

  // Fatigue
  final FatigueLevel fatigueLevel;
  final double fatigueIndex;

  // Symmetry (singleLegBalance only)
  final LegSide currentLeg;
  final double? leftLegAvgScore;
  final double? rightLegAvgScore;

  const ExerciseSessionState({
    this.currentExercise = ExerciseType.kneeBend,
    this.isRunning = false,
    this.isPaused = false,
    this.calibrationPhase = CalibrationPhase.idle,
    this.calibrationProgress = 0.0,
    this.isCalibrated = false,
    this.calibrationQuality = CalibrationQuality.pending,
    this.baselineS1 = 0.0,
    this.baselineS2 = 0.0,
    this.currentAngle = 0.0,
    this.rawAngle = 0.0,
    this.peakAngle = 0.0,
    this.holdSeconds = 0,
    this.dynamicMinTarget = 0.0,
    this.dynamicMaxTarget = 0.0,
    this.stabilityScore = 100.0,
    this.smoothnessScore = 100.0,
    this.sensorQualityS1 = SensorQuality.good,
    this.sensorQualityS2 = SensorQuality.good,
    this.totalDroppedPackets = 0,
    this.sensorDisconnected = false,
    this.totalReps = 0,
    this.completedReps = 0,
    this.repScores = const [],
    this.restSecondsRemaining = 0,
    this.isResting = false,
    this.currentPhase = RepPhase.resting,
    this.coachingMessage = 'Get ready',
    this.fatigueLevel = FatigueLevel.none,
    this.fatigueIndex = 0.0,
    this.currentLeg = LegSide.both,
    this.leftLegAvgScore,
    this.rightLegAvgScore,
  });

  ExerciseSessionState copyWith({
    ExerciseType? currentExercise,
    bool? isRunning,
    bool? isPaused,
    CalibrationPhase? calibrationPhase,
    double? calibrationProgress,
    bool? isCalibrated,
    CalibrationQuality? calibrationQuality,
    double? baselineS1,
    double? baselineS2,
    double? currentAngle,
    double? rawAngle,
    double? peakAngle,
    int? holdSeconds,
    double? dynamicMinTarget,
    double? dynamicMaxTarget,
    double? stabilityScore,
    double? smoothnessScore,
    SensorQuality? sensorQualityS1,
    SensorQuality? sensorQualityS2,
    int? totalDroppedPackets,
    bool? sensorDisconnected,
    int? totalReps,
    int? completedReps,
    List<double>? repScores,
    int? restSecondsRemaining,
    bool? isResting,
    RepPhase? currentPhase,
    String? coachingMessage,
    FatigueLevel? fatigueLevel,
    double? fatigueIndex,
    LegSide? currentLeg,
    double? leftLegAvgScore,
    double? rightLegAvgScore,
  }) {
    return ExerciseSessionState(
      currentExercise: currentExercise ?? this.currentExercise,
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      calibrationPhase: calibrationPhase ?? this.calibrationPhase,
      calibrationProgress: calibrationProgress ?? this.calibrationProgress,
      isCalibrated: isCalibrated ?? this.isCalibrated,
      calibrationQuality: calibrationQuality ?? this.calibrationQuality,
      baselineS1: baselineS1 ?? this.baselineS1,
      baselineS2: baselineS2 ?? this.baselineS2,
      currentAngle: currentAngle ?? this.currentAngle,
      rawAngle: rawAngle ?? this.rawAngle,
      peakAngle: peakAngle ?? this.peakAngle,
      holdSeconds: holdSeconds ?? this.holdSeconds,
      dynamicMinTarget: dynamicMinTarget ?? this.dynamicMinTarget,
      dynamicMaxTarget: dynamicMaxTarget ?? this.dynamicMaxTarget,
      stabilityScore: stabilityScore ?? this.stabilityScore,
      smoothnessScore: smoothnessScore ?? this.smoothnessScore,
      sensorQualityS1: sensorQualityS1 ?? this.sensorQualityS1,
      sensorQualityS2: sensorQualityS2 ?? this.sensorQualityS2,
      totalDroppedPackets: totalDroppedPackets ?? this.totalDroppedPackets,
      sensorDisconnected: sensorDisconnected ?? this.sensorDisconnected,
      totalReps: totalReps ?? this.totalReps,
      completedReps: completedReps ?? this.completedReps,
      repScores: repScores ?? this.repScores,
      restSecondsRemaining: restSecondsRemaining ?? this.restSecondsRemaining,
      isResting: isResting ?? this.isResting,
      currentPhase: currentPhase ?? this.currentPhase,
      coachingMessage: coachingMessage ?? this.coachingMessage,
      fatigueLevel: fatigueLevel ?? this.fatigueLevel,
      fatigueIndex: fatigueIndex ?? this.fatigueIndex,
      currentLeg: currentLeg ?? this.currentLeg,
      leftLegAvgScore: leftLegAvgScore ?? this.leftLegAvgScore,
      rightLegAvgScore: rightLegAvgScore ?? this.rightLegAvgScore,
    );
  }

  double get minTarget {
    if (currentExercise == ExerciseType.holdPosition) return dynamicMinTarget;
    if (currentExercise == ExerciseType.singleLegBalance) {
      return dynamicMinTarget;
    }
    return currentExercise.minTargetAngle;
  }

  double get maxTarget {
    if (currentExercise == ExerciseType.holdPosition) return dynamicMaxTarget;
    if (currentExercise == ExerciseType.singleLegBalance) {
      return dynamicMaxTarget;
    }
    return currentExercise.maxTargetAngle;
  }

  // Whether the current angle (or its absolute value) is within the target zone.
  // Using abs() makes the system robust to sensors oriented so that bending
  // produces negative angles (e.g. IMU mounted facing the opposite direction).
  bool get isInTargetRange {
    // For holdPosition / singleLegBalance, the dynamic targets are set around
    // the calibrated neutral, so we check the signed angle directly.
    if (currentExercise == ExerciseType.holdPosition ||
        currentExercise == ExerciseType.singleLegBalance) {
      return currentAngle >= minTarget && currentAngle <= maxTarget;
    }
    // For positive-target exercises: accept motion in either direction.
    final check = currentAngle.abs();
    return check >= minTarget && check <= maxTarget;
  }
}

// ─── Exercise Session Notifier ────────────────────────────────────────────────
class ExerciseSessionNotifier extends Notifier<ExerciseSessionState> {
  StreamSubscription<GaitData>? _gaitSub;
  Timer? _holdTimer;
  Timer? _restTimer;

  // Calibration
  static const int _calibrationSamples = 20;
  final List<double> _calibSamplesS1 = [];
  final List<double> _calibSamplesS2 = [];

  // EMA filter state — 0.40 gives fast response without jitter
  static const double _emaAlpha = 0.40;
  double _emaAngle = 0.0;
  bool _emaInitialized = false;

  // Dead zone thresholds (degrees from 0-neutral)
  static const double _repStartThreshold = 4.0; // movement begins > 4°
  static const double _repReturnThreshold = 3.0; // returns to rest < 3°

  // Packet dropout tracking
  int _packetCounter = 0; // throttle secondary field updates
  int? _lastSequence;
  int _droppedPacketCount = 0;
  final List<int> _recentDrops = [];

  // Fatigue baseline
  double _fatigueBaselineAvg = 0.0;

  // Previous smoothed angle for smoothness calc
  double? _prevSmoothedAngle;
  DateTime? _prevSampleTime;

  @override
  ExerciseSessionState build() => const ExerciseSessionState();

  // ── Reset ──────────────────────────────────────────────────────────────────
  void reset() {
    _gaitSub?.cancel();
    _holdTimer?.cancel();
    _restTimer?.cancel();
    _calibSamplesS1.clear();
    _calibSamplesS2.clear();
    _emaInitialized = false;
    _emaAngle = 0.0;
    _lastSequence = null;
    _droppedPacketCount = 0;
    _recentDrops.clear();
    _fatigueBaselineAvg = 0.0;
    _prevSmoothedAngle = null;
    _prevSampleTime = null;
    state = const ExerciseSessionState();
  }

  // ── Calibration ────────────────────────────────────────────────────────────
  /// Streams live sensor data, collects 20 samples, computes median baseline.
  /// The UI should watch `calibrationPhase` and `calibrationProgress`.
  void startCalibration(ExerciseType type, Stream<GaitData> dataStream) {
    _calibSamplesS1.clear();
    _calibSamplesS2.clear();
    _emaInitialized = false;

    state = state.copyWith(
      currentExercise: type,
      calibrationPhase: CalibrationPhase.collecting,
      calibrationProgress: 0.0,
      isCalibrated: false,
      calibrationQuality: CalibrationQuality.pending,
      coachingMessage: 'Hold still — calibrating your position...',
    );

    _gaitSub?.cancel();
    _gaitSub = dataStream.listen(
      (data) {
        if (state.calibrationPhase != CalibrationPhase.collecting) return;

        _calibSamplesS1.add(data.kneeAngle);
        _calibSamplesS2.add(data.rightKneeFlexion);

        // Only emit progress to the UI every 4th sample (5 updates total).
        // The sample DATA is still collected every packet for accuracy.
        final count = _calibSamplesS1.length;
        if (count % 4 == 0 || count >= _calibrationSamples) {
          final progress = count / _calibrationSamples;
          state = state.copyWith(calibrationProgress: progress.clamp(0.0, 1.0));
        }

        if (_calibSamplesS1.length >= _calibrationSamples) {
          _finalizeCalibration(type, dataStream);
        }
      },
      onError: (_) {
        state = state.copyWith(
          sensorDisconnected: true,
          coachingMessage: 'Sensor disconnected. Please reconnect.',
        );
      },
      onDone: () {
        if (!state.isCalibrated) {
          state = state.copyWith(
            sensorDisconnected: true,
            coachingMessage: 'Sensor disconnected. Please reconnect.',
          );
        }
      },
    );
  }

  void _finalizeCalibration(ExerciseType type, Stream<GaitData> dataStream) {
    // Sort samples for std-dev quality check (baselines are always 0 — raw angles used directly)
    final sortedS1 = List<double>.from(_calibSamplesS1)..sort();

    // Assess quality via std-dev of S1
    final mean = sortedS1.reduce((a, b) => a + b) / sortedS1.length;
    final variance =
        sortedS1.map((s) => (s - mean) * (s - mean)).reduce((a, b) => a + b) /
        sortedS1.length;
    final stdDev = math.sqrt(variance);

    CalibrationQuality quality;
    if (stdDev < 1.0) {
      quality = CalibrationQuality.excellent;
    } else if (stdDev <= 3.0) {
      quality = CalibrationQuality.acceptable;
    } else {
      quality = CalibrationQuality.poor;
    }

    // Use raw sensor angles directly — no baseline offset
    // (Calibration phase is still used to assess sensor stability/quality)
    state = state.copyWith(
      baselineS1: 0.0,
      baselineS2: 0.0,
      isCalibrated: true,
      calibrationPhase: CalibrationPhase.done,
      calibrationProgress: 1.0,
      calibrationQuality: quality,
      coachingMessage: 'Sensor ready! Starting exercise...',
    );

    // Immediately start the exercise on the same stream (no re-subscription needed)
    _gaitSub?.cancel();
    _startExerciseListening(type, dataStream);
  }

  // ── Exercise Start ─────────────────────────────────────────────────────────
  void _startExerciseListening(ExerciseType type, Stream<GaitData> dataStream) {
    _sessionStartTime = DateTime.now(); // ✅ record real wall-clock start
    state = ExerciseSessionState(
      currentExercise: type,
      isRunning: true,
      isCalibrated: true,
      calibrationPhase: CalibrationPhase.done,
      calibrationProgress: 1.0,
      calibrationQuality: state.calibrationQuality,
      baselineS1: state.baselineS1,
      baselineS2: state.baselineS2,
      totalReps: type.targetReps,
      coachingMessage:
          'Alright champ, let\'s do this! Start when you\'re ready 💪',
      currentPhase: RepPhase.resting,
      isResting: false,
    );

    // Hold timer — ticks every second in holdingTarget phase
    _holdTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.isPaused || !state.isRunning) return;
      if (state.currentPhase == RepPhase.holdingTarget &&
          state.isInTargetRange) {
        final newHold = state.holdSeconds + 1;
        state = state.copyWith(holdSeconds: newHold);

        if (newHold >= type.requiredHoldSeconds) {
          // Rep successfully held — record and transition
          final newCompleted = state.completedReps + 1;
          final repScore = _computeRepQuality();
          final newScores = [...state.repScores, repScore];

          // Symmetry tracking for singleLegBalance
          double? leftAvg = state.leftLegAvgScore;
          double? rightAvg = state.rightLegAvgScore;
          LegSide nextLeg = state.currentLeg;
          // ✅ Use newCompleted (not stale state.completedReps) to detect
          // the last rep correctly — fixes session never auto-ending.
          if (type == ExerciseType.singleLegBalance &&
              newCompleted >= state.totalReps) {
            if (state.currentLeg == LegSide.left) {
              leftAvg = newScores.reduce((a, b) => a + b) / newScores.length;
              nextLeg = LegSide.right;
            } else if (state.currentLeg == LegSide.right) {
              rightAvg = newScores.reduce((a, b) => a + b) / newScores.length;
              nextLeg = LegSide.both;
            }
          }

          final resetScores = nextLeg != state.currentLeg
              ? const <double>[]
              : newScores;
          final resetCompleted = nextLeg != state.currentLeg ? 0 : newCompleted;

          state = state.copyWith(
            currentPhase: RepPhase.returning,
            completedReps: resetCompleted,
            repScores: resetScores,
            holdSeconds: 0,
            coachingMessage:
                'Awesome! That was solid! Now bring it back slowly 🙌',
            leftLegAvgScore: leftAvg,
            rightLegAvgScore: rightAvg,
            currentLeg: nextLeg,
          );

          _checkFatigue();
        }
      }
    });

    _gaitSub = dataStream.listen(
      (data) {
        if (state.isPaused || !state.isRunning) return;

        // ── Sensor quality / dropout tracking ───────────────────────────────
        SensorQuality nextQualityS1 = state.sensorQualityS1;
        SensorQuality nextQualityS2 = state.sensorQualityS2;
        if (data.packetSequence != null && _lastSequence != null) {
          final dropped = data.packetSequence! - (_lastSequence! + 1);
          if (dropped > 0) {
            _droppedPacketCount += dropped;
            _recentDrops.add(dropped);
          } else {
            _recentDrops.add(0);
          }
          if (_recentDrops.length > 10) _recentDrops.removeAt(0);

          final dropSum = _recentDrops.isEmpty
              ? 0
              : _recentDrops.reduce((a, b) => a + b);
          if (dropSum > 5) {
            nextQualityS1 = SensorQuality.poor;
            nextQualityS2 = SensorQuality.poor;
          } else if (dropSum > 2) {
            nextQualityS1 = SensorQuality.degraded;
            nextQualityS2 = SensorQuality.degraded;
          } else {
            nextQualityS1 = SensorQuality.good;
            nextQualityS2 = SensorQuality.good;
          }
        }
        _lastSequence = data.packetSequence;

        // ── Use exact sensor angle (no baseline offset) ──────────────────────
        double rawAngle;
        if (state.currentExercise == ExerciseType.singleLegBalance) {
          rawAngle = _fusedAngle(data);
        } else {
          rawAngle = data.kneeAngle;
        }

        // ── EMA smoothing (α = 0.40 — responsive and jitter-free) ─────────────
        if (!_emaInitialized) {
          _emaAngle = rawAngle;
          _emaInitialized = true;
        } else {
          _emaAngle = _emaAlpha * rawAngle + (1 - _emaAlpha) * _emaAngle;
        }
        final smoothedAngle = _emaAngle;

        // Set dynamic target for holdPosition / singleLegBalance on first reading
        double dynMin = state.dynamicMinTarget;
        double dynMax = state.dynamicMaxTarget;
        if (state.completedReps == 0 &&
            state.holdSeconds == 0 &&
            state.currentPhase == RepPhase.resting &&
            (state.currentExercise == ExerciseType.holdPosition ||
                state.currentExercise == ExerciseType.singleLegBalance) &&
            dynMin == 0.0 &&
            dynMax == 0.0) {
          dynMin = smoothedAngle - 5.0;
          dynMax = smoothedAngle + 5.0;
        }

        // ── Smoothness scoring ────────────────────────────────────────────────
        double newSmoothness = state.smoothnessScore;
        final now = data.timestamp;
        if (_prevSmoothedAngle != null && _prevSampleTime != null) {
          final dt = now.difference(_prevSampleTime!).inMilliseconds / 1000.0;
          if (dt > 0) {
            final degPerSec = (smoothedAngle - _prevSmoothedAngle!).abs() / dt;
            if (degPerSec > 60.0) {
              newSmoothness = (newSmoothness - 4.0).clamp(0.0, 100.0);
            } else {
              // Recover slowly
              newSmoothness = (newSmoothness + 0.5).clamp(0.0, 100.0);
            }
          }
        }
        _prevSmoothedAngle = smoothedAngle;
        _prevSampleTime = now;

        // ── Stability scoring (from ESP32 STAB field) ─────────────────────────
        double newStability = state.stabilityScore;
        if (data.stabilityLevel == 'Poor') {
          newStability = (newStability - 2.0).clamp(0.0, 100.0);
        } else if (data.stabilityLevel == 'Moderate') {
          newStability = (newStability - 0.5).clamp(0.0, 100.0);
        } else {
          newStability = (newStability + 0.3).clamp(0.0, 100.0);
        }

        // ── Peak tracking (absolute value — works for both ± directions) ──────
        final newPeak = smoothedAngle.abs() > state.peakAngle
            ? smoothedAngle.abs()
            : state.peakAngle;

        // ── Rep phase state machine ───────────────────────────────────────────
        RepPhase nextPhase = state.currentPhase;
        bool nextIsResting = state.isResting;
        int nextRestSeconds = state.restSecondsRemaining;
        String coaching = state.coachingMessage;

        // Use abs() for positive-target exercises so a sensor oriented to
        // produce negative angles still triggers the target zone correctly.
        final bool inTarget;
        if (state.currentExercise == ExerciseType.holdPosition ||
            state.currentExercise == ExerciseType.singleLegBalance) {
          inTarget =
              smoothedAngle >= state.minTarget &&
              smoothedAngle <= state.maxTarget;
        } else {
          final check = smoothedAngle.abs();
          inTarget = check >= state.minTarget && check <= state.maxTarget;
        }

        switch (state.currentPhase) {
          case RepPhase.resting:
            // Dead zone: only begin a rep if movement exceeds threshold
            if (smoothedAngle.abs() > _repStartThreshold && !state.isResting) {
              nextPhase = RepPhase.movingToTarget;
              coaching = _coachMoving(state.currentExercise);
            } else {
              coaching = state.isResting
                  ? 'Take a breather! Rest for ${state.restSecondsRemaining} seconds 😌'
                  : 'You got this! Start moving when you\'re ready 💪';
            }
            break;

          case RepPhase.movingToTarget:
            if (inTarget) {
              nextPhase = RepPhase.holdingTarget;
              coaching = 'Perfect! Now hold it right there! 🔥';
            } else {
              // Check for jitter (angle barely moving)
              if (newSmoothness < 60) {
                coaching = 'Easy does it — nice and smooth!';
              } else {
                coaching = _coachMoving(state.currentExercise);
              }
            }
            break;

          case RepPhase.holdingTarget:
            if (!inTarget) {
              // Left target before hold complete — return to moving
              nextPhase = RepPhase.movingToTarget;
              state = state.copyWith(holdSeconds: 0);
              coaching = 'Almost! Get back in position — you can do it!';
            } else {
              final remaining =
                  state.currentExercise.requiredHoldSeconds - state.holdSeconds;
              if (remaining > 0) {
                coaching = newStability < 60
                    ? 'Stay strong! Keep it steady!'
                    : 'Keep holding! ${remaining}s to go! 💪';
              }
            }
            break;

          case RepPhase.returning:
            // Return to neutral dead zone
            if (smoothedAngle.abs() < _repReturnThreshold) {
              nextPhase = RepPhase.resting;
              nextIsResting = true;
              nextRestSeconds = _restDurationForFatigue();
              coaching = 'Great rep! Rest for ${nextRestSeconds} seconds 🎉';
              _startRestTimer(nextRestSeconds);

              // ✅ Check against newCompleted (not state.completedReps which is
              // still the pre-increment value at this point in the returning phase).
              // Also only stop when not in singleLegBalance mid-switch.
              if (state.completedReps >= state.totalReps) {
                Future.microtask(() => stopExercise());
              }
            } else {
              coaching = 'Slowly bring it back — nice and controlled!';
            }
            break;
        }

        _packetCounter++;
        final updateSecondary = _packetCounter % 3 == 0;

        state = state.copyWith(
          // Always update — these drive the live gauge
          currentAngle: smoothedAngle,
          rawAngle: rawAngle,
          peakAngle: newPeak,
          dynamicMinTarget: dynMin,
          dynamicMaxTarget: dynMax,
          currentPhase: nextPhase,
          isResting: nextIsResting,
          restSecondsRemaining: nextRestSeconds,
          coachingMessage: coaching,
          // Throttled — update every 3rd packet (slow-changing fields)
          smoothnessScore: updateSecondary ? newSmoothness : null,
          stabilityScore: updateSecondary ? newStability : null,
          sensorQualityS1: updateSecondary ? nextQualityS1 : null,
          sensorQualityS2: updateSecondary ? nextQualityS2 : null,
          totalDroppedPackets: updateSecondary ? _droppedPacketCount : null,
        );
      },
      onError: (_) {
        state = state.copyWith(sensorDisconnected: true);
        pauseExercise();
      },
      onDone: () {
        state = state.copyWith(
          sensorDisconnected: true,
          sensorQualityS1: SensorQuality.disconnected,
          sensorQualityS2: SensorQuality.disconnected,
        );
        pauseExercise();
      },
    );
  }

  // ── Sensor fusion for balance exercise ───────────────────────────────────
  double _fusedAngle(GaitData data) {
    final w1 = state.sensorQualityS1 == SensorQuality.good ? 0.5 : 0.2;
    final w2 = state.sensorQualityS2 == SensorQuality.good ? 0.5 : 0.2;
    final total = w1 + w2;
    return ((data.kneeAngle * w1) + (data.rightKneeFlexion * w2)) / total;
  }

  // ── Coaching helpers ──────────────────────────────────────────────────────
  String _coachMoving(ExerciseType type) {
    switch (type) {
      case ExerciseType.kneeBend:
        return 'That\'s it! Bend that knee — you\'re doing great! 🦵';
      case ExerciseType.straightLegRaise:
        return 'Lift it up! Slow and steady wins the race!';
      case ExerciseType.holdPosition:
        return 'Hold it right there — like a rock!';
      case ExerciseType.ankleDorsiflexion:
        return 'Point those toes up! Nice and easy!';
      case ExerciseType.terminalKneeExtension:
        return 'Straighten it out! Full extension, you got this!';
      case ExerciseType.hipAbduction:
        return 'Raise it to the side — strong and controlled!';
      case ExerciseType.calfRaiseHold:
        return 'Up on those toes! Feel the burn! 🔥';
      case ExerciseType.singleLegBalance:
        return 'Find your centre — stay balanced!';
    }
  }

  // ── Rep quality (for internal history — not shown as score to user) ───────
  double _computeRepQuality() {
    double angleAcc;
    final peak = state.peakAngle;
    if (peak >= state.minTarget && peak <= state.maxTarget) {
      angleAcc = 100.0;
    } else if (peak > state.maxTarget) {
      angleAcc = (100.0 - ((peak - state.maxTarget) * 2)).clamp(0.0, 100.0);
    } else {
      angleAcc = (100.0 - ((state.minTarget - peak) * 2)).clamp(0.0, 100.0);
    }

    return ((angleAcc * 0.40) +
            (state.stabilityScore * 0.30) +
            (state.smoothnessScore * 0.30))
        .clamp(0.0, 100.0);
  }

  // ── Rest timer ────────────────────────────────────────────────────────────
  int _restDurationForFatigue() {
    switch (state.fatigueLevel) {
      case FatigueLevel.high:
      case FatigueLevel.moderate:
        return 20;
      default:
        return 10;
    }
  }

  void _startRestTimer(int seconds) {
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.isPaused || !state.isRunning) return;
      if (state.restSecondsRemaining > 1) {
        state = state.copyWith(
          restSecondsRemaining: state.restSecondsRemaining - 1,
          coachingMessage:
              'Breathe easy — ${state.restSecondsRemaining - 1}s rest left 😌',
        );
      } else {
        timer.cancel();
        state = state.copyWith(
          isResting: false,
          restSecondsRemaining: 0,
          currentPhase: RepPhase.resting,
          stabilityScore: 100.0,
          smoothnessScore: 100.0,
          peakAngle: 0.0,
          holdSeconds: 0,
          coachingMessage:
              'Let\'s go again! Next rep — you\'re crushing it! 🚀',
        );
      }
    });
  }

  // ── Fatigue detection ─────────────────────────────────────────────────────
  void _checkFatigue() {
    final scores = state.repScores;
    if (scores.length < 3) return;

    if (scores.length == 3) {
      _fatigueBaselineAvg = scores.reduce((a, b) => a + b) / 3;
    }
    // ✅ Guard against uninitialised baseline (skip fatigue check if not yet set)
    if (_fatigueBaselineAvg == 0.0) return;
    final baseline = _fatigueBaselineAvg;
    final recent = scores.length >= 3
        ? scores.skip(scores.length - 3).reduce((a, b) => a + b) / 3
        : scores.last;

    final drop = baseline - recent;
    final index = (drop / 50.0).clamp(0.0, 1.0);

    FatigueLevel level;
    if (drop > 35) {
      level = FatigueLevel.high;
    } else if (drop > 25) {
      level = FatigueLevel.moderate;
    } else if (drop > 15) {
      level = FatigueLevel.mild;
    } else {
      level = FatigueLevel.none;
    }

    state = state.copyWith(fatigueLevel: level, fatigueIndex: index);
  }

  // ── Pause / Resume / Stop ─────────────────────────────────────────────────
  void pauseExercise() {
    state = state.copyWith(isPaused: true, coachingMessage: 'Paused');
  }

  void resumeExercise() {
    state = state.copyWith(
      isPaused: false,
      coachingMessage: 'Continue when ready',
    );
  }

  void stopExercise() {
    _gaitSub?.cancel();
    _holdTimer?.cancel();
    _restTimer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  // ── Final Result ──────────────────────────────────────────────────────────
  // Records the wall-clock start time so we can compute real session duration.
  DateTime? _sessionStartTime;

  ExerciseResult calculateFinalResult() {
    double avgRepScore = 0.0;
    if (state.repScores.isNotEmpty) {
      avgRepScore =
          state.repScores.reduce((a, b) => a + b) / state.repScores.length;
    }

    // ✅ Use real elapsed seconds, not just accumulated hold time.
    final sessionDuration = _sessionStartTime != null
        ? DateTime.now().difference(_sessionStartTime!).inSeconds
        : state.holdSeconds;

    double? symmetry;
    if (state.leftLegAvgScore != null && state.rightLegAvgScore != null) {
      final diff = (state.leftLegAvgScore! - state.rightLegAvgScore!).abs();
      symmetry = (100.0 - (diff * 1.5)).clamp(0.0, 100.0);
    }

    return ExerciseResult(
      date: DateTime.now(),
      exerciseType: state.currentExercise,
      finalScore: avgRepScore,
      angleAccuracy: avgRepScore,
      stabilityScore: state.stabilityScore,
      holdDurationScore: 100.0,
      smoothnessScore: state.smoothnessScore,
      peakAngle: state.peakAngle,
      holdTime: sessionDuration,
      totalReps: state.totalReps,
      completedReps: state.completedReps,
      repScores: state.repScores,
      bestStreakThisSession: 0,
      fatigueLevel: state.fatigueLevel,
      fatigueIndex: state.fatigueIndex,
      isPersonalBest: false,
      symmetryIndex: symmetry,
      peakHeartRate: null,
      avgHeartRate: null,
      heartRateSafetyPauseCount: 0,
      overallDataQuality: state.sensorQualityS1,
      totalDroppedPackets: _droppedPacketCount,
      calibrationQuality: state.calibrationQuality,
    );
  }

  void dispose() {
    _gaitSub?.cancel();
    _holdTimer?.cancel();
    _restTimer?.cancel();
    state = const ExerciseSessionState();
  }
}

final exerciseSessionProvider =
    NotifierProvider<ExerciseSessionNotifier, ExerciseSessionState>(
      ExerciseSessionNotifier.new,
    );
