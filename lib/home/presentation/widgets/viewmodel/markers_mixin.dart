import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Mixin para gestión de marcadores del mapa
mixin MarkersMixin on ChangeNotifier {
  
  // Marcadores y rutas
  final List<Marker> _markers = [];
  List<Marker> get markers => _markers;

  // Crear marcador de ubicación actual
  void createCurrentLocationMarker(LatLng location, bool isNavigating) {
    _markers.removeWhere(
      (marker) => marker.key?.toString().contains('current_location') == true,
    );

    _markers.add(
      Marker(
        key: const Key('current_location'),
        point: location,
        width: 30,
        height: 30,
        child: Container(
          decoration: BoxDecoration(
            color: isNavigating ? Colors.green : Colors.blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            isNavigating ? Icons.navigation : Icons.my_location,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  void addDestinationMarker(LatLng location, String name) {
    _markers.removeWhere(
      (marker) => marker.key?.toString().contains('destination') == true,
    );

    _markers.add(
      Marker(
        key: const Key('destination'),
        point: location,
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.place, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  void addRouteMarker(LatLng point, Color color, IconData icon, String type) {
    _markers.removeWhere(
      (marker) => marker.key?.toString().contains(type) == true,
    );

    _markers.add(
      Marker(
        key: Key(type),
        point: point,
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  void clearRouteMarkers() {
    _markers.removeWhere(
      (marker) =>
          marker.key?.toString().contains('start') == true ||
          marker.key?.toString().contains('end') == true ||
          marker.key?.toString().contains('destination') == true,
    );
  }
}
