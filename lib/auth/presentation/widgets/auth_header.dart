// auth/presentation/widgets/auth_header.dart
import 'package:flutter/material.dart';
import 'package:safy/auth/presentation/widgets/wave_clipper.dart'; // Importa el nuevo clipper

class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const AuthHeader({
    super.key,
    required this.title,
    this.subtitle = "",
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath( // Usa ClipPath para aplicar la forma personalizada
      clipper: WaveClipper(), // Aplica tu custom clipper
      child: Container(
        width: double.infinity,
        height: 250, // Dale una altura fija o calcula dinámicamente si es necesario
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4CAF50), // Verde
              Color(0xFF2196F3), // Azul
            ],
          ),
          // No es necesario borderRadius aquí, ClipPath maneja la forma
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            24,
            60, // Aumentamos el padding superior para empujar el texto hacia abajo
            24,
            0, // El padding inferior se gestionará con la altura y la alineación
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start, // Alinea el texto al inicio (parte superior)
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 38, // Tamaño de fuente más grande para el título principal
                  fontWeight: FontWeight.w900, // Extra negrita para "Bienvenido" y "Register"
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 10), // Espacio reducido ya que el subtítulo es más pequeño
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 24, // Tamaño de fuente más pequeño para el subtítulo
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800], // Gris más oscuro para "Log in"
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}