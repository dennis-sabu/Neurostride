import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'gait_provider.dart';

// ─── Rep Phase Enum ───────────────────────────────────────────────────────────
enum RepPhase { movingToTarget, holdingTarget, returning, resting }

// ─── Exercise Type Enum & Extensions ──────────────────────────────────────────
enum ExerciseType { kneeBend, straightLegRaise, holdPosition }

extension ExerciseTypeExtension on ExerciseType {
  String get name {
    switch (this) {
      case ExerciseType.kneeBend:
        return 'Knee Bend';
      case ExerciseType.straightLegRaise:
        return 'Straight Leg Raise';
      case ExerciseType.holdPosition:
        return 'Hold Position';
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
    }
  }

  double get minTargetAngle {
    switch (this) {
      case ExerciseType.kneeBend:
        return 60.0;
      case ExerciseType.straightLegRaise:
        return 30.0;
      case ExerciseType.holdPosition:
        return 0.0; // Dynamic, set when started
    }
  }

  double get maxTargetAngle {
    switch (this) {
      case ExerciseType.kneeBend:
        return 90.0;
      case ExerciseType.straightLegRaise:
        return 45.0;
      case ExerciseType.holdPosition:
        return 0.0; // Dynamic, set when started
    }
  }

  int get requiredHoldSeconds {
    switch (this) {
      case ExerciseType.kneeBend:
        return 3;
      case ExerciseType.straightLegRaise:
        return 5;
      case ExerciseType.holdPosition:
        return 5;
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
  final int holdTime; // in seconds
  final int totalReps;
  final int completedReps;
  final List<double> repScores;

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
  });
}

// ─── Exercise Session State ───────────────────────────────────────────────────
class ExerciseSessionState {
  final ExerciseType currentExercise;
  final bool isRunning;
  final bool isPaused;
  final double currentAngle;
  final double peakAngle;
  final int holdSeconds;
  final List<double> angleHistory;

  final double stabilityRaw;
  final double smoothnessRaw;

  final double dynamicMinTarget;
  final double dynamicMaxTarget;

  // New Baseline Calibration Fields
  final double baselineS1;
  final double baselineS2;
  final bool isCalibrated;

  // New Rep Tracking Fields
  final int totalReps;
  final int completedReps;
  final List<double> repScores;
  final bool isResting;
  final int restSecondsRemaining;
  final RepPhase currentPhase;

  const ExerciseSessionState({
    this.currentExercise = ExerciseType.kneeBend,
    this.isRunning = false,
    this.isPaused = false,
    this.currentAngle = 0.0,
    this.peakAngle = 0.0,
    this.holdSeconds = 0,
    this.angleHistory = const [],
    this.stabilityRaw = 100.0,
    this.smoothnessRaw = 100.0,
    this.dynamicMinTarget = 0.0,
    this.dynamicMaxTarget = 0.0,
    this.baselineS1 = 0.0,
    this.baselineS2 = 0.0,
    this.isCalibrated = false,
    this.totalReps = 0,
    this.completedReps = 0,
    this.repScores = const [],
    this.isResting = false,
    this.restSecondsRemaining = 0,
    this.currentPhase = RepPhase.movingToTarget,
  });

  ExerciseSessionState copyWith({
    ExerciseType? currentExercise,
    bool? isRunning,
    bool? isPaused,
    double? currentAngle,
    double? peakAngle,
    int? holdSeconds,
    List<double>? angleHistory,
    double? stabilityRaw,
    double? smoothnessRaw,
    double? dynamicMinTarget,
    double? dynamicMaxTarget,
    double? baselineS1,
    double? baselineS2,
    bool? isCalibrated,
    int? totalReps,
    int? completedReps,
    List<double>? repScores,
    bool? isResting,
    int? restSecondsRemaining,
    RepPhase? currentPhase,
  }) {
    return ExerciseSessionState(
      currentExercise: currentExercise ?? this.currentExercise,
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      currentAngle: currentAngle ?? this.currentAngle,
      peakAngle: peakAngle ?? this.peakAngle,
      holdSeconds: holdSeconds ?? this.holdSeconds,
      angleHistory: angleHistory ?? this.angleHistory,
      stabilityRaw: stabilityRaw ?? this.stabilityRaw,
      smoothnessRaw: smoothnessRaw ?? this.smoothnessRaw,
      dynamicMinTarget: dynamicMinTarget ?? this.dynamicMinTarget,
      dynamicMaxTarget: dynamicMaxTarget ?? this.dynamicMaxTarget,
      baselineS1: baselineS1 ?? this.baselineS1,
      baselineS2: baselineS2 ?? this.baselineS2,
      isCalibrated: isCalibrated ?? this.isCalibrated,
      totalReps: totalReps ?? this.totalReps,
      completedReps: completedReps ?? this.completedReps,
      repScores: repScores ?? this.repScores,
      isResting: isResting ?? this.isResting,
      restSecondsRemaining: restSecondsRemaining ?? this.restSecondsRemaining,
      currentPhase: currentPhase ?? this.currentPhase,
    );
  }

