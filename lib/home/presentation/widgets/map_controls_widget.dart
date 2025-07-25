import 'package:flutter/material.dart';

class MapControlsWidget extends StatelessWidget {
  final VoidCallback onLocationPressed;
  final VoidCallback onToggleDangerZones;
  final VoidCallback onToggleClusters; // NUEVO
  final VoidCallback? onRefreshClusters; // NUEVO
  final bool showDangerZones;
  final bool showClusters; // NUEVO
  final bool clustersLoading; // NUEVO

  const MapControlsWidget({
    super.key,
    required this.onLocationPressed,
    required this.onToggleDangerZones,
    required this.onToggleClusters, // NUEVO
    this.onRefreshClusters, // NUEVO
    required this.showDangerZones,
    required this.showClusters, // NUEVO
    this.clustersLoading = false, // NUEVO
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
        
        // NUEVO: Botón para alternar clusters de zonas peligrosas
        _buildControlButton(
          onPressed: clustersLoading ? null : onToggleClusters,
          icon: clustersLoading 
            ? Icons.hourglass_empty 
            : (showClusters ? Icons.dangerous : Icons.dangerous_outlined),
          tooltip: clustersLoading
            ? 'Cargando clusters...'
            : (showClusters ? 'Ocultar zonas críticas' : 'Mostrar zonas críticas'),
          backgroundColor: showClusters ? Colors.red[100] : Colors.white,
          iconColor: clustersLoading 
            ? Colors.grey 
            : (showClusters ? Colors.red[700] : Colors.grey[600]),
          isLoading: clustersLoading,
        ),
        
        const SizedBox(height: 8),
        
        // Botón para alternar reportes individuales
        _buildControlButton(
          onPressed: onToggleDangerZones,
          icon: showDangerZones ? Icons.visibility : Icons.visibility_off,
          tooltip: showDangerZones ? 'Ocultar reportes individuales' : 'Mostrar reportes individuales',
          backgroundColor: showDangerZones ? Colors.orange[100] : Colors.white,
          iconColor: showDangerZones ? Colors.orange[700] : Colors.grey[600],
        ),
        
        const SizedBox(height: 8),
        
        // NUEVO: Botón de refresh para clusters (opcional)
        if (onRefreshClusters != null) ...[
          _buildControlButton(
            onPressed: clustersLoading ? null : onRefreshClusters,
            icon: Icons.refresh,
            tooltip: 'Actualizar zonas peligrosas',
            backgroundColor: Colors.white,
            iconColor: clustersLoading ? Colors.grey : Colors.blue[600],
          ),
          const SizedBox(height: 8),
        ],
        
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
    required VoidCallback? onPressed,
    required IconData icon,
    required String tooltip,
    required Color? backgroundColor,
    required Color? iconColor,
    bool isLoading = false,
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
          child: SizedBox(
            width: 48,
            height: 48,
            child: Tooltip(
              message: tooltip,
              child: isLoading
                ? Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(iconColor ?? Colors.grey),
                      ),
                    ),
                  )
                : Icon(
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

            // NUEVO: Opción: Clusters de zonas críticas
            ListTile(
              leading: Icon(
                showClusters ? Icons.dangerous : Icons.dangerous_outlined,
                color: showClusters ? Colors.red[700] : Colors.grey,
              ),
              title: const Text('Zonas críticas'),
              subtitle: Text(
                showClusters 
                    ? 'Clusters de alta peligrosidad visibles'
                    : 'Clusters de zonas peligrosas ocultos',
              ),
              trailing: clustersLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Switch(
                    value: showClusters,
                    onChanged: clustersLoading ? null : (_) {
                      onToggleClusters();
                      Navigator.pop(context);
                    },
                  ),
              onTap: clustersLoading ? null : () {
                onToggleClusters();
                Navigator.pop(context);
              },
            ),

            const Divider(),

            // Opción: Reportes individuales
            ListTile(
              leading: Icon(
                showDangerZones ? Icons.visibility : Icons.visibility_off,
                color: showDangerZones ? Colors.orange[700] : Colors.grey,
              ),
              title: const Text('Reportes individuales'),
              subtitle: Text(
                showDangerZones 
                    ? 'Incidentes individuales visibles'
                    : 'Incidentes individuales ocultos',
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
              leading: Icon(Icons.access_time, color: Colors.blue[600]),
              title: const Text('Solo reportes recientes'),
              subtitle: const Text('Mostrar incidentes de las últimas 24h'),
              trailing: Switch(
                value: true, // Por defecto activado
                onChanged: (value) {
                  // TODO: Implementar lógica para filtrar por tiempo
                  Navigator.pop(context);
                },
              ),
            ),

            const Divider(),

            // Opción: Patrullas policiales (futura funcionalidad)
            ListTile(
              leading: Icon(Icons.local_police, color: Colors.green[600]),
              title: const Text('Patrullas policiales'),
              subtitle: const Text('Ubicación aproximada de patrullas'),
              trailing: Switch(
                value: false, // Por defecto desactivado
                onChanged: (value) {
                  // TODO: Implementar lógica para mostrar/ocultar patrullas
                  Navigator.pop(context);
                },
              ),
            ),

            // NUEVO: Botón de refresh
            if (onRefreshClusters != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: clustersLoading ? null : () {
                  onRefreshClusters!();
                  Navigator.pop(context);
                },
                icon: clustersLoading 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.refresh),
                label: Text(
                  clustersLoading ? 'Actualizando...' : 'Actualizar datos'
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[50],
                  foregroundColor: Colors.blue[700],
                ),
              ),
            ],

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
            // NUEVO: Info sobre clusters
            _buildInfoItem(
              icon: Icons.dangerous,
              color: Colors.red[700]!,
              title: 'Zonas críticas',
              description: 'Clusters de alta concentración de incidentes',
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              icon: Icons.warning,
              color: Colors.orange,
              title: 'Reportes individuales',
              description: 'Incidentes específicos reportados por usuarios',
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
                      'Tip: Los marcadores rojos indican zonas de mayor peligro. Planifica rutas alternativas.',
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