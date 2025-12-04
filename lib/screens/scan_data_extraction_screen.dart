import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../models/bank_data.dart';
import '../services/api_service.dart';

class ScanDataExtractionScreen extends StatefulWidget {
  final BankData bankData;
  final String imagePath;
  final VoidCallback? onSaveSuccess;
  final VoidCallback? onBack;

  const ScanDataExtractionScreen({
    super.key,
    required this.bankData,
    required this.imagePath,
    this.onSaveSuccess,
    this.onBack,
  });

  @override
  State<ScanDataExtractionScreen> createState() =>
      _ScanDataExtractionScreenState();

  static Future<void> navigateTo(
    BuildContext context, {
    required BankData bankData,
    required String imagePath,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ScanDataExtractionScreen(bankData: bankData, imagePath: imagePath),
        fullscreenDialog: true,
      ),
    );
  }
}

class _ScanDataExtractionScreenState extends State<ScanDataExtractionScreen> {
  late TextEditingController _customerNameController;
  late TextEditingController _accountNumberController;
  late TextEditingController _ifscCodeController;
  late TextEditingController _dateController;
  late TextEditingController _nicknameController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _aadharController;
  late TextEditingController _panController;
  late TextEditingController _commentController;
  late TextEditingController _amountToPayController;

  bool _isSaving = false;
  DateTime? _selectedDate;

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$year-$month-$day';
  }

  @override
  void initState() {
    super.initState();
    _customerNameController = TextEditingController(
      text: widget.bankData.accountHolderName,
    );
    _accountNumberController = TextEditingController(
      text: widget.bankData.accountNumber,
    );
    _ifscCodeController = TextEditingController(text: widget.bankData.ifscCode);
    _selectedDate = DateTime.now();
    _dateController = TextEditingController(text: _formatDate(_selectedDate!));
    _nicknameController = TextEditingController();
    _phoneNumberController = TextEditingController();
    _aadharController = TextEditingController();
    _panController = TextEditingController();
    _commentController = TextEditingController();
    _amountToPayController = TextEditingController();
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _accountNumberController.dispose();
    _ifscCodeController.dispose();
    _dateController.dispose();
    _nicknameController.dispose();
    _phoneNumberController.dispose();
    _aadharController.dispose();
    _panController.dispose();
    _commentController.dispose();
    _amountToPayController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = _formatDate(picked);
      });
    }
  }

  Future<void> _saveDetails() async {
    if (_customerNameController.text.isEmpty ||
        _accountNumberController.text.isEmpty ||
        _ifscCodeController.text.isEmpty ||
        _selectedDate == null ||
        _amountToPayController.text.isEmpty) {
      _showSnackBar('Please fill all required fields', false);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final photoFile = File(widget.imagePath);
      if (!await photoFile.exists()) {
        _showSnackBar('Photo file not found', false);
        setState(() => _isSaving = false);
        return;
      }

      final success = await ApiService.addPayment(
        accountNumber: _accountNumberController.text.trim(),
        ifscCode: _ifscCodeController.text.trim(),
        customerName: _customerNameController.text.trim(),
        paymentDate: _dateController.text.trim(),
        amountToPay: _amountToPayController.text.trim(),
        photo: photoFile,
        bankName: widget.bankData.branchName.isNotEmpty
            ? widget.bankData.branchName
            : null,
        nickname: _nicknameController.text.trim().isNotEmpty
            ? _nicknameController.text.trim()
            : null,
        phoneNumber: _phoneNumberController.text.trim().isNotEmpty
            ? _phoneNumberController.text.trim()
            : null,
        panNumber: _panController.text.trim().isNotEmpty
            ? _panController.text.trim()
            : null,
        aadhaarNumber: _aadharController.text.trim().isNotEmpty
            ? _aadharController.text.trim()
            : null,
        comments: _commentController.text.trim().isNotEmpty
            ? _commentController.text.trim()
            : null,
        bankInfoId: null, // Can be added later if needed
      );

      if (mounted) {
        setState(() => _isSaving = false);
        if (success) {
          _showSnackBar('Payment details saved successfully!', true);
          // Wait a bit for the snackbar to show, then handle navigation/callback
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              // If callback is provided (embedded mode), use it
              if (widget.onSaveSuccess != null) {
                widget.onSaveSuccess!();
              } else {
                // Otherwise, pop back (navigation mode)
                Navigator.of(context).pop();
              }
            }
          });
        } else {
          _showSnackBar('Failed to save payment details', false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showSnackBar('Error: $e', false);
      }
    }
  }

  void _showSnackBar(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess
            ? AppTheme.successColor
            : AppTheme.errorColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () {
            // If callback is provided (embedded mode), use it
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              // Otherwise, pop back (navigation mode)
              Navigator.of(context).pop();
            }
          },
        ),
        title: const Text(
          'Scan Document',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status Banner
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.lightBlueAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppTheme.primaryBlue,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Extraction completed',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Verify and edit details below.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            // Form Fields
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _customerNameController,
                      label: 'Customer Name',
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _accountNumberController,
                      label: 'Account Number',
                      icon: Icons.account_balance,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _ifscCodeController,
                      label: 'IFSC Code',
                      icon: Icons.code,
                    ),
                    const SizedBox(height: 16),
                    _buildDateField(),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _amountToPayController,
                      label: 'Amount to Pay',
                      icon: Icons.currency_rupee,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _nicknameController,
                      label: 'Nickname (Optional)',
                      icon: Icons.label,
                      isOptional: true,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneNumberController,
                      label: 'Phone Number (Optional)',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      isOptional: true,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _aadharController,
                      label: 'Aadhar Number (Optional)',
                      icon: Icons.badge,
                      keyboardType: TextInputType.number,
                      isOptional: true,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _panController,
                      label: 'PAN Number (Optional)',
                      icon: Icons.credit_card,
                      isOptional: true,
                    ),
                    const SizedBox(height: 16),
                    _buildCommentField(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // Save Button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isOptional = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryBlue),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return TextField(
      controller: _dateController,
      readOnly: true,
      onTap: _selectDate,
      decoration: InputDecoration(
        labelText: 'Payment Date',
        prefixIcon: const Icon(
          Icons.calendar_today,
          color: AppTheme.primaryBlue,
        ),
        suffixIcon: const Icon(
          Icons.arrow_drop_down,
          color: AppTheme.primaryBlue,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
        ),
      ),
    );
  }

  Widget _buildCommentField() {
    return TextField(
      controller: _commentController,
      maxLines: 4,
      decoration: InputDecoration(
        labelText: 'Add Comment (Optional)',
        prefixIcon: const Icon(Icons.comment, color: AppTheme.primaryBlue),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
        ),
      ),
    );
  }
}
