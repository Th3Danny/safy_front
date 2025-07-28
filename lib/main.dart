import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safy/core/application/dependency_injection.dart';
import 'package:safy/core/router/app_router.dart';
import 'package:safy/core/services/firebase/firebase_messaging_service.dart';
import 'package:safy/core/session/session_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:safy/core/services/firebase/firebase_message_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:safy/core/services/cluster_detection_service.dart';
import 'package:safy/core/services/background_danger_detection_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Inicializar Firebase
  await Firebase.initializeApp();
  await FirebaseMessagingService().init();

  // 👂 Escuchar mensajes en segundo plano
  FirebaseMessaging.onBackgroundMessage(firebaseBackgroundMessageHandler);

  try {
    // 1. Inicializar SharedPreferences

    final prefs = await SharedPreferences.getInstance();

    // DEBUG: Verificar si hay datos almacenados
    final storedToken = prefs.getString('access_token');
    final storedUser = prefs.getString('user_data');

    if (storedToken != null) {
      print('[Main] 🔍 Token preview: ${storedToken.substring(0, 20)}...');
    }

    // 2. Inicializar SessionManager

    await SessionManager.instance.initialize(prefs: prefs);

    // DEBUG: Verificar estado del SessionManager después de initialize

    SessionManager.instance.debugSessionState();

    // 3. Configurar dependencias
    await setupDependencyInjection(sharedPreferences: prefs);

    // 👇 Iniciar el servicio de notificaciones
    await sl<FirebaseMessagingService>().init();

    // 🚨 NUEVO: Inicializar servicio de detección de clusters
    await sl<ClusterDetectionService>().init();

    // 🚨 NUEVO: Inicializar servicio de detección de peligro en segundo plano
    await BackgroundDangerDetectionService.initialize();

    runApp(const MyApp());
  } catch (e, stackTrace) {
    print('[Main]  ========== ERROR CRÍTICO ==========');
    print('[Main]  Error: $e');
    print('[Main]  StackTrace: $stackTrace');

    runApp(ErrorApp(error: e.toString()));
  }
}

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: getAllProviders(),
      child: MaterialApp.router(
        title: 'Safy App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        routerConfig: AppRouter.router,
        builder: (context, child) => LocationPermissionGate(child: child!),
      ),
    );
  }
}

class LocationPermissionGate extends StatefulWidget {
  final Widget child;
  const LocationPermissionGate({required this.child, super.key});

  @override
  State<LocationPermissionGate> createState() => _LocationPermissionGateState();
}

class _LocationPermissionGateState extends State<LocationPermissionGate> {
  bool _checking = true;
  bool _granted = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() {
          _checking = false;
          _granted = false;
          _error = 'Se requiere el permiso de ubicación para usar la app.';
        });
        return;
      }
      setState(() {
        _checking = false;
        _granted = true;
      });
    } catch (e) {
      setState(() {
        _checking = false;
        _granted = false;
        _error = 'Error solicitando permiso de ubicación: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_granted) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_off, size: 64, color: Colors.red),
                const SizedBox(height: 24),
                const Text(
                  'Permiso de ubicación requerido',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  _error ?? 'Activa el permiso de ubicación para continuar.',
                  style: const TextStyle(fontSize: 14, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _checkPermission,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Intentar de nuevo'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return widget.child;
  }
}

class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red.shade50,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade600),
                const SizedBox(height: 24),
                Text(
                  'Error al iniciar la aplicación',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    error,
                    style: TextStyle(fontSize: 14, color: Colors.red.shade700),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    // Reiniciar la app
                    main();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text(
                    'Reintentar',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
