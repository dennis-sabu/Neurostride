import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'screens/onboarding/onboarding_screen.dart';

void main() {
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
      home: const OnboardingScreen(),
    );
  }
}
