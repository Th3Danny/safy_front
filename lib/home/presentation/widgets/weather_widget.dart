
import 'package:flutter/material.dart';


class WeatherWidget extends StatefulWidget {
  const WeatherWidget({super.key});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  // Datos simulados del clima
  final WeatherData _weatherData = WeatherData(
    temperature: 24,
    condition: WeatherCondition.partlyCloudy,
    humidity: 65,
    windSpeed: 12,
    location: 'Tuxtla Gutiérrez',
  );

  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: _getWeatherGradient(_weatherData.condition),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _isExpanded ? _buildExpandedWeather() : _buildCompactWeather(),
      ),
    );
  }

  Widget _buildCompactWeather() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _getWeatherIcon(_weatherData.condition),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_weatherData.temperature}°C',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _getConditionText(_weatherData.condition),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpandedWeather() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ubicación
        Row(
          children: [
            const Icon(Icons.location_on, color: Colors.white70, size: 16),
            const SizedBox(width: 4),
            Text(
              _weatherData.location,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Temperatura y condición principal
        Row(
          children: [
            _getWeatherIcon(_weatherData.condition),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_weatherData.temperature}°C',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getConditionText(_weatherData.condition),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Información adicional
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildWeatherDetail(
              Icons.water_drop,
              'Humedad',
              '${_weatherData.humidity}%',
            ),
            _buildWeatherDetail(
              Icons.air,
              'Viento',
              '${_weatherData.windSpeed} km/h',
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Consejo de seguridad basado en el clima
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                _getSafetyIcon(_weatherData.condition),
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getSafetyTip(_weatherData.condition),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherDetail(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _getWeatherIcon(WeatherCondition condition) {
    IconData iconData;
    switch (condition) {
      case WeatherCondition.sunny:
        iconData = Icons.wb_sunny;
        break;
      case WeatherCondition.partlyCloudy:
        iconData = Icons.wb_cloudy;
        break;
      case WeatherCondition.cloudy:
        iconData = Icons.cloud;
        break;
      case WeatherCondition.rainy:
        iconData = Icons.umbrella;
        break;
      case WeatherCondition.stormy:
        iconData = Icons.thunderstorm;
        break;
    }

    return Icon(
      iconData,
      color: Colors.white,
      size: _isExpanded ? 32 : 24,
    );
  }

  LinearGradient _getWeatherGradient(WeatherCondition condition) {
    List<Color> colors;
    switch (condition) {
      case WeatherCondition.sunny:
        colors = [Colors.orange.shade400, Colors.yellow.shade600];
        break;
      case WeatherCondition.partlyCloudy:
        colors = [Colors.blue.shade400, Colors.blue.shade600];
        break;
      case WeatherCondition.cloudy:
        colors = [Colors.grey.shade500, Colors.grey.shade700];
        break;
      case WeatherCondition.rainy:
        colors = [Colors.indigo.shade400, Colors.indigo.shade600];
        break;
      case WeatherCondition.stormy:
        colors = [Colors.purple.shade600, Colors.indigo.shade800];
        break;
    }

    return LinearGradient(
      colors: colors,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  String _getConditionText(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.sunny:
        return 'Soleado';
      case WeatherCondition.partlyCloudy:
        return 'Parcialmente nublado';
      case WeatherCondition.cloudy:
        return 'Nublado';
      case WeatherCondition.rainy:
        return 'Lluvioso';
      case WeatherCondition.stormy:
        return 'Tormenta';
    }
  }

  IconData _getSafetyIcon(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.sunny:
        return Icons.wb_sunny;
      case WeatherCondition.partlyCloudy:
      case WeatherCondition.cloudy:
        return Icons.info;
      case WeatherCondition.rainy:
      case WeatherCondition.stormy:
        return Icons.warning;
    }
  }

  String _getSafetyTip(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.sunny:
        return 'Buen día para caminar. Mantente hidratado.';
      case WeatherCondition.partlyCloudy:
        return 'Condiciones estables para cualquier transporte.';
      case WeatherCondition.cloudy:
        return 'Visibilidad reducida. Conduce con precaución.';
      case WeatherCondition.rainy:
        return 'Calles resbaladizas. Considera transporte cubierto.';
      case WeatherCondition.stormy:
        return '⚠️ Evita salir. Riesgo de clima severo.';
    }
  }
}

// Modelo de datos del clima
enum WeatherCondition {
  sunny,
  partlyCloudy,
  cloudy,
  rainy,
  stormy,
}

class WeatherData {
  final int temperature;
  final WeatherCondition condition;
  final int humidity;
  final int windSpeed;
  final String location;

  WeatherData({
    required this.temperature,
    required this.condition,
    required this.humidity,
    required this.windSpeed,
    required this.location,
  });
}