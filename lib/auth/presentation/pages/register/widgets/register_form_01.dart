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

  late final RegisterViewModel _registerViewModel;
  
  // 🔧 Flag para evitar callbacks durante la carga inicial
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    
    _registerViewModel = GetIt.instance<RegisterViewModel>();
    print('[RegisterForm01] ViewModel hashCode: ${_registerViewModel.hashCode}');
    
    _registerViewModel.addListener(_onViewModelChanged);

    // ✅ Ir a la página 0 sin notificar (evita setState durante initState)
    _registerViewModel.goToPage(0);
    
    // 🔧 Cargar datos después del primer frame para evitar setState durante build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingData();
      setState(() {
        _isLoadingData = false;
      });
    });
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

  // ✅ Cargar datos existentes del ViewModel a los controladores
  void _loadExistingData() {
    // Cargar datos sin disparar callbacks
    _nameController.text = _registerViewModel.name;
    _lastNameController.text = _registerViewModel.lastName;
    _secondLastNameController.text = _registerViewModel.secondLastName;
    _usernameController.text = _registerViewModel.username;
    if (_registerViewModel.age != 18) {
      _ageController.text = _registerViewModel.age.toString();
    } else {
      _ageController.text = '';
    }
    
    print('[RegisterForm01] Datos cargados del ViewModel:');
    print('  Name: "${_registerViewModel.name}"');
    print('  LastName: "${_registerViewModel.lastName}"');
    print('  Username: "${_registerViewModel.username}"');
  }

  void _onViewModelChanged() {
    if (mounted && !_isLoadingData) {
      // 🔧 Diferir setState hasta después del frame actual para evitar setState durante build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  // 🔄 Método para sincronizar todos los datos del formulario
  void _syncAllDataToViewModel() {
    final name = _nameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final secondLastName = _secondLastNameController.text.trim();
    final username = _usernameController.text.trim();
    final age = int.tryParse(_ageController.text) ?? 18;

    // Sincronizar todos los campos sin condiciones
    _registerViewModel.setName(name);
    _registerViewModel.setLastName(lastName);
    _registerViewModel.setSecondLastName(secondLastName);
    _registerViewModel.setUsername(username);
    _registerViewModel.setAge(age);
    
    print('[RegisterForm01] Datos sincronizados al ViewModel');
  }

  // ✅ Validar y sincronizar datos antes de continuar
  void _validateAndContinue() {
    if (_formKey.currentState!.validate()) {
      // 🔄 Forzar sincronización de TODOS los datos
      _syncAllDataToViewModel();
      
      // 🔍 Debug: imprimir datos para verificar
      print('=== DEBUG FORM 1 ANTES DE NAVEGAR ===');
      print('Form1 ViewModel hashCode: ${_registerViewModel.hashCode}');
      print('Name Controller: "${_nameController.text}"');
      print('Name ViewModel: "${_registerViewModel.name}"');
      print('LastName Controller: "${_lastNameController.text}"');
      print('LastName ViewModel: "${_registerViewModel.lastName}"');
      print('Username Controller: "${_usernameController.text}"');
      print('Username ViewModel: "${_registerViewModel.username}"');
      print('Age Controller: "${_ageController.text}"');
      print('Age ViewModel: ${_registerViewModel.age}');
      print('Gender ViewModel: ${_registerViewModel.selectedGender.value}');
      print('canGoToNextPage: ${_registerViewModel.canGoToNextPage}');
      print('=====================================');

      // Verificar que todos los campos requeridos estén llenos
      if (_registerViewModel.canGoToNextPage) {
        _registerViewModel.nextPage();
        
        // 🔍 Verificar datos después de nextPage()
        print('=== DEBUG FORM 1 DESPUÉS DE NEXTPAGE ===');
        print('Name: "${_registerViewModel.name}"');
        print('LastName: "${_registerViewModel.lastName}"');
        print('Username: "${_registerViewModel.username}"');
        print('Page: ${_registerViewModel.currentPage}');
        print('=======================================');
        
        context.go(AppRoutesConstant.registerStep2);
      } else {
        // Mostrar mensaje de error si faltan datos
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor completa todos los campos requeridos'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔧 Mostrar loading mientras se cargan los datos iniciales
    if (_isLoadingData) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

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
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 14,
                      ),
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
            onChanged: (value) {
              // 🔧 Solo actualizar ViewModel si no estamos cargando datos
              if (!_isLoadingData) {
                _registerViewModel.setName(value.trim());
              }
            },
            validator: (value) {
              final error = _registerViewModel.getFieldError('name');
              if (error != null) return error;

              if (value == null || value.trim().isEmpty) {
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
            onChanged: (value) {
              if (!_isLoadingData) {
                _registerViewModel.setLastName(value.trim());
              }
            },
            validator: (value) {
              final error = _registerViewModel.getFieldError('lastName');
              if (error != null) return error;

              if (value == null || value.trim().isEmpty) {
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
            onChanged: (value) {
              if (!_isLoadingData) {
                _registerViewModel.setSecondLastName(value.trim());
              }
            },
          ),

          const SizedBox(height: 16),

          // Username field
          CustomTextField(
            controller: _usernameController,
            label: 'Username',
            hint: 'chivemoon',
            onChanged: (value) {
              if (!_isLoadingData) {
                _registerViewModel.setUsername(value.trim());
              }
            },
            validator: (value) {
              final error = _registerViewModel.getFieldError('username');
              if (error != null) return error;

              if (value == null || value.trim().isEmpty) {
                return 'Username is required';
              }
              if (value.trim().length < 3) {
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
              if (!_isLoadingData) {
                final age = int.tryParse(value) ?? 18;
                _registerViewModel.setAge(age);
              }
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
            value: _registerViewModel.selectedGender != Gender.preferNotToSay 
                ? _registerViewModel.selectedGender.displayName 
                : null,
            items: Gender.values.map((g) => g.displayName).toList(),
            onChanged: (value) {
              if (!_isLoadingData && value != null) {
                final gender = Gender.values.firstWhere(
                  (g) => g.displayName == value,
                  orElse: () => Gender.preferNotToSay,
                );
                _registerViewModel.setGender(gender);
              }
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
              style: TextStyle(color: Color(0xFF2196F3), fontSize: 14),
            ),
          ),

          const SizedBox(height: 8),

          // Next button
          CustomButton(
            text: 'Next',
            onPressed: _validateAndContinue,
          ),
        ],
      ),
    );
  }
}