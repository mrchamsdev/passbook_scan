import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/custom_dialog.dart';
import '../auth/welcome_screen.dart';
import '../myapp.dart';
import '../screens/users_screen.dart';
import 'widgets/profile_header_card.dart';
import 'widgets/profile_details_section.dart';
import 'widgets/support_section.dart';
import 'widgets/logout_button.dart';
import 'support/contact_us_screen.dart';
import 'support/about_us_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _handleLogout(BuildContext context) {
    CustomDialog.show(
      context: context,
      message: 'Are you sure you want to logout?',
      type: DialogType.warning,
      title: 'Logout',
      buttonText: 'Logout',
      barrierDismissible: true,
      onButtonPressed: () {
        Navigator.of(context).pop(); // Close dialog
        MyApp.clearAuthToken();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          (route) => false,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      body: Column(
        children: [
          // Header with Profile Info
          ProfileHeaderCard(
            userName: 'John Doe',
            userEmail: 'john.doe@example.com',
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Details Section
                  ProfileDetailsSection(userProfile: "csndcms"),
                  const SizedBox(height: 24),
                  // Support Section
                  SupportSection(
                    onContactUs: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ContactUsScreen(),
                        ),
                      );
                    },
                    onAboutUs: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutUsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  // Logout Button
                  LogoutButton(onPressed: () => _handleLogout(context)),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
