import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BankPassbookOCRApp());
}

class BankPassbookOCRApp extends StatelessWidget {
  const BankPassbookOCRApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeoScan - Bank Passbook OCR',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Inter',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashScreen(), // Changed to SplashScreen
      debugShowCheckedModeBanner: false,
    );
  }
}
