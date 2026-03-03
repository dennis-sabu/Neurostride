import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Screens
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/dashboard/history_screen.dart'; // <--- Added History Screen
import 'screens/patients/patient_management_screen.dart';
import 'screens/patients/patient_history_screen.dart';
import 'screens/session/session_setup_screen.dart';
import 'screens/session/live_session_screen.dart';
import 'screens/session/session_summary_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'core/theme/app_theme.dart';

// Exercise Screens
import 'screens/exercise/exercise_menu_screen.dart';
import 'screens/exercise/exercise_instruction_screen.dart';
import 'screens/exercise/live_exercise_screen.dart';
import 'screens/exercise/exercise_result_screen.dart';
import 'screens/exercise/free_walk_screen.dart'; // <--- Added
import 'screens/bluetooth/bluetooth_connect_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch all Flutter errors
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  // Catch all other errors
  PlatformDispatcher.instance.onError = (error, stack) {
    // Log error but do not crash app
    debugPrint('Error: $error');
    return true; // Prevent crash
  };

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark, // dark icons on light bg
      statusBarBrightness: Brightness.light,
    ),
  );
  runApp(const ProviderScope(child: NurostrideApp()));
}

class NurostrideApp extends StatelessWidget {
  const NurostrideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nurostride',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/onboarding',
      onGenerateRoute: _generateRoute,
      builder: (context, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          child: child!,
        );
      },
    );
  }

  Route<dynamic> _generateRoute(RouteSettings settings) {
    Widget page;

    switch (settings.name) {
      case '/onboarding':
        page = const OnboardingScreen();
        break;
      case '/dashboard':
        page = const DashboardScreen();
        break;
      case '/patients':
        page = const PatientManagementScreen();
        break;
      case '/patient_history':
        final id = settings.arguments as String?;
        page = PatientHistoryScreen(patientId: id);
        break;
      case '/session_setup':
        page = const SessionSetupScreen();
        break;
      case '/live_session':
        page = const LiveSessionScreen();
        break;
      case '/session_summary':
        page = const SessionSummaryScreen();
        break;
      case '/settings':
        page = const SettingsScreen();
        break;
      case '/exercise_menu':
        page = const ExerciseMenuScreen();
        break;
      case '/exercise_instruction':
        page = const ExerciseInstructionScreen();
        break;
      case '/live_exercise':
        page = const LiveExerciseScreen();
        break;
      case '/exercise_result':
        page = const ExerciseResultScreen();
        break;
      case '/free_walk':
        page = const FreeWalkScreen();
        break;
      case '/bluetooth_connect':
        page = const BluetoothConnectScreen();
        break;
      case '/history':
        page = const HistoryScreen();
        break;
      default:
        page = const DashboardScreen();
    }

    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}
