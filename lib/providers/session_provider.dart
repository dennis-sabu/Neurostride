import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'gait_provider.dart';
import 'patient_provider.dart';

// ─── Live Session State ────────────────────────────────────────────────
class LiveSessionState {
  final bool isRunning;
  final bool isPaused;
  final int secondsElapsed;
  final int stepCount;
  final double peakAngle;
  final double currentAngle;
  final double cadence;
  final double mobilityScore;
  final String stabilityLevel;
  final List<double> angleHistory; // Last 60 readings for the graph

  const LiveSessionState({
    this.isRunning = false,
    this.isPaused = false,
    this.secondsElapsed = 0,
    this.stepCount = 0,
    this.peakAngle = 0,
    this.currentAngle = 0,
    this.cadence = 0,
    this.mobilityScore = 0,
    this.stabilityLevel = 'Good',
    this.angleHistory = const [],
  });

  LiveSessionState copyWith({
    bool? isRunning,
    bool? isPaused,
    int? secondsElapsed,
    int? stepCount,
    double? peakAngle,
    double? currentAngle,
    double? cadence,
    double? mobilityScore,
    String? stabilityLevel,
    List<double>? angleHistory,
  }) {
    return LiveSessionState(
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      secondsElapsed: secondsElapsed ?? this.secondsElapsed,
      stepCount: stepCount ?? this.stepCount,
      peakAngle: peakAngle ?? this.peakAngle,
      currentAngle: currentAngle ?? this.currentAngle,
      cadence: cadence ?? this.cadence,
      mobilityScore: mobilityScore ?? this.mobilityScore,
      stabilityLevel: stabilityLevel ?? this.stabilityLevel,
      angleHistory: angleHistory ?? this.angleHistory,
    );
  }

  // Build a PatientSession to save when done
  PatientSession toPatientSession() {
    return PatientSession(
      date: DateTime.now(),
      averageMobilityScore: mobilityScore,
      telemetryData: [], // Full telemetry not stored in state — summary only
    );
  }
}

// ─── Session Notifier ──────────────────────────────────────────────────
class LiveSessionNotifier extends Notifier<LiveSessionState> {
  StreamSubscription<GaitData>? _gaitSub;
  Timer? _clockTimer;

  @override
  LiveSessionState build() => const LiveSessionState();

  /// Start a session. Accepts a stream so it works with both mock and live BT.
  void startSession({required Stream<GaitData> dataStream}) {
    state = const LiveSessionState(isRunning: true);

    // 1-second clock tick
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.isPaused) {
        state = state.copyWith(secondsElapsed: state.secondsElapsed + 1);
      }
    });

    // Subscribe to the provided stream (mock or Bluetooth)
    _gaitSub = dataStream.listen((data) {
      if (state.isPaused || !state.isRunning) return;

      final angle = data.kneeAngle;
      final history = [...state.angleHistory, angle];
      if (history.length > 60) history.removeAt(0);

      final steps = data.stepDetected ? state.stepCount + 1 : state.stepCount;
      final peak = angle > state.peakAngle ? angle : state.peakAngle;

      state = state.copyWith(
        currentAngle: angle,
        angleHistory: history,
        stepCount: steps,
        peakAngle: peak,
        cadence: data.cadence,
        mobilityScore: data.mobilityScore,
        stabilityLevel: data.stabilityLevel,
      );
    });
  }

  void togglePause() {
    state = state.copyWith(isPaused: !state.isPaused);
  }

  void endSession() {
    _gaitSub?.cancel();
    _clockTimer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  void reset() {
    _gaitSub?.cancel();
    _clockTimer?.cancel();
    state = const LiveSessionState();
  }

  void dispose() {
    _gaitSub?.cancel();
    _clockTimer?.cancel();
  }
}

final liveSessionProvider =
    NotifierProvider<LiveSessionNotifier, LiveSessionState>(
      LiveSessionNotifier.new,
    );
