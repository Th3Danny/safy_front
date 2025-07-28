import 'package:flutter/material.dart';

class MapControlsWidget extends StatelessWidget {
  final VoidCallback onLocationPressed;
  final VoidCallback onToggleDangerZones;
  final VoidCallback onToggleClusters;
  final bool showDangerZones;
  final bool showClusters;
  final bool clustersLoading;

  const MapControlsWidget({
    super.key,
    required this.onLocationPressed,
    required this.onToggleDangerZones,
    required this.onToggleClusters,
    required this.showDangerZones,
    required this.showClusters,
    this.clustersLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        

        const SizedBox(height: 8),

        // ✅ Botón para alternar clusters de zonas peligrosas (ESENCIAL)
        _buildControlButton(
          onPressed: clustersLoading ? null : onToggleClusters,
          icon:
              clustersLoading
                  ? Icons.hourglass_empty
                  : (showClusters ? Icons.dangerous : Icons.dangerous_outlined),
          tooltip:
              clustersLoading
                  ? 'Cargando clusters...'
                  : (showClusters
                      ? 'Ocultar zonas críticas'
                      : 'Mostrar zonas críticas'),
          backgroundColor: showClusters ? Colors.red[100] : Colors.white,
          iconColor:
              clustersLoading
                  ? Colors.grey
                  : (showClusters ? Colors.red[700] : Colors.grey[600]),
          isLoading: clustersLoading,
        ),

        const SizedBox(height: 8),

        // ✅ Botón para alternar reportes individuales (ESENCIAL)
        _buildControlButton(
          onPressed: onToggleDangerZones,
          icon: showDangerZones ? Icons.visibility : Icons.visibility_off,
          tooltip:
              showDangerZones
                  ? 'Ocultar reportes individuales'
                  : 'Mostrar reportes individuales',
          backgroundColor: showDangerZones ? Colors.orange[100] : Colors.white,
          iconColor: showDangerZones ? Colors.orange[700] : Colors.grey[600],
        ),

        // ❌ ELIMINADO: Botón de refresh (no es esencial)
        // ❌ ELIMINADO: Botón de capas del mapa (no es esencial)
        // ❌ ELIMINADO: Botón de información (no es esencial)
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
              child:
                  isLoading
                      ? Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              iconColor ?? Colors.grey,
                            ),
                          ),
                        ),
                      )
                      : Icon(icon, color: iconColor, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}
