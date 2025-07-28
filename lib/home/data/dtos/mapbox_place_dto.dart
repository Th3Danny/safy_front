import 'package:safy/home/domain/entities/place.dart';
import 'package:safy/home/domain/entities/location.dart';

class MapboxPlaceDto {
  final String id;
  final String displayName;
  final double latitude;
  final double longitude;
  final String? category;
  final String? type;
  final Map<String, dynamic>? properties;
  final Map<String, dynamic>? context;
  final String? placeType;
  final double? relevance;
  final String? address;
  final String? postcode;
  final String? city;
  final String? state;
  final String? country;

  MapboxPlaceDto({
    required this.id,
    required this.displayName,
    required this.latitude,
    required this.longitude,
    this.category,
    this.type,
    this.properties,
    this.context,
    this.placeType,
    this.relevance,
    this.address,
    this.postcode,
    this.city,
    this.state,
    this.country,
  });

  factory MapboxPlaceDto.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] as Map<String, dynamic>?;
    final coordinates = geometry?['coordinates'] as List<dynamic>?;

    final properties = json['properties'] as Map<String, dynamic>?;
    final context = json['context'] as List<dynamic>?;

    // 🆕 MANEJO SEGURO DE COORDENADAS
    double latitude = 0.0;
    double longitude = 0.0;

    if (coordinates != null && coordinates.length >= 2) {
      // Manejar tanto int como double para las coordenadas
      final lngRaw = coordinates[0];
      final latRaw = coordinates[1];

      longitude =
          lngRaw is int ? lngRaw.toDouble() : (lngRaw as double? ?? 0.0);
      latitude = latRaw is int ? latRaw.toDouble() : (latRaw as double? ?? 0.0);
    }

    // Extraer información de contexto
    String? postcode, city, state, country;
    if (context != null) {
      for (final item in context) {
        final itemMap = item as Map<String, dynamic>;
        final id = itemMap['id'] as String?;
        final text = itemMap['text'] as String?;

        if (id?.contains('postcode') == true) {
          postcode = text;
        } else if (id?.contains('place') == true) {
          city = text;
        } else if (id?.contains('region') == true) {
          state = text;
        } else if (id?.contains('country') == true) {
          country = text;
        }
      }
    }

    return MapboxPlaceDto(
      id: json['id'] as String? ?? '',
      displayName:
          json['place_name'] as String? ?? json['text'] as String? ?? '',
      latitude: latitude,
      longitude: longitude,
      category: properties?['category'] as String?,
      type: json['place_type']?.first as String?,
      properties: properties,
      context:
          context?.isNotEmpty == true
              ? context!.first as Map<String, dynamic>?
              : null,
      placeType: json['place_type']?.first as String?,
      relevance:
          json['relevance'] is int
              ? (json['relevance'] as int).toDouble()
              : (json['relevance'] as double?),
      address: properties?['address'] as String?,
      postcode: postcode,
      city: city,
      state: state,
      country: country,
    );
  }

  Place toDomainEntity() {
    // Construir dirección completa
    final addressParts = <String>[];
    if (address != null) addressParts.add(address!);
    if (city != null) addressParts.add(city!);
    if (state != null) addressParts.add(state!);
    if (postcode != null) addressParts.add(postcode!);
    if (country != null) addressParts.add(country!);

    final fullAddress =
        addressParts.isNotEmpty ? addressParts.join(', ') : null;

    return Place(
      displayName: displayName,
      location: Location(latitude: latitude, longitude: longitude),
      category: category ?? type,
      type: placeType,
      address: fullAddress,
    );
  }

  @override
  String toString() {
    return 'MapboxPlaceDto(id: $id, name: $displayName, lat: $latitude, lng: $longitude)';
  }
}
