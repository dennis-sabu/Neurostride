import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'gait_provider.dart';

class FreeWalkState {
  final bool isRecording;
  final int durationSeconds;
  final double peakAngle;
  final double currentAngle;
  final List<FlSpot> dataPoints; // Timestamp and Angle

  FreeWalkState({
    this.isRecording = false,
    this.durationSeconds = 0,
    this.peakAngle = 0.0,
    this.currentAngle = 0.0,
    this.dataPoints = const [],
  });

  FreeWalkState copyWith({
    bool? isRecording,
    int? durationSeconds,
    double? peakAngle,
    double? currentAngle,
    List<FlSpot>? dataPoints,
  }) {
    return FreeWalkState(
      isRecording: isRecording ?? this.isRecording,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      peakAngle: peakAngle ?? this.peakAngle,
      currentAngle: currentAngle ?? this.currentAngle,
      dataPoints: dataPoints ?? this.dataPoints,
    );
  }
}

class FreeWalkNotifier extends Notifier<FreeWalkState> {
  StreamSubscription<GaitData>? _gaitSubscription;
  Timer? _durationTimer;
  double _timeCounter = 0;

  @override
  FreeWalkState build() => FreeWalkState();

  void toggleRecording() {
    if (state.isRecording) {
      stopRecording();
    } else {
      startRecording();
    }
  }

  void startRecording() {
    _timeCounter = 0;
    state = FreeWalkState(isRecording: true);

    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      state = state.copyWith(durationSeconds: state.durationSeconds + 1);
    });

    final gaitStream = ref.read(gaitStreamProvider);
    _gaitSubscription = gaitStream.listen((data) {
      _timeCounter += 0.1;

      final angle = data.kneeAngle;
      final newPeak = math.max(state.peakAngle, angle);

      final newPoints = List<FlSpot>.from(state.dataPoints);
      newPoints.add(FlSpot(_timeCounter, angle));

      if (newPoints.length > 150) {
        newPoints.removeAt(0);
      }

      state = state.copyWith(
        currentAngle: angle,
        peakAngle: newPeak,
        dataPoints: newPoints,
      );
    });
  }

  void stopRecording() {
    _durationTimer?.cancel();
    _gaitSubscription?.cancel();
    state = state.copyWith(isRecording: false);
  }

  void dispose() {
    _durationTimer?.cancel();
    _gaitSubscription?.cancel();
  }
}

final freeWalkProvider = NotifierProvider<FreeWalkNotifier, FreeWalkState>(
  FreeWalkNotifier.new,
);
