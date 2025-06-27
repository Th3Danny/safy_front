import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:safy/auth/presentation/pages/login/widgets/custom_button.dart';
import 'package:safy/auth/presentation/pages/login/widgets/custom_text_field.dart';
import 'package:safy/auth/presentation/pages/register/widgets/job_selector.dart';
import 'package:safy/core/router/domain/constants/app_routes_constant.dart';

class RegisterForm02 extends StatefulWidget {
  final Map<String, dynamic>? registerData;
  
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
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _selectedJob;

  final List<String> _jobs = [
    'Student',
    'Employees',
    'Businessman',
    'Tourist'
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
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
          
          const SizedBox(height: 24),
          
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
            hint: 'Add your password',
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
            obscureText: _obscureConfirmPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey[600],
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
            validator: (value) {
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
            text: 'Sign Up',
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                if (_selectedJob == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a job'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                _handleSignUp();
              }
            },
          ),
        ],
      ),
    );
  }

  void _handleSignUp() {
    // Combinar datos de ambos pasos
    final completeRegistrationData = {
      ...?widget.registerData, // Datos del paso 1
      'job': _selectedJob,
      'email': _emailController.text,
      'password': _passwordController.text,
    };
    
    // TODO: Implementar registro completo con ViewModel
    print('Complete Registration Data: $completeRegistrationData');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Registration completed successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    
    // Navegar al login después del registro exitoso
    Future.delayed(const Duration(seconds: 2), () {
      context.go(AppRoutesConstant.login);
    });
  }
}