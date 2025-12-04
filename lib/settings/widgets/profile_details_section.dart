import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import 'profile_detail_item.dart';
import '../edit_profile_screen.dart';

class ProfileDetailsSection extends StatelessWidget {
  final Map<String, dynamic> userData;
  final VoidCallback? onProfileUpdated;

  const ProfileDetailsSection({
    super.key,
    required this.userData,
    this.onProfileUpdated,
  });

  String _getValue(String key) {
    final value = userData[key];
    if (value == null || value.toString().isEmpty) {
      return 'N/A';
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: const Text(
                'PROFILE DETAILS',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfileScreen(userData: userData),
                  ),
                ).then((result) {
                  // Refresh profile if update was successful
                  if (result == true && onProfileUpdated != null) {
                    onProfileUpdated!();
                  }
                });
              },
              icon: const Icon(
                Icons.edit_outlined,
                size: 18,
                color: AppTheme.primaryBlue,
              ),
              label: const Text(
                'Edit',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryBlue,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppTheme.primaryBlue, width: 1),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppTheme.cardBackground),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileDetailItem(
                icon: Icons.person_outline,
                label: 'Full Name',
                value: _getValue('name'),
              ),
              const Divider(height: 32),
              ProfileDetailItem(
                icon: Icons.email_outlined,
                label: 'Email Address',
                value: _getValue('email'),
              ),
              const Divider(height: 32),
              ProfileDetailItem(
                icon: Icons.phone_outlined,
                label: 'Phone Number',
                value: _getValue('phoneNumber'),
              ),
              const Divider(height: 32),
              ProfileDetailItem(
                icon: Icons.business_outlined,
                label: 'Company Name',
                value: _getValue('companyName'),
              ),
              const Divider(height: 32),
              ProfileDetailItem(
                icon: Icons.category_outlined,
                label: 'Company Type',
                value: _getValue('companyType'),
              ),
              const Divider(height: 32),
              ProfileDetailItem(
                icon: Icons.credit_card_outlined,
                label: 'PAN Number',
                value: _getValue('pan'),
              ),
              const Divider(height: 32),
              ProfileDetailItem(
                icon: Icons.description_outlined,
                label: 'GST Number',
                value: _getValue('gstNo'),
              ),
              if (userData['address'] != null &&
                  userData['address'].toString().isNotEmpty) ...[
                const Divider(height: 32),
                ProfileDetailItem(
                  icon: Icons.location_on_outlined,
                  label: 'Address',
                  value: _getValue('address'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
