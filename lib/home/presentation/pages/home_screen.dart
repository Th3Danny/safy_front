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
  // MapController se inicializa pero no se usa hasta que el mapa esté listo
  final MapController _mapController = MapController();
  List<Marker> markers = [];
  List<Marker> dangerMarkers = [];
  bool _showDangerZones = true;
  bool _isLoading = true;
  bool _mapReady = false; // Nuevo flag para saber si el mapa está listo
  late LatLng _initialLocation;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      final position = await _determinePosition();
      _initialLocation = LatLng(position.latitude, position.longitude);
      
      // Crear marcador de ubicación actual
      _createCurrentLocationMarker(_initialLocation);
      
    } catch (e) {
      print("❌ Error al obtener ubicación: $e");
      _initialLocation = LatLng(16.7569, -93.1292); // Tuxtla por defecto
      _createCurrentLocationMarker(_initialLocation);
    }

    // Cargar zonas de peligro
    _loadDangerZones();
    
    setState(() => _isLoading = false);
    
    // Mover el mapa después de que esté renderizado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_mapReady && mounted) {
        _moveToCurrentLocation();
      }
    });
  }

  void _createCurrentLocationMarker(LatLng location) {
    markers.add(
      Marker(
        point: location,
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
  }

  void _moveToCurrentLocation() {
    if (_mapReady && mounted) {
      try {
        _mapController.move(_initialLocation, 15.0);
      } catch (e) {
        print("Error moviendo mapa: $e");
      }
    }
  }

  Future<void> _loadDangerZones() async {
    final dangerZones = [
      {'lat': 16.7500, 'lng': -93.1300, 'reports': 5, 'type': 'high'},
      {'lat': 16.7600, 'lng': -93.1250, 'reports': 3, 'type': 'medium'},
      {'lat': 16.7400, 'lng': -93.1400, 'reports': 8, 'type': 'high'},
      {'lat': 16.7650, 'lng': -93.1350, 'reports': 2, 'type': 'low'},
    ];

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
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw 'Los servicios de ubicación están desactivados.';

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) throw 'Permiso de ubicación denegado.';
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Permisos de ubicación permanentemente denegados.';
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  void _onNavigationTap(String type) {
    switch (type) {
      case 'add':
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
      SnackBar(content: Text('Modo de navegación: $mode')),
    );
  }

  void _centerOnCurrentLocation() async {
    if (!_mapReady) return;
    
    try {
      final position = await _determinePosition();
      final currentLatLng = LatLng(position.latitude, position.longitude);
      _mapController.move(currentLatLng, 15.0);
      
      // Actualizar marcador de ubicación actual
      setState(() {
        markers.removeWhere((marker) => marker.point == _initialLocation);
        _initialLocation = currentLatLng;
        _createCurrentLocationMarker(currentLatLng);
      });
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  bool _shouldShowDangerWarning() {
    return false; // lógica personalizada futura
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Cargando mapa...'),
            ],
          ),
        ),
      );
    }

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
        // 🌍 Mapa principal
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _initialLocation,
            initialZoom: 15,
            minZoom: 3,
            maxZoom: 18,
            onMapReady: () {
              setState(() {
                _mapReady = true;
              });
              // Mover a ubicación actual una vez que el mapa esté listo
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _moveToCurrentLocation();
              });
            },
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

        // 🌤 Widget de clima
        const Positioned(
          top: 50,
          left: 16,
          child: WeatherWidget(),
        ),

        // 🎯 Botón para centrar ubicación
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

        // 🚨 Overlay si hay zonas peligrosas detectadas
        if (_shouldShowDangerWarning())
          const DangerZoneOverlay(),

        // 🧭 Panel deslizable inferior (NavigationFab actualizado)
        NavigationFab(onNavigationTap: _onNavigationTap),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      children: [
        const SizedBox(width: 300, child: AppDrawer()),
        Expanded(child: _buildMobileLayout()),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        const SizedBox(width: 350, child: AppDrawer()),
        Expanded(child: _buildMobileLayout()),
        SizedBox(width: 250, child: _buildControlPanel()),
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
          const Text('Controles', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Mostrar zonas peligrosas'),
            value: _showDangerZones,
            onChanged: (value) => setState(() => _showDangerZones = value),
          ),
          const Divider(),
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
}