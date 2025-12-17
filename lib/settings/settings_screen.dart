import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/app_theme.dart';
import '../utils/custom_dialog.dart';
import '../auth/welcome_screen.dart';
import 'package:bank_scan/myapp.dart';
import '../services/network_service.dart';
import '../widgets/bank_loader.dart';
import 'widgets/profile_header_card.dart';
import 'widgets/profile_details_section.dart';
import 'widgets/support_section.dart';
import 'widgets/logout_button.dart';
import 'support/contact_us_screen.dart';
import 'support/about_us_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    print('🔄 [SETTINGS] Fetching user details...');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userDetailsURL = '${dotenv.env['API_URL']}users/userDetails';
      print('🌐 [SETTINGS] API URL: $userDetailsURL');
      var response = await ServiceWithHeader(userDetailsURL).data();
      print('📥 [SETTINGS] API Response received');

      if (response is List && response.length >= 2) {
        int statusCode = response[0];
        dynamic responseBody = response[1];

        if (statusCode == 200 && responseBody != null) {
          print('✅ [SETTINGS] API Status: $statusCode');
          if (responseBody is Map<String, dynamic>) {
            // Check if response has 'status' and 'data' structure
            if (responseBody['status'] == 'success' &&
                responseBody['data'] != null) {
              setState(() {
                _userData = responseBody['data'] as Map<String, dynamic>;
                _isLoading = false;
              });
              print('✅ [SETTINGS] User data loaded successfully');
              return;
            } else if (responseBody.containsKey('id')) {
              // Direct data structure
              setState(() {
                _userData = responseBody;
                _isLoading = false;
              });
              print('✅ [SETTINGS] User data loaded successfully');
              return;
            }
          }
        }
        print('⚠️ [SETTINGS] Unexpected response format');
      }

      print('❌ [SETTINGS] Failed to load user details');
      setState(() {
        _errorMessage = 'Failed to load user details';
        _isLoading = false;
      });
    } catch (e) {
      print('❌ [SETTINGS] Error: $e');
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _handleLogout(BuildContext context) {
    CustomDialog.show(
      context: context,
      message: 'Are you sure you want to logout?',
      type: DialogType.warning,
      title: 'Logout',
      buttonText: 'Logout',
      barrierDismissible: true,
      onButtonPressed: () {
        Navigator.of(context).pop();
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
            userName: _userData?['name']?.toString().trim() ?? 'User',
            userEmail: _userData?['email']?.toString() ?? '',
            userImageUrl: _userData?['profile']?.toString(),
          ),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: RefreshLoader(color: AppTheme.primaryBlue),
                  )
                : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppTheme.errorColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppTheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchUserDetails,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Details Section
                        ProfileDetailsSection(
                          userData: _userData ?? {},
                          onProfileUpdated: _fetchUserDetails,
                        ),
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
                        // const SizedBox(height: 20),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
