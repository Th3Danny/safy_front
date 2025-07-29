import 'package:flutter/material.dart';
import 'package:safy/shared/widget/custom_app_bar.dart';
import 'package:safy/shared/widget/help_institution_card.dart';
import 'package:safy/help/presentation/widgets/safety_tips_widget.dart';
import 'package:url_launcher/url_launcher.dart'; 

class HelpInstitutionsScreen extends StatelessWidget {
  const HelpInstitutionsScreen({super.key});

  // Función para realizar la llamada
  Future<void> _callNumber(String phoneNumber) async {
   
    // Para un número real en México, el formato sería "tel:911" o "tel:9611234567"
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      // Manejar el error si no se puede lanzar la URL (ej. no hay app de teléfono)
      // Removed debug print
      
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(
        title: 'Instituciones de Ayuda',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // ========== TU CONTENIDO EXISTENTE (SIN CAMBIOS) ==========

              // Instituciones principales
              const HelpInstitutionCard(
                title: 'Fiscalía',
                subtitle: 'Dirección',
                icon: Icons.account_balance,
                color: Colors.red,
              ),

              const SizedBox(height: 16),

              const HelpInstitutionCard(
                title: 'Hospital',
                subtitle: 'Dirección',
                icon: Icons.local_hospital,
                color: Colors.red,
              ),

              const SizedBox(height: 24),

              // Sección Emergencias
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Emergencias',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Lista de números de emergencia
                    // MODIFICADO: Agregando onTap para llamar a _callNumber
                    _EmergencyContactTile(
                      title: '911',
                      subtitle: 'Atención a emergencias',
                      phone: '911', // Número real para mostrar
                      onTap: () => _callNumber('9661016271'), // Número de prueba para llamar
                    ),

                    const SizedBox(height: 12),

                    // MODIFICADO: Agregando onTap para llamar a _callNumber
                    _EmergencyContactTile(
                      title: '089',
                      subtitle: 'Denuncia anónima',
                      phone: '089', // Número real para mostrar
                      onTap: () => _callNumber('9519876543'), // Número de prueba para llamar
                    ),

                    const SizedBox(height: 12),

                    // MODIFICADO: Agregando onTap para llamar a _callNumber
                    _EmergencyContactTile(
                      title: 'Estatales - Chiapas',
                      subtitle: 'Consumidor general',
                      phone: '(961)617-2300(Ext.17000)', // Número real para mostrar
                      onTap: () => _callNumber('9611112233'), // Número de prueba para llamar
                    ),

                    const SizedBox(height: 12),

                    // MODIFICADO: Agregando onTap para llamar a _callNumber
                    _EmergencyContactTile(
                      title: '961-614-9350',
                      subtitle: 'Dirección Chiapas',
                      phone: '961-614-9350', // Número real para mostrar
                      onTap: () => _callNumber('9611358216'), // Número de prueba para llamar
                    ),
                  ],
                ),
              ),

              // ========== NUEVA SECCIÓN DE INFORMACIÓN DE SEGURIDAD ==========
              const SafetyTipsWidget(), 

              const SizedBox(height: 24), 
            ],
          ),
        ),
      ),
    );
  }
}

// MODIFICADO: Agregando VoidCallback onTap para el tile
class _EmergencyContactTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String phone;
  final VoidCallback onTap; 

  const _EmergencyContactTile({
    required this.title,
    required this.subtitle,
    required this.phone,
    required this.onTap, 
  });

  @override
  Widget build(BuildContext context) {
    return InkWell( 
      onTap: onTap, 
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.phone,
                color: Colors.green,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
           
            InkWell( // Hace el círculo del teléfono clickeable individualmente
              onTap: onTap, // Llama a la misma función al presionar el icono
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(8), 
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.phone,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
