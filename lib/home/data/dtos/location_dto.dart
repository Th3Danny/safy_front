

import 'package:safy/home/domain/entities/location.dart';

class LocationDto {
  final double latitude;
  final double longitude;
  final String? address;
  final String? timestamp;

  LocationDto({
    required this.latitude,
    required this.longitude,
    this.address,
    this.timestamp,
  });

  factory LocationDto.fromJson(Map<String, dynamic> json) {
    return LocationDto(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      timestamp: json['timestamp'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      if (address != null) 'address': address,
      if (timestamp != null) 'timestamp': timestamp,
    };
  }

  Location toDomainEntity() {
    return Location(
      latitude: latitude,
      longitude: longitude,
      address: address,
      timestamp: timestamp != null ? DateTime.parse(timestamp!) : null,
    );
  }

  factory LocationDto.fromDomainEntity(Location entity) {
    return LocationDto(
      latitude: entity.latitude,
      longitude: entity.longitude,
      address: entity.address,
      timestamp: entity.timestamp.toIso8601String(),
    );
  }
}
