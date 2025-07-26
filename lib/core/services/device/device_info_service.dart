import 'dart:io';
import 'package:flutter/foundation.dart';

class DeviceInfoService {
  static final DeviceInfoService _instance = DeviceInfoService._internal();
  factory DeviceInfoService() => _instance;
  DeviceInfoService._internal();

  /// Obtiene el tipo de dispositivo como string
  String getDeviceType() {
    if (kIsWeb) {
      return 'WEB';
    } else if (Platform.isAndroid) {
      return 'ANDROID';
    } else if (Platform.isIOS) {
      return 'IOS';
    } else if (Platform.isLinux) {
      return 'LINUX';
    } else if (Platform.isMacOS) {
      return 'MACOS';
    } else if (Platform.isWindows) {
      return 'WINDOWS';
    } else {
      return 'UNKNOWN';
    }
  }

  /// Verifica si es un dispositivo móvil
  bool get isMobile {
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Verifica si es Android
  bool get isAndroid {
    return Platform.isAndroid;
  }

  /// Verifica si es iOS
  bool get isIOS {
    return Platform.isIOS;
  }
}
