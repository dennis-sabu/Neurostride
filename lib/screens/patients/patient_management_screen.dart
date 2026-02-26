import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/patient_provider.dart';
import '../../providers/app_settings_provider.dart';

class PatientManagementScreen extends ConsumerStatefulWidget {
  const PatientManagementScreen({super.key});
  @override
  ConsumerState<PatientManagementScreen> createState() =>
      _PatientManagementScreenState();
}

class _PatientManagementScreenState
    extends ConsumerState<PatientManagementScreen> {
  // Add patient form controllers
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _conditionCtrl = TextEditingController();
  String _selectedLeg = 'Left';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _conditionCtrl.dispose();
    super.dispose();
  }

  void _showAddPatient() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _AddPatientSheet(
        nameCtrl: _nameCtrl,
        ageCtrl: _ageCtrl,
        conditionCtrl: _conditionCtrl,
        selectedLeg: _selectedLeg,
        onLegChanged: (v) => setState(() => _selectedLeg = v),
        onSave: () {
          final name = _nameCtrl.text.trim();
          final age = int.tryParse(_ageCtrl.text.trim()) ?? 0;
          final condition = _conditionCtrl.text.trim();
          if (name.isEmpty || age == 0) return;
          ref
              .read(patientListProvider.notifier)
              .addPatient(
                Patient(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  age: age,
                  weight: 70,
                  condition: condition.isEmpty ? 'Gait Assessment' : condition,
                  affectedLeg: _selectedLeg,
                  rehabStartDate: DateTime.now().toString().substring(0, 10),
                ),
              );
          _nameCtrl.clear();
          _ageCtrl.clear();
          _conditionCtrl.clear();
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showPatientActions(BuildContext context, Patient p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  child: Text(
                    p.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: Icon(
                    Icons.play_arrow_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Start New Session'),
                  onTap: () {
                    ref
                        .read(appSettingsProvider.notifier)
                        .selectPatient(id: p.id, name: p.name);
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/session_setup');
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.bar_chart_rounded,
                    color: theme.colorScheme.secondary,
                  ),
                  title: const Text('View History'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                      context,
                      '/patient_history',
                      arguments: p.id,
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.error,
                  ),
                  title: const Text('Remove Patient'),
                  onTap: () {
                    ref.read(patientListProvider.notifier).removePatient(p.id);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final patients = ref.watch(patientListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Patient Directory')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPatient,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: patients.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_add_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No patients yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add your first patient',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: patients.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final p = patients[i];
                return _PatientCard(
                  patient: p,
                  onTap: () => _showPatientActions(context, p),
                );
              },
            ),
    );
  }
}

// ─── Patient Card ──────────────────────────────────────────────────────
class _PatientCard extends StatelessWidget {
  final Patient patient;
  final VoidCallback onTap;
  const _PatientCard({required this.patient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = patient.name.split(' ').map((w) => w[0]).take(2).join();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Name & condition
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Age: ${patient.age} | ${patient.condition}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Mini sparkline
            if (patient.progress.length > 1)
              SizedBox(
                width: 80,
                height: 40,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: patient.progress
                            .asMap()
                            .entries
                            .map((e) => FlSpot(e.key.toDouble(), e.value))
                            .toList(),
                        isCurved: true,
                        color: theme.colorScheme.secondary,
                        barWidth: 2,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: theme.colorScheme.secondary.withValues(
                            alpha: 0.15,
                          ),
                        ),
                      ),
                    ],
                    minY: 0,
                    maxY: 100,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add Patient Bottom Sheet ──────────────────────────────────────────
class _AddPatientSheet extends StatefulWidget {
  final TextEditingController nameCtrl, ageCtrl, conditionCtrl;
  final String selectedLeg;
  final void Function(String) onLegChanged;
  final VoidCallback onSave;

  const _AddPatientSheet({
    required this.nameCtrl,
    required this.ageCtrl,
    required this.conditionCtrl,
    required this.selectedLeg,
    required this.onLegChanged,
    required this.onSave,
  });

  @override
  State<_AddPatientSheet> createState() => _AddPatientSheetState();
}

class _AddPatientSheetState extends State<_AddPatientSheet> {
  late String _leg;

  @override
  void initState() {
    super.initState();
    _leg = widget.selectedLeg;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Add New Patient',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: widget.nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Full Name *',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.ageCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Age *',
                    prefixIcon: Icon(Icons.cake_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _leg,
                  decoration: InputDecoration(
                    labelText: 'Affected Leg',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                  ),
                  items: ['Left', 'Right', 'Both']
                      .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _leg = v);
                      widget.onLegChanged(v);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: widget.conditionCtrl,
            decoration: const InputDecoration(
              labelText: 'Condition / Diagnosis',
              prefixIcon: Icon(Icons.medical_information_outlined),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: widget.onSave,
            child: const Text('ADD PATIENT'),
          ),
        ],
      ),
    );
  }
}
