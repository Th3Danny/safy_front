import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:safy/core/network/domian/config/dio_config.dart';
import 'package:safy/home/data/datasources/danger_zone_api_client.dart';
import 'package:safy/home/data/datasources/route_api_client.dart';
import 'package:safy/home/data/repositories/danger_zone_repository_impl.dart';
import 'package:safy/home/data/repositories/route_repository_impl.dart';
import 'package:safy/home/domain/repositories/danger_zone_repository.dart';
import 'package:safy/home/domain/repositories/route_repository.dart';
import 'package:safy/home/domain/usecases/calculate_safe_routes_use_case.dart';
import 'package:safy/home/domain/usecases/check_danger_zones_use_case.dart';
import 'package:safy/home/domain/usecases/get_current_location_use_case.dart';
import 'package:safy/home/domain/usecases/get_danger_zones_use_case.dart';
import 'package:safy/home/presentation/viewmodels/map_view_model.dart';

// Core

// Data Sources

// Repositories

// Use Cases

// Presentation

class MapsInjector {
  static List<SingleChildWidget> getDependencies() {
    return [
      // ===== CORE DEPENDENCIES =====
      Provider<Dio>(create: (_) => DioConfig.createDio()),

      // ===== DATA SOURCES =====
      Provider<RouteApiClient>(
        create: (context) => RouteApiClient(context.read<Dio>()),
      ),

      Provider<DangerZoneApiClient>(
        create: (context) => DangerZoneApiClient(context.read<Dio>()),
      ),

      // ===== REPOSITORIES =====
      Provider<RouteRepository>(
        create:
            (context) => RouteRepositoryImpl(context.read<RouteApiClient>()),
      ),

      Provider<DangerZoneRepository>(
        create:
            (context) =>
                DangerZoneRepositoryImpl(context.read<DangerZoneApiClient>()),
      ),

      // ===== USE CASES =====
      Provider<CalculateSafeRoutesUseCase>(
        create:
            (context) => CalculateSafeRoutesUseCase(
              context.read<RouteRepository>(),
              context.read<DangerZoneRepository>(),
            ),
      ),

      Provider<GetCurrentLocationUseCase>(
        create: (_) => GetCurrentLocationUseCase(),
      ),

      Provider<CheckDangerZonesUseCase>(
        create:
            (context) =>
                CheckDangerZonesUseCase(context.read<DangerZoneRepository>()),
      ),
      Provider<GetDangerZonesUseCase>(
        create:
            (context) =>
                GetDangerZonesUseCase(context.read<DangerZoneRepository>()),
      ),

      // ===== VIEW MODELS =====
      
      ChangeNotifierProvider<MapViewModel>(create: (context) => MapViewModel()),
    ];
  }
}
