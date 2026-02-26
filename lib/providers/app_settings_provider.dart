import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Settings State ────────────────────────────────────────────────────
class AppSettings {
  final bool isMockMode;
  final String? selectedPatientId;
  final String? selectedPatientName;

  const AppSettings({
    this.isMockMode = true, // Safe default: demo mode ON
    this.selectedPatientId,
    this.selectedPatientName,
  });

  AppSettings copyWith({
    bool? isMockMode,
    String? selectedPatientId,
    String? selectedPatientName,
  }) {
    return AppSettings(
      isMockMode: isMockMode ?? this.isMockMode,
      selectedPatientId: selectedPatientId ?? this.selectedPatientId,
      selectedPatientName: selectedPatientName ?? this.selectedPatientName,
    );
  }
}

class AppSettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => const AppSettings();

  void toggleMockMode() {
    state = state.copyWith(isMockMode: !state.isMockMode);
  }

  void setMockMode(bool value) {
    state = state.copyWith(isMockMode: value);
  }

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
