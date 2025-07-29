import 'package:flutter/material.dart';
import 'package:safy/shared/widget/custom_app_bar.dart';
import 'package:safy/help/presentation/widgets/safety_info_widgets.dart';
import 'package:safy/help/presentation/widgets/specific_safety_widgets.dart';
import 'package:url_launcher/url_launcher.dart'; 

class SafetyEducationScreen extends StatefulWidget {
  const SafetyEducationScreen({super.key});

  @override
  State<SafetyEducationScreen> createState() => _SafetyEducationScreenState();
}

class _SafetyEducationScreenState extends State<SafetyEducationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Función para realizar la llamada (similar a la anterior)
  Future<void> _callNumber(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      // Removed debug print
      // Mostrar un SnackBar al usuario
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo realizar la llamada.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(
        title: 'Educación en Seguridad',
        showBackButton: true,
      ),
      body: Column(
        children: [
          // Pestañas
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.blue.shade700,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue.shade700,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.emergency, size: 20),
                  text: 'Emergencias',
                ),
                Tab(
                  icon: Icon(Icons.warning, size: 20),
                  text: 'Situaciones',
                ),
                Tab(
                  icon: Icon(Icons.group, size: 20),
                  text: 'Grupos',
                ),
              ],
            ),
          ),

          // Contenido de las pestañas
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Pestaña 1: Información general de emergencias
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: const SafetyInfoSection(),
                ),

                // Pestaña 2: Situaciones específicas
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: const SpecificSituationsWidget(),
                ),

                // Pestaña 3: Grupos vulnerables
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: const VulnerableGroupsWidget(),
                ),
              ],
            ),
          ),
        ],
      ),

      // Botón flotante para acceso rápido a emergencias
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEmergencyDialog(context),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.emergency),
        label: const Text(
          'Emergencia',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _showEmergencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.emergency, color: Colors.red.shade600, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Números de Emergencia',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // MODIFICADO: Cambiando la llamada a _callNumber con números de prueba
              _buildEmergencyButton(
                '911',
                'Emergencias generales',
                Icons.local_police,
                Colors.red,
                () => _callNumber('9511234567'), // Número de prueba
              ),
              const SizedBox(height: 12),
              // MODIFICADO: Cambiando la llamada a _callNumber con números de prueba
              _buildEmergencyButton(
                '089',
                'Denuncia anónima',
                Icons.phone,
                Colors.orange,
                () => _callNumber('9519876543'), // Número de prueba
              ),
              const SizedBox(height: 12),
              // MODIFICADO: Cambiando la llamada a _callNumber con números de prueba
              _buildEmergencyButton(
                '961-614-9350',
                'Dirección Chiapas',
                Icons.location_city,
                Colors.blue,
                () => _callNumber('9614445566'), // Número de prueba
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmergencyButton(
    String number,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    number,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.phone, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
