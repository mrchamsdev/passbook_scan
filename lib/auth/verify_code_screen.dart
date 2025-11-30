import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'set_password_screen.dart';

class VerifyCodeScreen extends StatefulWidget {
  final String email;

  const VerifyCodeScreen({super.key, required this.email});

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  String _otpCode = '';

  void _handleVerify() {
    if (_otpCode.length == 6) {
      // Navigate to set password screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SetPasswordScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 6-digit OTP'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleResend() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('OTP has been resent to your email'),
        backgroundColor: Color(0xFF1E3A8A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                // Title
                const Text(
                  'Verify Code',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                // Subtitle
                const Text(
                  'An authentication code has been sent to your Phone Number',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 40),
                // OTP Field Label
                const Text(
                  'Enter OTP',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 16),
                // OTP Input Field
                PinCodeTextField(
                  appContext: context,
                  length: 6,
                  obscureText: true,
                  obscuringCharacter: 'X',
                  animationType: AnimationType.fade,
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(12),
                    fieldHeight: 56,
                    fieldWidth: 48,
                    activeFillColor: const Color(0xFFF9FAFB),
                    inactiveFillColor: const Color(0xFFF9FAFB),
                    selectedFillColor: const Color(0xFFF9FAFB),
                    activeColor: const Color(0xFF1E3A8A),
                    inactiveColor: const Color(0xFFE5E7EB),
                    selectedColor: const Color(0xFF1E3A8A),
                  ),
                  cursorColor: const Color(0xFF1E3A8A),
                  animationDuration: const Duration(milliseconds: 300),
                  enableActiveFill: true,
                  keyboardType: TextInputType.number,
                  onCompleted: (value) {
                    _otpCode = value;
                  },
                  onChanged: (value) {
                    _otpCode = value;
                  },
                ),
                const SizedBox(height: 24),
                // Resend Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Didn't receive a code? ",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                    TextButton(
                      onPressed: _handleResend,
                      child: const Text(
                        'RESEND',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1E3A8A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Help Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Need Help?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                        children: [
                          const TextSpan(
                            text: 'If you cannot receive the code or if you changed phone number. ',
                          ),
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: () {
                                // Handle try different way
                                Navigator.pop(context);
                              },
                              child: const Text(
                                'Try a different way',
                                style: TextStyle(
                                  color: Color(0xFF1E3A8A),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                // Verify Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _handleVerify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'VERIFY',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

