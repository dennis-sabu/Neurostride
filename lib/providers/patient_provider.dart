import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'exercise_provider.dart';

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

enum WorkoutType { exercise, gaitAssessment }

class WorkoutHistoryEntry {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final String patientId;
  final String patientName;
  final WorkoutType type;
  final int durationSeconds;

  // Exercise specific
  final ExerciseType? exerciseType;
  final double? finalScore;
  final double? angleAccuracy;
  final double? stabilityScore;
  final double? holdDurationScore;
  final double? smoothnessScore;
  final double? peakAngle;
  final int? totalReps;
  final int? completedReps;
  final List<double>? repScores;

  // Gait specific
  final int? stepCount;
  final double? cadence;
  final double? mobilityScore;
  final String? stabilityLevel;
  final double? peakKneeAngle;

  // Common
  final String? doctorNotes;

  WorkoutHistoryEntry({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.patientId,
    required this.patientName,
    required this.type,
    required this.durationSeconds,
    this.exerciseType,
    this.finalScore,
    this.angleAccuracy,
    this.stabilityScore,
    this.holdDurationScore,
    this.smoothnessScore,
    this.peakAngle,
    this.totalReps,
    this.completedReps,
    this.repScores,
    this.stepCount,
    this.cadence,
    this.mobilityScore,
    this.stabilityLevel,
    this.peakKneeAngle,
    this.doctorNotes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'patientId': patientId,
      'patientName': patientName,
      'type': type.name,
      'durationSeconds': durationSeconds,
      'exerciseType': exerciseType?.name,
      'finalScore': finalScore,
      'angleAccuracy': angleAccuracy,
      'stabilityScore': stabilityScore,
      'holdDurationScore': holdDurationScore,
      'smoothnessScore': smoothnessScore,
      'peakAngle': peakAngle,
      'totalReps': totalReps,
      'completedReps': completedReps,
      'repScores': repScores,
      'stepCount': stepCount,
      'cadence': cadence,
      'mobilityScore': mobilityScore,
      'stabilityLevel': stabilityLevel,
      'peakKneeAngle': peakKneeAngle,
      'doctorNotes': doctorNotes,
    };
  }

  factory WorkoutHistoryEntry.fromJson(Map<String, dynamic> json) {
    return WorkoutHistoryEntry(
      id: json['id'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      patientId: json['patientId'] as String,
      patientName: json['patientName'] as String,
      type: WorkoutType.values.firstWhere((e) => e.name == json['type']),
      durationSeconds: json['durationSeconds'] as int,
      exerciseType: json['exerciseType'] != null
          ? ExerciseType.values.firstWhere(
              (e) => e.name == json['exerciseType'],
              orElse: () => ExerciseType.kneeBend,
            )
          : null,
      finalScore: (json['finalScore'] as num?)?.toDouble(),
      angleAccuracy: (json['angleAccuracy'] as num?)?.toDouble(),
      stabilityScore: (json['stabilityScore'] as num?)?.toDouble(),
      holdDurationScore: (json['holdDurationScore'] as num?)?.toDouble(),
      smoothnessScore: (json['smoothnessScore'] as num?)?.toDouble(),
      peakAngle: (json['peakAngle'] as num?)?.toDouble(),
      totalReps: json['totalReps'] as int?,
      completedReps: json['completedReps'] as int?,
      repScores: (json['repScores'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      stepCount: json['stepCount'] as int?,
      cadence: (json['cadence'] as num?)?.toDouble(),
      mobilityScore: (json['mobilityScore'] as num?)?.toDouble(),
      stabilityLevel: json['stabilityLevel'] as String?,
      peakKneeAngle: (json['peakKneeAngle'] as num?)?.toDouble(),
      doctorNotes: json['doctorNotes'] as String?,
    );
  }
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
  final String injuryType;
  final String affectedLeg;
  final String rehabStartDate;
  final List<double> progress;
  final List<PatientSession> sessions;
  final List<ExerciseResult> exerciseHistory;
  final List<WorkoutHistoryEntry> workoutHistory;

  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.weight,
    required this.condition,
    this.injuryType = '',
    this.affectedLeg = 'Both',
    this.rehabStartDate = '',
    this.progress = const [],
    this.sessions = const [],
    this.exerciseHistory = const [],
    this.workoutHistory = const [],
  });

  Patient copyWith({
    String? id,
    String? name,
    int? age,
    double? weight,
    String? condition,
    String? injuryType,
    String? affectedLeg,
    String? rehabStartDate,
    List<double>? progress,
    List<PatientSession>? sessions,
    List<ExerciseResult>? exerciseHistory,
    List<WorkoutHistoryEntry>? workoutHistory,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      condition: condition ?? this.condition,
      injuryType: injuryType ?? this.injuryType,
      affectedLeg: affectedLeg ?? this.affectedLeg,
      rehabStartDate: rehabStartDate ?? this.rehabStartDate,
      progress: progress ?? this.progress,
      sessions: sessions ?? this.sessions,
      exerciseHistory: exerciseHistory ?? this.exerciseHistory,
      workoutHistory: workoutHistory ?? this.workoutHistory,
    );
  }
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

  void removePatient(String patientId) {
    state = state.where((p) => p.id != patientId).toList();
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
            exerciseHistory: patient.exerciseHistory,
          )
        else
          patient,
    ];
  }

  void addExerciseResult(String patientId, ExerciseResult result) {
    final index = state.indexWhere((p) => p.id == patientId);
    if (index == -1) return; // Patient not found - do not crash

    final patient = state[index];
    final updated = patient.copyWith(
      exerciseHistory: [...patient.exerciseHistory, result],
    );

    state = [...state.sublist(0, index), updated, ...state.sublist(index + 1)];
  }

  void addWorkoutEntry(String patientId, WorkoutHistoryEntry entry) {
    final index = state.indexWhere((p) => p.id == patientId);
    if (index == -1) return;

    final patient = state[index];
    final updated = patient.copyWith(
      workoutHistory: [...patient.workoutHistory, entry],
    );

    state = [...state.sublist(0, index), updated, ...state.sublist(index + 1)];
  }

  WorkoutHistoryEntry? getLastWorkout(String patientId, WorkoutType type) {
    final patient = state.firstWhere(
      (p) => p.id == patientId,
      orElse: () => state.first, // or null but sticking to standard structure
    );
    final filtered = patient.workoutHistory
        .where((w) => w.type == type)
        .toList();
    if (filtered.isEmpty) return null;
    return filtered.last;
  }
}

final patientListProvider =
    NotifierProvider<PatientListNotifier, List<Patient>>(() {
      return PatientListNotifier();
    });
