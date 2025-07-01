import 'package:flutter/material.dart';
import 'package:safy/core/application/dependency_injection.dart';
import 'package:safy/core/router/app_router.dart';

// ✅ AGREGAR ESTOS IMPORTS

import 'package:safy/core/session/session_manager.dart';

void main() async {
  // ✅ AGREGAR ESTAS LÍNEAS
  WidgetsFlutterBinding.ensureInitialized();
  
  print('[Main] 🚀 Iniciando Safy...');
  
  // Configurar dependencias ANTES de la app
  await setupDependencyInjection();
  
  // Inicializar SessionManager
  await SessionManager.instance.initialize();
  
  print('[Main] ✅ Dependencias configuradas, iniciando app...');
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Safy App',
      debugShowCheckedModeBanner: false, // ✅ Opcional
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      routerConfig: AppRouter.router,
    );
  }
}