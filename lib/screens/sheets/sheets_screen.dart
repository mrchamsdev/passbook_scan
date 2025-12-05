import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../myapp.dart';
import 'sheets_provider/sheets_provider.dart';
import 'month_tab.dart';
import 'date_range_tab.dart';

class SheetsScreen extends StatefulWidget {
  const SheetsScreen({super.key});

  @override
  State<SheetsScreen> createState() => SheetsScreenState();
}

class SheetsScreenState extends State<SheetsScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  late SheetsProvider _provider;
  bool _isMonthFilter = true;
  DateTime? _lastRefreshTime;
  static const _refreshInterval = Duration(seconds: 30); // Refresh if more than 30 seconds passed

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Set default JWT token for API calls
    const defaultToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6NSwiaWF0IjoxNzY0NzYzMjc2LCJleHAiOjE3NzI1MzkyNzZ9.Yv1NgkZNiJUeHsptFLU_i5zQwZjpy1YqqKKPSsWfa3k';
    if (MyApp.authTokenValue == null || MyApp.authTokenValue!.isEmpty) {
      MyApp.setAuthToken(defaultToken);
    }
    _tabController = TabController(length: 2, vsync: this);
    _provider = SheetsProvider();
    _tabController.addListener(() {
      setState(() {
        _isMonthFilter = _tabController.index == 0;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _provider.dispose();
    super.dispose();
  }

  // Public method to refresh data when tab becomes visible
  void refreshDataIfNeeded() {
    print('🔄 [SHEETS TAB] Tab clicked - Checking if refresh is needed...');
    final now = DateTime.now();
    // Refresh if never refreshed or if more than refresh interval has passed
    if (_lastRefreshTime == null || 
        now.difference(_lastRefreshTime!) > _refreshInterval) {
      _lastRefreshTime = now;
      print('✅ [SHEETS TAB] Triggering API refresh...');
      // First fetch all data
      _provider.fetchAll();
    } else {
      final timeSinceLastRefresh = now.difference(_lastRefreshTime!);
      print('⏸️ [SHEETS TAB] Skipping refresh - Only ${timeSinceLastRefresh.inSeconds}s since last refresh (cooldown: ${_refreshInterval.inSeconds}s)');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    // Refresh data when screen becomes visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      refreshDataIfNeeded();
    });
    
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      body: Column(
        children: [
          // Header
          SizedBox(height: MediaQuery.of(context).padding.top),
          _buildHeader(),
          // Filter Buttons (Tabs)
          _buildFilterButtons(),
          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                MonthTab(provider: _provider),
                DateRangeTab(provider: _provider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),

      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sheets',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Extracted information',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterButton(
              label: 'Month',
              isSelected: _isMonthFilter,
              onTap: () {
                _tabController.animateTo(0);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildFilterButton(
              label: 'Date Range',
              isSelected: !_isMonthFilter,
              onTap: () {
                _tabController.animateTo(1);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 18,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
