import 'package:flutter/material.dart';
import 'package:safy/auth/presentation/pages/register/widgets/register_form_01.dart';
import '../../widgets/auth_header.dart';



class RegisterScreen01 extends StatelessWidget {
  const RegisterScreen01({super.key});

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
              
              // Formulario de registro parte 1
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: RegisterForm01(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
