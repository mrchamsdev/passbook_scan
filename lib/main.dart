import 'package:flutter/material.dart';
import 'auth/welcome_screen.dart';
import 'utils/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BankPassbookOCRApp());
}

class BankPassbookOCRApp extends StatelessWidget {
  const BankPassbookOCRApp({super.key});

  @override

  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bank Passbook OCR',
      theme: ThemeData(
        primaryColor: AppTheme.primaryBlue,
        scaffoldBackgroundColor: AppTheme.backgroundColor,
        useMaterial3: true,
        fontFamily: 'Inter',
        visualDensity: VisualDensity.adaptivePlatformDensity,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.primaryBlue,
          primary: AppTheme.primaryBlue,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: AppTheme.primaryButtonStyle,
        ),
      ),
      home: const WelcomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
