import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:safy/auth/presentation/pages/login/widgets/custom_button.dart';
import 'package:safy/auth/presentation/pages/login/widgets/custom_text_field.dart';
import 'package:safy/core/router/domain/constants/app_routes_constant.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
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
          // Email field
          CustomTextField(
            controller: _emailController,
            label: 'Email address',
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
          
          // Remember me y Forgot password
          Row(
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: (value) {
                      setState(() {
                        _rememberMe = value ?? false;
                      });
                    },
                    activeColor: const Color(0xFF2196F3),
                  ),
                  const Text(
                    'Remember me',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // TODO: Implementar forgot password
                },
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF2196F3),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Login button
          CustomButton(
            text: 'Log in',
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                // TODO: Implementar login logic
                _handleLogin();
                context.go(AppRoutesConstant.home);
              }
            },
          ),
          
          const SizedBox(height: 16),
          
          // Botón para ir al registro
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Don't have an account? ",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              TextButton(
                onPressed: () {
                  context.go(AppRoutesConstant.register);
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Register',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF2196F3),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleLogin() {
    // TODO: Implementar con ViewModel cuando esté listo
    print('Email: ${_emailController.text}');
    print('Password: ${_passwordController.text}');
    print('Remember me: $_rememberMe');
  }
}
