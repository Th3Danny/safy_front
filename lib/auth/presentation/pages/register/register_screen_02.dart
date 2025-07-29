import 'package:flutter/material.dart';
import 'package:safy/auth/presentation/pages/register/widgets/register_form_02.dart';
import 'package:safy/auth/presentation/widgets/auth_header.dart';


class RegisterScreen02 extends StatelessWidget {
  final Map<String, dynamic>? registerData;
  
  const RegisterScreen02({
    super.key, 
    this.registerData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header con gradiente y título
              const AuthHeader(
                title: "Register",
                subtitle: "",
              ),
              
              // Formulario de registro parte 2
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: RegisterForm02(registerData: registerData),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
