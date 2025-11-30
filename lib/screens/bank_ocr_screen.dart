import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/image_preview.dart';
import '../widgets/action_buttons.dart';
import '../widgets/status_card.dart';
import '../widgets/tips_card.dart';
import '../widgets/response_display.dart';
import '../models/bank_data.dart';
import '../services/api_service.dart';

class BankOCRScreen extends StatefulWidget {
  const BankOCRScreen({super.key});

  @override
  State<BankOCRScreen> createState() => _BankOCRScreenState();
}

class _BankOCRScreenState extends State<BankOCRScreen>
    with SingleTickerProviderStateMixin {
  String _status = 'Ready to capture passbook';
  XFile? _capturedImage;
  bool _isProcessing = false;
  final ImagePicker _picker = ImagePicker();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  BankData _bankData = BankData();
  bool _showResponse = false;

  // Scroll controller for the main screen
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    try {
      setState(() {
        _isProcessing = true;
        _status = '🔍 Checking camera permission...';
        _showResponse = false;
      });

      final status = await Permission.camera.request();

      if (status.isGranted) {
        setState(() {
          _status = '📷 Opening camera for high-quality capture...';
        });

        final XFile? image = await _picker.pickImage(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.rear,
          maxWidth: 2048,
          maxHeight: 2048,
          imageQuality: 98,
        );

        if (image != null) {
          await _processSelectedImage(image);
        } else {
          setState(() {
            _status = '❌ Camera cancelled';
            _isProcessing = false;
          });
        }
      } else {
        setState(() {
          _status = '❌ Camera permission denied';
          _isProcessing = false;
        });
        _showPermissionDialog('Camera');
      }
    } catch (e) {
      setState(() {
        _status = '❌ Camera Error: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      setState(() {
        _isProcessing = true;
        _status = '🖼️ Opening gallery...';
        _showResponse = false;
      });

      final XFile? image = await _picker
          .pickImage(
            source: ImageSource.gallery,
            maxWidth: 2048,
            maxHeight: 2048,
            imageQuality: 98,
          )
          .catchError((error) async {
            PermissionStatus? photoStatus = await Permission.photos.request();
            PermissionStatus? storageStatus = await Permission.storage
                .request();

            if ((photoStatus.isGranted) || (storageStatus.isGranted)) {
              return await _picker.pickImage(
                source: ImageSource.gallery,
                maxWidth: 2048,
                maxHeight: 2048,
                imageQuality: 98,
              );
            } else {
              throw Exception('Permission denied');
            }
          });

      if (image != null) {
        await _processSelectedImage(image);
      } else {
        setState(() {
          _status = '❌ Gallery selection cancelled';
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _status = '❌ Gallery Error: $e';
        _isProcessing = false;
      });
      _showPermissionDialog('Gallery');
    }
  }

  void _showPermissionDialog(String permission) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.lock, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Permission Required',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          '$permission permission is required to use this feature.',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Open Settings',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processSelectedImage(XFile image) async {
    setState(() {
      _capturedImage = image;
      _status = '🔄 Uploading image to server...';
      _isProcessing = true;
      _showResponse = false;
      _bankData = BankData(); // Reset bank data
    });

    await _uploadImageToAPI(image);
  }

  Future<void> _uploadImageToAPI(XFile image) async {
    try {
      print('🚀 [SCREEN] Starting image upload process...');
      setState(() {
        _status = '📤 Uploading image to server...';
      });

      final response = await ApiService.uploadImage(File(image.path));

      print('✅ [SCREEN] Image upload API call completed');
      setState(() {
        _status = '✅ Image uploaded successfully!';
      });

      _bankData = BankData.fromJson(response);
      print('📋 [SCREEN] Bank data parsed from response');

      setState(() {
        _showResponse = true;
        _isProcessing = false;
      });

      // Auto-scroll to show the response when it appears
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      });
    } catch (e) {
      print('❌ [SCREEN] Image upload failed: $e');
      setState(() {
        _status = '❌ Upload failed: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _saveBankData() async {
    try {
      print('💾 [SCREEN] Starting save bank data process...');
      setState(() {
        _isProcessing = true;
        _status = '💾 Storing data in database...';
      });

      final success = await ApiService.storeBankData(_bankData);

      setState(() {
        _isProcessing = false;
      });

      if (success) {
        print('🎉 [SCREEN] Data saved successfully!');
        setState(() {
          _status = '✅ Data stored successfully!';
        });
        _showSnackBar('Data has been stored successfully!', true);
      } else {
        print('❌ [SCREEN] Data save failed on server');
        setState(() {
          _status = '❌ Failed to store data';
        });
        _showSnackBar('Failed to store data in database', false);
      }
    } catch (e) {
      print('💥 [SCREEN] Data save error: $e');
      setState(() {
        _isProcessing = false;
        _status = '❌ Error storing data: $e';
      });
      _showSnackBar('Error storing data: $e', false);
    }
  }

  void _showSnackBar(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _resetApp() {
    setState(() {
      _capturedImage = null;
      _status = 'Ready to capture passbook';
      _isProcessing = false;
      _showResponse = false;
      _bankData = BankData();
    });

    // Scroll back to top when resetting
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _fadeAnimation.value)),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667eea).withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mrchams Tech',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Advanced Bank Passbook OCR',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_capturedImage != null)
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: _isProcessing ? null : _resetApp,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8f9fa),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: 30),

              // Main scrollable content
              Expanded(
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Image Preview Section
                    SliverToBoxAdapter(
                      child: ImagePreview(
                        capturedImage: _capturedImage,
                        scaleAnimation: _scaleAnimation,
                        fadeAnimation: _fadeAnimation,
                        onRefresh: _resetApp,
                      ),
                    ),

                    // Spacing
                    const SliverToBoxAdapter(child: SizedBox(height: 30)),

                    // Action Buttons Section
                    SliverToBoxAdapter(
                      child: ActionButtons(
                        isProcessing: _isProcessing,
                        onCameraTap: _captureImage,
                        onGalleryTap: _pickImageFromGallery,
                        scaleAnimation: _scaleAnimation,
                        fadeAnimation: _fadeAnimation,
                      ),
                    ),

                    // Spacing
                    const SliverToBoxAdapter(child: SizedBox(height: 30)),

                    // Status Card Section
                    SliverToBoxAdapter(
                      child: StatusCard(
                        status: _status,
                        isProcessing: _isProcessing,
                        fadeAnimation: _fadeAnimation,
                      ),
                    ),

                    // Response Display Section (appears when data is available)
                    if (_showResponse)
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            ResponseDisplay(
                              bankData: _bankData,
                              onSave: _saveBankData,
                              isProcessing: _isProcessing,
                            ),
                          ],
                        ),
                      ),

                    // Tips Card Section (only shown when no response is displayed)
                    if (!_showResponse &&
                        _capturedImage != null &&
                        !_isProcessing)
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            const SizedBox(height: 30),
                            TipsCard(fadeAnimation: _fadeAnimation),
                          ],
                        ),
                      ),

                    // Bottom padding for better scrolling
                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // Floating Action Button for quick actions
      floatingActionButton: _showResponse
          ? FloatingActionButton(
              onPressed: () {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
              backgroundColor: const Color(0xFF667eea),
              child: const Icon(Icons.arrow_downward, color: Colors.white),
            )
          : null,
    );
  }
}
