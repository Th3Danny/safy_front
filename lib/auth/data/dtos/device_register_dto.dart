class DeviceRegisterDto {
  final String fcmToken;
  final String deviceType;
  final double latitude;
  final double longitude;

  const DeviceRegisterDto({
    required this.fcmToken,
    required this.deviceType,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() => {
    'fcm_token': fcmToken,
    'device_type': deviceType,
    'latitude': latitude,
    'longitude': longitude,
  };

  @override
  String toString() =>
      'DeviceRegisterDto(fcmToken: $fcmToken, deviceType: $deviceType, latitude: $latitude, longitude: $longitude)';
}
