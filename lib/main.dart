import 'package:poultry_app/screens/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:poultry_app/config/themes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// MyApp widget
/// This widget is the root of the application.
/// It sets up the MaterialApp with a title, theme, and home screen.
/// The home screen is the SplashScreen.
/// The app uses a custom theme defined in the AppTheme class.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR0anZvZWR1cmRud21wb3FseWpsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk1NDg1NTgsImV4cCI6MjA3NTEyNDU1OH0.EKJuoOw7R0vHY9q-H0DKqWJHNSxA5FOpZutwN_p0t-k",
    url: 'https://ttjvoedurdnwmpoqlyjl.supabase.co',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FaunaPulse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      home: const SplashScreen(),
    );
  }
}