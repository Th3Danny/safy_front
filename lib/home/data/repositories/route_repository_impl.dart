import 'package:safy/core/errors/failures.dart';
import 'package:safy/home/data/datasources/route_api_client.dart';
import 'package:safy/home/data/dtos/location_dto.dart';
import 'package:safy/home/data/dtos/route_dto.dart';
import 'package:safy/home/domain/entities/location.dart';
import 'package:safy/home/domain/entities/route.dart';
import 'package:safy/home/domain/repositories/route_repository.dart';
import 'package:safy/home/domain/value_objects/value_objects.dart';


class RouteRepositoryImpl implements RouteRepository {
  final RouteApiClient _apiClient;

  RouteRepositoryImpl(this._apiClient);

  @override
  Future<List<RouteEntity>> calculateRoutes({
    required Location startPoint,
    required Location endPoint,
    required TransportMode transportMode,
  }) async {
    try {
      final startDto = LocationDto.fromDomainEntity(startPoint);
      final endDto = LocationDto.fromDomainEntity(endPoint);
      
      final routeDtos = await _apiClient.calculateRoutes(
        startPoint: startDto,
        endPoint: endDto,
        transportMode: transportMode.apiIdentifier,
      );

      return routeDtos.map((dto) => dto.toDomainEntity()).toList();
    } catch (e) {
      throw ServerFailure('Error calculando rutas: $e');
    }
  }

  @override
  Future<RouteEntity> getOptimalRoute({
    required Location startPoint,
    required Location endPoint,
    required TransportMode transportMode,
    bool prioritizeSafety = true,
  }) async {
    try {
      final startDto = LocationDto.fromDomainEntity(startPoint);
      final endDto = LocationDto.fromDomainEntity(endPoint);
      
      final routeDto = await _apiClient.getOptimalRoute(
        startPoint: startDto,
        endPoint: endDto,
        transportMode: transportMode.apiIdentifier,
        prioritizeSafety: prioritizeSafety,
      );

      return routeDto.toDomainEntity();
    } catch (e) {
      throw ServerFailure('Error obteniendo ruta óptima: $e');
    }
  }

  @override
  Future<List<RouteEntity>> getAlternativeRoutes({
    required Location startPoint,
    required Location endPoint,
    required TransportMode transportMode,
  }) async {
    try {
      // Implementar lógica para obtener rutas alternativas
      // Por ahora, usar el método calculateRoutes
      return await calculateRoutes(
        startPoint: startPoint,
        endPoint: endPoint,
        transportMode: transportMode,
      );
    } catch (e) {
      throw ServerFailure('Error obteniendo rutas alternativas: $e');
    }
  }

  @override
  Future<void> saveRouteHistory(RouteEntity route) async {
    try {
      final routeDto = RouteDto.fromDomainEntity(route);
      await _apiClient.saveRouteHistory(routeDto);
    } catch (e) {
      throw ServerFailure('Error guardando historial de ruta: $e');
    }
  }

  @override
  Future<List<RouteEntity>> getRouteHistory({int limit = 10}) async {
    try {
      final routeDtos = await _apiClient.getRouteHistory(limit: limit);
      return routeDtos.map((dto) => dto.toDomainEntity()).toList();
    } catch (e) {
      throw ServerFailure('Error obteniendo historial de rutas: $e');
    }
  }
}