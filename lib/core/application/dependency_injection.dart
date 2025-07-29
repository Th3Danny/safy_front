// lib/core/application/dependency_injection.dart

import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:safy/auth/application/auth_di.dart';
import 'package:safy/auth/presentation/viewmodels/auth_state_view_model.dart';
import 'package:safy/auth/presentation/viewmodels/login_viewmodel.dart';
import 'package:safy/auth/presentation/viewmodels/register_viewmodel.dart';
import 'package:safy/core/network/domian/config/dio_config.dart';
import 'package:safy/core/services/firebase/firebase_messaging_service.dart';
import 'package:safy/core/services/device/device_info_service.dart';
import 'package:safy/core/services/device/device_registration_service.dart';
import 'package:safy/core/services/cluster_detection_service.dart';
import 'package:safy/core/services/location_tracking_service.dart';
import 'package:safy/core/services/movement_detection_service.dart';
import 'package:safy/core/session/session_manager.dart';
import 'package:safy/home/application/maps_injector.dart';

import 'package:safy/home/domain/usecases/search_places_use_case.dart';
import 'package:safy/home/domain/usecases/get_predictions_use_case.dart';
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

Future<void> setupDependencyInjection({
  SharedPreferences? sharedPreferences,
}) async {
  // Removed debug print

  // ===== EXTERNAL DEPENDENCIES =====
  final prefs = sharedPreferences ?? await SharedPreferences.getInstance();

  // Verificar si SharedPreferences ya está registrado
  if (!sl.isRegistered<SharedPreferences>()) {
    sl.registerLazySingleton<SharedPreferences>(() => prefs);
  } else {
    // Removed debug print
  }

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
  sl.registerLazySingleton<SessionManager>(() => SessionManager.instance);

  // Firebase Messaging Service
  sl.registerLazySingleton<FirebaseMessagingService>(
    () => FirebaseMessagingService(),
  );

  // Device Services
  sl.registerLazySingleton<DeviceInfoService>(() => DeviceInfoService());

  sl.registerLazySingleton<DeviceRegistrationService>(
    () => DeviceRegistrationService(),
  );

  // Cluster Detection Service
  if (!sl.isRegistered<ClusterDetectionService>()) {
    sl.registerLazySingleton<ClusterDetectionService>(
      () => ClusterDetectionService(),
    );
  }

  // Location Tracking Service
  if (!sl.isRegistered<LocationTrackingService>()) {
    sl.registerLazySingleton<LocationTrackingService>(
      () => LocationTrackingService(),
    );
  }

  // Movement Detection Service
  if (!sl.isRegistered<MovementDetectionService>()) {
    sl.registerLazySingleton<MovementDetectionService>(
      () => MovementDetectionService(),
    );
  }

  // Map ViewModel (para acceso desde servicios)
  // NO registrar como singleton aquí, se maneja en getAllProviders()
  // if (!sl.isRegistered<MapViewModel>()) {
  //   sl.registerLazySingleton<MapViewModel>(() => MapViewModel());
  // }

  // ===== FEATURE DEPENDENCIES =====
  await setupAuthDependencies();
  await setupReportDependencies(); // Debe registrar TODOS los use cases de reports
  await setupMapsDependencies();

  // ===== VERIFICACIÓN DE DEPENDENCIAS CRÍTICAS =====
  // Asegurar que las dependencias críticas estén registradas
  _ensureCriticalDependencies();

  // Removed debug print
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
      // Removed debug print
      sl.registerLazySingleton<GetReportsForMapUseCase>(
        () => GetReportsForMapUseCase(sl<ReportRepository>()),
      );
    }

    // Verificar GetClustersUseCase
    if (!sl.isRegistered<GetClustersUseCase>()) {
      // Removed debug print
      sl.registerLazySingleton<GetClustersUseCase>(
        () => GetClustersUseCase(sl<ReportRepository>()),
      );
    }

    // Removed debug print
  } catch (e) {
    // Removed debug print
    rethrow;
  }
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
          // Removed debug print

          // Verificar dependencias antes de crear MapViewModel
          final searchPlacesUseCase = sl<SearchPlacesUseCase>();

          final getReportsForMapUseCase = sl<GetReportsForMapUseCase>();
          final getClustersUseCase = sl<GetClustersUseCase>();
          final getPredictionsUseCase = sl<GetPredictionsUseCase>();

          // Removed debug print

          return MapViewModel(
            searchPlacesUseCase: searchPlacesUseCase,
            getReportsForMapUseCase: getReportsForMapUseCase,
            getClustersUseCase: getClustersUseCase,
            getPredictionsUseCase: getPredictionsUseCase,
          );
        } catch (e) {
          // Removed debug print
          rethrow;
        }
      },
    ),
  ];
}
