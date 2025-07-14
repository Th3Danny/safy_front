import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:safy/auth/application/auth_di.dart';
import 'package:safy/auth/presentation/viewmodels/auth_state_view_model.dart';
import 'package:safy/auth/presentation/viewmodels/login_viewmodel.dart';
import 'package:safy/auth/presentation/viewmodels/register_viewmodel.dart';
import 'package:safy/core/network/domian/config/dio_config.dart';
import 'package:safy/core/session/session_manager.dart';
import 'package:safy/home/application/maps_injector.dart';
import 'package:safy/home/domain/usecases/get_open_route_use_case.dart';
import 'package:safy/home/domain/usecases/search_places_use_case.dart';
import 'package:safy/home/presentation/viewmodels/map_view_model.dart';
import 'package:safy/report/domain/usecases/get_reports_use_case.dart';
// ✅ NUEVOS IMPORTS:
import 'package:safy/report/application/report_di.dart';
import 'package:safy/report/domain/repositories/report_repository.dart';
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

  // Registrar SessionManager con las prefs
  sl.registerLazySingleton<SessionManager>(
    () => SessionManager.instance..initialize(prefs: prefs),
  );

  // Registrar el caso de uso
  sl.registerLazySingleton<GetReportsForMapUseCase>(
    () => GetReportsForMapUseCase(sl<ReportRepository>()),
  );

  // 👈 NUEVO CASO DE USO
    sl.registerLazySingleton<GetReportsUseCase>(
      () => GetReportsUseCase(sl<ReportRepository>()),
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
    ChangeNotifierProvider<LoginViewModel>(create: (_) => sl<LoginViewModel>()),
    ChangeNotifierProvider<RegisterViewModel>(
      create: (_) => sl<RegisterViewModel>(),
    ),
    ChangeNotifierProvider<AuthStateViewModel>(
      create: (_) => sl<AuthStateViewModel>(),
    ),

    ChangeNotifierProvider<GetReportsViewModel>(
  create: (_) => sl<GetReportsViewModel>(),
),


    // ===== MAP PROVIDERS =====
    ChangeNotifierProvider<MapViewModel>(
  create: (_) => MapViewModel(
    searchPlacesUseCase: sl<SearchPlacesUseCase>(),
    getOpenRouteUseCase: sl<GetOpenRouteUseCase>(),
    getReportsForMapUseCase: sl<GetReportsForMapUseCase>(), // 👈 NUEVO
    
  ),
),




    // ===== REPORT PROVIDERS ===== ✅ AGREGADO
    ChangeNotifierProvider<CreateReportViewModel>(
      create: (_) => sl<CreateReportViewModel>(),
    ),
  ];
}
