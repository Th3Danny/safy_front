import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:safy/home/data/datasources/danger_zone_api_client.dart';
import 'package:safy/home/data/datasources/nominatim_api_client.dart';
import 'package:safy/home/data/datasources/openroute_service_api_client.dart';
import 'package:safy/home/data/datasources/route_api_client.dart';
import 'package:safy/home/data/repositories/danger_zone_repository_impl.dart';
import 'package:safy/home/data/repositories/open_route_repository_impl.dart';
import 'package:safy/home/data/repositories/places_repository_impl.dart';
import 'package:safy/home/data/repositories/route_repository_impl.dart';
import 'package:safy/home/domain/repositories/danger_zone_repository.dart';
import 'package:safy/home/domain/repositories/open_route_repository.dart';
import 'package:safy/home/domain/repositories/places_repository.dart';
import 'package:safy/home/domain/repositories/route_repository.dart';
import 'package:safy/home/domain/usecases/calculate_route_use_case.dart';
import 'package:safy/home/domain/usecases/calculate_safe_routes_use_case.dart';
import 'package:safy/home/domain/usecases/check_danger_zones_use_case.dart';
import 'package:safy/home/domain/usecases/get_current_location_use_case.dart';
import 'package:safy/home/domain/usecases/get_danger_zones_use_case.dart';
import 'package:safy/home/domain/usecases/get_open_route_use_case.dart';
import 'package:safy/home/domain/usecases/search_places_use_case.dart';
import 'package:safy/home/presentation/viewmodels/map_view_model.dart';
import 'package:safy/home/presentation/viewmodels/map_view_model_enhanced.dart';
import 'package:safy/report/domain/repositories/report_repository.dart';

Future<void> setupMapsDependencies() async {
  print('[MapsDI] 🗺️ Configurando dependencias de mapas...');
  
  // ===== DATA LAYER =====
  
  // API Clients
  GetIt.instance.registerLazySingleton<RouteApiClient>(
    () => RouteApiClient(GetIt.instance<Dio>(instanceName: 'public')),
  );
  
  GetIt.instance.registerLazySingleton<DangerZoneApiClient>(
    () => DangerZoneApiClient(GetIt.instance<Dio>(instanceName: 'authenticated')),
  );

  // Nuevos API Clients
  GetIt.instance.registerLazySingleton<NominatimApiClient>(
    () => NominatimApiClient(GetIt.instance<Dio>(instanceName: 'public')),
  );
  
  GetIt.instance.registerLazySingleton<OSRMApiClient>(
    () => OSRMApiClient(GetIt.instance<Dio>(instanceName: 'public')),
  );
  
  // ===== REPOSITORIES =====
  
  GetIt.instance.registerLazySingleton<RouteRepository>(
    () => RouteRepositoryImpl(GetIt.instance<RouteApiClient>()),
  );
  
  GetIt.instance.registerLazySingleton<DangerZoneRepository>(
    () => DangerZoneRepositoryImpl(GetIt.instance<DangerZoneApiClient>()),
  );

  // Repositorios nuevos
  GetIt.instance.registerLazySingleton<PlacesRepository>(
    () => PlacesRepositoryImpl(GetIt.instance<NominatimApiClient>()),
  );
  
  // Repositorio de OpenRouteService
  GetIt.instance.registerLazySingleton<OpenRouteRepository>(
    () => OpenRouteRepositoryImpl(GetIt.instance<OSRMApiClient>()),
  );
  
  // ===== DOMAIN LAYER (USE CASES) =====
  
  GetIt.instance.registerLazySingleton<CalculateRouteUseCase>(
    () => CalculateRouteUseCase(GetIt.instance<RouteRepository>()),
  );
  
  // 🛡️ NUEVO: Caso de uso para rutas seguras mejorado
  GetIt.instance.registerLazySingleton<CalculateSafeRoutesUseCase>(
    () => CalculateSafeRoutesUseCase(
      GetIt.instance<RouteRepository>(),
      GetIt.instance<DangerZoneRepository>(),
      GetIt.instance<ReportRepository>(), // Opcional: para clusters
    ),
  );
  
  GetIt.instance.registerLazySingleton<GetCurrentLocationUseCase>(
    () => GetCurrentLocationUseCase(),
  );
  
  GetIt.instance.registerLazySingleton<CheckDangerZonesUseCase>(
    () => CheckDangerZonesUseCase(GetIt.instance<DangerZoneRepository>()),
  );
  
  // ❌ ELIMINADA DUPLICACIÓN - Solo UNA vez registrado
  GetIt.instance.registerLazySingleton<GetDangerZonesUseCase>(
    () => GetDangerZonesUseCase(GetIt.instance<DangerZoneRepository>()),
  );

  // Casos de uso nuevos
  GetIt.instance.registerLazySingleton<SearchPlacesUseCase>(
    () => SearchPlacesUseCase(GetIt.instance<PlacesRepository>()),
  );
  
  GetIt.instance.registerLazySingleton<GetOpenRouteUseCase>(
    () => GetOpenRouteUseCase(GetIt.instance<OpenRouteRepository>()),
  );
  
  // ===== PRESENTATION LAYER (VIEW MODELS) =====
  
  // MapViewModel original (mantener para compatibilidad)
  GetIt.instance.registerFactory<MapViewModel>(
    () => MapViewModel(
      searchPlacesUseCase: GetIt.instance<SearchPlacesUseCase>(),
      getOpenRouteUseCase: GetIt.instance<GetOpenRouteUseCase>(), 
    ),
  );

  // 🚀 ViewModel mejorado (NUEVO)
  GetIt.instance.registerFactory<MapViewModelEnhanced>(
    () => MapViewModelEnhanced(
      searchPlacesUseCase: GetIt.instance<SearchPlacesUseCase>(),
      getOpenRouteUseCase: GetIt.instance<GetOpenRouteUseCase>(),
      getCurrentLocationUseCase: GetIt.instance<GetCurrentLocationUseCase>(),
      checkDangerZonesUseCase: GetIt.instance<CheckDangerZonesUseCase>(),
      getDangerZonesUseCase: GetIt.instance<GetDangerZonesUseCase>(),
      calculateSafeRoutesUseCase: GetIt.instance<CalculateSafeRoutesUseCase>(),
    ),
  );
  
  print('[MapsDI] ✅ Dependencias de mapas registradas exitosamente');
}