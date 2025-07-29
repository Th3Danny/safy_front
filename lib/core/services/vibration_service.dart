import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Servicio para manejar vibraciones y feedback háptico
class VibrationService {
  static final VibrationService _instance = VibrationService._internal();
  factory VibrationService() => _instance;
  VibrationService._internal();

  bool _hasVibrator = false;
  bool get hasVibrator => _hasVibrator;

  /// Inicializar el servicio de vibración
  Future<void> init() async {
    try {
      _hasVibrator = true; // Asumir que está disponible
      // Removed debug print
    } catch (e) {
      // Removed debug print
      _hasVibrator = false;
    }
  }

  /// Vibración de alerta de zona peligrosa
  Future<void> dangerZoneAlert() async {
    if (!_hasVibrator) return;

    try {
      // Patrón de vibración: 3 vibraciones de impacto fuerte
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 200));
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 200));
      HapticFeedback.heavyImpact();
      // Removed debug print
    } catch (e) {
      // Removed debug print
    }
  }

  /// Vibración de notificación normal
  Future<void> notificationVibrate() async {
    if (!_hasVibrator) return;

    try {
      // Vibración simple de notificación
      HapticFeedback.lightImpact();
      // Removed debug print
    } catch (e) {
      // Removed debug print
    }
  }

  /// Vibración de confirmación
  Future<void> confirmVibrate() async {
    if (!_hasVibrator) return;

    try {
      // Vibración corta de confirmación
      HapticFeedback.selectionClick();
      // Removed debug print
    } catch (e) {
      // Removed debug print
    }
  }

  /// Vibración de error
  Future<void> errorVibrate() async {
    if (!_hasVibrator) return;

    try {
      // Patrón de vibración de error: 2 vibraciones largas
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 300));
      HapticFeedback.heavyImpact();
      // Removed debug print
    } catch (e) {
      // Removed debug print
    }
  }

  /// Vibración de GPS falso detectado
  Future<void> gpsSpoofingAlert() async {
    if (!_hasVibrator) return;

    try {
      // Patrón de vibración específico para GPS falso
      HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      HapticFeedback.mediumImpact();
      // Removed debug print
    } catch (e) {
      // Removed debug print
    }
  }

  /// Detener vibración actual
  Future<void> stopVibration() async {
    if (!_hasVibrator) return;

    try {
      // flutter_vibrate no tiene método de cancel, pero podemos simular
      // Removed debug print
    } catch (e) {
      // Removed debug print
    }
  }
}
