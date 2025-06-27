import 'package:flutter/material.dart';
import 'package:safy/auth/presentation/pages/login/widgets/login_form.dart';
import 'package:safy/auth/presentation/pages/login/widgets/social_login_buttons.dart';
import 'package:safy/auth/presentation/widgets/auth_header.dart';


class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header con gradiente y título
            const AuthHeader(
              title: "Welcome\nBack",
              subtitle: "Log in",
            ),
            
            // Formulario de login
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const LoginForm(),
                  const SizedBox(height: 24),
                  
                  // Divider con texto
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Or Login with',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Botones de redes sociales
                  const SocialLoginButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}