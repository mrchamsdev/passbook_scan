import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/bank_data.dart';
import 'network_service.dart';

class ApiService {
  static String get baseUrl => dotenv.env['API_URL'] ?? '';

  static String get storageUrl => dotenv.env['API_URL'] ?? '';

  // Get API timeout from environment variables, default to 30 seconds
  static int get apiTimeout =>
      int.tryParse(dotenv.env['API_TIMEOUT'] ?? '30') ?? 30;

  static Future<Map<String, dynamic>> uploadImage(File imageFile) async {
    try {
      print('🔄 [IMAGE UPLOAD] Starting image upload process...');
      print('📁 [IMAGE INFO] File path: ${imageFile.path}');
      print('📁 [IMAGE INFO] File size: ${await imageFile.length()} bytes');

      var scanURL = '${dotenv.env['API_URL']}scan';
      print('🌐 [API CALL] Making POST request to: $scanURL');

      var request = http.MultipartRequest('POST', Uri.parse(scanURL));

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
      print('📝 [RESPONSE] Body: ${response.body}');
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

        // Try to parse error message
        String errorMessage = 'API Error: ${response.statusCode}';
        try {
          var errorData = jsonDecode(response.body);
          if (errorData is Map && errorData.containsKey('message')) {
            errorMessage = errorData['message'].toString();
          } else if (errorData is Map && errorData.containsKey('error')) {
            errorMessage = errorData['error'].toString();
          } else {
            errorMessage = response.body;
          }
        } catch (e) {
          errorMessage = response.body;
        }

        throw Exception('API Error: ${response.statusCode} - $errorMessage');
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
      var paymentURL = '${dotenv.env['API_URL']}bank/payment';
      print('Payment URL: $paymentURL');

      var payload = {
        'accountNumber': bankData.accountNumber,
        'ifscCode': bankData.ifscCode,
        'customerName': bankData.accountHolderName,
        'bankName': bankData.branchName,
      };

      print('Payment Payload: $payload');

      var response = await ServiceWithDataPost(paymentURL, payload).data();

      print('Payment Response: $response');

      // Check response format: [statusCode, responseBody]
      if (response is List && response.length >= 2) {
        int statusCode = response[0];
        return statusCode >= 200 && statusCode < 300;
      }

      return false;
    } catch (e) {
      print('💥 [STORAGE FAILED] Exception occurred: $e');
      throw Exception('Storage failed: $e');
    }
  }

  static Future<bool> addPayment({
    required String accountNumber,
    required String ifscCode,
    required String customerName,
    required String bankName,
    required String amountToPay,
    required File photo,
    String? nickname,
    String? phoneNumber,
    String? comments,
    String? bankInfoId,
  }) async {
    try {
      var paymentURL = '${dotenv.env['API_URL']}bank/payment';
      print('Payment URL: $paymentURL');

      var request = http.MultipartRequest('POST', Uri.parse(paymentURL));

      // Add text fields
      request.fields['accountNumber'] = accountNumber;
      request.fields['ifscCode'] = ifscCode;
      request.fields['customerName'] = customerName;
      request.fields['bankName'] = bankName;
      request.fields['amountToPay'] = amountToPay;

      if (nickname != null && nickname.isNotEmpty) {
        request.fields['nickname'] = nickname;
      }
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        request.fields['phoneNumber'] = phoneNumber;
      }
      if (comments != null && comments.isNotEmpty) {
        request.fields['comments'] = comments;
      }
      if (bankInfoId != null && bankInfoId.isNotEmpty) {
        request.fields['bankInfoId'] = bankInfoId;
      }

      // Add photo file
      var imageBytes = await photo.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'photo',
          imageBytes,
          filename: 'payment_photo.jpg',
        ),
      );

      print('Payment Payload: ${request.fields}');
      print('Photo file: ${photo.path}');

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('Payment Response Status: ${response.statusCode}');
      print('Payment Response Body: ${response.body}');

      final bool isSuccess =
          response.statusCode == 200 || response.statusCode == 201;

      return isSuccess;
    } catch (e) {
      print('💥 [PAYMENT FAILED] Exception occurred: $e');
      throw Exception('Payment submission failed: $e');
    }
  }

  // Helper method to print formatted logs
  static void _printLog(String emoji, String title, String message) {
    print('$emoji [$title] $message');
  }
}
