enum TransportMode {
  walking,
  driving,
  publicTransport;

  String get displayName {
    switch (this) {
      case TransportMode.walking:
        return 'Caminar';
      case TransportMode.driving:
        return 'Auto';
      case TransportMode.publicTransport:
        return 'Transporte público';
    }
  }

  double get averageSpeedKmh {
    switch (this) {
      case TransportMode.walking:
        return 5.0;
      case TransportMode.driving:
        return 40.0;
      case TransportMode.publicTransport:
        return 25.0;
    }
  }

  String get apiIdentifier {
    switch (this) {
      case TransportMode.walking:
        return 'walk';
      case TransportMode.driving:
        return 'car';
      case TransportMode.publicTransport:
        return 'bus';
    }
  }

  static TransportMode fromString(String value) {
    switch (value) {
      case 'walk':
        return TransportMode.walking;
      case 'car':
        return TransportMode.driving;
      case 'bus':
        return TransportMode.publicTransport;
      default:
        return TransportMode.walking;
    }
  }
}
