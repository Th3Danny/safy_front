import 'package:safy/home/domain/entities/place.dart';
import 'package:safy/home/domain/entities/location.dart';

class NominatimPlaceDto {
  final String displayName;
  final String lat;
  final String lon;
  final String? category;
  final String? type;
  final Map<String, dynamic>? address;

  NominatimPlaceDto({
    required this.displayName,
    required this.lat,
    required this.lon,
    this.category,
    this.type,
    this.address,
  });

  factory NominatimPlaceDto.fromJson(Map<String, dynamic> json) {
    return NominatimPlaceDto(
      displayName: json['display_name'] ?? '',
      lat: json['lat'] ?? '0',
      lon: json['lon'] ?? '0',
      category: json['category'],
      type: json['type'],
      address: json['address'] as Map<String, dynamic>?,
    );
  }

  Place toDomainEntity() {
    final latitude = double.tryParse(lat) ?? 0.0;
    final longitude = double.tryParse(lon) ?? 0.0;
    
    return Place(
      displayName: displayName,
      location: Location(
        latitude: latitude,
        longitude: longitude,
      ),
      category: category,
      type: type,
      address: _formatAddress(),
    );
  }

  String? _formatAddress() {
    if (address == null) return null;
    
    final parts = <String>[];
    
    // Agregar componentes de dirección en orden lógico
    if (address!['house_number'] != null && address!['road'] != null) {
      parts.add('${address!['road']} ${address!['house_number']}');
    } else if (address!['road'] != null) {
      parts.add(address!['road']);
    }
    
    if (address!['neighbourhood'] != null) {
      parts.add(address!['neighbourhood']);
    }
    
    if (address!['city'] != null) {
      parts.add(address!['city']);
    } else if (address!['town'] != null) {
      parts.add(address!['town']);
    }
    
    if (address!['state'] != null) {
      parts.add(address!['state']);
    }
    
    return parts.isNotEmpty ? parts.join(', ') : null;
  }
}
