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
  final Map<String, dynamic>? registerData; // Mantener para compatibilidad
  
  const RegisterForm02({
    super.key,
    this.registerData,
  });

  @override
  State<RegisterForm02> createState() => _RegisterForm02State();
}

class _RegisterForm02State extends State<RegisterForm02> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // ✅ Obtener ViewModel de GetIt (el mismo que en el paso 1)
  late final RegisterViewModel _registerViewModel;

  @override
  void initState() {
    super.initState();
    _registerViewModel = GetIt.instance<RegisterViewModel>();
    _registerViewModel.addListener(_onViewModelChanged);
    
    // ✅ Asegurarse de estar en la página 1
    _registerViewModel.goToPage(1);
  }

  @override
  void dispose() {
    _registerViewModel.removeListener(_onViewModelChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) {
      setState(() {});
      
      // ✅ Navegar al login si registro fue exitoso
      if (_registerViewModel.lastSuccessfulSession != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Registro exitoso! Bienvenido a Safy'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navegar al home o login
          context.go(AppRoutesConstant.home);
        });
      }
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

          // Job selector
          _JobSelectorConnected(
            selectedJobType: _registerViewModel.selectedJobType,
            onJobSelected: _registerViewModel.setJobType, // ✅ Conectar con ViewModel
          ),
          
          const SizedBox(height: 24),
          
          // Email field
          CustomTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'yaz@gmail.com',
            keyboardType: TextInputType.emailAddress,
            onChanged: _registerViewModel.setEmail, // ✅ Conectar con ViewModel
            validator: (value) {
              final error = _registerViewModel.getFieldError('email');
              if (error != null) return error;
              
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
            hint: 'Add your password',
            obscureText: !_registerViewModel.isPasswordVisible, // ✅ Usar estado del ViewModel
            onChanged: _registerViewModel.setPassword, // ✅ Conectar con ViewModel
            suffixIcon: IconButton(
              icon: Icon(
                _registerViewModel.isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey[600],
              ),
              onPressed: _registerViewModel.togglePasswordVisibility, // ✅ Usar método del ViewModel
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
            obscureText: !_registerViewModel.isConfirmPasswordVisible, // ✅ Usar estado del ViewModel
            onChanged: _registerViewModel.setConfirmPassword, // ✅ Conectar con ViewModel
            suffixIcon: IconButton(
              icon: Icon(
                _registerViewModel.isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey[600],
              ),
              onPressed: _registerViewModel.toggleConfirmPasswordVisibility, // ✅ Usar método del ViewModel
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
              style: TextStyle(
                color: Color(0xFF2196F3),
                fontSize: 14,
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Sign Up button
          CustomButton(
            text: _registerViewModel.isLoading ? 'Creating account...' : 'Sign Up',
            onPressed: _registerViewModel.canSubmit ? () async {
              if (_formKey.currentState!.validate()) {
                // ✅ Sincronizar campos con ViewModel
                _registerViewModel.setEmail(_emailController.text);
                _registerViewModel.setPassword(_passwordController.text);
                _registerViewModel.setConfirmPassword(_confirmPasswordController.text);
                
                // ✅ Ejecutar registro real
                final success = await _registerViewModel.signUp();
                
                // La navegación se maneja en _onViewModelChanged
                if (success) {
                  print('Registro exitoso!');
                }
              }
            } : null,
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
