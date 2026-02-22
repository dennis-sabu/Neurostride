import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/patient_provider.dart';
import 'create_patient_screen.dart';
import 'patient_detail_screen.dart';
import '../dashboard/scan_selection_screen.dart';

class PatientListScreen extends ConsumerWidget {
  final bool isSelectingForScan;
  const PatientListScreen({super.key, this.isSelectingForScan = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patients = ref.watch(patientListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Patient Directory"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
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
      body: patients.isEmpty
          ? const Center(child: Text("No patients created yet."))
          : ListView.builder(
              padding: const EdgeInsets.all(24.0),
              itemCount: patients.length,
              itemBuilder: (context, index) {
                final patient = patients[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: InkWell(
                    onTap: () {
                      if (isSelectingForScan) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ScanSelectionScreen(
                              patientId: patient.id,
                              patientName: patient.name,
                            ),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PatientDetailScreen(patient: patient),
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(24.0),
                    child: Card(
                      elevation: AppTheme.cardElevation,
                      shadowColor: Colors.transparent,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24.0),
                          boxShadow: AppTheme.softShadows,
                        ),
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: AppColors.background,
                              child: Text(
                                patient.name.isNotEmpty
                                    ? patient.name.substring(0, 1)
                                    : "?",
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(color: AppColors.primary),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    patient.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Age: ${patient.age} | ${patient.condition}",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: AppColors.greyText),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (patient.progress.isNotEmpty)
                              SizedBox(
                                width: 100,
                                height: 50,
                                child: _buildSparkline(patient.progress),
                              ),
                            const SizedBox(width: 16),
                            const Icon(
                              Icons.chevron_right,
                              color: AppColors.greyText,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildSparkline(List<double> data) {
    if (data.isEmpty) return const SizedBox();

    List<FlSpot> spots = [];
    for (int i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i]));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: data.length.toDouble() - 1,
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.success,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.success.withAlpha(25),
            ),
          ),
        ],
      ),
    );
  }
}
