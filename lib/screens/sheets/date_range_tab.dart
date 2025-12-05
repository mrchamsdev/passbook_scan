import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../widgets/bank_loader.dart';
import 'sheets_provider/sheets_provider.dart';

class DateRangeTab extends StatefulWidget {
  final SheetsProvider provider;
  
  const DateRangeTab({super.key, required this.provider});

  @override
  State<DateRangeTab> createState() => _DateRangeTabState();
}

class _DateRangeTabState extends State<DateRangeTab> {
  DateTime? _startDate;
  DateTime? _endDate;

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day-$month-$year';
  }

  String _formatDateForApi(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _startDate!.isAfter(_endDate!)) {
          _endDate = null;
        }
      });
      _loadSheets();
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        _endDate = picked;
      });
      _loadSheets();
    }
  }

  @override
  void initState() {
    super.initState();
    // First ensure all data is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.provider.records.isEmpty && !widget.provider.isLoading) {
        await widget.provider.fetchAll();
      }
    });
  }

  void _loadSheets() {
    if (_startDate == null || _endDate == null) return;

    // Filter existing data by date range
    widget.provider.fetchByDateRange(
      startDate: _formatDateForApi(_startDate!),
      endDate: _formatDateForApi(_endDate!),
    );
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
            // Date Range Inputs
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _buildDateInput(
                      label: 'Start Date',
                      date: _startDate,
                      onTap: _selectStartDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateInput(
                      label: 'End Date',
                      date: _endDate,
                      onTap: _selectEndDate,
                    ),
                  ),
                ],
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

  Widget _buildDateInput({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    date != null ? _formatDate(date) : 'dd-mm-yyyy',
                    style: TextStyle(
                      fontSize: 14,
                      color: date != null ? Colors.black : AppTheme.textHint,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: AppTheme.primaryBlue,
                ),
              ],
            ),
          ],
        ),
      ),
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

