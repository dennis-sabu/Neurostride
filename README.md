# NuroStride App: Complete Architecture & Functionality Documentation

This document provides a highly comprehensive, technically detailed breakdown of the **NuroStride** application. It explains the entire architecture, data flow, features, and core functions of the app, ready to be reviewed, copied, or used as official project documentation.

---

## 1. App Overview & Purpose

**NuroStride** is a Flutter-based mobile application designed for real-time gait analysis, physiotherapy monitoring, and physical rehabilitation. It pairs via Bluetooth Classic with custom hardware (an ESP32 named `NuroStride_ESP32` connected to IMU sensors) to stream live kinematic data, analyze patients' walking patterns, and guide them through specific rehabilitative exercises. 

State management across the app is handled using **Riverpod** (`flutter_riverpod`), ensuring a highly reactive and decoupled architecture.

---

## 2. Core Architecture & Data Flow

### The Hardware Bridge
The ESP32 sensor hardware continuously generates telemetry strings formatted as comma-separated key-value pairs (e.g., `S1:12.50,S2:45.60,KNEE:33.10,STAB:Good`). This data is transmitted locally via Bluetooth to the mobile app.

### The Software Pipeline
1. **Bluetooth Provider:** Manages the Bluetooth adapter, handles permissions, scans for `NuroStride_ESP32`, pairs, and establishes an active stream of `String` data.
2. **Gait Provider:** Listens strictly to the string stream from the Bluetooth Provider, parses the raw strings, validates the data, and converts them into strongly-typed `GaitData` objects.
3. **Session / Exercise Providers:** Consumer providers that listen to the `GaitData` stream. They apply business logic for live walking sessions (counting steps, monitoring cadence) or specific rehabilitative exercises (monitoring angles against target thresholds).
4. **UI Layer:** Reactive Flutter widgets watch these providers and rebuild automatically at 60fps to render live charts, progress rings, and real-time feedback metrics.

---

## 3. Detailed Component Breakdown

### 3.1. Main Entry & Routing (`lib/main.dart`)
- **Initialization:** Ensures `WidgetsFlutterBinding` is initialized. Global error catchers are implemented for both Flutter and the Platform Dispatcher to prevent hard crashes.
- **Theme:** The application uses a custom `AppTheme` enforcing a clean, likely clinical, light theme.
- **Navigation:** Implements a central `onGenerateRoute` switch statement handling programmatic routing across all screens (Login, Dashboard, Patients, Session Setup, Live Session, Exercises, etc.).

### 3.2. Data Models
- **`GaitData`:** The core primitive of the app. It holds left/right knee flexion, hip extension, cadence, step duration, raw IMU values (accel, pitch, roll, yaw), and stability condition. It dynamically calculates **Kinematic Symmetry (%)** and a compound **Mobility Score (0-100)**.
- **`Patient`:** Represents a clinical user. Holds biographical data (age, weight), condition/injury details, rehab start dates, historical progress arrays, saved generic sessions (`PatientSession`), and historical exercise results (`ExerciseResult`).
- **`ExerciseResult`:** A historically saved snapshot detailing how well a patient performed a specific exercise (contains breakdown scores for angle accuracy, stability, holding duration, and smoothness).

---

## 4. Core Provider Functionality

### 4.1. `BluetoothNotifier` (`lib/providers/bluetooth_provider.dart`)
Manages the `BluetoothState` which dictates UI changes (scanning, connecting, connected, failed).
* **`startScan()`:** First requests permissions using `AppPermissionHandler`. Validates the adapter is ON. Initiates a scan looking specifically for devices named `NuroStride_ESP32`.
* **`connectToDevice()`:** Attempts to securely bind to the ESP32 MAC address with a 3-try retry loop mechanism.
* **`listenForDisconnection()`:** Mounts a listener on the `BluetoothConnection.input` stream. Converts raw `Uint8List` byte arrays into UTF-8 strings and pipes them into a broadcast `StreamController<String>`.

