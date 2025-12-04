import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/app_theme.dart';
import '../services/network_service.dart';
import '../widgets/bank_loader.dart';
import '../utils/custom_dialog.dart';
import '../myapp.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _panController;
  late TextEditingController _gstNoController;
  late TextEditingController _aadharController;

  final ImagePicker _picker = ImagePicker();
  File? _selectedProfileImage;
  String? _currentProfileUrl;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.userData['name']?.toString() ?? '',
    );
    _phoneNumberController = TextEditingController(
      text: widget.userData['phoneNumber']?.toString() ?? '',
    );
    _panController = TextEditingController(
      text: widget.userData['pan']?.toString() ?? '',
    );
    _gstNoController = TextEditingController(
      text: widget.userData['gstNo']?.toString() ?? '',
    );
    _aadharController = TextEditingController(
      text: widget.userData['aadhar']?.toString() ?? '',
    );
    _currentProfileUrl = widget.userData['profile']?.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneNumberController.dispose();
    _panController.dispose();
    _gstNoController.dispose();
    _aadharController.dispose();
    super.dispose();
  }

  Future<void> _updateProfileWithMultipart() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get user ID from userData or MyApp
      final userId =
          widget.userData['id']?.toString() ??
          widget.userData['_id']?.toString() ??
          MyApp.userId?.toString() ??
          '1'; // Fallback to 1 if not found

      final updateUrl = '${dotenv.env['API_URL']}users/updateUser/$userId';
      print('🔄 [EDIT PROFILE] Updating profile...');
      print('🌐 [EDIT PROFILE] API URL: $updateUrl');

      var request = http.MultipartRequest('PUT', Uri.parse(updateUrl));

      // Add Authorization header
      request.headers['Authorization'] = 'Bearer ${MyApp.authTokenValue ?? ""}';

      // Add all text fields - always include all fields in form data
      request.fields['name'] = _nameController.text.trim();
      request.fields['phoneNumber'] = _phoneNumberController.text.trim();
      request.fields['pan'] = _panController.text.trim();
      request.fields['gstNo'] = _gstNoController.text.trim();
      request.fields['aadhar'] = _aadharController.text.trim();

      // Add profile image as multipart file
      if (_selectedProfileImage != null) {
        var imageBytes = await _selectedProfileImage!.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'profile',
            imageBytes,
            filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        );
        print(
          '📸 [EDIT PROFILE] Profile image added to request (${imageBytes.length} bytes)',
        );
      } else {
        // If no new image selected, send existing profile URL or empty string
        request.fields['profile'] = _currentProfileUrl ?? '';
      }

      // Log all form fields being sent
      print('📋 [EDIT PROFILE] Form fields:');
      request.fields.forEach((key, value) {
        print('   $key: ${value.isEmpty ? "(empty)" : value}');
      });
      print('📁 [EDIT PROFILE] Files: ${request.files.length}');
      if (request.files.isNotEmpty) {
        request.files.forEach((file) {
          print('   File: ${file.filename} (field: ${file.field})');
        });
      }

      print('📤 [EDIT PROFILE] Sending multipart request...');
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('📥 [EDIT PROFILE] Response status: ${response.statusCode}');
      print('📥 [EDIT PROFILE] Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        dynamic responseBody;
        try {
          responseBody = jsonDecode(response.body);
        } catch (e) {
          responseBody = response.body;
        }
        _handleUpdateResponse([response.statusCode, responseBody]);
      } else {
        _handleUpdateResponse([response.statusCode, jsonDecode(response.body)]);
      }
    } catch (e) {
      print('❌ [EDIT PROFILE] Multipart upload error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        CustomDialog.show(
          context: context,
          message: 'Error: ${e.toString()}',
          type: DialogType.error,
          title: 'Error',
          buttonText: 'OK',
          barrierDismissible: true,
        );
      }
    }
  }

  void _handleUpdateResponse(dynamic response) {
    if (response is List && response.length >= 2) {
      int statusCode = response[0];
      dynamic responseBody = response[1];

      if (statusCode == 200 || statusCode == 201) {
        print('✅ [EDIT PROFILE] Profile updated successfully');

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          CustomDialog.show(
            context: context,
            message: 'Profile updated successfully!',
            type: DialogType.success,
            title: 'Success',
            buttonText: 'OK',
            barrierDismissible: false,
            onButtonPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(
                context,
              ).pop(true); // Return to settings with success flag
            },
          );
        }
      } else {
        print('❌ [EDIT PROFILE] Failed to update profile. Status: $statusCode');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          CustomDialog.show(
            context: context,
            message:
                responseBody['message']?.toString() ??
                'Failed to update profile. Please try again.',
            type: DialogType.error,
            title: 'Error',
            buttonText: 'OK',
            barrierDismissible: true,
          );
        }
      }
    } else {
      print('❌ [EDIT PROFILE] Unexpected response format');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        CustomDialog.show(
          context: context,
          message: 'Failed to update profile. Please try again.',
          type: DialogType.error,
          title: 'Error',
          buttonText: 'OK',
          barrierDismissible: true,
        );
      }
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedProfileImage = File(image.path);
        });
      }
    } catch (e) {
      print('❌ [EDIT PROFILE] Error picking image: $e');
      if (mounted) {
        CustomDialog.show(
          context: context,
          message: 'Error selecting image: ${e.toString()}',
          type: DialogType.error,
          title: 'Error',
          buttonText: 'OK',
          barrierDismissible: true,
        );
      }
    }
  }

  Future<void> _captureProfileImage() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          CustomDialog.show(
            context: context,
            message: 'Camera permission is required to take a photo.',
            type: DialogType.warning,
            title: 'Permission Required',
            buttonText: 'OK',
            barrierDismissible: true,
          );
        }
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedProfileImage = File(image.path);
        });
      }
    } catch (e) {
      print('❌ [EDIT PROFILE] Error capturing image: $e');
      if (mounted) {
        CustomDialog.show(
          context: context,
          message: 'Error capturing image: ${e.toString()}',
          type: DialogType.error,
          title: 'Error',
          buttonText: 'OK',
          barrierDismissible: true,
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.camera_alt,
                  color: AppTheme.primaryBlue,
                ),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _captureProfileImage();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: AppTheme.primaryBlue,
                ),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickProfileImage();
                },
              ),
              if (_selectedProfileImage != null || _currentProfileUrl != null)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: AppTheme.errorColor,
                  ),
                  title: const Text(
                    'Remove Photo',
                    style: TextStyle(color: AppTheme.errorColor),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedProfileImage = null;
                      _currentProfileUrl = null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF002E6E), Color(0xFF2A66B9)],
            ),
          ),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Image Section
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _showImageSourceDialog,
                            child: Stack(
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: AppTheme.cardBackground,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppTheme.primaryBlue,
                                      width: 3,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: _selectedProfileImage != null
                                        ? Image.file(
                                            _selectedProfileImage!,
                                            fit: BoxFit.cover,
                                          )
                                        : _currentProfileUrl != null &&
                                              _currentProfileUrl!.isNotEmpty
                                        ? Image.network(
                                            _currentProfileUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    _buildDefaultProfileIcon(),
                                          )
                                        : _buildDefaultProfileIcon(),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryBlue,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _showImageSourceDialog,
                            child: const Text(
                              'Change Photo',
                              style: TextStyle(
                                color: AppTheme.primaryBlue,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Name Field
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Phone Number Field
                    _buildTextField(
                      controller: _phoneNumberController,
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your phone number';
                        }
                        if (value.trim().length < 10) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // PAN Number Field
                    _buildTextField(
                      controller: _panController,
                      label: 'PAN Number',
                      icon: Icons.credit_card_outlined,
                      isOptional: true,
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 20),

                    // GST Number Field
                    _buildTextField(
                      controller: _gstNoController,
                      label: 'GST Number',
                      icon: Icons.description_outlined,
                      isOptional: true,
                    ),
                    const SizedBox(height: 20),

                    // Aadhar Number Field
                    _buildTextField(
                      controller: _aadharController,
                      label: 'Aadhar Number',
                      icon: Icons.badge_outlined,
                      keyboardType: TextInputType.number,
                      isOptional: true,
                      validator: (value) {
                        if (value != null &&
                            value.trim().isNotEmpty &&
                            value.trim().length != 12) {
                          return 'Aadhar number must be 12 digits';
                        }
                        return null;
                      },
                    ),
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
                  onPressed: _isLoading ? null : _updateProfileWithMultipart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: RefreshLoader(
                            size: 24,
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
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
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label + (isOptional ? ' (Optional)' : ''),
        prefixIcon: Icon(icon, color: AppTheme.primaryBlue),
        filled: true,
        fillColor: AppTheme.cardBackground,
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.errorColor, width: 2),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildDefaultProfileIcon() {
    return Container(
      color: AppTheme.lightBlueAccent,
      child: const Icon(Icons.person, size: 60, color: AppTheme.primaryBlue),
    );
  }
}
