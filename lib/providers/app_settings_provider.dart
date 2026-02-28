import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Settings State ────────────────────────────────────────────────────
class AppSettings {
  final String? selectedPatientId;
  final String? selectedPatientName;

  const AppSettings({this.selectedPatientId, this.selectedPatientName});

  AppSettings copyWith({
    String? selectedPatientId,
    String? selectedPatientName,
  }) {
    return AppSettings(
      selectedPatientId: selectedPatientId ?? this.selectedPatientId,
      selectedPatientName: selectedPatientName ?? this.selectedPatientName,
    );
  }
}

class AppSettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => const AppSettings();

  void selectPatient({required String id, required String name}) {
    state = state.copyWith(selectedPatientId: id, selectedPatientName: name);
  }

  void clearSelectedPatient() {
    state = const AppSettings();
  }
}

final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);
