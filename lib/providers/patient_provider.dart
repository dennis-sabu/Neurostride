import 'package:flutter_riverpod/flutter_riverpod.dart';

class PatientSession {
  final DateTime date;
  final double averageMobilityScore;
  final List<TelemetryPoint> telemetryData;

  PatientSession({
    required this.date,
    required this.averageMobilityScore,
    required this.telemetryData,
  });
}

class TelemetryPoint {
  final DateTime timestamp;
  final double leftKneeAngle;
  final double rightKneeAngle;
  final double leftHipAngle;
  final double rightHipAngle;
  final double cadence;
  final double leftStepDuration;
  final double rightStepDuration;
  final double accelX;
  final double accelY;
  final double accelZ;
  final double pitch;
  final double roll;
  final double yaw;
  final bool stepDetected;
  final String stabilityLevel;

  TelemetryPoint({
    required this.timestamp,
    required this.leftKneeAngle,
    required this.rightKneeAngle,
    required this.leftHipAngle,
    required this.rightHipAngle,
    required this.cadence,
    required this.leftStepDuration,
    required this.rightStepDuration,
    required this.accelX,
    required this.accelY,
    required this.accelZ,
    required this.pitch,
    required this.roll,
    required this.yaw,
    required this.stepDetected,
    required this.stabilityLevel,
  });
}

class Patient {
  final String id;
  final String name;
  final int age;
  final double weight;
  final String condition;
  final List<double> progress;
  final List<PatientSession> sessions;

  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.weight,
    required this.condition,
    required this.progress,
    this.sessions = const [],
  });
}

class PatientListNotifier extends Notifier<List<Patient>> {
  @override
  List<Patient> build() {
    return [
      Patient(
        id: '1',
        name: "Eleanor Vance",
        age: 68,
        weight: 65.0,
        condition: "Post-Stroke Hemiparesis",
        progress: [40.0, 50.0, 52.0, 60.0, 75.0, 82.0],
      ),
      Patient(
        id: '2',
        name: "Arthur Pendelton",
        age: 74,
        weight: 82.0,
        condition: "Parkinson's Disease",
        progress: [30.0, 32.0, 31.0, 35.0, 40.0, 42.0],
      ),
      Patient(
        id: '3',
        name: "Clara Bow",
        age: 55,
        weight: 60.0,
        condition: "Knee Arthroplasty Recovery",
        progress: [80.0, 82.0, 85.0, 87.0, 90.0, 95.0],
      ),
    ];
  }

  void addPatient(Patient patient) {
    state = [...state, patient];
  }

  void addSession(String patientId, PatientSession session) {
    state = [
      for (final patient in state)
        if (patient.id == patientId)
          Patient(
            id: patient.id,
            name: patient.name,
            age: patient.age,
            weight: patient.weight,
            condition: patient.condition,
            progress: [...patient.progress, session.averageMobilityScore],
            sessions: [...patient.sessions, session],
          )
        else
          patient,
    ];
  }
}

final patientListProvider =
    NotifierProvider<PatientListNotifier, List<Patient>>(() {
      return PatientListNotifier();
    });
