import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nurostride_app/models/sensor_frame.dart';
import 'package:nurostride_app/providers/bluetooth_provider.dart';

class SensorDataState {
  final SensorFrame? latestFrame;
  final bool connectionLag;

  const SensorDataState({this.latestFrame, this.connectionLag = false});

  SensorDataState copyWith({SensorFrame? latestFrame, bool? connectionLag}) {
    return SensorDataState(
      latestFrame: latestFrame ?? this.latestFrame,
      connectionLag: connectionLag ?? this.connectionLag,
    );
  }
}

class SensorDataNotifier extends Notifier<SensorDataState> {
  StreamSubscription<String>? _dataSub;
  Timer? _renderTimer;
  Timer? _lagTimer;

  final List<double> _kneeAngleBuffer = [];
  static const int _bufferSize = 5;
  double _calibrationOffset = 0.0;
  bool _hasAutoCalibrated = false;

  SensorFrame? _currentFrame;
  DateTime? _lastFrameTime;

  @override
  SensorDataState build() {
    // Listen to bluetooth data stream
    final bluetoothState = ref.watch(bluetoothProvider);

    // Set up render tick at ~30fps (~33ms)
    _renderTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      _updateUiState();
    });

    // Check for packet drops every 100ms
    _lagTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _checkLag();
    });

    ref.onDispose(() {
      _dataSub?.cancel();
      _renderTimer?.cancel();
      _lagTimer?.cancel();
    });

    if (bluetoothState.isConnected) {
      _startListening();
    } else {
      _stopListening();
    }

    return const SensorDataState();
  }

  void _startListening() {
    _dataSub?.cancel();
    _dataSub = ref.read(bluetoothProvider.notifier).dataStream.listen((line) {
      final now = DateTime.now();

      // Calculate smoothed knee angle first
      if (line.contains('KNEE:')) {
        try {
          final parts = line.split(',');
          for (var p in parts) {
            if (p.startsWith('KNEE:')) {
              final k = double.parse(p.split(':')[1]);
              _addKneeAngle(k);
              break;
            }
          }
        } catch (_) {}
      }

      final frame = SensorFrame.tryParse(line, now, _getSmoothedKneeAngle());
      if (frame != null) {
        _currentFrame = frame;
        _lastFrameTime = now;
      }
    });
  }

  void _stopListening() {
    _dataSub?.cancel();
    _dataSub = null;
    _currentFrame = null;
    _lastFrameTime = null;
    _kneeAngleBuffer.clear();
    _calibrationOffset = 0.0;
    _hasAutoCalibrated = false;
  }

  void _addKneeAngle(double angle) {
    if (_kneeAngleBuffer.length >= _bufferSize) {
      _kneeAngleBuffer.removeAt(0);
    }
    _kneeAngleBuffer.add(angle);

    // Auto-calibrate once the buffer is full for the first time.
    // This makes the standing/starting position always read as 0°.
    if (!_hasAutoCalibrated && _kneeAngleBuffer.length == _bufferSize) {
      _hasAutoCalibrated = true;
      calibrate();
    }
  }

  double _getSmoothedKneeAngle() {
    if (_kneeAngleBuffer.isEmpty) return 0.0;
    final sum = _kneeAngleBuffer.reduce((a, b) => a + b);
    return (sum / _kneeAngleBuffer.length) - _calibrationOffset;
  }

  /// Sets the current angle as the new zero reference point.
  void calibrate() {
    if (_kneeAngleBuffer.isEmpty) return;
    final sum = _kneeAngleBuffer.reduce((a, b) => a + b);
    _calibrationOffset = sum / _kneeAngleBuffer.length;
  }

  /// The current calibration offset (standing position baseline).
  double get calibrationOffset => _calibrationOffset;

  void _updateUiState() {
    if (_currentFrame != null) {
      // Only rebuild if the frame has actually updated since last tick
      if (state.latestFrame?.timestamp != _currentFrame!.timestamp) {
        state = state.copyWith(latestFrame: _currentFrame);
      }
    }
  }

  void _checkLag() {
    if (_lastFrameTime == null || !ref.read(bluetoothProvider).isConnected) {
      if (state.connectionLag) {
        state = state.copyWith(connectionLag: false);
      }
      return;
    }

    final delta = DateTime.now().difference(_lastFrameTime!).inMilliseconds;
    final isLagging = delta > 200;

    if (state.connectionLag != isLagging) {
      state = state.copyWith(connectionLag: isLagging);
    }
  }
}

final sensorDataProvider =
    NotifierProvider<SensorDataNotifier, SensorDataState>(
      SensorDataNotifier.new,
    );
