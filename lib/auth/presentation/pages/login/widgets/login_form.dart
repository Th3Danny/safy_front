import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:safy/auth/presentation/pages/login/widgets/custom_button.dart';
import 'package:safy/auth/presentation/pages/login/widgets/custom_text_field.dart';
import 'package:safy/auth/presentation/viewmodels/login_viewmodel.dart';
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

  // Obtener ViewModel de GetIt
  late final LoginViewModel _loginViewModel;

  @override
  void initState() {
    super.initState();
    _loginViewModel = GetIt.instance<LoginViewModel>();

    // Escuchar cambios del ViewModel
    _loginViewModel.addListener(_onViewModelChanged);

    // Precargar email si se recordó
    // _loginViewModel.preloadEmailIfRemembered(savedEmail);
  }

  @override
  void dispose() {
    _loginViewModel.removeListener(_onViewModelChanged);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) {
      setState(() {});

      // Navegar al home si login fue exitoso
      if (_loginViewModel.lastSuccessfulSession != null) {
        Future.microtask(() {
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
          //  Mostrar error si existe
          if (_loginViewModel.hasError) ...[
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
                      _loginViewModel.errorMessage!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: _loginViewModel.clearError,
                    color: Colors.red.shade700,
                  ),
                ],
              ),
            ),
          ],

          // Email field
          CustomTextField(
            controller: _emailController,
            label: 'Email address',
            hint: 'yaz@gmail.com',
            keyboardType: TextInputType.emailAddress,
            onChanged: _loginViewModel.setEmail,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email is required';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
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
            obscureText:
                !_loginViewModel
                    .isPasswordVisible, //  Usar estado del ViewModel
            onChanged: _loginViewModel.setPassword, //  Conectar con ViewModel
            suffixIcon: IconButton(
              icon: Icon(
                _loginViewModel.isPasswordVisible
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: Colors.grey[600],
              ),
              onPressed:
                  _loginViewModel
                      .togglePasswordVisibility, // Usar método del ViewModel
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
                    value:
                        _loginViewModel
                            .rememberMe, //  Usar estado del ViewModel
                    onChanged:
                        (value) => _loginViewModel.setRememberMe(
                          value ?? false,
                        ), //  Conectar
                    activeColor: const Color(0xFF2196F3),
                  ),
                  const Text('Remember me', style: TextStyle(fontSize: 14)),
                ],
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // TODO: Implementar forgot password
                },
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(fontSize: 14, color: Color(0xFF2196F3)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Login button
          CustomButton(
            text:
                _loginViewModel.isLoading
                    ? 'Logging in...'
                    : 'Log in', //  Texto dinámico
            onPressed:
                _loginViewModel.canSubmit
                    ? () async {
                      //  Deshabilitar si no puede enviar
                      if (_formKey.currentState!.validate()) {
                        //  Sincronizar controladores con ViewModel (por si acaso)
                        _loginViewModel.setEmail(_emailController.text);
                        _loginViewModel.setPassword(_passwordController.text);

                        //  Ejecutar login real
                        final success = await _loginViewModel.signIn();

                        // La navegación se maneja en _onViewModelChanged
                        if (success) {
                          // Removed debug print
                        }
                      }
                    }
                    : null,
            isLoading:
                _loginViewModel
                    .isLoading, //  Mostrar loading si el CustomButton lo soporta
          ),

          const SizedBox(height: 16),

          // Botón para ir al registro
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Don't have an account? ",
                style: TextStyle(fontSize: 14, color: Colors.black54),
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
}
