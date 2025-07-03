
import 'package:flutter/material.dart';

class MapControlsWidget extends StatelessWidget {
  final VoidCallback onLocationPressed;
  final VoidCallback onToggleDangerZones;
  final bool showDangerZones;

  const MapControlsWidget({
    super.key,
    required this.onLocationPressed,
    required this.onToggleDangerZones,
    required this.showDangerZones,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Botón para centrar en ubicación actual
        _buildControlButton(
          onPressed: onLocationPressed,
          icon: Icons.my_location,
          tooltip: 'Mi ubicación',
          backgroundColor: Colors.white,
          iconColor: Colors.blue,
        ),
        
        const SizedBox(height: 8),
        
        // Botón para alternar zonas peligrosas
        _buildControlButton(
          onPressed: onToggleDangerZones,
          icon: showDangerZones ? Icons.visibility : Icons.visibility_off,
          tooltip: showDangerZones ? 'Ocultar zonas peligrosas' : 'Mostrar zonas peligrosas',
          backgroundColor: showDangerZones ? Colors.red[100] : Colors.white,
          iconColor: showDangerZones ? Colors.red : Colors.grey[600],
        ),
        
        const SizedBox(height: 8),
        
        // Botón de capas del mapa
        _buildControlButton(
          onPressed: () => _showLayersMenu(context),
          icon: Icons.layers,
          tooltip: 'Capas del mapa',
          backgroundColor: Colors.white,
          iconColor: Colors.grey[600],
        ),
        
        const SizedBox(height: 8),
        
        // Botón de información
        _buildControlButton(
          onPressed: () => _showInfoDialog(context),
          icon: Icons.info_outline,
          tooltip: 'Información',
          backgroundColor: Colors.white,
          iconColor: Colors.grey[600],
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String tooltip,
    required Color? backgroundColor,
    required Color? iconColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 48,
            height: 48,
            child: Tooltip(
              message: tooltip,
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showLayersMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Indicador visual
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Capas del mapa',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Opción: Zonas peligrosas
            ListTile(
              leading: Icon(
                showDangerZones ? Icons.visibility : Icons.visibility_off,
                color: showDangerZones ? Colors.red : Colors.grey,
              ),
              title: const Text('Zonas peligrosas'),
              subtitle: Text(
                showDangerZones 
                    ? 'Las zonas de riesgo están visibles'
                    : 'Las zonas de riesgo están ocultas',
              ),
              trailing: Switch(
                value: showDangerZones,
                onChanged: (_) {
                  onToggleDangerZones();
                  Navigator.pop(context);
                },
              ),
              onTap: () {
                onToggleDangerZones();
                Navigator.pop(context);
              },
            ),

            const Divider(),

            // Opción: Reportes recientes
            ListTile(
              leading: Icon(Icons.report_problem, color: Colors.orange[600]),
              title: const Text('Reportes recientes'),
              subtitle: const Text('Mostrar incidentes de las últimas 24h'),
              trailing: Switch(
                value: true, // Por defecto activado
                onChanged: (value) {
                  // Implementar lógica para mostrar/ocultar reportes recientes
                  Navigator.pop(context);
                },
              ),
            ),

            const Divider(),

            // Opción: Patrullas policiales
            ListTile(
              leading: Icon(Icons.local_police, color: Colors.blue[600]),
              title: const Text('Patrullas policiales'),
              subtitle: const Text('Ubicación aproximada de patrullas'),
              trailing: Switch(
                value: false, // Por defecto desactivado
                onChanged: (value) {
                  // Implementar lógica para mostrar/ocultar patrullas
                  Navigator.pop(context);
                },
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue[600]),
            const SizedBox(width: 8),
            const Text('Información del mapa'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoItem(
              icon: Icons.my_location,
              color: Colors.blue,
              title: 'Tu ubicación',
              description: 'Punto azul en el mapa',
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              icon: Icons.play_arrow,
              color: Colors.green,
              title: 'Punto de inicio',
              description: 'Toca el mapa para seleccionar origen',
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              icon: Icons.stop,
              color: Colors.red,
              title: 'Destino',
              description: 'Toca el mapa para seleccionar destino',
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              icon: Icons.warning,
              color: Colors.orange,
              title: 'Zonas de riesgo',
              description: 'Áreas con reportes de incidentes',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb, color: Colors.blue[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tip: Mantén presionado el mapa para reportar un incidente',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}