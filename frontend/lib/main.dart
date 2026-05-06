import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/data_provider.dart';
import 'providers/locale_provider.dart';
import 'screens/login_screen.dart';
import 'screens/language_selection_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/doctor_dashboard_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DataProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rural Telemedicine',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00897B),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: Consumer2<AuthProvider, LocaleProvider>(
        builder: (context, auth, locale, _) {
          if (!locale.hasSelectedLanguage) {
            return const LanguageSelectionScreen();
          }
          if (auth.isAuthenticated) {
            // Route doctor accounts to Doctor Dashboard
            if (auth.isDoctor) {
              return const DoctorDashboardScreen();
            }
            return const DashboardScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
