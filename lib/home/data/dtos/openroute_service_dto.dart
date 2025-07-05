import 'package:latlong2/latlong.dart';
import 'package:safy/home/domain/entities/route_result.dart';

class OpenRouteServiceDto {
  final List<RouteDto> routes;

  OpenRouteServiceDto({required this.routes});

  factory OpenRouteServiceDto.fromJson(Map<String, dynamic> json) {
    final routesList = json['routes'] as List<dynamic>? ?? [];
    return OpenRouteServiceDto(
      routes: routesList
          .map((route) => RouteDto.fromJson(route as Map<String, dynamic>))
          .toList(),
    );
  }

  RouteResult? toDomainEntity() {
    if (routes.isEmpty) return null;
    return routes.first.toDomainEntity();
  }
}

class RouteDto {
  final Map<String, dynamic> summary;
  final List<List<double>> geometry;
  final List<Map<String, dynamic>> segments;

  RouteDto({
    required this.summary,
    required this.geometry,
    required this.segments,
  });

  factory RouteDto.fromJson(Map<String, dynamic> json) {
    final geometryList = json['geometry'] as List<dynamic>? ?? [];
    final segmentsList = json['segments'] as List<dynamic>? ?? [];
    
    return RouteDto(
      summary: json['summary'] as Map<String, dynamic>? ?? {},
      geometry: geometryList
          .map((coord) => (coord as List<dynamic>)
              .map((c) => (c as num).toDouble())
              .toList())
          .toList(),
      segments: segmentsList
          .map((segment) => segment as Map<String, dynamic>)
          .toList(),
    );
  }

  RouteResult toDomainEntity() {
    final coordinates = geometry
        .map((coord) => LatLng(coord[1], coord[0])) // [lon, lat] -> LatLng(lat, lon)
        .toList();

    final steps = <RouteStep>[];
    for (final segment in segments) {
      final segmentSteps = segment['steps'] as List<dynamic>? ?? [];
      for (final step in segmentSteps) {
        final stepMap = step as Map<String, dynamic>;
        steps.add(RouteStep(
          instruction: stepMap['instruction'] ?? '',
          distance: (stepMap['distance'] as num?)?.toDouble() ?? 0.0,
          duration: (stepMap['duration'] as num?)?.toDouble() ?? 0.0,
          startPoint: coordinates.isNotEmpty ? coordinates.first : LatLng(0, 0),
          endPoint: coordinates.isNotEmpty ? coordinates.last : LatLng(0, 0),
        ));
      }
    }

    return RouteResult(
      coordinates: coordinates,
      distance: (summary['distance'] as num?)?.toDouble() ?? 0.0,
      duration: (summary['duration'] as num?)?.toDouble() ?? 0.0,
      summary: 'Ruta calculada',
      steps: steps,
    );
  }
}