### 4.2. `GaitProvider` (`lib/providers/gait_provider.dart`)
* **`_parseLine()`:** Critical parsing function. Splits incoming ESP32 comma-delimited strings. Matches keys like `S1`, `S2`, `KNEE`, and `STAB`.
* **Derived Math:** Calculates `symmetry` (by measuring the differential variance between left and right limb kinematics) and `mobilityScore` (a weighted average combining symmetry, maximum flexion range, and cadence).
* **`gaitStreamProvider`:** Exposes a clean `Stream<GaitData>` that all other parts of the app can safely consume without needing to know about Bluetooth connections.

### 4.3. `LiveSessionNotifier` (`lib/providers/session_provider.dart`)
Used during "Free Walk" or generic "Assessment" sessions.
* **Clock Timer:** Maintains a perfect 1-second ticking clock for session duration.
* **Gait Subscriber:** Listens to the live `GaitData` stream. 
* **State Updates:** Conditionally tracks step counts (if `stepDetected` is true), identifies the maximum `peakAngle` hit during the walk, and maintains a rolling 60-frame `angleHistory` array meant specifically for rendering live line charts on the UI.

### 4.4. `ExerciseSessionNotifier` (`lib/providers/exercise_provider.dart`)
Powers the guided physiotherapy exercise modules. Supports three modes: **Knee Bend**, **Straight Leg Raise**, and **Hold Position**.
* **Target Mechanics:** Each exercise type defines a specific `minTargetAngle`, `maxTargetAngle`, and required `holdSeconds`.
* **Dynamic Target Acquisition:** For "Hold Position", it captures the initial knee angle at the start of the exercise and builds a dynamic +/- 5 degree acceptable window.
* **Live Scoring Engine:** 
  * Calculates `smoothnessRaw` by penalizing sudden, jerky angle changes (> 10 degrees between rapid readings).
  * Calculates `stabilityRaw` by applying penalties if the ESP32 reports "Poor" or "Moderate" stability (based on raw accelerometer turbulence).
  * **`calculateFinalScore()`:** When the exercise stops, it executes a complex weighting formula: 40% Angle Accuracy + 30% Stability + 20% Hold Duration completeness + 10% Smoothness.

### 4.5. `PatientListNotifier` (`lib/providers/patient_provider.dart`)
Acts as the central, mock database for patient records.
* **State:** Holds a `List<Patient>`. Currently pre-populated with realistic mock clinical profiles (e.g., Post-Stroke Hemiparesis, Parkinson's).
* **Functions:** Supports `addPatient`, `removePatient`, `addSession` (saving a walking session to a patient's historical medical record), and `addExerciseResult` (saving a specific physiotherapy exercise score to their chart).

---

## 5. Security & Permissions (`lib/core/permissions/permission_handler.dart`)
Because NuroStride depends natively on Bluetooth, it requires strict Android permission management.
* Handles Android 12+ BLE permission matrices (`BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, `LOCATION`).
* Features an artificial 500ms debounce delay after permission grants to prevent fatal OS layout crashes when the Bluetooth radio initializes too quickly.
* Provides a fallback OS-level Settings redirect dialog if the user permanently denies permissions.

---

## 6. Summary of Key App Workflows

1. **Authentication & Profile selection:** The user logs in and selects a Patient profile from the Patient Management Screen.
2. **Setup:** The app navigates to the Bluetooth pairing screen. It validates permissions, scans, finds the `NuroStride_ESP32` bootloader, and establishes a serial connection.
3. **Execution Choice:**
   * **Live Walking Session:** The user enters a free-walk module. The app tracks steps, cadence, and overall gait symmetry.
   * **Exercise Mode:** The user selects a specific therapy regimen (e.g., Straight Leg Raise). The app uses real-time kinematic telemetry to ensure their leg hits the correct angle (e.g., 30 to 45 degrees) and holds it smoothly without shaking for perfectly timed durations (e.g., 5 seconds), outputting a gamified physical therapy score.
4. **Reporting:** Data from the active session is mathematically averaged and stored persistently into the selected Patient's progress charts.
