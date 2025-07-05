import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:safy/home/data/datasources/danger_zone_api_client.dart';
import 'package:safy/home/data/datasources/nominatim_api_client.dart';
import 'package:safy/home/data/datasources/openroute_service_api_client.dart';
import 'package:safy/home/data/datasources/route_api_client.dart';
import 'package:safy/home/data/repositories/danger_zone_repository_impl.dart';
import 'package:safy/home/data/repositories/places_repository_impl.dart';
import 'package:safy/home/data/repositories/route_repository_impl.dart';
import 'package:safy/home/domain/repositories/danger_zone_repository.dart';
import 'package:safy/home/domain/repositories/places_repository.dart';
import 'package:safy/home/domain/repositories/route_repository.dart';
import 'package:safy/home/domain/usecases/calculate_route_use_case.dart';
import 'package:safy/home/domain/usecases/check_danger_zones_use_case.dart';
import 'package:safy/home/domain/usecases/get_current_location_use_case.dart';
import 'package:safy/home/domain/usecases/get_danger_zones_use_case.dart';
import 'package:safy/home/domain/usecases/search_places_use_case.dart';
import 'package:safy/home/presentation/viewmodels/map_view_model.dart';

Future<void> setupMapsDependencies() async {
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
  
  GetIt.instance.registerLazySingleton<OpenRouteServiceApiClient>(
    () => OpenRouteServiceApiClient(GetIt.instance<Dio>(instanceName: 'public')),
  );
  
  // ===== REPOSITORIES =====
  
  GetIt.instance.registerLazySingleton<RouteRepository>(
    () => RouteRepositoryImpl(GetIt.instance<RouteApiClient>()),
  );
  
  GetIt.instance.registerLazySingleton<DangerZoneRepository>(
    () => DangerZoneRepositoryImpl(GetIt.instance<DangerZoneApiClient>()),
  );

  // Nuevo repositorio
  GetIt.instance.registerLazySingleton<PlacesRepository>(
    () => PlacesRepositoryImpl(GetIt.instance<NominatimApiClient>()),
  );
  
  // ===== DOMAIN LAYER (USE CASES) =====
  
  GetIt.instance.registerLazySingleton<CalculateRouteUseCase>(
    () => CalculateRouteUseCase(GetIt.instance<RouteRepository>()),
  );
  
  GetIt.instance.registerLazySingleton<GetCurrentLocationUseCase>(
    () => GetCurrentLocationUseCase(),
  );
  
  GetIt.instance.registerLazySingleton<CheckDangerZonesUseCase>(
    () => CheckDangerZonesUseCase(GetIt.instance<DangerZoneRepository>()),
  );
  
  GetIt.instance.registerLazySingleton<GetDangerZonesUseCase>(
    () => GetDangerZonesUseCase(GetIt.instance<DangerZoneRepository>()),
  );

  // Nuevos casos de uso
  GetIt.instance.registerLazySingleton<SearchPlacesUseCase>(
    () => SearchPlacesUseCase(GetIt.instance<PlacesRepository>()),
  );
  
  // ===== PRESENTATION LAYER (VIEW MODELS) =====
  
  GetIt.instance.registerFactory<MapViewModel>(
    () => MapViewModel(
      searchPlacesUseCase: GetIt.instance<SearchPlacesUseCase>(),
    ),
  );
  
  print('[MapsDI] ✅ Dependencias de mapas registradas');
}