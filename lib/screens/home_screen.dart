import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/app_theme.dart';
import '../models/bank_data.dart';
import '../services/api_service.dart';
import '../widgets/bank_loader.dart';
import '../myapp.dart';
import 'scan_data_extraction_screen.dart';
import 'home/image_sections/welcome_header.dart';
import 'home/image_sections/scan_document_section.dart';
import 'home/image_sections/source_section.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onExtractionScreenShown;
  final VoidCallback? onExtractionScreenHidden;

  const HomeScreen({
    super.key,
    this.onExtractionScreenShown,
    this.onExtractionScreenHidden,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  BankData? _bankData;
  String? _imagePath;
  bool _isProcessing = false;
  bool _isSaving = false;
  bool _wasShowingExtraction = false;
  String? _userName;

  @override
  void initState() {
    super.initState();
    // Check static variable first (set during login)
    _userName = MyApp.userName;
    // Also load from SharedPreferences as fallback
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    await MyApp.loadUserData();
    if (mounted) {
      setState(() {
        _userName = MyApp.userName ?? _userName;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isShowingExtraction = _bankData != null && _imagePath != null;

    // Check if user name is available in static variable and update if needed
    if (MyApp.userName != null && MyApp.userName != _userName) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _userName = MyApp.userName;
          });
        }
      });
    }

    // Notify state changes
    if (isShowingExtraction && !_wasShowingExtraction) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onExtractionScreenShown?.call();
      });
      _wasShowingExtraction = true;
    } else if (!isShowingExtraction && _wasShowingExtraction) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onExtractionScreenHidden?.call();
      });
      _wasShowingExtraction = false;
    }

    // Show loader when processing
    if (_isProcessing) {
      // Notify that extraction screen is shown (to hide bottom nav)
      if (!_wasShowingExtraction) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onExtractionScreenShown?.call();
        });
      }
      return Scaffold(
        backgroundColor: AppTheme.scaffoldBackground,
        body: const BankLoader(message: 'Processing your document...'),
      );
    }

    // Show home screen with conditional content
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      body: Column(
        children: [
          // Welcome Header (only show when not showing extraction)
          if (!isShowingExtraction) WelcomeHeader(userName: _userName),
          // Main Content
          Expanded(
            child: isShowingExtraction
                ? ScanDataExtractionScreen(
                    bankData: _bankData!,
                    imagePath: _imagePath!,
                    onSaveSuccess: () {
                      setState(() {
                        _bankData = null;
                        _imagePath = null;
                        _selectedImage = null;
                      });
                    },
                    onBack: () {
                      setState(() {
                        _bankData = null;
                        _imagePath = null;
                        _selectedImage = null;
                      });
                    },
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        // Scan the Document Section
                        ScanDocumentSection(
                          selectedImage: _selectedImage,
                          isProcessing: _isProcessing,
                          onTap: () => _showImageSourceDialog(context),
                        ),
                        const SizedBox(height: 24),
                        // Source Section
                        SourceSection(
                          onCameraTap: _captureFromCamera,
                          onGalleryTap: _pickFromGallery,
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

  void _showImageSourceDialog(BuildContext context) {
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
                  _captureFromCamera();
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
                  _pickFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _captureFromCamera() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        _showPermissionDialog('Camera');
        return;
      }

      setState(() => _isProcessing = true);

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 98,
      );

      if (image != null) {
        // Process the image directly
        await _processImage(image);
      } else {
        setState(() => _isProcessing = false);
        // Show bottom nav again if cancelled
        widget.onExtractionScreenHidden?.call();
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      // Show bottom nav again on error
      widget.onExtractionScreenHidden?.call();
      _showError('Camera Error: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      setState(() => _isProcessing = true);

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 98,
      );

      if (image != null) {
        // Process the image directly
        await _processImage(image);
      } else {
        setState(() => _isProcessing = false);
        // Show bottom nav again if cancelled
        widget.onExtractionScreenHidden?.call();
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      // Show bottom nav again on error
      widget.onExtractionScreenHidden?.call();
      _showError('Gallery Error: $e');
    }
  }

  /// Process the image
  Future<void> _processImage(XFile image) async {
    try {
      setState(() {
        _selectedImage = image;
        _isProcessing = true;
      });

      // Upload and extract data
      final response = await ApiService.uploadImage(File(image.path));
      final bankData = BankData.fromJson(response);

      if (mounted) {
        setState(() {
          _bankData = bankData;
          _imagePath = image.path;
          _isProcessing = false;
        });
        // Processing complete, extraction screen will be shown
        // Bottom nav will be hidden by the extraction screen shown callback
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        // Show bottom nav again if processing failed
        widget.onExtractionScreenHidden?.call();
        _showError('Processing Error: $e');
      }
    }
  }

  void _showPermissionDialog(String permission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: Text(
          '$permission permission is required to use this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.errorColor),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.successColor),
    );
  }
}
