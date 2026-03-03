import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:nurostride_app/core/theme/app_colors.dart';
import 'package:nurostride_app/providers/bluetooth_provider.dart';
import 'package:nurostride_app/providers/sensor_data_provider.dart';

class LiveSensorDataScreen extends ConsumerWidget {
  const LiveSensorDataScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sensorState = ref.watch(sensorDataProvider);
    final bluetoothState = ref.watch(bluetoothProvider);

    final frame = sensorState.latestFrame;
    final isConnected = bluetoothState.isConnected;
    final isLagging = sensorState.connectionLag;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Live Sensor Data'),
        actions: [
          _ConnectionBadge(isConnected: isConnected, isLagging: isLagging),
          const SizedBox(width: 16),
        ],
      ),
      body: !isConnected
          ? _buildDisconnectedState(context)
          : frame == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Warnings
                  if (isLagging)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: const [
                          Icon(LucideIcons.alertTriangle, color: Colors.orange),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Connection Lag > 200ms',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Large Knee Angle Display
                  _KneeAngleCard(angle: frame.smoothedKneeAngle),

                  const SizedBox(height: 24),

                  // Stability Status
                  _StabilityCard(stability: frame.stability),

                  const SizedBox(height: 24),

                  // Other Metrics
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5,
                      children: [
                        _MetricCard(
                          title: 'Pitch 1',
                          value: '${frame.pitch1.toStringAsFixed(1)}°',
                        ),
                        _MetricCard(
                          title: 'Pitch 2',
                          value: '${frame.pitch2.toStringAsFixed(1)}°',
                        ),
                        _MetricCard(
                          title: 'Roll 1',
                          value: '${frame.roll1.toStringAsFixed(1)}°',
                        ),
                        _MetricCard(
                          title: 'Roll 2',
                          value: '${frame.roll2.toStringAsFixed(1)}°',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDisconnectedState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.bluetoothOff, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Sensor Disconnected',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Check your connection and try again.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Go to Connection Screen'),
          ),
        ],
      ),
    );
  }
}

class _ConnectionBadge extends StatelessWidget {
  final bool isConnected;
  final bool isLagging;

  const _ConnectionBadge({required this.isConnected, required this.isLagging});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.red;
    String text = 'Disconnected';

    if (isConnected) {
      if (isLagging) {
        color = Colors.orange;
        text = 'Lagging';
      } else {
        color = Colors.green;
        text = 'Connected';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _KneeAngleCard extends StatelessWidget {
  final double angle;

  const _KneeAngleCard({required this.angle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Knee Angle (Smoothed)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${angle.toStringAsFixed(1)}°',
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StabilityCard extends StatelessWidget {
  final String stability;

  const _StabilityCard({required this.stability});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.grey;
    final stabUpper = stability.toUpperCase();
    if (stabUpper.contains('GOOD')) {
      color = Colors.green;
    } else if (stabUpper.contains('WARN') ||
        stabUpper.contains('YELLOW') ||
        stabUpper.contains('FAIR')) {
      color = Colors.orange;
    } else if (stabUpper.contains('BAD') ||
        stabUpper.contains('POOR') ||
        stabUpper.contains('POO')) {
      color = Colors.red;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Stability Status',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              stability.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;

  const _MetricCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
