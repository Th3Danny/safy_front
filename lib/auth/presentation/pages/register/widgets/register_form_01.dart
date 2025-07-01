import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:safy/auth/domain/value_objects/gender.dart';
import 'package:safy/auth/presentation/pages/login/widgets/custom_button.dart';
import 'package:safy/auth/presentation/pages/login/widgets/custom_text_field.dart';
import 'package:safy/auth/presentation/pages/register/widgets/custom_dropdown.dart';
import 'package:safy/auth/presentation/viewmodels/register_viewmodel.dart';
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

  // ✅ Obtener ViewModel de GetIt
  late final RegisterViewModel _registerViewModel;

  @override
  void initState() {
    super.initState();
    _registerViewModel = GetIt.instance<RegisterViewModel>();
    _registerViewModel.addListener(_onViewModelChanged);
    
    // ✅ Asegurarse de estar en la página 0
    _registerViewModel.goToPage(0);
  }

  @override
  void dispose() {
    _registerViewModel.removeListener(_onViewModelChanged);
    _nameController.dispose();
    _lastNameController.dispose();
    _secondLastNameController.dispose();
    _usernameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // ✅ Mostrar errores si existen
          if (_registerViewModel.hasError) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _registerViewModel.errorMessage!,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: _registerViewModel.clearError,
                    color: Colors.red.shade700,
                  ),
                ],
              ),
            ),
          ],

          // Name field
          CustomTextField(
            controller: _nameController,
            label: 'Name',
            hint: 'Yazmin',
            onChanged: _registerViewModel.setName, // ✅ Conectar con ViewModel
            validator: (value) {
              final error = _registerViewModel.getFieldError('name');
              if (error != null) return error;
              
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
            onChanged: _registerViewModel.setLastName, // ✅ Conectar con ViewModel
            validator: (value) {
              final error = _registerViewModel.getFieldError('lastName');
              if (error != null) return error;
              
              if (value == null || value.isEmpty) {
                return 'Last name is required';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Second Last Name field (opcional)
          CustomTextField(
            controller: _secondLastNameController,
            label: 'Second Last Name',
            hint: 'Ruiz (optional)',
            onChanged: _registerViewModel.setSecondLastName, // ✅ Conectar con ViewModel
          ),
          
          const SizedBox(height: 16),
          
          // Username field
          CustomTextField(
            controller: _usernameController,
            label: 'Username',
            hint: 'chivemoon',
            onChanged: _registerViewModel.setUsername, // ✅ Conectar con ViewModel
            validator: (value) {
              final error = _registerViewModel.getFieldError('username');
              if (error != null) return error;
              
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
            onChanged: (value) {
              final age = int.tryParse(value) ?? 18;
              _registerViewModel.setAge(age); // ✅ Conectar con ViewModel
            },
            validator: (value) {
              final error = _registerViewModel.getFieldError('age');
              if (error != null) return error;
              
              if (value == null || value.isEmpty) {
                return 'Age is required';
              }
              final age = int.tryParse(value);
              if (age == null || age < 13 || age > 120) {
                return 'Please enter a valid age (13-120)';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Gender dropdown
          CustomDropdown<String>(
            label: 'Gender',
            hint: 'Select gender',
            value: _registerViewModel.selectedGender.displayName,
            items: Gender.values.map((g) => g.displayName).toList(),
            onChanged: (value) {
              if (value != null) {
                final gender = Gender.values.firstWhere(
                  (g) => g.displayName == value,
                  orElse: () => Gender.preferNotToSay,
                );
                _registerViewModel.setGender(gender); // ✅ Conectar con ViewModel
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty || value == Gender.preferNotToSay.displayName) {
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
            onPressed: _registerViewModel.canGoToNextPage ? () {
              if (_formKey.currentState!.validate()) {
                // ✅ Sincronizar todos los campos con el ViewModel
                _registerViewModel.setName(_nameController.text);
                _registerViewModel.setLastName(_lastNameController.text);
                _registerViewModel.setSecondLastName(_secondLastNameController.text);
                _registerViewModel.setUsername(_usernameController.text);
                _registerViewModel.setAge(int.tryParse(_ageController.text) ?? 18);
                
                // ✅ Ir a la siguiente página
                _registerViewModel.nextPage();
                
                // ✅ Navegar a la pantalla del paso 2
                context.go(AppRoutesConstant.registerStep2);
              }
            } : null,
          ),
        ],
      ),
    );
  }
}
