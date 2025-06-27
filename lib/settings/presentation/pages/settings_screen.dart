import 'package:flutter/material.dart';
import 'package:safy/settings/presentation/widgets/settings_list.dart';
import 'package:safy/shared/widget/custom_app_bar.dart';


class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(
        title: 'Ajustes',
        showBackButton: true,
      ),
      body: const SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: SettingsList(),
        ),
      ),
    );
  }
}