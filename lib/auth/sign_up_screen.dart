import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_theme.dart';
import 'sign_in_screen.dart';

enum CompanyType { individual, company }

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _panNumberController = TextEditingController();
  final _gstNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _ifscCodeController = TextEditingController();

  CompanyType _selectedCompanyType = CompanyType.individual;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _companyNameController.dispose();
    _panNumberController.dispose();
    _gstNumberController.dispose();
    _bankNameController.dispose();
    _bankAccountController.dispose();
    _ifscCodeController.dispose();
    super.dispose();
  }

  void _handleSignUp() {
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to terms & conditions'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      // Handle sign up logic here
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!'),
          backgroundColor: AppTheme.primaryBlue,
        ),
      );
      // Navigate to sign in screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const SignInScreen(),
        ),
      );
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!value.contains('@') || !value.contains('.')) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    if (value.length < 10) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please enter $fieldName';
    }
    return null;
  }

  String? _validatePAN(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter PAN Number';
    }
    // PAN format: ABCDE1234F
    if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(value.toUpperCase())) {
      return 'Please enter a valid PAN Number';
    }
    return null;
  }

  String? _validateGST(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter GST Number';
    }
    // GST format: 15 characters
    if (value.length != 15) {
      return 'GST Number must be 15 characters';
    }
    return null;
  }

  String? _validateIFSC(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter IFSC Code';
    }
    // IFSC format: 11 characters (4 letters + 0 + 6 alphanumeric)
    if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(value.toUpperCase())) {
      return 'Please enter a valid IFSC Code';
    }
    return null;
  }

  String? _validateAccountNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter Bank Account Number';
    }
    if (value.length < 9 || value.length > 18) {
      return 'Account number must be 9-18 digits';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
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
                  'Create an account',
                  style: AppTheme.headingLarge,
                ),
                const SizedBox(height: 8),
                // Subtitle
                const Text(
                  'Welcome To The App',
                  style: AppTheme.bodyLarge,
                ),
                const SizedBox(height: 32),
                // Name Field
                _buildLabel('Name'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: AppTheme.inputDecoration('Enter your name here'),
                  validator: _validateName,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 20),
                // Email Field
                _buildLabel('Email'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: AppTheme.inputDecoration('Enter your email here'),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 20),
                // Phone Number Field
                _buildLabel('Phone Number'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: AppTheme.inputDecoration('Enter your phone number here'),
                  validator: _validatePhone,
                ),
                const SizedBox(height: 20),
                // Password Field
                _buildLabel('Password'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: AppTheme.inputDecoration('Enter your password here').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: AppTheme.textHint,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 20),
                // Confirm Password Field
                _buildLabel('Confirm Password'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: AppTheme.inputDecoration('Enter your password here').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: AppTheme.textHint,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: _validateConfirmPassword,
                ),
                const SizedBox(height: 24),
                // Company Type Selection
                _buildLabel('Company Type*'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildCompanyTypeButton(
                        CompanyType.individual,
                        'Individual',
                        Icons.person,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCompanyTypeButton(
                        CompanyType.company,
                        'Company',
                        Icons.business,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Conditional Fields based on Company Type
                if (_selectedCompanyType == CompanyType.individual || _selectedCompanyType == CompanyType.company) ...[
                  // Company Name
                  _buildLabel('Company Name'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _companyNameController,
                    decoration: AppTheme.inputDecoration('Enter your company name here'),
                    validator: (value) => _validateRequired(value, 'company name'),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 20),
                  // PAN Number
                  _buildLabel('PAN Number'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _panNumberController,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: AppTheme.inputDecoration('Enter your PAN Number here'),
                    validator: _validatePAN,
                  ),
                  const SizedBox(height: 20),
                  // GST Number
                  _buildLabel('GST Number'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _gstNumberController,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(15),
                    ],
                    decoration: AppTheme.inputDecoration('Enter your GST Number here'),
                    validator: _validateGST,
                  ),
                ],
                // Additional fields for Company type
                if (_selectedCompanyType == CompanyType.company) ...[
                  const SizedBox(height: 20),
                  // Bank Name
                  _buildLabel('Bank Name'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _bankNameController,
                    decoration: AppTheme.inputDecoration('Enter your bank name here'),
                    validator: (value) => _validateRequired(value, 'bank name'),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 20),
                  // Bank Account Number
                  _buildLabel('Bank Account Number'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _bankAccountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(18),
                    ],
                    decoration: AppTheme.inputDecoration('Enter your bank account number here'),
                    validator: _validateAccountNumber,
                  ),
                  const SizedBox(height: 20),
                  // IFSC Code
                  _buildLabel('IFSC Code'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _ifscCodeController,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(11),
                    ],
                    decoration: AppTheme.inputDecoration('Enter your IFSC Code here'),
                    validator: _validateIFSC,
                  ),
                ],
                const SizedBox(height: 24),
                // Terms & Conditions
                Row(
                  children: [
                    Checkbox(
                      value: _agreeToTerms,
                      onChanged: (value) {
                        setState(() {
                          _agreeToTerms = value ?? false;
                        });
                      },
                      activeColor: AppTheme.primaryBlue,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _agreeToTerms = !_agreeToTerms;
                          });
                        },
                        child: const Text(
                          'I agree to all terms & conditions',
                          style: AppTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Sign Up Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _handleSignUp,
                    style: AppTheme.primaryButtonStyle,
                    child: const Text(
                      'SIGN-UP NOW',
                      style: AppTheme.buttonText,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Sign In Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an Account? ',
                      style: AppTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignInScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'SIGN IN',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildCompanyTypeButton(CompanyType type, String label, IconData icon) {
    final isSelected = _selectedCompanyType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCompanyType = type;
        });
      },
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : AppTheme.primaryBlue,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppTheme.primaryBlue,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

