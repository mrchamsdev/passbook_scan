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
import 'widgets/deactivate_account_button.dart';
import 'support/contact_us_screen.dart';
import 'support/about_us_screen.dart';
import 'dart:async';
import 'dart:io';

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

      if (response.length >= 2) {
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

  String _formatDateForAPI(DateTime date) {
    // Format: 2025-12-19T10:00:00.000Z
    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final second = date.second.toString().padLeft(2, '0');
    return '$year-$month-${day}T$hour:$minute:$second.000Z';
  }

  Future<void> _handleDeactivateAccount(BuildContext context) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.errorColor,
                        AppTheme.errorColor.withOpacity(0.8),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.errorColor.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 0,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                // Title
                const Text(
                  'Deactivate Account',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 16),
                // Message
                Text(
                  'Are you sure you want to deactivate your account? This action will restrict access to your data.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15.5,
                    color: AppTheme.textSecondary.withOpacity(0.9),
                    height: 1.6,
                    letterSpacing: 0.1,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: AppTheme.borderColor,
                              width: 1,
                            ),
                          ),
                        ),
                        child: const Text(
                          'No',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.errorColor,
                              AppTheme.errorColor.withOpacity(0.9),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.errorColor.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 0,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => Navigator.of(context).pop(true),
                            splashColor: Colors.white.withOpacity(0.2),
                            highlightColor: Colors.white.withOpacity(0.1),
                            child: Container(
                              alignment: Alignment.center,
                              child: const Text(
                                'Yes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                ),
                SizedBox(height: 16),
                Text(
                  'Deactivating account...',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      print('🔄 [DEACTIVATE ACCOUNT] Starting deactivation process...');
      final now = DateTime.now();
      final deactivationDate = _formatDateForAPI(now);
      print('   📅 Deactivation Date: $deactivationDate');
      print('   🗑️ Want to Delete: Yes');

      final deactivateURL = '${dotenv.env['API_URL']}users/accountStatus';
      print('🌐 [API CALL] Making PUT request to: $deactivateURL');

      final requestBody = {
        'status': 'deActive',
        'doYouWantToDelete': 'Yes',
        'deActivationDate': deactivationDate,
      };

      print('📦 [PAYLOAD] $requestBody');

      final response = await ServiceWithPutHeader(deactivateURL, requestBody)
          .data()
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('⏱️ [TIMEOUT] Request timed out after 30 seconds');
          throw TimeoutException('Request timed out after 30 seconds');
        },
      );

      print('📥 [RESPONSE] Received response from server');
      print('📊 [RESPONSE] Status Code: ${response[0]}');
      print('📝 [RESPONSE] Body: ${response[1]}');

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        if (response[0] == 200 || response[0] == 201) {
          print('🎉 [SUCCESS] Account deactivated successfully!');

          // Show success dialog
          CustomDialog.show(
            context: context,
            message: 'Your account has been deactivated successfully.',
            type: DialogType.success,
            title: 'Account Deactivated',
            buttonText: 'OK',
            barrierDismissible: false,
            onButtonPressed: () {
              Navigator.of(context).pop();
              // Clear auth token and navigate to welcome screen
              MyApp.clearAuthToken();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const WelcomeScreen(),
                ),
                (route) => false,
              );
            },
          );
        } else {
          print('❌ [API ERROR] Status Code: ${response[0]}');
          print('❌ [API ERROR] Response Body: ${response[1]}');

          String errorMessage =
              'Failed to deactivate account. Please try again.';
          if (response[1] != null && response[1] is Map) {
            final errorData = response[1] as Map<String, dynamic>;
            if (errorData.containsKey('message')) {
              errorMessage = errorData['message'].toString();
            } else if (errorData.containsKey('error')) {
              errorMessage = errorData['error'].toString();
            }
          }

          CustomDialog.show(
            context: context,
            message: errorMessage,
            type: DialogType.error,
            title: 'Deactivation Failed',
            buttonText: 'OK',
            barrierDismissible: true,
          );
        }
      }
    } on TimeoutException catch (e) {
      print('⏱️ [TIMEOUT] ${e.toString()}');
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        CustomDialog.show(
          context: context,
          message:
              'Request timed out. Please check your internet connection and try again.',
          type: DialogType.error,
          title: 'Timeout Error',
          buttonText: 'OK',
          barrierDismissible: true,
        );
      }
    } on SocketException catch (e) {
      print('🌐 [NETWORK ERROR] ${e.toString()}');
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        CustomDialog.show(
          context: context,
          message:
              'Network error. Please check your internet connection and try again.',
          type: DialogType.error,
          title: 'Network Error',
          buttonText: 'OK',
          barrierDismissible: true,
        );
      }
    } catch (e) {
      print('💥 [DEACTIVATE FAILED] Exception: $e');
      print('🔄 [DEACTIVATE FAILED] Stack trace: ${e.toString()}');

      String errorMessage =
          'Failed to deactivate account. Please check your internet connection and try again.';
      if (e.toString().contains('timeout') || e.toString().contains('Timeout')) {
        errorMessage =
            'Request timed out. Please check your internet connection and try again.';
      } else if (e.toString().contains('SocketException') ||
          e.toString().contains('network') ||
          e.toString().contains('Network')) {
        errorMessage = 'Network error. Please check your internet connection.';
      }

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        CustomDialog.show(
          context: context,
          message: errorMessage,
          type: DialogType.error,
          title: 'Error',
          buttonText: 'OK',
          barrierDismissible: true,
        );
      }
    }
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
                        const SizedBox(height: 16),
                        // Deactivate Account Button
                        DeactivateAccountButton(
                          onPressed: () => _handleDeactivateAccount(context),
                        ),
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
