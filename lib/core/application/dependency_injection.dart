// lib/core/application/dependency_injection.dart

import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:safy/auth/application/auth_di.dart';
import 'package:safy/auth/presentation/viewmodels/auth_state_view_model.dart';
import 'package:safy/auth/presentation/viewmodels/login_viewmodel.dart';
import 'package:safy/auth/presentation/viewmodels/register_viewmodel.dart';
import 'package:safy/core/network/domian/config/dio_config.dart';
import 'package:safy/core/services/firebase_messaging_service.dart';
import 'package:safy/core/session/session_manager.dart';
import 'package:safy/home/application/maps_injector.dart';
import 'package:safy/home/domain/usecases/get_open_route_use_case.dart';
import 'package:safy/home/domain/usecases/search_places_use_case.dart';
import 'package:safy/home/presentation/viewmodels/map_view_model.dart';
import 'package:safy/report/application/report_di.dart';
import 'package:safy/report/domain/repositories/report_repository.dart';
import 'package:safy/report/domain/usecases/get_clusters_use_case.dart';
import 'package:safy/report/domain/usecases/get_reports_for_map_use_case.dart';
import 'package:safy/report/presentation/viewmodels/create_report_viewmodel.dart';
import 'package:safy/report/presentation/viewmodels/my_get_reports_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

final sl = GetIt.instance;

Future<void> setupDependencyInjection({SharedPreferences? sharedPreferences}) async {
  print('[DI] 🚀 Iniciando configuración de dependencias...');

  // ===== EXTERNAL DEPENDENCIES =====
  final prefs = sharedPreferences ?? await SharedPreferences.getInstance();
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

  // Session Manager
  sl.registerLazySingleton<SessionManager>(
    () => SessionManager.instance,
  );

  // Firebase Messaging Service
  sl.registerLazySingleton<FirebaseMessagingService>(
    () => FirebaseMessagingService(),
  );

  // ===== FEATURE DEPENDENCIES =====
  await setupAuthDependencies();
  await setupReportDependencies(); // Debe registrar TODOS los use cases de reports
  await setupMapsDependencies();

  // ===== VERIFICACIÓN DE DEPENDENCIAS CRÍTICAS =====
  // Asegurar que las dependencias críticas estén registradas
  _ensureCriticalDependencies();

  print('[DI] ✅ Todas las dependencias configuradas exitosamente');
}

void _ensureCriticalDependencies() {
  // Verificar que las dependencias críticas estén registradas
  try {
    // Verificar ReportRepository
    if (!sl.isRegistered<ReportRepository>()) {
      throw Exception('ReportRepository no está registrado');
    }

    // Verificar GetReportsForMapUseCase
    if (!sl.isRegistered<GetReportsForMapUseCase>()) {
      print('[DI] ⚠️ GetReportsForMapUseCase no registrado, registrando ahora...');
      sl.registerLazySingleton<GetReportsForMapUseCase>(
        () => GetReportsForMapUseCase(sl<ReportRepository>()),
      );
    }

    // Verificar GetClustersUseCase
    if (!sl.isRegistered<GetClustersUseCase>()) {
      print('[DI] ⚠️ GetClustersUseCase no registrado, registrando ahora...');
      sl.registerLazySingleton<GetClustersUseCase>(
        () => GetClustersUseCase(sl<ReportRepository>()),
      );
    }

    print('[DI] ✅ Todas las dependencias críticas verificadas');
  } catch (e) {
    print('[DI] ❌ Error verificando dependencias: $e');
    rethrow;
  }
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

    // ===== REPORT PROVIDERS =====
    ChangeNotifierProvider<GetReportsViewModel>(
      create: (_) => sl<GetReportsViewModel>(),
    ),
    ChangeNotifierProvider<CreateReportViewModel>(
      create: (_) => sl<CreateReportViewModel>(),
    ),

    // ===== MAP PROVIDERS =====
    ChangeNotifierProvider<MapViewModel>(
      create: (_) {
        try {
          print('[DI] 🗺️ Creando MapViewModel...');
          
          // Verificar dependencias antes de crear MapViewModel
          final searchPlacesUseCase = sl<SearchPlacesUseCase>();
          final getOpenRouteUseCase = sl<GetOpenRouteUseCase>();
          final getReportsForMapUseCase = sl<GetReportsForMapUseCase>();
          final getClustersUseCase = sl<GetClustersUseCase>();
          
          print('[DI] ✅ Todas las dependencias disponibles para MapViewModel');
          
          return MapViewModel(
            searchPlacesUseCase: searchPlacesUseCase,
            getOpenRouteUseCase: getOpenRouteUseCase,
            getReportsForMapUseCase: getReportsForMapUseCase,
            getClustersUseCase: getClustersUseCase,
          );
        } catch (e) {
          print('[DI] ❌ Error creando MapViewModel: $e');
          rethrow;
        }
      },
    ),
  ];
}