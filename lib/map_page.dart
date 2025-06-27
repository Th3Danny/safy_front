import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends StatefulWidget {
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late final MapController _mapController;
  List<Marker> markers = [];
  int markerCount = 0;

  late LatLng _initialLocation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _setInitialLocation();
  }

  Future<void> _setInitialLocation() async {
    try {
      final position = await _determinePosition();
      final currentLatLng = LatLng(position.latitude, position.longitude);

      setState(() {
        _initialLocation = currentLatLng;
        markers.add(
          Marker(
            point: currentLatLng,
            width: 80,
            height: 80,
            child: Icon(Icons.my_location, color: Colors.blue, size: 35),
          ),
        );
      });

      _mapController.move(currentLatLng, 15.0);
    } catch (e) {
      print("❌ Error al obtener ubicación: $e");
      // Valor por defecto si falla
      _initialLocation = LatLng(19.4326, -99.1332); // CDMX
      _mapController.move(_initialLocation, 10.0);
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Los servicios de ubicación están desactivados.';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Permiso de ubicación denegado.';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Permisos permanentemente denegados.';
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🛰️ Mapa con Ubicación Actual'),
        backgroundColor: Colors.green,
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: LatLng(0, 0), // se ajustará en tiempo real
          initialZoom: 2,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.safy',
          ),
          MarkerLayer(markers: markers),
        ],
      ),
    );
  }
}

