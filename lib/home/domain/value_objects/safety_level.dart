import 'package:flutter/material.dart';

class SafetyLevel {
  final double percentage;
  final String description;

  SafetyLevel({
    required this.percentage,
    required this.description,
  }) : assert(percentage >= 0 && percentage <= 100);

  factory SafetyLevel.safe() => SafetyLevel(percentage: 85, description: 'Segura');
  factory SafetyLevel.moderate() => SafetyLevel(percentage: 65, description: 'Moderada');
  factory SafetyLevel.dangerous() => SafetyLevel(percentage: 30, description: 'Peligrosa');

  Color get color {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  bool get isSafe => percentage >= 70;
}
