import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:safy/core/router/domain/constants/app_routes_constant.dart';
import 'package:safy/shared/widget/settings_section.dart';
import 'package:safy/shared/widget/settings_tile.dart';


class SettingsList extends StatelessWidget {
  const SettingsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Sección Account
        SettingsSection(
          title: 'Account',
          children: [
            SettingsTile(
              title: 'Edit Profil',
              icon: Icons.account_circle,
              onTap: () {
                 context.go(AppRoutesConstant.editProfile);
              },
            ),
            SettingsTile(
              title: 'Notificaciones',
              icon: Icons.notifications,
              onTap: () {
                print('Navigate to Notifications');
              },
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Sección Support & About
        SettingsSection(
          title: 'Support & About',
          children: [
            SettingsTile(
              title: 'Help and support',
              icon: Icons.help_outline,
              onTap: () {
                print('Navigate to Help');
              },
            ),
            SettingsTile(
              title: 'Terms and Policies',
              icon: Icons.description,
              onTap: () {
                print('Navigate to Terms');
              },
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Sección Actions
        SettingsSection(
          title: 'Actions',
          children: [
            SettingsTile(
              title: 'Log out',
              icon: Icons.logout,
              textColor: Colors.red,
              iconColor: Colors.red,
              onTap: () {
                _showLogoutDialog(context);
              },
            ),
          ],
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Log out'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // context.go('/login');
                print('User logged out');
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Log out'),
            ),
          ],
        );
      },
    );
  }
}