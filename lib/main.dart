import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safy/core/application/dependency_injection.dart'; 
import 'package:safy/core/router/app_router.dart';
import 'package:safy/core/session/session_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('[Main] 🚀 Iniciando Safy...');
  
  try {
    // 1. Inicializar SharedPreferences primero
    final prefs = await SharedPreferences.getInstance();
    print('[Main] SharedPreferences initialized: ${prefs != null}');
    
    // 2. Configurar dependencias con las prefs ya inicializadas
    await setupDependencyInjection(sharedPreferences: prefs);
    
    // 3. Inicializar SessionManager con las prefs
    await SessionManager.instance.initialize(prefs: prefs);
    
    print('[Main] ✅ Dependencias configuradas correctamente');
    
    runApp(const MyApp());
  } catch (e, stackTrace) {
    print('[Main] ❌ Error crítico durante la inicialización: $e');
    print(stackTrace);
    runApp(const ErrorApp());
  }
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
      ),
    );
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 20),
              const Text(
                'Error al iniciar la aplicación',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => main(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}