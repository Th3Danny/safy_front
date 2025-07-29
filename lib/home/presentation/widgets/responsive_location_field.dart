import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:safy/home/domain/usecases/get_current_location_use_case.dart';
import 'package:safy/home/domain/entities/location.dart';

class ResponsiveLocationFieldForSafy extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onLocationSelected;
  final ValueChanged<Location>? onLocationEntitySelected;
  final String? label;
  final String? hint;
  final bool showCurrentLocationButton;

  const ResponsiveLocationFieldForSafy({
    super.key,
    required this.controller,
    this.onLocationSelected,
    this.onLocationEntitySelected,
    this.label,
    this.hint,
    this.showCurrentLocationButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isSmallScreen = screenWidth < 400;
        final isTablet = screenWidth > 600;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con título y botón
            _buildHeader(context, isSmallScreen, isTablet),
            
            SizedBox(height: isSmallScreen ? 8 : 12),
            
            // Campo de ubicación simple (sin ViewModel por ahora)
            _buildLocationDisplay(context, isSmallScreen, isTablet),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isSmallScreen, bool isTablet) {
    final iconSize = isTablet ? 24.0 : (isSmallScreen ? 18.0 : 20.0);
    final fontSize = isTablet ? 18.0 : (isSmallScreen ? 14.0 : 16.0);
    final buttonSize = isTablet ? 48.0 : (isSmallScreen ? 40.0 : 44.0);

    return Row(
      children: [
        Icon(
          Icons.location_on,
          color: Colors.red,
          size: iconSize,
        ),
        SizedBox(width: isSmallScreen ? 6 : 8),
        Text(
          label ?? 'Ubicación',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
        const Spacer(),
        if (showCurrentLocationButton)
          _buildLocationButton(context, buttonSize, iconSize),
      ],
    );
  }

  Widget _buildLocationButton(BuildContext context, double size, double iconSize) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.shade200,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _handleLocationRequest(context),
          child: Icon(
            Icons.my_location,
            color: Colors.blue.shade600,
            size: iconSize,
          ),
        ),
      ),
    );
  }

  Widget _buildLocationDisplay(BuildContext context, bool isSmallScreen, bool isTablet) {
    final padding = isTablet ? 20.0 : (isSmallScreen ? 12.0 : 16.0);
    final fontSize = isTablet ? 16.0 : (isSmallScreen ? 13.0 : 14.0);
    final minHeight = isTablet ? 60.0 : (isSmallScreen ? 48.0 : 52.0);

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: controller.text.isNotEmpty ? Colors.green.shade300 : Colors.grey.shade300,
          width: controller.text.isNotEmpty ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: controller.text.isNotEmpty
        ? Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: isSmallScreen ? 18 : 20,
              ),
              SizedBox(width: isSmallScreen ? 8 : 12),
              Expanded(
                child: SelectableText(
                  controller.text,
                  style: TextStyle(
                    fontSize: fontSize,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.clear,
                  color: Colors.grey.shade600,
                  size: isSmallScreen ? 18 : 20,
                ),
                onPressed: () {
                  controller.clear();
                },
              ),
            ],
          )
        : Text(
            hint ?? 'Toca el ícono para obtener tu ubicación actual',
            style: TextStyle(
              fontSize: fontSize,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
    );
  }

  void _handleLocationRequest(BuildContext context) async {
    // Mostrar loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text('Obteniendo ubicación en segundo plano...'),
          ],
        ),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.blue,
      ),
    );

    try {
      // 🚀 USAR TU USE CASE CON COMPUTE
      final getCurrentLocationUseCase = GetIt.instance<GetCurrentLocationUseCase>();
      final location = await getCurrentLocationUseCase.execute();

      // Actualizar campo
      final locationText = '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
      controller.text = locationText;
      
      // Callbacks
      onLocationSelected?.call(locationText);
      onLocationEntitySelected?.call(location);

      // Mostrar éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Ubicación obtenida exitosamente'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Error: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
