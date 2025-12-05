import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../utils/app_theme.dart';
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
  final ImagePicker _picker = ImagePicker();
  File? _selectedProfileImage;
  String? _currentProfileUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentProfileUrl = widget.userData['profile']?.toString();
  }

  Future<http.MultipartRequest> _buildMultipartRequest(
    String updateUrl,
    List<int> imageBytes,
  ) async {
    var request = http.MultipartRequest('PUT', Uri.parse(updateUrl));

    // Add Authorization header
    request.headers['Authorization'] = 'Bearer ${MyApp.authTokenValue ?? ""}';
    // Note: Don't set Content-Type header manually for multipart requests
    // The http package will set it automatically with the boundary

    // Add profile image as multipart file
    request.files.add(
      http.MultipartFile.fromBytes(
        'profile',
        imageBytes,
        filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ),
    );

    return request;
  }

  Future<http.Response> _sendRequestWithRetry(
    Future<http.MultipartRequest> Function() buildRequest, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 2),
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (attempt < maxRetries) {
      try {
        attempt++;
        print('🔄 [EDIT PROFILE] Attempt $attempt of $maxRetries...');

        // Create a new request for each attempt
        var request = await buildRequest();

        // Send request with timeout
        var streamedResponse = await request.send().timeout(
          const Duration(seconds: 60),
          onTimeout: () {
            throw TimeoutException('Request timeout after 60 seconds');
          },
        );

        var response = await http.Response.fromStream(streamedResponse).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException('Response timeout after 30 seconds');
          },
        );

        print('✅ [EDIT PROFILE] Request successful on attempt $attempt');
        return response;
      } on SocketException catch (e) {
        print('❌ [EDIT PROFILE] Network error on attempt $attempt: $e');
        if (attempt >= maxRetries) {
          rethrow;
        }
        print('⏳ [EDIT PROFILE] Retrying in ${delay.inSeconds} seconds...');
        await Future.delayed(delay);
        delay = Duration(seconds: delay.inSeconds * 2); // Exponential backoff
      } on TimeoutException catch (e) {
        print('⏱️ [EDIT PROFILE] Timeout on attempt $attempt: $e');
        if (attempt >= maxRetries) {
          rethrow;
        }
        print('⏳ [EDIT PROFILE] Retrying in ${delay.inSeconds} seconds...');
        await Future.delayed(delay);
        delay = Duration(seconds: delay.inSeconds * 2);
      } catch (e) {
        print('❌ [EDIT PROFILE] Error on attempt $attempt: $e');
        if (attempt >= maxRetries) {
          rethrow;
        }
        // Check if it's a "finalized request" error - this shouldn't happen now
        if (e.toString().contains('finalized')) {
          print(
            '⚠️ [EDIT PROFILE] Request finalized error - will create new request on retry',
          );
        }
        print('⏳ [EDIT PROFILE] Retrying in ${delay.inSeconds} seconds...');
        await Future.delayed(delay);
        delay = Duration(seconds: delay.inSeconds * 2);
      }
    }

    throw Exception('Failed after $maxRetries attempts');
  }

  Future<void> _updateProfileWithMultipart() async {
    // Check if a new image is selected
    if (_selectedProfileImage == null) {
      if (mounted) {
        CustomDialog.show(
          context: context,
          message: 'Please select a profile image to update.',
          type: DialogType.warning,
          title: 'No Image Selected',
          buttonText: 'OK',
          barrierDismissible: true,
        );
      }
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
      print('🔄 [EDIT PROFILE] Updating profile image...');
      print('🌐 [EDIT PROFILE] API URL: $updateUrl');

      // Read image bytes once (will be reused for retries)
      var imageBytes = await _selectedProfileImage!.readAsBytes();
      final imageSize = imageBytes.length;
      print(
        '📊 [EDIT PROFILE] Image size: $imageSize bytes (${(imageSize / 1024).toStringAsFixed(2)} KB)',
      );

      // Warn if image is too large (> 500KB)
      if (imageSize > 500 * 1024) {
        print(
          '⚠️ [EDIT PROFILE] Image is large (${(imageSize / 1024).toStringAsFixed(2)} KB). Consider using a smaller image.',
        );
      }

      // Create a function that builds a new request for each retry attempt
      Future<http.MultipartRequest> buildRequest() async {
        var request = await _buildMultipartRequest(updateUrl, imageBytes);

        // Log request details (only on first attempt or when debugging)
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

        return request;
      }

      print('📤 [EDIT PROFILE] Sending multipart request...');
      var response = await _sendRequestWithRetry(buildRequest);

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
        dynamic responseBody;
        try {
          responseBody = jsonDecode(response.body);
        } catch (e) {
          responseBody = {'message': response.body};
        }
        _handleUpdateResponse([response.statusCode, responseBody]);
      }
    } on SocketException catch (e) {
      print('❌ [EDIT PROFILE] Network error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        CustomDialog.show(
          context: context,
          message:
              'Network connection error. Please check your internet connection and try again.',
          type: DialogType.error,
          title: 'Connection Error',
          buttonText: 'OK',
          barrierDismissible: true,
        );
      }
    } on TimeoutException catch (e) {
      print('❌ [EDIT PROFILE] Timeout error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        CustomDialog.show(
          context: context,
          message:
              'Request timed out. Please try again with a better internet connection.',
          type: DialogType.error,
          title: 'Timeout Error',
          buttonText: 'OK',
          barrierDismissible: true,
        );
      }
    } catch (e) {
      print('❌ [EDIT PROFILE] Multipart upload error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        String errorMessage = 'Failed to update profile. ';
        if (e.toString().contains('Connection reset')) {
          errorMessage += 'The connection was reset. Please try again.';
        } else if (e.toString().contains('Failed after')) {
          errorMessage +=
              'Multiple attempts failed. Please check your connection and try again.';
        } else {
          errorMessage += e.toString();
        }
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
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 75,
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
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 75,
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  // Profile Image Section
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _showImageSourceDialog,
                          child: Stack(
                            children: [
                              Container(
                                width: 150,
                                height: 150,
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
                                  width: 40,
                                  height: 40,
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
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: _showImageSourceDialog,
                          child: const Text(
                            'Change Photo',
                            style: TextStyle(
                              color: AppTheme.primaryBlue,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_selectedProfileImage != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'New photo selected',
                              style: TextStyle(
                                color: AppTheme.primaryBlue,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
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
    );
  }

  Widget _buildDefaultProfileIcon() {
    return Container(
      color: AppTheme.lightBlueAccent,
      child: const Icon(Icons.person, size: 60, color: AppTheme.primaryBlue),
    );
  }
}
