import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../patients/patient_list_screen.dart';
import '../patients/create_patient_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        automaticallyImplyLeading: false, // Prevent going back to login
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Welcome, Dr. Smith",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              "What would you like to do today?",
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.greyText),
            ),
            const SizedBox(height: 32),
            _buildActionCard(
              context,
              title: "Patient List & History",
              subtitle: "View your patient directories and past session data.",
              icon: Icons.folder_shared_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PatientListScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              context,
              title: "Start Scanning",
              subtitle:
                  "Select a patient to begin a new live telemetry session.",
              icon: Icons.monitor_heart_outlined,
              iconColor: AppColors.warning,
              onTap: () {
                // Clicking start scanning will redirect to patient list as requested
                // From there they can click a patient to start scanning (open dashboard)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const PatientListScreen(isSelectingForScan: true),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              context,
              title: "Add New Patient",
              subtitle: "Register a new profile and physical record.",
              icon: Icons.person_add_alt_1_outlined,
              iconColor: AppColors.success,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreatePatientScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = AppColors.primary,
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
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
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
}
