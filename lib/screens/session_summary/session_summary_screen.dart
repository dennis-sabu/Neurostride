import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../patients/patient_list_screen.dart';

class SessionSummaryScreen extends StatelessWidget {
  final double finalMobilityScore;
  final double finalSymmetry;
  final double avgFlexion;
  final int totalSteps;
  final double avgStepDuration;

  const SessionSummaryScreen({
    super.key,
    required this.finalMobilityScore,
    required this.finalSymmetry,
    required this.avgFlexion,
    required this.totalSteps,
    required this.avgStepDuration,
  });

  String _getSymmetryLabel() {
    if (finalSymmetry >= 90) return "Excellent Symmetry";
    if (finalSymmetry >= 80) return "Slight Asymmetry";
    if (finalSymmetry >= 70) return "Mild Asymmetry";
    return "Significant Asymmetry";
  }

  String _getFlexionComparison() {
    if (avgFlexion >= 50 && avgFlexion <= 60) {
      return "Within Normal Range (50-60°)";
    }
    if (avgFlexion < 50) {
      return "Below Normal (< 50°)";
    }
    return "Above Normal (> 60°)";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Session Summary"),
        automaticallyImplyLeading: false, // Force them to use actions
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const PatientListScreen(),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeroCard(context),
            const SizedBox(height: 24),
            Text(
              "Logic Summary",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildLogicSummary(context),
            const SizedBox(height: 24),
            Text(
              "Progress Comparison",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildComparisonCard(context),
            const SizedBox(height: 48),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return Card(
      elevation: AppTheme.cardElevation,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          boxShadow: AppTheme.softShadows,
        ),
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Text(
              "Final Mobility Score",
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppColors.greyText),
            ),
            const SizedBox(height: 16),
            Text(
              finalMobilityScore.toStringAsFixed(0),
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 72,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogicSummary(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryItem(
                context,
                "Gait Symmetry",
                "${finalSymmetry.toStringAsFixed(1)}%",
                _getSymmetryLabel(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryItem(
                context,
                "Average Flexion",
                "${avgFlexion.toStringAsFixed(1)}°",
                _getFlexionComparison(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSummaryItem(
                context,
                "Total Steps",
                "$totalSteps",
                "Recorded over session",
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryItem(
                context,
                "Avg Step Dur.",
                "${avgStepDuration.toStringAsFixed(2)}s",
                "Kinematic Analysis",
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String title,
    String value,
    String subtitle,
  ) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          boxShadow: AppTheme.softShadows,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: AppColors.greyText),
            ),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.warning),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonCard(BuildContext context) {
    return Card(
      child: Container(
        height: 250,
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          boxShadow: AppTheme.softShadows,
        ),
        child: BarChart(
          BarChartData(
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        value.toInt() == 0 ? "Last Session" : "Today",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.greyText,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: [
              BarChartGroupData(
                x: 0,
                barRods: [
                  BarChartRodData(
                    toY: 65, // mock last session score
                    color: AppColors.greyLight,
                    width: 40,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ],
              ),
              BarChartGroupData(
                x: 1,
                barRods: [
                  BarChartRodData(
                    toY: finalMobilityScore,
                    color: AppColors.success,
                    width: 40,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ],
              ),
            ],
            maxY: 100,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Saved to Cloud successfully.')),
            );
          },
          icon: const Icon(Icons.cloud_upload_outlined, color: Colors.white),
          label: const Text("Save to Cloud"),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('CSV Exported.')));
          },
          icon: const Icon(
            Icons.file_download_outlined,
            color: AppColors.primary,
          ),
          label: const Text(
            "Export CSV",
            style: TextStyle(color: AppColors.primary),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: const BorderSide(color: AppColors.greyLight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            ),
          ),
        ),
      ],
    );
  }
}
