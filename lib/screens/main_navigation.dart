import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'home_screen.dart';
import '../settings/settings_screen.dart';
import '../utils/app_theme.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  bool _showBottomNav = true;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(
        onExtractionScreenShown: () {
          setState(() {
            _showBottomNav = false;
          });
        },
        onExtractionScreenHidden: () {
          setState(() {
            _showBottomNav = true;
          });
        },
      ),
      // DocsScreen(), // This will be "Yours" screen
      // DocsScreen(), // This will be "Share" screen
      SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _showBottomNav
          ? Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.white,
                selectedItemColor: Colors.black,
                unselectedItemColor: AppTheme.navUnselected,
                selectedFontSize: 12,
                unselectedFontSize: 12,
                iconSize: 24,
                elevation: 0,
                selectedLabelStyle: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: TextStyle(
                  color: AppTheme.navUnselected,
                  fontWeight: FontWeight.w500,
                ),
                items: [
                  BottomNavigationBarItem(
                    icon: _buildSvgIcon(
                      'assets/images/bottom_nav_home.svg',
                      isActive: _currentIndex == 0,
                    ),
                    activeIcon: _buildSvgIcon(
                      'assets/images/bottom_nav_home.svg',
                      isActive: true,
                    ),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: _buildSvgIcon(
                      'assets/images/bottom_nav_sheets.svg',
                      isActive: _currentIndex == 1,
                    ),
                    activeIcon: _buildSvgIcon(
                      'assets/images/bottom_nav_sheets.svg',
                      isActive: true,
                    ),
                    label: 'Sheets',
                  ),
                  BottomNavigationBarItem(
                    icon: _buildSvgIcon(
                      'assets/images/bottom_nav_users.svg',
                      isActive: _currentIndex == 2,
                    ),
                    activeIcon: _buildSvgIcon(
                      'assets/images/bottom_nav_users.svg',
                      isActive: true,
                    ),
                    label: 'Users',
                  ),
                  BottomNavigationBarItem(
                    icon: _buildSvgIcon(
                      'assets/images/bottom_nav_settings.svg',
                      isActive: _currentIndex == 3,
                    ),
                    activeIcon: _buildSvgIcon(
                      'assets/images/bottom_nav_settings.svg',
                      isActive: true,
                    ),
                    label: 'Settings',
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildSvgIcon(String assetPath, {required bool isActive}) {
    return SvgPicture.asset(
      assetPath,
      width: 18,
      height: 18,
      colorFilter: ColorFilter.mode(
        isActive ? Colors.black : AppTheme.navUnselected,
        BlendMode.srcIn,
      ),
    );
  }
}