  double get minTarget {
    if (currentExercise == ExerciseType.holdPosition && dynamicMinTarget != 0) {
      return dynamicMinTarget;
    }
    return currentExercise.minTargetAngle;
  }

  double get maxTarget {
    if (currentExercise == ExerciseType.holdPosition && dynamicMaxTarget != 0) {
      return dynamicMaxTarget;
    }
    return currentExercise.maxTargetAngle;
  }

  bool get isInTargetRange {
    return currentAngle >= minTarget && currentAngle <= maxTarget;
  }
}

// ─── Exercise Session Notifier ────────────────────────────────────────────────
class ExerciseSessionNotifier extends Notifier<ExerciseSessionState> {
  StreamSubscription<GaitData>? _gaitSub;
  Timer? _holdTimer;
  Timer? _restTimer;

  @override
  ExerciseSessionState build() => const ExerciseSessionState();

  void reset() {
    _gaitSub?.cancel();
    _holdTimer?.cancel();
    _restTimer?.cancel();
    state = const ExerciseSessionState();
  }

  void calibrateBaseline(GaitData currentData) {
    state = state.copyWith(
      baselineS1: currentData.kneeAngle,
      baselineS2: currentData.rightKneeFlexion,
      isCalibrated: true,
    );
  }

  void startExercise(ExerciseType type, Stream<GaitData> dataStream) {
    if (!state.isCalibrated) {
      throw Exception('Exercise must be calibrated before starting.');
    }

    state = const ExerciseSessionState().copyWith(
      currentExercise: type,
      isRunning: true,
      totalReps: type.targetReps,
      baselineS1: state.baselineS1,
      baselineS2: state.baselineS2,
      isCalibrated: true,
    );

    _holdTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.isPaused || !state.isRunning) return;

