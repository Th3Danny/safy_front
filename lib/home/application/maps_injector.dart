import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:safy/home/data/datasources/danger_zone_api_client.dart';
import 'package:safy/home/data/datasources/mapbox_places_client.dart';
import 'package:safy/home/data/datasources/prediction_api_client.dart';
import 'package:safy/home/data/repositories/danger_zone_repository_impl.dart';
import 'package:safy/home/data/repositories/places_repository_impl.dart';
import 'package:safy/home/data/repositories/prediction_repository_impl.dart';
import 'package:safy/home/domain/repositories/danger_zone_repository.dart';
import 'package:safy/home/domain/repositories/places_repository.dart';
import 'package:safy/home/domain/repositories/prediction_repository.dart';
import 'package:safy/home/domain/usecases/check_danger_zones_use_case.dart';
import 'package:safy/home/domain/usecases/get_current_location_use_case.dart';
import 'package:safy/home/domain/usecases/get_danger_zones_use_case.dart';
import 'package:safy/home/domain/usecases/get_predictions_use_case.dart';
import 'package:safy/home/domain/usecases/search_places_use_case.dart';
import 'package:safy/home/presentation/viewmodels/map_view_model.dart';
import 'package:safy/report/domain/repositories/report_repository.dart';

Future<void> setupMapsDependencies() async {
  // Removed debug print

  // ===== DATA LAYER =====

  // API Clients
  GetIt.instance.registerLazySingleton<DangerZoneApiClient>(
    () =>
        DangerZoneApiClient(GetIt.instance<Dio>(instanceName: 'authenticated')),
  );

  // 🆕 NUEVO: Mapbox Places Client (reemplaza Nominatim)
  GetIt.instance.registerLazySingleton<MapboxPlacesClient>(
    () => MapboxPlacesClient(),
  );

  // 🆕 NUEVO: Prediction API Client
  GetIt.instance.registerLazySingleton<PredictionApiClient>(
    () =>
        PredictionApiClient(GetIt.instance<Dio>(instanceName: 'authenticated')),
  );

  // ===== REPOSITORIES =====

  GetIt.instance.registerLazySingleton<DangerZoneRepository>(
    () => DangerZoneRepositoryImpl(GetIt.instance<DangerZoneApiClient>()),
  );

  // 🆕 NUEVO: Places Repository con Mapbox
  GetIt.instance.registerLazySingleton<PlacesRepository>(
    () => PlacesRepositoryImpl(GetIt.instance<MapboxPlacesClient>()),
  );

  // 🆕 NUEVO: Prediction Repository
  GetIt.instance.registerLazySingleton<PredictionRepository>(
    () => PredictionRepositoryImpl(GetIt.instance<PredictionApiClient>()),
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

  // 🆕 NUEVO: Prediction Use Case
  GetIt.instance.registerLazySingleton<GetPredictionsUseCase>(
    () => GetPredictionsUseCase(GetIt.instance<PredictionRepository>()),
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

  // Removed debug print
}
