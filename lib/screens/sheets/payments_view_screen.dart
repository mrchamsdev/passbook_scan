import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';

class PaymentsViewScreen extends StatelessWidget {
  final List<Map<String, dynamic>> payments;
  final String filterDate;

  const PaymentsViewScreen({
    super.key,
    required this.payments,
    required this.filterDate,
  });

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd-MM-yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatAmount(String amount) {
    try {
      final value = double.parse(amount);
      return '₹${NumberFormat('#,##0.00').format(value)}';
    } catch (e) {
      return '₹$amount';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payments View',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              'Date: $filterDate',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: payments.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                // Summary Card
                Container(
                  margin: const EdgeInsets.all(16),
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
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            '${payments.length}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Total Payments',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: AppTheme.borderColor,
                      ),
                      Column(
                        children: [
                          Text(
                            _formatAmount(
                              payments
                                  .fold<double>(
                                    0.0,
                                    (sum, payment) =>
                                        sum +
                                        (double.tryParse(
                                              payment['amountToPay']
                                                      as String? ??
                                                  '0',
                                            ) ??
                                            0.0),
                                  )
                                  .toString(),
                            ),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Total Amount',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Payments List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: payments.length,
                    itemBuilder: (context, index) {
                      return _buildPaymentCard(payments[index], index + 1);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment, int index) {
    final paymentDate = payment['paymentDate'] as String? ?? '';
    final amountToPay = payment['amountToPay'] as String? ?? '0';
    final bankInfo = payment['bankInfo'] as Map<String, dynamic>? ?? {};
    final accountNumber = bankInfo['accountNumber'] as String? ?? 'N/A';
    final ifscCode = bankInfo['ifscCode'] as String? ?? 'N/A';
    final customerName = bankInfo['customerName'] as String? ?? 'N/A';

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#$index',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
              Text(
                _formatAmount(amountToPay),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Customer Name
          _buildInfoRow('Customer Name', customerName),
          const SizedBox(height: 8),
          // Payment Date
          _buildInfoRow('Payment Date', _formatDate(paymentDate)),
          const SizedBox(height: 8),
          // Account Number
          _buildInfoRow('Account Number', accountNumber),
          const SizedBox(height: 8),
          // IFSC Code
          _buildInfoRow('IFSC Code', ifscCode),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payment_outlined, size: 64, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          Text(
            'No payments found',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Date: $filterDate',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