      if (state.currentPhase == RepPhase.holdingTarget &&
          state.isInTargetRange) {
        state = state.copyWith(holdSeconds: state.holdSeconds + 1);

        if (state.holdSeconds >= type.requiredHoldSeconds) {
          // Rep complete
          double repScore = _calculateCurrentRepScore();
          final newScores = [...state.repScores, repScore];
          final newCompletedReps = state.completedReps + 1;

          state = state.copyWith(
            currentPhase: RepPhase.returning,
            completedReps: newCompletedReps,
            repScores: newScores,
            holdSeconds: 0,
          );
        }
      }
    });

    bool isFirstReading = true;

    _gaitSub = dataStream.listen(
      (data) {
        if (state.isPaused || !state.isRunning) return;

        // Apply baseline correction
        final angle = data.kneeAngle - state.baselineS1;

        if (isFirstReading && type == ExerciseType.holdPosition) {
          state = state.copyWith(
            dynamicMinTarget: angle - 5.0,
            dynamicMaxTarget: angle + 5.0,
          );
        }
        isFirstReading = false;

        final history = [...state.angleHistory, angle];
        while (history.length > 100) {
          history.removeAt(0);
        }

        final peak = angle > state.peakAngle ? angle : state.peakAngle;

        double newSmoothness = state.smoothnessRaw;
        if (state.angleHistory.isNotEmpty) {
          double diff = (angle - state.angleHistory.last).abs();
          if (diff > 10.0) {
            newSmoothness = (newSmoothness - (diff * 0.5)).clamp(0.0, 100.0);
          }
        }

        double newStability = state.stabilityRaw;
        if (data.stabilityLevel == "Poor") {
          newStability = (newStability - 2.0).clamp(0.0, 100.0);
        } else if (data.stabilityLevel == "Moderate") {
          newStability = (newStability - 0.5).clamp(0.0, 100.0);
        }

        // Rep phase transitions
        RepPhase nextPhase = state.currentPhase;
        bool nextIsResting = state.isResting;
        int nextRestSeconds = state.restSecondsRemaining;

        if (state.currentPhase == RepPhase.movingToTarget) {
          if (state.isInTargetRange) {
            nextPhase = RepPhase.holdingTarget;
          }
        } else if (state.currentPhase == RepPhase.returning) {
          // Returning back to start position (e.g., < 20 deg)
          if (angle < 20.0) {
            nextPhase = RepPhase.resting;
            nextIsResting = true;
            nextRestSeconds = 10;
            _startRestTimer();

            if (state.completedReps >= state.totalReps) {
              Future.microtask(() => stopExercise());
            }
          }
        }

        state = state.copyWith(
          currentAngle: angle,
          angleHistory: history,
          peakAngle: peak,
          smoothnessRaw: newSmoothness,
          stabilityRaw: newStability,
          currentPhase: nextPhase,
          isResting: nextIsResting,
          restSecondsRemaining: nextRestSeconds,
        );
      },
      onError: (e) {
        pauseExercise();
      },
      onDone: () {
        pauseExercise();
      },
    );
  }

  void _startRestTimer() {
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.isPaused || !state.isRunning) return;

      if (state.restSecondsRemaining > 1) {
        state = state.copyWith(
          restSecondsRemaining: state.restSecondsRemaining - 1,
        );
      } else {
        // Rest complete, move to next rep
        timer.cancel();
        state = state.copyWith(
          isResting: false,
          restSecondsRemaining: 0,
          currentPhase: RepPhase.movingToTarget,
          smoothnessRaw: 100.0, // Reset metrics for next rep
          stabilityRaw: 100.0,
          peakAngle: 0.0,
        );
      }
    });
  }

  double _calculateCurrentRepScore() {
    double angleAcc = 0.0;
    if (state.peakAngle >= state.minTarget &&
        state.peakAngle <= state.maxTarget) {
      angleAcc = 100.0;
    } else if (state.peakAngle > state.maxTarget) {
      double diff = state.peakAngle - state.maxTarget;
      angleAcc = (100.0 - (diff * 2)).clamp(0.0, 100.0);
    } else {
      double diff = state.minTarget - state.peakAngle;
      angleAcc = (100.0 - (diff * 2)).clamp(0.0, 100.0);
    }

    if (state.currentExercise == ExerciseType.holdPosition) {
      angleAcc = state.smoothnessRaw;
    }

    double finalScore =
        (angleAcc * 0.40) +
        (state.stabilityRaw * 0.30) +
        (100.0 * 0.20) +
        (state.smoothnessRaw * 0.10);

    return finalScore;
  }

  void pauseExercise() {
    state = state.copyWith(isPaused: true);
  }

  void resumeExercise() {
    state = state.copyWith(isPaused: false);
  }

  void stopExercise() {
    _gaitSub?.cancel();
    _holdTimer?.cancel();
    _restTimer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  ExerciseResult calculateFinalScore() {
    double avgRepScore = 0.0;
    if (state.repScores.isNotEmpty) {
      avgRepScore =
          state.repScores.reduce((a, b) => a + b) / state.repScores.length;
    }

    return ExerciseResult(
      date: DateTime.now(),
      exerciseType: state.currentExercise,
      finalScore: avgRepScore,
      angleAccuracy: avgRepScore,
      stabilityScore: state.stabilityRaw,
      holdDurationScore: 100.0,
      smoothnessScore: state.smoothnessRaw,
      peakAngle: state.peakAngle,
      holdTime: state.holdSeconds,
      totalReps: state.totalReps,
      completedReps: state.completedReps,
      repScores: state.repScores,
    );
  }

  void dispose() {
    _gaitSub?.cancel();
    _holdTimer?.cancel();
    _restTimer?.cancel();
    state = const ExerciseSessionState(); // Full reset
  }
}

final exerciseSessionProvider =
    NotifierProvider<ExerciseSessionNotifier, ExerciseSessionState>(
      ExerciseSessionNotifier.new,
    );
