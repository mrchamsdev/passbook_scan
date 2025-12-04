import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import '../utils/app_theme.dart';
import '../services/network_service.dart';
import '../widgets/bank_loader.dart';
import 'widgets/user_avatar.dart';
import 'add_transaction_screen.dart';

class UserDetailScreen extends StatefulWidget {
  final int bankInfoId;

  const UserDetailScreen({super.key, required this.bankInfoId});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _bankInfo;
  List<dynamic> _futureTransactions = [];
  List<dynamic> _pastTransactions = [];

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final url =
          '${dotenv.env['API_URL']}bank/userDetails/${widget.bankInfoId}';
      print('🌐 [USER DETAILS] Fetching from: $url');
      var response = await ServiceWithHeader(url).data();

      if (response is List && response.length >= 2) {
        int statusCode = response[0];
        dynamic responseBody = response[1];

        if (statusCode == 200 && responseBody != null) {
          setState(() {
            _userData = responseBody['user'] as Map<String, dynamic>?;
            _bankInfo = responseBody['bankInfo'] as Map<String, dynamic>?;
            _futureTransactions =
                responseBody['futureTransactions'] as List<dynamic>? ?? [];
            _pastTransactions =
                responseBody['pastTransactions'] as List<dynamic>? ?? [];
            _isLoading = false;
          });
          return;
        }
      }

      setState(() {
        _errorMessage = 'Failed to load user details';
        _isLoading = false;
      });
    } catch (e) {
      print('❌ [USER DETAILS] Error: $e');
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  String get displayName {
    if (_bankInfo == null) return '';
    final customerName = _bankInfo!['customerName'] as String? ?? '';
    final nickname = _bankInfo!['nickname'] as String? ?? '';
    return customerName.isNotEmpty ? customerName : nickname;
  }

  String get initials {
    if (_bankInfo == null) return 'U';
    final customerName = _bankInfo!['customerName'] as String? ?? '';
    if (customerName.isNotEmpty) {
      final parts = customerName.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return customerName[0].toUpperCase();
    }
    final nickname = _bankInfo!['nickname'] as String? ?? '';
    if (nickname.isNotEmpty) {
      return nickname[0].toUpperCase();
    }
    return 'U';
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM-dd-yyyy').format(date);
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
              'User Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              'View Mode',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: RefreshLoader(color: AppTheme.primaryBlue))
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppTheme.errorColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchUserDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _buildViewMode(),
    );
  }

  Widget _buildViewMode() {
    if (_bankInfo == null) {
      return const Center(child: Text('No data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Details Card
          Container(
            decoration: BoxDecoration(
              color: AppTheme.lightBlueAccent,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                _buildInfoRow(
                  'AC',
                  _bankInfo!['accountNumber'] as String? ?? 'N/A',
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  'IFSC',
                  _bankInfo!['ifscCode'] as String? ?? 'N/A',
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  'PAN',
                  _bankInfo!['panNumber'] as String? ?? 'N/A',
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddTransactionScreen(
                          bankInfoId: widget.bankInfoId,
                          displayName: displayName,
                          initials: initials,
                          panNumber: _bankInfo!['panNumber'] as String?,
                          accountNumber: _bankInfo!['accountNumber'] as String?,
                          ifscCode: _bankInfo!['ifscCode'] as String?,
                        ),
                      ),
                    ).then((result) {
                      // Refresh user details if transaction was added successfully
                      if (result == true) {
                        _fetchUserDetails();
                      }
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primaryBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Edit',
                    style: TextStyle(color: AppTheme.primaryBlue),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Future Transactions Section
          const Text(
            'Future Transactions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _futureTransactions.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'No future transactions',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _futureTransactions.length,
                  itemBuilder: (context, index) {
                    final transaction =
                        _futureTransactions[index] as Map<String, dynamic>;
                    return _buildTransactionItem(transaction, isFuture: true);
                  },
                ),

          const SizedBox(height: 24),

          // Past Transactions Section
          const Text(
            'Transactions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _pastTransactions.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'No transactions',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _pastTransactions.length,
                  itemBuilder: (context, index) {
                    final transaction =
                        _pastTransactions[index] as Map<String, dynamic>;
                    return _buildTransactionItem(transaction, isFuture: false);
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(
    Map<String, dynamic> transaction, {
    required bool isFuture,
  }) {
    final amount = transaction['amountToPay'] as String? ?? '0';
    final paymentDate = transaction['paymentDate'] as String? ?? '';
    final entryPerson = _userData?['name'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatAmount(amount),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                if (isFuture && paymentDate.isNotEmpty)
                  Text(
                    _formatDate(paymentDate),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                Text(
                  '$entryPerson (Entry person name)',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isFuture)
            IconButton(
              icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
              onPressed: () {
                // TODO: Implement transaction options
              },
            )
          else if (paymentDate.isNotEmpty)
            Text(
              _formatDate(paymentDate),
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}
