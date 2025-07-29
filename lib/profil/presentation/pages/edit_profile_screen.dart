import 'package:flutter/material.dart';
import 'package:safy/profil/presentation/widgets/edit_profile_form.dart';
import 'package:safy/shared/widget/custom_app_bar.dart';


class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(
        title: 'Editar Perfil',
        showBackButton: true,
      ),
      body: const SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: EditProfileForm(),
        ),
      ),
    );
  }
}
