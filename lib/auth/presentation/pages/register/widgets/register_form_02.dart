import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:safy/auth/domain/value_objects/job_type.dart';
import 'package:safy/auth/presentation/pages/login/widgets/custom_button.dart';
import 'package:safy/auth/presentation/pages/login/widgets/custom_text_field.dart';
import 'package:safy/auth/presentation/pages/register/widgets/job_selector.dart';
import 'package:safy/auth/presentation/viewmodels/register_viewmodel.dart';
import 'package:safy/core/router/domain/constants/app_routes_constant.dart';

class RegisterForm02 extends StatefulWidget {
  final Map<String, dynamic>? registerData;

  const RegisterForm02({super.key, this.registerData});

  @override
  State<RegisterForm02> createState() => _RegisterForm02State();
}

class _RegisterForm02State extends State<RegisterForm02> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late final RegisterViewModel _registerViewModel;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    
    // 🔧 Obtener la MISMA instancia de GetIt
    _registerViewModel = GetIt.instance<RegisterViewModel>();
    print('[RegisterForm02] ViewModel hashCode: ${_registerViewModel.hashCode}');
    
    _registerViewModel.addListener(_onViewModelChanged);

    // ✅ Ir a la página 1 sin notificar
    _registerViewModel.goToPage(1);
    
    // 🔧 Cargar datos después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingData();
      _debugPrintForm1Data();
      setState(() {
        _isLoadingData = false;
      });
    });
  }

  @override
  void dispose() {
    _registerViewModel.removeListener(_onViewModelChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ✅ Cargar datos existentes del ViewModel a los controladores
  void _loadExistingData() {
    _emailController.text = _registerViewModel.email;
    _passwordController.text = _registerViewModel.password;
    _confirmPasswordController.text = _registerViewModel.confirmPassword;
  }

  // 🔍 Debug: imprimir datos del primer formulario
  void _debugPrintForm1Data() {
    print('=== DEBUG FORM 2 - VERIFICACIÓN DE DATOS ===');
    print('Form2 ViewModel hashCode: ${_registerViewModel.hashCode}');
    _registerViewModel.printCurrentState();
    
    // Si los datos están vacíos, hay un problema
    if (_registerViewModel.name.isEmpty) {
      print('❌ ERROR: Los datos del Form1 se perdieron!');
      print('❌ Posibles causas:');
      print('   1. GetIt no está configurado como singleton');
      print('   2. Se está creando una nueva instancia');
      print('   3. Los datos se están limpiando en algún lugar');
    } else {
      print('✅ Los datos del Form1 están presentes');
    }
    print('===========================================');
  }

  void _onViewModelChanged() {
    if (mounted && !_isLoadingData) {
      // 🔧 Diferir setState hasta después del frame actual
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
        }
      });

      // ✅ Navegar al home si registro fue exitoso
      if (_registerViewModel.lastSuccessfulSession != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('¡Registro exitoso! Bienvenido a Safy'),
                backgroundColor: Colors.green,
              ),
            );
            context.go(AppRoutesConstant.home);
          }
        });
      }
    }
  }

  // 🔄 Sincronizar datos del formulario 2 con el ViewModel
  void _syncFormDataToViewModel() {
    _registerViewModel.setEmail(_emailController.text.trim());
    _registerViewModel.setPassword(_passwordController.text);
    _registerViewModel.setConfirmPassword(_confirmPasswordController.text);
  }

  // ✅ Validar y enviar registro
  Future<void> _validateAndSubmit() async {
    if (_formKey.currentState!.validate()) {
      // 🔄 Sincronizar datos actuales
      _syncFormDataToViewModel();
      
      // 🔍 Debug: imprimir estado final antes del registro
      print('=== DEBUG FORM 2 - ANTES DEL REGISTRO ===');
      _registerViewModel.printCurrentState();
      print('=======================================');

      // ✅ Verificar que se puede enviar
      if (_registerViewModel.canSubmit) {
        final success = await _registerViewModel.signUp();
        
        if (success) {
          print('✅ Registro exitoso desde register_form_02.dart');
        } else {
          print('❌ Error en el registro desde register_form_02.dart');
        }
      } else {
        print('❌ No se puede enviar: canSubmit = false');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor completa todos los campos correctamente'),
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
          // 🔍 Debug widget - mostrar datos del primer formulario
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: _registerViewModel.name.isEmpty ? Colors.red.shade50 : Colors.green.shade50,
              border: Border.all(
                color: _registerViewModel.name.isEmpty ? Colors.red.shade300 : Colors.green.shade300
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _registerViewModel.name.isEmpty ? 'ERROR - Datos perdidos:' : 'DEBUG - Datos recibidos:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 12,
                    color: _registerViewModel.name.isEmpty ? Colors.red.shade700 : Colors.green.shade700,
                  ),
                ),
                Text('Nombre: "${_registerViewModel.name}"', style: TextStyle(fontSize: 11)),
                Text('Apellido: "${_registerViewModel.lastName}"', style: TextStyle(fontSize: 11)),
                Text('Usuario: "${_registerViewModel.username}"', style: TextStyle(fontSize: 11)),
                Text('Edad: ${_registerViewModel.age}', style: TextStyle(fontSize: 11)),
                Text('Género: ${_registerViewModel.selectedGender.value}', style: TextStyle(fontSize: 11)),
                Text('HashCode: ${_registerViewModel.hashCode}', style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic)),
              ],
            ),
          ),

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

          // Job selector
          _JobSelectorConnected(
            selectedJobType: _registerViewModel.selectedJobType,
            onJobSelected: (jobType) {
              if (!_isLoadingData) {
                _registerViewModel.setJobType(jobType);
              }
            },
          ),

          const SizedBox(height: 24),

          // Email field
          CustomTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'yaz@gmail.com',
            keyboardType: TextInputType.emailAddress,
            onChanged: (value) {
              if (!_isLoadingData) {
                _registerViewModel.setEmail(value.trim());
              }
            },
            validator: (value) {
              final error = _registerViewModel.getFieldError('email');
              if (error != null) return error;

              if (value == null || value.trim().isEmpty) {
                return 'Email is required';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
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
            hint: 'Add your password',
            obscureText: !_registerViewModel.isPasswordVisible,
            onChanged: (value) {
              if (!_isLoadingData) {
                _registerViewModel.setPassword(value);
              }
            },
            suffixIcon: IconButton(
              icon: Icon(
                _registerViewModel.isPasswordVisible
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: Colors.grey[600],
              ),
              onPressed: () {
                if (!_isLoadingData) {
                  _registerViewModel.togglePasswordVisibility();
                }
              },
            ),
            validator: (value) {
              final error = _registerViewModel.getFieldError('password');
              if (error != null) return error;

              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Confirm Password field
          CustomTextField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            hint: 'Add your password',
            obscureText: !_registerViewModel.isConfirmPasswordVisible,
            onChanged: (value) {
              if (!_isLoadingData) {
                _registerViewModel.setConfirmPassword(value);
              }
            },
            suffixIcon: IconButton(
              icon: Icon(
                _registerViewModel.isConfirmPasswordVisible
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: Colors.grey[600],
              ),
              onPressed: () {
                if (!_isLoadingData) {
                  _registerViewModel.toggleConfirmPasswordVisibility();
                }
              },
            ),
            validator: (value) {
              final error = _registerViewModel.getFieldError('confirmPassword');
              if (error != null) return error;

              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),

          const SizedBox(height: 24),

          // Botón para regresar
          TextButton(
            onPressed: () {
              _registerViewModel.previousPage();
              context.go(AppRoutesConstant.register);
            },
            child: const Text(
              'Back to previous step',
              style: TextStyle(color: Color(0xFF2196F3), fontSize: 14),
            ),
          ),

          const SizedBox(height: 8),

          // Sign Up button
          CustomButton(
            text: _registerViewModel.isLoading ? 'Creating account...' : 'Sign Up',
            onPressed: _validateAndSubmit,
            isLoading: _registerViewModel.isLoading,
          ),
        ],
      ),
    );
  }
}

// ✅ Widget para conectar JobSelector con JobType enum
class _JobSelectorConnected extends StatelessWidget {
  final JobType selectedJobType;
  final ValueChanged<JobType> onJobSelected;

  const _JobSelectorConnected({
    required this.selectedJobType,
    required this.onJobSelected,
  });

  @override
  Widget build(BuildContext context) {
    return JobSelector(
      selectedJob: selectedJobType.displayName,
      jobs: JobType.values.map((job) => job.displayName).toList(),
      onJobSelected: (jobDisplayName) {
        final jobType = JobType.values.firstWhere(
          (job) => job.displayName == jobDisplayName,
          orElse: () => JobType.student,
        );
        onJobSelected(jobType);
      },
    );
  }
}