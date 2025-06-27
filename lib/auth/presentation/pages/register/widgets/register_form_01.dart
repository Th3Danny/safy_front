import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:safy/auth/presentation/pages/login/widgets/custom_button.dart';
import 'package:safy/auth/presentation/pages/login/widgets/custom_text_field.dart';
import 'package:safy/auth/presentation/pages/register/widgets/custom_dropdown.dart';
import 'package:safy/core/router/domain/constants/app_routes_constant.dart';


class RegisterForm01 extends StatefulWidget {
  const RegisterForm01({super.key});

  @override
  State<RegisterForm01> createState() => _RegisterForm01State();
}

class _RegisterForm01State extends State<RegisterForm01> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _secondLastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _ageController = TextEditingController();
  String? _selectedGender;

  final List<String> _genders = ['Fem', 'Masc', 'Other'];

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _secondLastNameController.dispose();
    _usernameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Name field
          CustomTextField(
            controller: _nameController,
            label: 'Name',
            hint: 'Yazmin',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Name is required';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Last Name field
          CustomTextField(
            controller: _lastNameController,
            label: 'Last Name',
            hint: 'Reyes',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Last name is required';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Second Last Name field
          CustomTextField(
            controller: _secondLastNameController,
            label: 'Second Last Name',
            hint: 'Ruiz',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Second last name is required';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Username field
          CustomTextField(
            controller: _usernameController,
            label: 'Username',
            hint: 'chivemoon',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Username is required';
              }
              if (value.length < 3) {
                return 'Username must be at least 3 characters';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Age field
          CustomTextField(
            controller: _ageController,
            label: 'Age',
            hint: '18',
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Age is required';
              }
              final age = int.tryParse(value);
              if (age == null || age < 18 || age > 120) {
                return 'Please enter a valid age (18-120)';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Gender dropdown
          CustomDropdown<String>(
            label: 'Gender',
            hint: 'Fem',
            value: _selectedGender,
            items: _genders,
            onChanged: (value) {
              setState(() {
                _selectedGender = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select your gender';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 24),
          
          // Botón para ir al login
          TextButton(
            onPressed: () {
              context.go(AppRoutesConstant.login);
            },
            child: const Text(
              'Already have an account? Login',
              style: TextStyle(
                color: Color(0xFF2196F3),
                fontSize: 14,
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Next button
          CustomButton(
            text: 'Next',
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _handleNext();
              }
            },
          ),
        ],
      ),
    );
  }

  void _handleNext() {
    // Crear datos para pasar a la siguiente pantalla
    final registerData = {
      'name': _nameController.text,
      'lastName': _lastNameController.text,
      'secondLastName': _secondLastNameController.text,
      'username': _usernameController.text,
      'age': _ageController.text,
      'gender': _selectedGender,
    };
    
    // Navegar a la siguiente pantalla con los datos
    context.go(AppRoutesConstant.registerStep2, extra: registerData);
  }
}