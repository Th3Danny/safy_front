import 'package:safy/report/domain/value_objects/danger_zone_radius_calculator.dart';

/// Ejemplo de uso de la calculadora de radio de zonas de peligro
class DangerZoneExample {
  /// Ejemplo de cómo usar la calculadora con datos reales del servidor
  static void demonstrateRadiusCalculation() {
    // Datos del ejemplo que proporcionaste
    final averageSeverity = 3.0;
    final maxSeverity = 5;
    final reportCount = 13;
    final riskLevel = "CRITICAL";
    final clusterType = "HIGH_ACTIVITY";

    print('=== Ejemplo de Cálculo de Radio de Zona de Peligro ===');
    print('Datos del cluster:');
    print('- Severidad promedio: $averageSeverity');
    print('- Severidad máxima: $maxSeverity');
    print('- Cantidad de reportes: $reportCount');
    print('- Nivel de riesgo: $riskLevel');
    print('- Tipo de cluster: $clusterType');
    print('');

    // Calcular radio usando diferentes métodos
    final severityRadius = DangerZoneRadiusCalculator.calculateRadius(
      averageSeverity: averageSeverity,
      maxSeverity: maxSeverity,
      reportCount: reportCount,
    );

    final riskRadius = DangerZoneRadiusCalculator.calculateRadiusByRiskLevel(
      riskLevel: riskLevel,
      reportCount: reportCount,
    );

    final clusterRadius =
        DangerZoneRadiusCalculator.calculateRadiusByClusterType(
          clusterType: clusterType,
          averageSeverity: averageSeverity,
          reportCount: reportCount,
        );

    final recommendedRadius =
        DangerZoneRadiusCalculator.calculateRecommendedRadius(
          averageSeverity: averageSeverity,
          maxSeverity: maxSeverity,
          reportCount: reportCount,
          riskLevel: riskLevel,
          clusterType: clusterType,
        );

    print('Resultados:');
    print('- Radio por severidad: ${severityRadius.toStringAsFixed(1)} metros');
    print(
      '- Radio por nivel de riesgo: ${riskRadius.toStringAsFixed(1)} metros',
    );
    print(
      '- Radio por tipo de cluster: ${clusterRadius.toStringAsFixed(1)} metros',
    );
    print(
      '- Radio recomendado: ${recommendedRadius['radius'].toStringAsFixed(1)} metros',
    );
    print('- Color de zona: ${recommendedRadius['color']}');
    print('- Opacidad: ${recommendedRadius['opacity'].toStringAsFixed(2)}');
    print(
      '- Grosor del borde: ${recommendedRadius['borderWidth'].toStringAsFixed(1)} píxeles',
    );
    print('');

    // Mostrar interpretación
    _interpretRadius(recommendedRadius['radius'] as double);
  }

  /// Interpreta el radio calculado
  static void _interpretRadius(double radius) {
    print('Interpretación del radio:');
    if (radius >= 400) {
      print(
        '🔴 ZONA MUY PELIGROSA - Radio de ${radius.toStringAsFixed(0)} metros',
      );
      print('   - Evitar completamente esta área');
      print('   - Usar rutas alternativas');
      print('   - Reportar inmediatamente cualquier incidente');
    } else if (radius >= 300) {
      print(
        '🟠 ZONA DE ALTO PELIGRO - Radio de ${radius.toStringAsFixed(0)} metros',
      );
      print('   - Extremar precauciones');
      print('   - Mantener alerta constante');
      print('   - Evitar transitar solo');
    } else if (radius >= 200) {
      print(
        '🟡 ZONA DE PELIGRO MEDIO - Radio de ${radius.toStringAsFixed(0)} metros',
      );
      print('   - Mantener precauciones normales');
      print('   - Estar atento al entorno');
      print('   - Reportar actividades sospechosas');
    } else if (radius >= 100) {
      print(
        '🟢 ZONA DE BAJO PELIGRO - Radio de ${radius.toStringAsFixed(0)} metros',
      );
      print('   - Precauciones mínimas');
      print('   - Mantener vigilancia básica');
    } else {
      print(
        '🔵 ZONA DE MUY BAJO PELIGRO - Radio de ${radius.toStringAsFixed(0)} metros',
      );
      print('   - Área relativamente segura');
      print('   - Precauciones normales de la ciudad');
    }
  }

  /// Ejemplo de cómo integrar con datos reales del servidor
  static Map<String, dynamic> processClusterData(
    Map<String, dynamic> clusterData,
  ) {
    // Extraer datos del cluster
    final averageSeverity = clusterData['average_severity'] as double? ?? 0.0;
    final maxSeverity = clusterData['max_severity'] as int? ?? 0;
    final reportCount = clusterData['report_count'] as int? ?? 0;
    final riskLevel = clusterData['risk_level'] as String? ?? 'LOW';
    final clusterType = clusterData['cluster_type'] as String? ?? 'UNKNOWN';

    // Calcular radio recomendado
    final radiusInfo = DangerZoneRadiusCalculator.calculateRecommendedRadius(
      averageSeverity: averageSeverity,
      maxSeverity: maxSeverity,
      reportCount: reportCount,
      riskLevel: riskLevel,
      clusterType: clusterType,
    );

    // Agregar información del radio al cluster
    return {
      ...clusterData,
      'calculated_radius': radiusInfo['radius'],
      'zone_color': radiusInfo['color'],
      'zone_opacity': radiusInfo['opacity'],
      'border_width': radiusInfo['borderWidth'],
    };
  }
}
