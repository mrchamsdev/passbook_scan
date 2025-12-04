import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';
import '../../widgets/bank_loader.dart';
import 'sheets_provider/sheets_provider.dart';

class MonthTab extends StatefulWidget {
  final SheetsProvider provider;
  
  const MonthTab({super.key, required this.provider});

  @override
  State<MonthTab> createState() => _MonthTabState();
}

class _MonthTabState extends State<MonthTab> {
  DateTime? _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    // Defer API call until after build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSheets();
    });
  }

  Future<void> _loadSheets() async {
    if (_selectedMonth == null) return;
    
    await widget.provider.fetchByMonth(
      month: _selectedMonth!.month,
      year: _selectedMonth!.year,
    );
    
    if (mounted && widget.provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.provider.errorMessage!),
          backgroundColor: AppTheme.errorColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatMonth(DateTime date) {
    return DateFormat('MMM yyyy').format(date);
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day-$month-$year';
  }

  Future<void> _selectMonth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
      });
      _loadSheets();
    }
  }

  String _getRecordDate(Map<String, dynamic> record) {
    // Prioritize paymentDate field (as per API response structure)
    dynamic dateValue = record['paymentDate'] ?? 
                       record['date'] ?? 
                       record['createdAt'] ?? 
                       record['createdDate'] ??
                       '';
    
    if (dateValue == null || dateValue.toString().isEmpty || dateValue.toString() == 'null') {
      return '';
    }
    
    try {
      // Try to parse as DateTime if it's a string
      DateTime? dateTime;
      if (dateValue is String) {
        String dateStr = dateValue.trim();
        // Try different date formats
        try {
          // Try ISO format first (2025-12-03T00:00:00.000Z)
          // DateTime.parse handles ISO 8601 format including 'Z' suffix
          dateTime = DateTime.parse(dateStr);
        } catch (e) {
          // Try other formats
          try {
            // Try YYYY-MM-DD format (split by space or T to get date part)
            final parts = dateStr.split(RegExp(r'[T\s]'));
            if (parts.isNotEmpty && parts[0].isNotEmpty) {
              dateTime = DateTime.parse(parts[0]);
            }
          } catch (e2) {
            // If parsing fails, return the original string
            return dateStr;
          }
        }
      } else if (dateValue is DateTime) {
        dateTime = dateValue;
      }
      
      if (dateTime != null) {
        return _formatDate(dateTime);
      }
    } catch (e) {
      // If all parsing fails, return the original value
      return dateValue.toString();
    }
    
    return dateValue.toString();
  }

  String _getRecordInitial(Map<String, dynamic> record) {
    final initial = record['iconInitial']?.toString();
    if (initial != null && initial.isNotEmpty) {
      return initial.toUpperCase();
    }
    final customerName = record['customerName']?.toString();
    if (customerName != null && customerName.isNotEmpty) {
      return customerName[0].toUpperCase();
    }
    return 'H';
  }

  void _onDownload(Map<String, dynamic> record) {
    final date = _getRecordDate(record);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading $date...'),
        backgroundColor: AppTheme.primaryBlue,
      ),
    );
  }

  void _onShare(Map<String, dynamic> record) {
    final date = _getRecordDate(record);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing $date...'),
        backgroundColor: AppTheme.primaryBlue,
      ),
    );
  }

  void _onView(Map<String, dynamic> record) {
    final date = _getRecordDate(record);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing $date...'),
        backgroundColor: AppTheme.primaryBlue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.provider,
      builder: (context, child) {
        return Column(
          children: [
            // Month Selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: GestureDetector(
                onTap: _selectMonth,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedMonth != null
                            ? _formatMonth(_selectedMonth!)
                            : 'Select Month',
                        style: TextStyle(
                          fontSize: 14,
                          color: _selectedMonth != null
                              ? Colors.black
                              : AppTheme.textHint,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: AppTheme.primaryBlue),
                    ],
                  ),
                ),
              ),
            ),
            // Records List
            Expanded(
              child: widget.provider.isLoading
                  ? const Center(child: RefreshLoader(color: AppTheme.primaryBlue))
                  : widget.provider.records.isEmpty
                      ? _buildEmptyState()
                      : _buildRecordsList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecordsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: widget.provider.records.length,
      itemBuilder: (context, index) {
        return _buildRecordCard(widget.provider.records[index]);
      },
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> record) {
    final date = _getRecordDate(record);
    final initial = _getRecordInitial(record);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Green circular icon with 'H'
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Date
          Expanded(
            child: Text(
              date,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          // Action icons
          _buildActionIcon(
            icon: Icons.download,
            onTap: () => _onDownload(record),
          ),
          const SizedBox(width: 12),
          _buildActionIcon(icon: Icons.share, onTap: () => _onShare(record)),
          const SizedBox(width: 12),
          _buildActionIcon(
            icon: Icons.visibility,
            onTap: () => _onView(record),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 20, color: AppTheme.textSecondary),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 64,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No records found',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

