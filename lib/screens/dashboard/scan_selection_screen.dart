import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'clinical_dashboard_screen.dart';

class ScanSelectionScreen extends StatelessWidget {
  final String patientId;
  final String patientName;

  const ScanSelectionScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Scan Type")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Scanning Patient: $patientName",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              "Select the body part or focus area to monitor during this session.",
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.greyText),
            ),
            const SizedBox(height: 32),
            _buildSelectionCard(
              context,
              title: "Full Lower Body Gait",
              description:
                  "Monitor bilateral kinematic symmetry, hips, knees, and overall step cadence.",
              icon: Icons.directions_walk,
              onTap: () => _startScan(context, "Full Lower Body"),
            ),
            const SizedBox(height: 16),
            _buildSelectionCard(
              context,
              title: "Left Leg Focus",
              description:
                  "Isolate telemetry to the left hip and knee extension sequences.",
              icon: Icons.airline_seat_legroom_reduced,
              onTap: () => _startScan(context, "Left Leg"),
            ),
            const SizedBox(height: 16),
            _buildSelectionCard(
              context,
              title: "Right Leg Focus",
              description:
                  "Isolate telemetry to the right hip and knee extension sequences.",
              icon: Icons.airline_seat_legroom_reduced,
              onTap: () => _startScan(context, "Right Leg"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: AppTheme.cardElevation,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            boxShadow: AppTheme.softShadows,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.greyText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.greyText),
            ],
          ),
        ),
      ),
    );
  }

  void _startScan(BuildContext context, String scanType) {
    // Navigate to the dashboard.
    // In the future, scanType can be passed to ClinicalDashboardScreen to adjust the view/logic
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClinicalDashboardScreen(
          patientId: patientId,
          patientName: patientName,
        ),
      ),
    );
  }
}
