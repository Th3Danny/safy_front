import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:safy/home/presentation/layout/responsive_layout.dart';
import 'package:safy/home/presentation/widgets/app_drawer.dart';
import 'package:safy/home/presentation/widgets/danger_zone_overlay.dart';
import 'package:safy/home/presentation/widgets/navigation_fab.dart';
import 'package:safy/home/presentation/widgets/weather_widget.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final MapController _mapController;
  List<Marker> markers = [];
  List<Marker> dangerMarkers = [];
  int markerCount = 0;
  bool _showDangerZones = true;
  late LatLng _initialLocation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _setInitialLocation();
    _loadDangerZones();
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
            width: 40,
            height: 40,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.my_location,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        );
        _isLoading = false;
      });

      _mapController.move(currentLatLng, 15.0);
    } catch (e) {
      print("❌ Error al obtener ubicación: $e");
      // Tuxtla Gutiérrez, Chiapas como valor por defecto
      _initialLocation = LatLng(16.7569, -93.1292);
      setState(() {
        _isLoading = false;
      });
      _mapController.move(_initialLocation, 13.0);
    }
  }

  Future<void> _loadDangerZones() async {
    // Simular zonas peligrosas alrededor de Tuxtla Gutiérrez
    final dangerZones = [
      {'lat': 16.7500, 'lng': -93.1300, 'reports': 5, 'type': 'high'},
      {'lat': 16.7600, 'lng': -93.1250, 'reports': 3, 'type': 'medium'},
      {'lat': 16.7400, 'lng': -93.1400, 'reports': 8, 'type': 'high'},
      {'lat': 16.7650, 'lng': -93.1350, 'reports': 2, 'type': 'low'},
    ];

    setState(() {
      dangerMarkers = dangerZones.map((zone) {
        Color zoneColor;
        double zoneRadius;
        
        switch (zone['type']) {
          case 'high':
            zoneColor = Colors.red;
            zoneRadius = 25;
            break;
          case 'medium':
            zoneColor = Colors.orange;
            zoneRadius = 20;
            break;
          default:
            zoneColor = Colors.yellow;
            zoneRadius = 15;
        }

        return Marker(
          point: LatLng(zone['lat'] as double, zone['lng'] as double),
          width: zoneRadius * 2,
          height: zoneRadius * 2,
          child: Container(
            decoration: BoxDecoration(
              color: zoneColor.withOpacity(0.3),
              shape: BoxShape.circle,
              border: Border.all(color: zoneColor, width: 2),
            ),
            child: Center(
              child: Text(
                '${zone['reports']}',
                style: TextStyle(
                  color: zoneColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      }).toList();
    });
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

  void _onNavigationTap(String type) {
    switch (type) {
      case 'add':
        // Navegar a crear reporte
        Navigator.pushNamed(context, '/create-report');
        break;
      case 'walk':
        _setNavigationMode('walk');
        break;
      case 'car':
        _setNavigationMode('car');
        break;
      case 'bus':
        _setNavigationMode('bus');
        break;
    }
  }

  void _setNavigationMode(String mode) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Modo de navegación: $mode'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(),
        tablet: _buildTabletLayout(),
        desktop: _buildDesktopLayout(),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Stack(
      children: [
        // Mapa principal
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _isLoading ? LatLng(16.7569, -93.1292) : _initialLocation,
            initialZoom: _isLoading ? 10 : 15,
            minZoom: 3,
            maxZoom: 18,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.safy',
            ),
            if (_showDangerZones) MarkerLayer(markers: dangerMarkers),
            MarkerLayer(markers: markers),
          ],
        ),

        // Weather widget en la parte superior
        const Positioned(
          top: 50,
          left: 16,
          child: WeatherWidget(),
        ),

        // Botón de centrar ubicación
        Positioned(
          top: 50,
          right: 16,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: Colors.white,
            onPressed: _centerOnCurrentLocation,
            child: const Icon(Icons.my_location, color: Colors.blue),
          ),
        ),

        // FAB de navegación
        Positioned(
          bottom: 100,
          right: 16,
          child: NavigationFab(onNavigationTap: _onNavigationTap),
        ),

        // Información de la app en la parte inferior
        Positioned(
          bottom: 20,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Safy',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[300],
                  child: const Icon(Icons.person, size: 20),
                ),
              ],
            ),
          ),
        ),

        // Overlay de zona peligrosa si está detectada
        if (_shouldShowDangerWarning())
          const DangerZoneOverlay(),

        // Loading indicator
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      children: [
        // Drawer siempre visible en tablet
        const SizedBox(
          width: 300,
          child: AppDrawer(),
        ),
        // Mapa ocupa el resto del espacio
        Expanded(
          child: _buildMobileLayout(),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Sidebar permanente en desktop
        const SizedBox(
          width: 350,
          child: AppDrawer(),
        ),
        // Mapa principal
        Expanded(
          child: _buildMobileLayout(),
        ),
        // Panel de controles a la derecha
        SizedBox(
          width: 250,
          child: _buildControlPanel(),
        ),
      ],
    );
  }

  Widget _buildControlPanel() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Controles',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Toggle para zonas peligrosas
          SwitchListTile(
            title: const Text('Mostrar zonas peligrosas'),
            value: _showDangerZones,
            onChanged: (value) {
              setState(() {
                _showDangerZones = value;
              });
            },
          ),
          
          const Divider(),
          
          // Botones de navegación vertical
          ListTile(
            leading: const Icon(Icons.directions_walk),
            title: const Text('Caminar'),
            onTap: () => _setNavigationMode('walk'),
          ),
          ListTile(
            leading: const Icon(Icons.directions_car),
            title: const Text('Auto'),
            onTap: () => _setNavigationMode('car'),
          ),
          ListTile(
            leading: const Icon(Icons.directions_bus),
            title: const Text('Transporte'),
            onTap: () => _setNavigationMode('bus'),
          ),
        ],
      ),
    );
  }

  void _centerOnCurrentLocation() async {
    try {
      final position = await _determinePosition();
      final currentLatLng = LatLng(position.latitude, position.longitude);
      _mapController.move(currentLatLng, 15.0);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  bool _shouldShowDangerWarning() {
    // Lógica para determinar si mostrar advertencia de zona peligrosa
    return false; // Por ahora false
  }
}