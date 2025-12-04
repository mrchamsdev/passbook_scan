import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../services/network_service.dart';

class SheetsProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> get records => _records;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  static String get baseUrl => dotenv.env['API_URL'] ?? '';

  /// Fetch payment info by date range
  /// URL: /api/bank/paymentInfo?startDate=2025-11-01&endDate=2025-11-31&type=date
  Future<void> fetchByDateRange({
    required String startDate, // Format: YYYY-MM-DD
    required String endDate, // Format: YYYY-MM-DD
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url =
          '${baseUrl}bank/paymentInfo?startDate=$startDate&endDate=$endDate&type=date';
      print('📋 [SHEETS API] ==========================================');
      print('📋 [SHEETS API] Fetching by date range');
      print('🌐 [SHEETS API] URL: $url');
      print('📅 [SHEETS API] Start Date: $startDate');
      print('📅 [SHEETS API] End Date: $endDate');

      var response = await ServiceWithHeader(url).data();
      final statusCode = response[0] as int;
      final responseData = response[1];

      print('📥 [SHEETS API] Response Status: $statusCode');
      print('📄 [SHEETS API] Response Data: $responseData');
      print('📋 [SHEETS API] ==========================================');

      if (statusCode == 200 && responseData != null) {
        // Check if response indicates no data (like 404 with message)
        if (responseData is Map &&
            responseData.containsKey('status') &&
            responseData['status'] == 'error') {
          // No payments found - this is not an error, just empty data
          _records = [];
          _errorMessage = null;
        } else {
          List<dynamic> dataList = [];
          if (responseData is List) {
            dataList = responseData;
          } else if (responseData is Map && responseData.containsKey('payments')) {
            // API returns data in 'payments' array
            dataList = responseData['payments'] as List? ?? [];
          } else if (responseData is Map && responseData.containsKey('data')) {
            dataList = responseData['data'] as List;
          } else if (responseData is Map) {
            // If response is a single object, wrap it in a list
            dataList = [responseData];
          }

          _records = dataList
              .map((json) => json as Map<String, dynamic>)
              .toList();
          _errorMessage = null;
        }
      } else if (statusCode == 404) {
        // 404 means no data found - not an error, just empty
        _records = [];
        _errorMessage = null;
      } else {
        throw Exception('Failed to fetch sheets: Status $statusCode');
      }
    } catch (e) {
      _errorMessage = e.toString();
      _records = [];
      print('Error fetching by date range: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch payment info by month
  /// URL: /api/bank/paymentInfo?type=month&month=12&year=2025
  Future<void> fetchByMonth({
    required int month, // 1-12
    required int year,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url =
          '${baseUrl}bank/paymentInfo?type=month&month=$month&year=$year';
      print('📋 [SHEETS API] ==========================================');
      print('📋 [SHEETS API] Fetching by month');
      print('🌐 [SHEETS API] URL: $url');
      print('📅 [SHEETS API] Month: $month, Year: $year');

      var response = await ServiceWithHeader(url).data();
      final statusCode = response[0] as int;
      final responseData = response[1];

      print('📥 [SHEETS API] Response Status: $statusCode');
      print('📄 [SHEETS API] Response Data: $responseData');
      
      if (responseData is Map && responseData.containsKey('payments')) {
        final payments = responseData['payments'] as List?;
        print('📊 [SHEETS API] Found ${payments?.length ?? 0} payment records');
      }
      print('📋 [SHEETS API] ==========================================');

      if (statusCode == 200 && responseData != null) {
        // Check if response indicates no data (like 404 with message)
        if (responseData is Map &&
            responseData.containsKey('status') &&
            responseData['status'] == 'error') {
          // No payments found - this is not an error, just empty data
          _records = [];
          _errorMessage = null;
        } else {
          List<dynamic> dataList = [];
          if (responseData is List) {
            dataList = responseData;
          } else if (responseData is Map && responseData.containsKey('payments')) {
            // API returns data in 'payments' array
            dataList = responseData['payments'] as List? ?? [];
          } else if (responseData is Map && responseData.containsKey('data')) {
            dataList = responseData['data'] as List;
          } else if (responseData is Map) {
            // If response is a single object, wrap it in a list
            dataList = [responseData];
          }

          _records = dataList
              .map((json) => json as Map<String, dynamic>)
              .toList();
          _errorMessage = null;
        }
      } else if (statusCode == 404) {
        // 404 means no data found - not an error, just empty
        _records = [];
        _errorMessage = null;
      } else {
        throw Exception('Failed to fetch sheets: Status $statusCode');
      }
    } catch (e) {
      _errorMessage = e.toString();
      _records = [];
      print('Error fetching by month: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearRecords() {
    _records = [];
    _errorMessage = null;
    notifyListeners();
  }
}
