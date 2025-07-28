# 🔮 Endpoint de Predicciones de Zonas de Peligro

## Descripción
Este endpoint permite obtener predicciones de futuras zonas de peligro basadas en análisis de datos históricos y patrones de comportamiento.

## Endpoint
```
POST {{base_url}}/api/v1/predictions/predict
```

## Cuerpo de la Petición
```json
[
  {
    "latitude": 16.729091,
    "longitude": -93.164129,
    "timestamp": "2025-01-15T14:30:00"
  }
]
```

### Parámetros
- `latitude` (number): Latitud de la ubicación
- `longitude` (number): Longitud de la ubicación  
- `timestamp` (string): Timestamp en formato ISO 8601 para el cual se desea la predicción

## Respuesta
```json
[
  {
    "latitude": 16.7516,
    "longitude": -93.1166,
    "timestamp": "2025-01-18T20:00:00",
    "high_activity_risk": 0.06537463485052274,
    "predicted_crime_count": 38.13761994666688,
    "risk_level": "HIGH",
    "zone_id": 0,
    "model_version": "V2",
    "confidence_score": 0.85
  }
]
```

### Campos de Respuesta
- `latitude` (number): Latitud de la zona predicha
- `longitude` (number): Longitud de la zona predicha
- `timestamp` (string): Timestamp para el cual se hizo la predicción
- `high_activity_risk` (number): Probabilidad de actividad de riesgo (0-1)
- `predicted_crime_count` (number): Número estimado de crímenes
- `risk_level` (string): Nivel de riesgo ("LOW", "MEDIUM", "HIGH", "CRITICAL")
- `zone_id` (number): ID único de la zona
- `model_version` (string): Versión del modelo de predicción usado
- `confidence_score` (number): Nivel de confianza de la predicción (0-1)

## Implementación en Flutter

### 1. DTOs Creados
- `PredictionRequestDto`: Para enviar datos de ubicación y tiempo
- `PredictionResponseDto`: Para recibir las predicciones del servidor

### 2. Entidad de Dominio
- `Prediction`: Entidad que representa una predicción con métodos de negocio

### 3. Cliente API
- `PredictionApiClient`: Maneja las peticiones HTTP al endpoint

### 4. Repositorio
- `PredictionRepository`: Interfaz abstracta
- `PredictionRepositoryImpl`: Implementación con lógica de negocio

### 5. Caso de Uso
- `GetPredictionsUseCase`: Orquesta la obtención de predicciones

### 6. Mixin para ViewModel
- `PredictionsMixin`: Agrega funcionalidad de predicciones al MapViewModel

## Uso en la Aplicación

### Ejemplo Básico
```dart
// Obtener predicciones para una ubicación específica
await mapViewModel.loadPredictions(
  location: LatLng(16.729091, -93.164129),
  timestamp: DateTime.now().add(Duration(days: 3)),
);

// Verificar predicciones obtenidas
if (mapViewModel.predictions.isNotEmpty) {
  for (final prediction in mapViewModel.predictions) {
    print('Riesgo: ${prediction.riskLevel}');
    print('Confianza: ${prediction.confidenceScore}');
  }
}
```

### Ejemplo para Rutas
```dart
// Obtener predicciones para una ruta completa
await mapViewModel.loadPredictionsForRoute(
  waypoints: routePoints,
  estimatedArrivalTime: DateTime.now().add(Duration(hours: 2)),
);
```

### Filtros Disponibles
```dart
// Obtener predicciones críticas
final criticalPredictions = mapViewModel.criticalPredictions;

// Filtrar por nivel de riesgo
final highRiskPredictions = mapViewModel.getPredictionsByRiskLevel('HIGH');

// Filtrar por confiabilidad mínima
final reliablePredictions = mapViewModel.getPredictionsByConfidence(0.7);
```

## Integración con el Mapa

### Marcadores de Predicciones
Las predicciones se muestran como marcadores en el mapa con colores según el nivel de riesgo:
- 🟢 Verde: Riesgo bajo
- 🟡 Naranja: Riesgo medio  
- 🔴 Rojo: Riesgo alto
- 🟣 Púrpura: Riesgo crítico

### Widgets de Información
- `PredictionMarkerWidget`: Marcadores interactivos en el mapa
- `PredictionInfoCard`: Tarjeta con información detallada de la predicción
- `PredictionExampleWidget`: Widget de ejemplo para demostrar el uso

## Configuración

### 1. Agregar Dependencias
El endpoint ya está configurado en las constantes de la API:
```dart
static const String predictions = '/api/v1/predictions/predict';
```

### 2. Inyección de Dependencias
Las dependencias están registradas en `maps_injector.dart`:
```dart
// API Client
GetIt.instance.registerLazySingleton<PredictionApiClient>(
  () => PredictionApiClient(GetIt.instance<Dio>(instanceName: 'authenticated')),
);

// Repository
GetIt.instance.registerLazySingleton<PredictionRepository>(
  () => PredictionRepositoryImpl(GetIt.instance<PredictionApiClient>()),
);

// Use Case
GetIt.instance.registerLazySingleton<GetPredictionsUseCase>(
  () => GetPredictionsUseCase(GetIt.instance<PredictionRepository>()),
);
```

### 3. Integración con MapViewModel
El MapViewModel incluye el `PredictionsMixin` que proporciona:
- Carga de predicciones
- Gestión de marcadores
- Filtros y consultas
- Interfaz de usuario

## Casos de Uso

### 1. Predicción al Establecer Destino
Cuando el usuario establece un destino, automáticamente se obtienen predicciones para esa ubicación.

### 2. Predicciones de Ruta
Al calcular una ruta, se obtienen predicciones para todos los waypoints importantes.

### 3. Alertas Proactivas
Las predicciones críticas pueden generar alertas para el usuario.

### 4. Planificación de Viajes
Los usuarios pueden consultar predicciones para planificar viajes seguros.

## Manejo de Errores

### Errores de Red
- Timeout de conexión
- Errores de servidor
- Problemas de autenticación

### Errores de Datos
- Ubicaciones inválidas
- Timestamps malformados
- Respuestas inesperadas del servidor

## Logs y Debugging

El sistema incluye logs detallados para debugging:
```
[PredictionApiClient] 🔮 Obteniendo predicciones para: 16.729091, -93.164129
[PredictionApiClient] 📅 Timestamp: 2025-01-15T14:30:00
[PredictionApiClient] ✅ Respuesta recibida: 200
[PredictionRepository] ✅ Predicciones cargadas: 1
```

## Próximos Pasos

1. **Integración con Rutas**: Conectar predicciones con el cálculo de rutas seguras
2. **Notificaciones**: Alertas push para predicciones críticas
3. **Historial**: Guardar predicciones consultadas
4. **Personalización**: Ajustar predicciones según preferencias del usuario
5. **Machine Learning**: Mejorar modelos de predicción con feedback del usuario 