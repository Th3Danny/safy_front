class PredictionRequestDto {
  final double latitude;
  final double longitude;
  final String timestamp;

  PredictionRequestDto({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  factory PredictionRequestDto.fromJson(Map<String, dynamic> json) {
    return PredictionRequestDto(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: json['timestamp'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
    };
  }

  @override
  String toString() {
    return 'PredictionRequestDto(latitude: $latitude, longitude: $longitude, timestamp: $timestamp)';
  }
}
