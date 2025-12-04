import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import 'profile_detail_item.dart';

class ProfileDetailsSection extends StatelessWidget {
  final Map<String, dynamic> userData;

  const ProfileDetailsSection({super.key, required this.userData});

  String _getValue(String key) {
    final value = userData[key];
    if (value == null || value.toString().isEmpty) {
      return 'N/A';
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PROFILE DETAILS',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),
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
    );
  }
}
