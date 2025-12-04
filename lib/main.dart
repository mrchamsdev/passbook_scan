import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth/welcome_screen.dart';
import 'screens/main_navigation.dart';
import 'utils/app_theme.dart';
import 'myapp.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  try {
    await dotenv.load(fileName: ".env");
    print('✅ Environment variables loaded successfully');
  } catch (e) {
    print('⚠️ Warning: Could not load .env file: $e');
    print('⚠️ Using default values or hardcoded URLs');
  }

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
        scaffoldBackgroundColor: AppTheme.scaffoldBackground,
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.primaryBlue,
          primary: AppTheme.primaryBlue,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: AppTheme.primaryButtonStyle,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: AppTheme.textPrimary),
          titleTextStyle: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: MyApp.authStateStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text(' Snapshot Error: ${snapshot.error}')),
          );
        } else {
          return snapshot.data == true
              ? const MainNavigation()
              : const WelcomeScreen();
        }
      },
    );
  }
}
