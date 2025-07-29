import 'package:latlong2/latlong.dart';

class RouteResult {
  final List<LatLng> coordinates;
  final double distance; // en metros
  final double duration; // en segundos
  final String summary;
  final List<RouteStep> steps;

  const RouteResult({
    required this.coordinates,
    required this.distance,
    required this.duration,
    required this.summary,
    required this.steps,
  });
}

class RouteStep {
  final String instruction;
  final double distance;
  final double duration;
  final LatLng startPoint;
  final LatLng endPoint;

  const RouteStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.startPoint,
    required this.endPoint,
  });
}
