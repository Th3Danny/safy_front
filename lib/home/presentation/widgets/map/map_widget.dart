import 'package:flutter/material.dart';
import 'package:safy/home/presentation/widgets/map/map_renderer_widget.dart';

/// Widget principal del mapa que reemplaza al MapboxMapWidget original
class MapWidget extends StatelessWidget {
  const MapWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const MapRendererWidget();
  }
}
