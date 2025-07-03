import 'package:flutter/material.dart';

enum DangerLevel {
  low,
  medium,
  high,
  critical;

  String get displayName {
    switch (this) {
      case DangerLevel.low:
        return 'Bajo';
      case DangerLevel.medium:
        return 'Medio';
      case DangerLevel.high:
        return 'Alto';
      case DangerLevel.critical:
        return 'Crítico';
    }
  }

  Color get color {
    switch (this) {
      case DangerLevel.low:
        return Colors.yellow;
      case DangerLevel.medium:
        return Colors.orange;
      case DangerLevel.high:
        return Colors.red;
      case DangerLevel.critical:
        return Colors.purple;
    }
  }

  double get radius {
    switch (this) {
      case DangerLevel.low:
        return 15.0;
      case DangerLevel.medium:
        return 20.0;
      case DangerLevel.high:
        return 25.0;
      case DangerLevel.critical:
        return 30.0;
    }
  }
}
