import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/gait_provider.dart';
import '../../providers/patient_provider.dart';
import '../session_summary/session_summary_screen.dart';

class ClinicalDashboardScreen extends ConsumerStatefulWidget {
  final String patientId;
  final String patientName;
  const ClinicalDashboardScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  ConsumerState<ClinicalDashboardScreen> createState() =>
      _ClinicalDashboardScreenState();
}

class _ClinicalDashboardScreenState
    extends ConsumerState<ClinicalDashboardScreen> {
  Timer? _timer;
  int _secondsElapsed = 0;
  final int _maxDataPoints = 60;
  final List<FlSpot> _leftKneeSpots = [];
  final List<FlSpot> _rightKneeSpots = [];
  final List<TelemetryPoint> _sessionTelemetry = [];
  double _timeIndex = 0;
  int _stepCount = 0;
  bool _alertActive = false;
  String _alertMessage = "";

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _secondsElapsed++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime() {
    int minutes = _secondsElapsed ~/ 60;
    int seconds = _secondsElapsed % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _processData(GaitData data) {
    if (!mounted) return;

    _timeIndex++;
    _leftKneeSpots.add(FlSpot(_timeIndex, data.leftKneeFlexion));
    _rightKneeSpots.add(FlSpot(_timeIndex, data.rightKneeFlexion));

    if (_leftKneeSpots.length > _maxDataPoints) {
      _leftKneeSpots.removeAt(0);
      _rightKneeSpots.removeAt(0);
    }

    _sessionTelemetry.add(
      TelemetryPoint(
        timestamp: DateTime.now(),
        leftKneeAngle: data.leftKneeFlexion,
        rightKneeAngle: data.rightKneeFlexion,
        leftHipAngle: data.leftHipExtension,
        rightHipAngle: data.rightHipExtension,
        cadence: data.cadence,
        leftStepDuration: data.leftStepDuration,
        rightStepDuration: data.rightStepDuration,
        accelX: data.accelX,
        accelY: data.accelY,
        accelZ: data.accelZ,
        pitch: data.pitch,
        roll: data.roll,
        yaw: data.yaw,
        stepDetected: data.stepDetected,
        stabilityLevel: data.stabilityLevel,
      ),
    );

    // Real Step Detection
    if (data.stepDetected) {
      _stepCount++;
    }

    // Alert Logic
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (data.maxFlexionRange < 30.0) {
          _showAlert("Warning: Stiff Knee Movement detected");
        } else if (data.symmetry < 70.0) {
          _showAlert("Warning: Significant Imbalance");
        } else if (_alertActive) {
          setState(() {
            _alertActive = false;
          });
        }
      }
    });
  }

  void _showAlert(String message) {
    if (_alertActive && _alertMessage == message) return;
    setState(() {
      _alertActive = true;
      _alertMessage = message;
    });
  }

  void _endSession(GaitData currentData) {
    // Generate the full session record
    final currentSession = PatientSession(
      date: DateTime.now(),
      averageMobilityScore: currentData.mobilityScore,
      telemetryData: _sessionTelemetry,
    );

    ref
        .read(patientListProvider.notifier)
        .addSession(widget.patientId, currentSession);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SessionSummaryScreen(
          finalMobilityScore: currentData.mobilityScore,
          finalSymmetry: currentData.symmetry,
          avgFlexion: currentData.maxFlexionRange, // approx avg from last
          totalSteps: _stepCount,
          avgStepDuration: currentData.leftStepDuration, // Sample duration
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gaitStream = ref.watch(gaitDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.patientName),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                _formatTime(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: gaitStream.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (data) {
                _processData(data);

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    children: [
                      _buildGraphSection(),
                      const SizedBox(height: 24),
                      _buildMetricsGrid(data),
                      const SizedBox(height: 48),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _endSession(data),
                          icon: const Icon(
                            Icons.stop_circle_outlined,
                            color: Colors.white,
                          ),
                          label: const Text("End Session"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Alert Overlay
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            top: _alertActive ? 16.0 : -100.0,
            left: 24.0,
            right: 24.0,
            child: SafeArea(
              child: Card(
                color: AppColors.warning,
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _alertMessage,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraphSection() {
    return Card(
      elevation: AppTheme.cardElevation,
      child: Container(
        height: 250,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          boxShadow: AppTheme.softShadows,
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Knee Flexion (°)",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Row(
                  children: [
                    _buildLegendItem("Left", AppColors.success),
                    const SizedBox(width: 12),
                    _buildLegendItem("Right", AppColors.primary),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: RepaintBoundary(
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: _timeIndex > _maxDataPoints
                        ? _timeIndex - _maxDataPoints
                        : 0,
                    maxX: _timeIndex,
                    minY: 0,
                    maxY: 90,
                    lineBarsData: [
                      LineChartBarData(
                        spots: _leftKneeSpots,
                        isCurved: true,
                        color: AppColors.success,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                      ),
                      LineChartBarData(
                        spots: _rightKneeSpots,
                        isCurved: true,
                        color: AppColors.primary,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildMetricsGrid(GaitData data) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.1,
      children: [
        _buildGaugeCard(data.symmetry),
        _buildScoreCard(data.mobilityScore),
        _buildMetricCard(
          "Cadence",
          data.cadence.toStringAsFixed(0),
          "Steps/min",
        ),
        _buildMetricCard("Step Count", "$_stepCount", "Total Steps"),
      ],
    );
  }

  Widget _buildGaugeCard(double symmetry) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          boxShadow: AppTheme.softShadows,
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Symmetry", style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            SizedBox(
              height: 80,
              width: 80,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: symmetry / 100,
                    strokeWidth: 10,
                    backgroundColor: AppColors.greyLight,
                    color: symmetry > 80
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                  Center(
                    child: Text(
                      "${symmetry.toStringAsFixed(0)}%",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(double score) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          boxShadow: AppTheme.softShadows,
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Live Score", style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            Text(
              score.toStringAsFixed(0),
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 56,
                color: AppColors.primary,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String subtitle) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          boxShadow: AppTheme.softShadows,
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.greyText),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
