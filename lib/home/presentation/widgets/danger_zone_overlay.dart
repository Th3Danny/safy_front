import 'package:flutter/material.dart';

class DangerZoneOverlay extends StatelessWidget {
  const DangerZoneOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 200,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.warning,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '¡Zona Peligrosa!\nEstás entrando a una zona con muchos reportes de incidentes.',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                // Ocultar overlay
              },
            ),
          ],
        ),
      ),
    );
  }
}
