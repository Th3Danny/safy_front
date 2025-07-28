import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:safy/home/data/datasources/danger_zone_api_client.dart';
import 'package:safy/home/data/datasources/nominatim_api_client.dart';
import 'package:safy/home/data/repositories/danger_zone_repository_impl.dart';
import 'package:safy/home/data/repositories/places_repository_impl.dart';
import 'package:safy/home/domain/repositories/danger_zone_repository.dart';
import 'package:safy/home/domain/repositories/places_repository.dart';
import 'package:safy/home/domain/usecases/check_danger_zones_use_case.dart';
import 'package:safy/home/domain/usecases/get_current_location_use_case.dart';
import 'package:safy/home/domain/usecases/get_danger_zones_use_case.dart';
import 'package:safy/home/domain/usecases/search_places_use_case.dart';
import 'package:safy/home/presentation/viewmodels/map_view_model.dart';
import 'package:safy/report/domain/repositories/report_repository.dart';

Future<void> setupMapsDependencies() async {
  print('[MapsDI] 🗺️ Configurando dependencias de mapas...');

  // ===== DATA LAYER =====

  // API Clients
  GetIt.instance.registerLazySingleton<DangerZoneApiClient>(
    () =>
        DangerZoneApiClient(GetIt.instance<Dio>(instanceName: 'authenticated')),
  );

  // Nuevos API Clients
  GetIt.instance.registerLazySingleton<NominatimApiClient>(
    () => NominatimApiClient(GetIt.instance<Dio>(instanceName: 'public')),
  );

  // ===== REPOSITORIES =====

  GetIt.instance.registerLazySingleton<DangerZoneRepository>(
    () => DangerZoneRepositoryImpl(GetIt.instance<DangerZoneApiClient>()),
  );

  // Repositorios nuevos
  GetIt.instance.registerLazySingleton<PlacesRepository>(
    () => PlacesRepositoryImpl(GetIt.instance<NominatimApiClient>()),
  );

  // ===== DOMAIN LAYER (USE CASES) =====

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

  // ===== PRESENTATION LAYER (VIEW MODELS) =====

  // MapViewModel principal
  GetIt.instance.registerFactory<MapViewModel>(
    () => MapViewModel(
      searchPlacesUseCase: GetIt.instance<SearchPlacesUseCase>(),
    ),
  );

  print('[MapsDI] ✅ Dependencias de mapas registradas exitosamente');
}
