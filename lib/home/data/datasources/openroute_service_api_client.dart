import 'package:dio/dio.dart';

class OSRMApiClient {
  final Dio dio;
  
  OSRMApiClient(this.dio);
  
  Future<List<List<double>>> getRouteCoordinates({
    required List<double> start,
    required List<double> end,
    String profile = 'foot',
  }) async {
    try {
      print('🌐 Llamando a OSRM: $start -> $end');
      
      // OSRM espera lon,lat formato
      final startCoord = '${start[0]},${start[1]}';
      final endCoord = '${end[0]},${end[1]}';
      
      final response = await dio.get(
        'http://router.project-osrm.org/route/v1/$profile/$startCoord;$endCoord',
        queryParameters: {
          'overview': 'full',
          'geometries': 'geojson',
        },
      );
      
      print('📊 Respuesta de OSRM: ${response.statusCode}');
      
      if (response.data == null) {
        throw Exception('Respuesta vacía de OSRM');
      }
      
      final routes = response.data['routes'] as List?;
      if (routes == null || routes.isEmpty) {
        throw Exception('No se encontraron rutas en la respuesta');
      }
      
      final geometry = routes[0]['geometry']['coordinates'] as List?;
      if (geometry == null) {
        throw Exception('No se encontró geometría en la respuesta');
      }
      
      final coordinates = List<List<double>>.from(
        geometry.map((coord) => List<double>.from(coord as List)),
      );
      
      print('✅ Coordenadas obtenidas: ${coordinates.length} puntos');
      return coordinates;
      
    } catch (e) {
      print('❌ Error en OSRM: $e');
      rethrow;
    }
  }
}