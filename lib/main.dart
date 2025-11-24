import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const BankPassbookOCRApp());
}

class BankPassbookOCRApp extends StatelessWidget {
  const BankPassbookOCRApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bank Passbook OCR - Advanced',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const BankOCRScreen(),
    );
  }
}

class BankOCRScreen extends StatefulWidget {
  const BankOCRScreen({super.key});

  @override
  State<BankOCRScreen> createState() => _BankOCRScreenState();
}

class _BankOCRScreenState extends State<BankOCRScreen> {
  String _status = 'Ready to capture passbook';
  XFile? _capturedImage;
  bool _isProcessing = false;
  final ImagePicker _picker = ImagePicker();

  // Bank data fields
  String _accountHolderName = 'Not detected';
  String _accountNumber = 'Not detected';
  String _ifscCode = 'Not detected';
  String _branchAddress = 'Not detected';
  String _branchName = 'Not detected';

  Future<void> _captureImage() async {
    try {
      setState(() {
        _isProcessing = true;
        _status = '🔍 Checking camera permission...';
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
      });

      // Try to pick image directly first (works on newer Android versions)
      final XFile? image = await _picker
          .pickImage(
            source: ImageSource.gallery,
            maxWidth: 2048,
            maxHeight: 2048,
            imageQuality: 98,
          )
          .catchError((error) async {
            // If direct pick fails, try requesting permission
            print('⚠️ Direct gallery access failed: $error');

            // Try photos permission (Android 13+)
            PermissionStatus? photoStatus;
            try {
              photoStatus = await Permission.photos.request();
            } catch (e) {
              print('⚠️ Photos permission not available: $e');
            }

            // Try storage permission (older Android)
            PermissionStatus? storageStatus;
            try {
              storageStatus = await Permission.storage.request();
            } catch (e) {
              print('⚠️ Storage permission not available: $e');
            }

            // Try again after permission request
            if ((photoStatus?.isGranted ?? false) ||
                (storageStatus?.isGranted ?? false) ||
                (photoStatus == null && storageStatus == null)) {
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
        title: const Text('Permission Required'),
        content: Text(
          '$permission permission is required to use this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
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

      // Reset all bank data
      _accountHolderName = 'Not detected';
      _accountNumber = 'Not detected';
      _ifscCode = 'Not detected';
      _branchAddress = 'Not detected';
      _branchName = 'Not detected';
    });

    // Upload image to API
    await _uploadImageToAPI(image);
  }

  Future<void> _uploadImageToAPI(XFile image) async {
    try {
      setState(() {
        _status = '📤 Uploading image to server...';
      });

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://dev.zaanvar.com/api/scan/'),
      );

      // Add image file
      var imageFile = await File(image.path).readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes('image', imageFile, filename: image.name),
      );

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      setState(() {
        _status = '✅ Image uploaded successfully!';
      });

      // Parse and display response
      if (response.statusCode == 201) {
        var responseData = jsonDecode(response.body);
        _showAPIResponsePopup(responseData);

        // Update bank data from API response if available
        if (responseData is Map<String, dynamic>) {
          _updateBankDataFromAPI(responseData);
        }
      } else {
        _showAPIResponsePopup({
          'error': '',
          'statusCode': response.statusCode,
          'message': response.body,
        });
      }

      setState(() {
        _isProcessing = false;
      });
    } catch (e) {
      print('❌ API Upload Error: $e');
      setState(() {
        _status = '❌ Upload failed: $e';
        _isProcessing = false;
      });

      _showAPIResponsePopup({
        'error': 'Upload Failed',
        'message': e.toString(),
      });
    }
  }

  void _updateBankDataFromAPI(Map<String, dynamic> data) {
    setState(() {
      _accountHolderName = data['customerName'] ?? _accountHolderName;
      _accountNumber = data['accountNumber'] ?? _accountNumber;
      _ifscCode = data['ifscCode'] ?? _ifscCode;
      _branchName = data['branchName'] ?? _branchName;
      _branchAddress = data['address'] ?? _branchAddress;
    });
  }

  void _showAPIResponsePopup(dynamic responseData) {
    // Check if response has error
    if (responseData['error'] != null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error, color: const Color.fromARGB(255, 3, 165, 38)),
                const SizedBox(width: 8),
                const Text('Success'),
              ],
            ),
            content: Container(
              padding: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 450),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[700]!, Colors.blue[600]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.account_balance,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text(
                              'Bank Details Extracted',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Customer Name
                    _buildResponseField(
                      '👤 Customer Name',
                      responseData['customerName']?.toString().trim() ?? '',
                    ),
                    const SizedBox(height: 14),

                    // Account Number
                    _buildResponseField(
                      '🔢 Account Number',
                      responseData['accountNumber']?.toString().trim() ?? '',
                    ),
                    const SizedBox(height: 14),

                    // IFSC Code
                    _buildResponseField(
                      '🏛️ IFSC Code',
                      responseData['ifscCode']?.toString().trim() ?? '',
                    ),
                    const SizedBox(height: 14),

                    // Branch Name
                    _buildResponseField(
                      '🏢 Branch Name',
                      responseData['branchName']?.toString().trim() ?? '',
                    ),
                    const SizedBox(height: 14),

                    // Address
                    _buildResponseField(
                      '📍 Address',
                      responseData['address']?.toString().trim() ?? '',
                      isMultiline: true,
                    ),
                    const SizedBox(height: 24),

                    // OK Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          // Store data in sheet via API
                          await _storeDataInSheet(responseData);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.save, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'OK - Save to Sheet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }
  }

