import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/bank_data.dart';

class ApiService {
  static const String baseUrl = 'https://dev.zaanvar.com/api/scan/';
  static const String storageUrl = 'https://dev.zaanvar.com/api/scan/data';

  static Future<Map<String, dynamic>> uploadImage(File imageFile) async {
    try {
      print('🔄 [IMAGE UPLOAD] Starting image upload process...');
      print('📁 [IMAGE INFO] File path: ${imageFile.path}');
      print('📁 [IMAGE INFO] File size: ${await imageFile.length()} bytes');
      print('🌐 [API CALL] Making POST request to: $baseUrl');

      var request = http.MultipartRequest('POST', Uri.parse(baseUrl));

      var imageBytes = await imageFile.readAsBytes();
      print('📊 [IMAGE DATA] Image bytes length: ${imageBytes.length}');

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: 'passbook.jpg',
        ),
      );

      print('⏳ [UPLOAD] Sending request to server...');
      var streamedResponse = await request.send();
      print('✅ [UPLOAD] Request sent, waiting for response...');

      var response = await http.Response.fromStream(streamedResponse);

      print('📥 [RESPONSE] Received response from server');
      print('📊 [RESPONSE] Status Code: ${response.statusCode}');
      print('📄 [RESPONSE] Headers: ${response.headers}');
      print('📝 [RESPONSE] Body length: ${response.body.length} characters');

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        print('🎉 [SUCCESS] Image upload successful!');
        print('📋 [RESPONSE DATA] Full response: $responseData');

        // Print individual fields if they exist
        if (responseData is Map<String, dynamic>) {
          print('🔍 [EXTRACTED DATA] Parsing response:');
          print(
            '   👤 Customer Name: ${responseData['customerName'] ?? 'Not found'}',
          );
          print(
            '   🔢 Account Number: ${responseData['accountNumber'] ?? 'Not found'}',
          );
          print('   🏛️ IFSC Code: ${responseData['ifscCode'] ?? 'Not found'}');
          print(
            '   🏢 Branch Name: ${responseData['branchName'] ?? 'Not found'}',
          );
          print(
            '   📍 Branch Address: ${responseData['address'] ?? 'Not found'}',
          );
        }

        return responseData;
      } else {
        print('❌ [API ERROR] Status Code: ${response.statusCode}');
        print('❌ [API ERROR] Response Body: ${response.body}');
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('💥 [UPLOAD FAILED] Exception: $e');
      print('🔄 [UPLOAD FAILED] Stack trace: ${e.toString()}');
      throw Exception('Upload failed: $e');
    } finally {
      print('🏁 [IMAGE UPLOAD] Process completed');
    }
  }

  static Future<bool> storeBankData(BankData bankData) async {
    try {
      print('\n💾 [DATA STORAGE] Starting bank data storage process...');
      print('📋 [DATA TO STORE] Bank data details:');
      print('   👤 Customer Name: "${bankData.accountHolderName}"');
      print('   🔢 Account Number: "${bankData.accountNumber}"');
      print('   🏛️ IFSC Code: "${bankData.ifscCode}"');
      print('   🏢 Branch Name: "${bankData.branchName}"');
      print('   📍 Branch Address: "${bankData.branchAddress}"');

      print('🌐 [API CALL] Making POST request to: $storageUrl');

      final requestBody = bankData.toJson();
      print('📦 [REQUEST BODY] JSON payload: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(storageUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('📥 [STORAGE RESPONSE] Received response');
      print('📊 [STORAGE RESPONSE] Status Code: ${response.statusCode}');
      print('📄 [STORAGE RESPONSE] Headers: ${response.headers}');
      print('📝 [STORAGE RESPONSE] Body: ${response.body}');

      final bool isSuccess =
          response.statusCode == 200 || response.statusCode == 201;

      if (isSuccess) {
        print('🎉 [STORAGE SUCCESS] Data stored successfully!');
        print('✅ [STORAGE SUCCESS] Response: ${response.body}');
      } else {
        print(
          '❌ [STORAGE FAILED] Server returned error status: ${response.statusCode}',
        );
        print('❌ [STORAGE FAILED] Error response: ${response.body}');
      }

      return isSuccess;
    } catch (e) {
      print('💥 [STORAGE FAILED] Exception occurred: $e');
      print('🔄 [STORAGE FAILED] Stack trace: ${e.toString()}');
      throw Exception('Storage failed: $e');
    } finally {
      print('🏁 [DATA STORAGE] Process completed\n');
    }
  }

  // Helper method to print formatted logs
  static void _printLog(String emoji, String title, String message) {
    print('$emoji [$title] $message');
  }
}
