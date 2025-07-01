import 'package:get_it/get_it.dart';
import 'package:safy/auth/application/auth_di.dart';
import 'package:safy/core/network/domian/config/dio_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';


final sl = GetIt.instance;

Future<void> setupDependencyInjection() async {
  print('[DI] 🚀 Iniciando configuración de dependencias...');

  // ===== EXTERNAL DEPENDENCIES =====
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => prefs);

  // ===== CORE DEPENDENCIES =====
  
  sl.registerLazySingleton<Dio>(
    () => DioConfig.createDio(),
    instanceName: 'authenticated',
  );
  
  sl.registerLazySingleton<Dio>(
    () => DioConfig.createPublicDio(),
    instanceName: 'public',
  );

  // ===== FEATURE DEPENDENCIES =====
  await setupAuthDependencies();
  
  // Aquí agregarás otras features:
  // await setupMapDependencies();
  // await setupReportsDependencies();

  print('[DI]  Todas las dependencias configuradas exitosamente');
}