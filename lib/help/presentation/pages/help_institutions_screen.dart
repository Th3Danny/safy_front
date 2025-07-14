import 'package:flutter/material.dart';
import 'package:safy/shared/widget/custom_app_bar.dart';
import 'package:safy/shared/widget/help_institution_card.dart';
import 'package:safy/help/presentation/widgets/safety_tips_widget.dart'; // 👈 NUEVO IMPORT

class HelpInstitutionsScreen extends StatelessWidget {
  const HelpInstitutionsScreen({super.key});

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
                    const _EmergencyContactTile(
                      title: '911',
                      subtitle: 'Atención a emergencias',
                      phone: '911',
                    ),
                    
                    const SizedBox(height: 12),
                    
                    const _EmergencyContactTile(
                      title: '089',
                      subtitle: 'Denuncia anónima',
                      phone: '089',
                    ),
                    
                    const SizedBox(height: 12),
                    
                    const _EmergencyContactTile(
                      title: 'Estatales - Chiapas',
                      subtitle: 'Consumidor general',
                      phone: '(961)617-2300(Ext.17000)',
                    ),
                    
                    const SizedBox(height: 12),
                    
                    const _EmergencyContactTile(
                      title: '961-614-9350',
                      subtitle: 'Dirección Chiapas',
                      phone: '961-614-9350',
                    ),
                  ],
                ),
              ),

              // ========== NUEVA SECCIÓN DE INFORMACIÓN DE SEGURIDAD ==========
              const SafetyTipsWidget(), // 👈 AGREGAR ESTE WIDGET
              
              const SizedBox(height: 24), // Espacio final
            ],
          ),
        ),
      ),
    );
  }
}

// ========== TU WIDGET EXISTENTE (SIN CAMBIOS) ==========
class _EmergencyContactTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String phone;

  const _EmergencyContactTile({
    required this.title,
    required this.subtitle,
    required this.phone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Container(
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
        ],
      ),
    );
  }
}