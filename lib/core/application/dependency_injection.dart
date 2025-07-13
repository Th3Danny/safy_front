import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:safy/auth/application/auth_di.dart';
import 'package:safy/auth/presentation/viewmodels/auth_state_view_model.dart';
import 'package:safy/auth/presentation/viewmodels/login_viewmodel.dart';
import 'package:safy/auth/presentation/viewmodels/register_viewmodel.dart';
import 'package:safy/core/network/domian/config/dio_config.dart';
import 'package:safy/home/application/maps_injector.dart';
import 'package:safy/home/presentation/viewmodels/map_view_model.dart';
// ✅ NUEVOS IMPORTS:
import 'package:safy/report/application/report_di.dart';
import 'package:safy/report/presentation/viewmodels/create_report_viewmodel.dart';
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
    () => DioConfig.createDio(),
    instanceName: 'public',
  );

  // ===== FEATURE DEPENDENCIES =====
  await setupAuthDependencies();
  await setupMapsDependencies();
  await setupReportDependencies(); // ✅ AGREGADO

  print('[DI] ✅ Todas las dependencias configuradas exitosamente');
}

List<SingleChildWidget> getAllProviders() {
  return [
    // ===== AUTH PROVIDERS =====
    ChangeNotifierProvider<LoginViewModel>(
      create: (_) => sl<LoginViewModel>(),
    ),
    ChangeNotifierProvider<RegisterViewModel>(
      create: (_) => sl<RegisterViewModel>(),
    ),
    ChangeNotifierProvider<AuthStateViewModel>(
      create: (_) => sl<AuthStateViewModel>(),
    ),
    
    // ===== MAP PROVIDERS =====
    ChangeNotifierProvider<MapViewModel>(
      create: (_) => sl<MapViewModel>(),
    ),
    
    // ===== REPORT PROVIDERS ===== ✅ AGREGADO
    ChangeNotifierProvider<CreateReportViewModel>(
      create: (_) => sl<CreateReportViewModel>(),
    ),
  ];
}