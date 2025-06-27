import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:safy/auth/presentation/pages/login/widgets/custom_button.dart';
import 'package:safy/auth/presentation/pages/register/widgets/job_selector.dart';
import 'package:safy/shared/widget/custom_text_field.dart';
import 'package:safy/shared/widget/profile_avatar.dart';


class EditProfileForm extends StatefulWidget {
  const EditProfileForm({super.key});

  @override
  State<EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends State<EditProfileForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController(text: 'Chivemoon');
  final _emailController = TextEditingController(text: 'yaz@gmail.com');
  final _passwordController = TextEditingController(text: '••••••••••••');
  bool _obscurePassword = true;
  String? _selectedJob = 'Student';

  final List<String> _jobs = [
    'Student',
    'Employees',
    'Businessman',
    'Tourist'
  ];

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Avatar de perfil
          const ProfileAvatar(
            radius: 50,
            showEditButton: true,
          ),
          
          const SizedBox(height: 32),
          
          // Username field
          CustomTextField(
            controller: _usernameController,
            label: 'Username',
            hint: 'Chivemoon',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Username is required';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Email field
          CustomTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'yaz@gmail.com',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email is required';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Password field
          CustomTextField(
            controller: _passwordController,
            label: 'Password',
            hint: '••••••••••••',
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey[600],
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 24),
          
          // Job selector
          JobSelector(
            selectedJob: _selectedJob,
            jobs: _jobs,
            onJobSelected: (job) {
              setState(() {
                _selectedJob = job;
              });
            },
          ),
          
          const SizedBox(height: 32),
          
          // Save button
          CustomButton(
            text: 'Guardar',
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _handleSaveProfile();
              }
            },
          ),
        ],
      ),
    );
  }

  void _handleSaveProfile() {
    final profileData = {
      'username': _usernameController.text,
      'email': _emailController.text,
      'job': _selectedJob,
    };
    
    print('Profile Data: $profileData');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    
    context.pop();
  }
}