import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safy/core/application/dependency_injection.dart';
import 'package:safy/core/router/app_router.dart';
import 'package:safy/core/session/session_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('[Main] 🚀 ========== INICIANDO SAFY ==========');

  try {
    // 1. Inicializar SharedPreferences
    print('[Main] 📱 Paso 1: Inicializando SharedPreferences...');
    final prefs = await SharedPreferences.getInstance();
    print('[Main] ✅ SharedPreferences OK');
    
    // DEBUG: Verificar si hay datos almacenados
    final storedToken = prefs.getString('access_token');
    final storedUser = prefs.getString('user_data');
    print('[Main] 🔍 Token almacenado encontrado: ${storedToken != null}');
    print('[Main] 🔍 Usuario almacenado encontrado: ${storedUser != null}');
    if (storedToken != null) {
      print('[Main] 🔍 Token preview: ${storedToken.substring(0, 20)}...');
    }

    // 2. Inicializar SessionManager
    print('[Main] 🔐 Paso 2: Inicializando SessionManager...');
    await SessionManager.instance.initialize(prefs: prefs);
    
    // DEBUG: Verificar estado del SessionManager después de initialize
    print('[Main] 🔍 VERIFICACIÓN POST-INICIALIZACIÓN:');
    SessionManager.instance.debugSessionState();
    print('[Main] ✅ SessionManager OK');

    // 3. Configurar dependencias
    print('[Main] 🔧 Paso 3: Configurando dependencias...');
    await setupDependencyInjection(sharedPreferences: prefs);
    print('[Main] ✅ Dependencias OK');

    print('[Main] 🎉 ========== INICIALIZACIÓN COMPLETA ==========');
    print('[Main] 🎉 Estado final - Usuario logueado: ${SessionManager.instance.isLoggedIn}');
    
    runApp(const MyApp());
    
  } catch (e, stackTrace) {
    print('[Main] ❌ ========== ERROR CRÍTICO ==========');
    print('[Main] ❌ Error: $e');
    print('[Main] ❌ StackTrace: $stackTrace');
    print('[Main] ❌ =====================================');
    runApp(ErrorApp(error: e.toString()));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('[MyApp] 🏗️ Construyendo MyApp...');
    
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
      ),
    );
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
                Icon(
                  Icons.error_outline, 
                  size: 64, 
                  color: Colors.red.shade600,
                ),
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
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red.shade700,
                    ),
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