  Future<void> _storeDataInSheet(Map<String, dynamic> responseData) async {
    try {
      setState(() {
        _isProcessing = true;
        _status = '💾 Storing data in sheet...';
      });

      // Prepare request body
      final requestBody = {
        'customerName': responseData['customerName'] ?? '',
        'accountNumber': responseData['accountNumber'] ?? '',
        'ifscCode': responseData['ifscCode'] ?? '',
        'branchName': responseData['branchName'] ?? '',
        'address': responseData['address'] ?? '',
      };

      // Make POST request
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/scan/data'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      setState(() {
        _isProcessing = false;
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _status = '✅ Data stored successfully!';
        });

        // Show success message
        _showSuccessMessage('Data has been stored in the sheet successfully!');
      } else {
        setState(() {
          _status = '❌ Failed to store data';
        });

        // Show error message
        _showErrorMessage('Failed to store data: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _status = '❌ Error storing data: $e';
      });

      _showErrorMessage('Error storing data: $e');
    }
  }

  void _showSuccessMessage(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[700]),
              const SizedBox(width: 8),
              const Text('Success'),
            ],
          ),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red[700]),
              const SizedBox(width: 8),
              const Text('Error'),
            ],
          ),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResponseField(
    String label,
    String value, {
    bool isMultiline = false,
  }) {
    bool isEmpty = value.isEmpty || value == 'Not found';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isEmpty ? Colors.grey[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEmpty ? Colors.grey[300]! : Colors.blue[200]!,
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isEmpty ? Colors.grey[500] : Colors.blue[700],
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                SelectableText(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isEmpty ? Colors.grey[600] : Colors.grey[900],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (!isEmpty)
            Icon(Icons.check_circle, color: Colors.green[600], size: 20),
        ],
      ),
    );
  }

  // Enhanced UI with better visual feedback
  Widget _buildImagePreview() {
    if (_capturedImage == null) {
      return Container(
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_camera, size: 52, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'No image selected',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 4),
            Text(
              'Use high-quality, well-lit images for best results',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: FutureBuilder<Uint8List>(
              future: _capturedImage!.readAsBytes(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Image.memory(
                    snapshot.data!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.error, color: Colors.red, size: 48),
                      );
                    },
                  );
                }
                return Container(
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _capturedImage!.name,
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildBankDataCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue[700], size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Advanced Scan Results',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildEnhancedDataRow('👤 Account Holder', _accountHolderName),
            _buildEnhancedDataRow('🔢 Account Number', _accountNumber),
            _buildEnhancedDataRow('🏛️ IFSC Code', _ifscCode),
            _buildEnhancedDataRow('📍 Branch Address', _branchAddress),
            if (_branchName != 'Not detected')
              _buildEnhancedDataRow('🏢 Branch Name', _branchName),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedDataRow(String label, String value) {
    bool isDetected = value != 'Not detected';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDetected ? Colors.green[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDetected ? Colors.green[100]! : Colors.grey[300]!,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: isDetected ? Colors.green[800] : Colors.red[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Passbook OCR - Advanced'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          if (_capturedImage != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isProcessing
                  ? null
                  : () {
                      setState(() {
                        _capturedImage = null;
                        _status = 'Ready to capture passbook';
                        _accountHolderName = 'Not detected';
                        _accountNumber = 'Not detected';
                        _ifscCode = 'Not detected';
                        _branchAddress = 'Not detected';
                        _branchName = 'Not detected';
                      });
                    },
              tooltip: 'Clear and Start Over',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.enhanced_encryption,
                        size: 64,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Advanced Bank Passbook Scanner',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Multi-strategy OCR with enhanced data extraction',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              _buildImagePreview(),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('High-Quality Camera'),
                      onPressed: _isProcessing ? null : _captureImage,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.photo_library_rounded),
                      label: const Text('Select from Gallery'),
                      onPressed: _isProcessing ? null : _pickImageFromGallery,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Scan Status',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isProcessing
                              ? Colors.blue[50]
                              : (_status.contains('✅')
                                    ? Colors.green[50]
                                    : (_status.contains('❌')
                                          ? Colors.red[50]
                                          : Colors.grey[50])),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isProcessing
                                ? Colors.blue[100]!
                                : (_status.contains('✅')
                                      ? Colors.green[100]!
                                      : (_status.contains('❌')
                                            ? Colors.red[100]!
                                            : Colors.grey[300]!)),
                          ),
                        ),
                        child: Row(
                          children: [
                            if (_isProcessing)
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.blue[700],
                                ),
                              )
                            else if (_status.contains('✅'))
                              Icon(
                                Icons.check_circle,
                                color: Colors.green[600],
                                size: 20,
                              )
                            else if (_status.contains('❌'))
                              Icon(
                                Icons.error,
                                color: Colors.red[600],
                                size: 20,
                              )
                            else
                              Icon(
                                Icons.info,
                                color: Colors.blue[600],
                                size: 20,
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _status,
                                style: TextStyle(
                                  color: _isProcessing
                                      ? Colors.blue[800]
                                      : (_status.contains('✅')
                                            ? Colors.green[800]
                                            : (_status.contains('❌')
                                                  ? Colors.red[800]
                                                  : Colors.grey[800])),
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

              const SizedBox(height: 24),
              if (_accountNumber != 'Not detected' ||
                  _ifscCode != 'Not detected')
                _buildBankDataCard(),

              const SizedBox(height: 20),
              if (_capturedImage != null && !_isProcessing)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tips for Better Results:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildTipItem('📸 Use good lighting without shadows'),
                        _buildTipItem(
                          '🔍 Ensure the passbook is flat and focused',
                        ),
                        _buildTipItem('📄 Capture the entire passbook page'),
                        _buildTipItem('🎯 Avoid glare and reflections'),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
