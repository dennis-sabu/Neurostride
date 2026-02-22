import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/patient_provider.dart';
import 'package:intl/intl.dart';
import '../dashboard/scan_selection_screen.dart';

class PatientDetailScreen extends StatelessWidget {
  final Patient patient;
  const PatientDetailScreen({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(patient.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPatientHeader(context),
            const SizedBox(height: 32),
            Text(
              "Session History",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            if (patient.sessions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    "No sessions recorded yet. Start scanning to capture data.",
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: patient.sessions.length,
                itemBuilder: (context, index) {
                  // Reverse order to show newest first
                  final session =
                      patient.sessions[patient.sessions.length - 1 - index];
                  return _buildSessionCard(context, session);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientHeader(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: AppColors.background,
          child: Text(
            patient.name.isNotEmpty ? patient.name.substring(0, 1) : "?",
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: AppColors.primary),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Age: ${patient.age}  |  Weight: ${patient.weight}kg",
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                "Condition:",
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.greyText),
              ),
              Text(
                patient.condition,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ScanSelectionScreen(
                        patientId: patient.id,
                        patientName: patient.name,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                icon: const Icon(Icons.monitor_heart_outlined, size: 20),
                label: const Text("Start Scanning"),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSessionCard(BuildContext context, PatientSession session) {
    final dateFormat = DateFormat('MMM d, yyyy - h:mm a');

    return Card(
      elevation: AppTheme.cardElevation,
      margin: const EdgeInsets.only(bottom: 16.0),
      child: ExpansionTile(
        title: Text(
          dateFormat.format(session.date),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          "Avg Mobility Score: ${session.averageMobilityScore.toStringAsFixed(1)}",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: session.averageMobilityScore > 75
                ? AppColors.success
                : AppColors.warning,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: AppColors.background,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Detailed Telemetry Log",
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 250,
                  child: ListView.builder(
                    itemCount: session.telemetryData.length,
                    itemBuilder: (context, index) {
                      final point = session.telemetryData[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.greyLight.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "+${index}s | Steps Detected: ${point.stepDetected} | Cadence: ${point.cadence.toStringAsFixed(0)}",
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.greyText,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Hip (L/R): ${point.leftHipAngle.toStringAsFixed(1)}° / ${point.rightHipAngle.toStringAsFixed(1)}°",
                                ),
                                Text(
                                  "Knee (L/R): ${point.leftKneeAngle.toStringAsFixed(1)}° / ${point.rightKneeAngle.toStringAsFixed(1)}°",
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Step Dur (L/R): ${point.leftStepDuration.toStringAsFixed(2)}s / ${point.rightStepDuration.toStringAsFixed(2)}s",
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  "Stability: ${point.stabilityLevel}",
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: point.stabilityLevel == "Good"
                                            ? AppColors.success
                                            : AppColors.warning,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "IMU (X,Y,Z): Accel [${point.accelX.toStringAsFixed(1)}, ${point.accelY.toStringAsFixed(1)}, ${point.accelZ.toStringAsFixed(1)}] | Gyro [${point.pitch.toStringAsFixed(0)}°, ${point.roll.toStringAsFixed(0)}°, ${point.yaw.toStringAsFixed(0)}°]",
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(fontSize: 10),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
