import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Screens
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/patients/patient_management_screen.dart';
import 'screens/patients/patient_history_screen.dart';
import 'screens/session/session_setup_screen.dart';
import 'screens/session/live_session_screen.dart';
import 'screens/session/session_summary_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      initialRoute: '/login',
      onGenerateRoute: _generateRoute,
    );
  }

  Route<dynamic> _generateRoute(RouteSettings settings) {
    Widget page;

    switch (settings.name) {
      case '/login':
        page = const LoginScreen();
        break;
      case '/signup':
        page = const SignUpScreen();
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
      default:
        page = const DashboardScreen();
    }

    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}
