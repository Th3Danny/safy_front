
import 'package:safy/home/domain/entities/location.dart';
import 'package:safy/home/domain/entities/route.dart';
import 'package:safy/home/domain/value_objects/value_objects.dart';


abstract class RouteRepository {
  Future<List<RouteEntity>> calculateRoutes({
    required Location startPoint,
    required Location endPoint,
    required TransportMode transportMode,
  });

  Future<RouteEntity> getOptimalRoute({
    required Location startPoint,
    required Location endPoint,
    required TransportMode transportMode,
    bool prioritizeSafety = true,
  });

  Future<List<RouteEntity>> getAlternativeRoutes({
    required Location startPoint,
    required Location endPoint,
    required TransportMode transportMode,
  });

  Future<void> saveRouteHistory(RouteEntity route);
  Future<List<RouteEntity>> getRouteHistory({int limit = 10});
}
