class ApiConstants {
  
  static const String baseUrl = 'https://1eb39063c03b.ngrok-free.app'; 
  
  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String profile = '/auth/profile';

  // 🔧 CORREGIR ENDPOINTS DE REPORTS
  static const String reports = '/reports'; 
  static const String createReport = '/reports'; 
  static const String nearbyReports = '/reports/nearby';

  // Map endpoints
  static const String heatmap = '/map/heatmap';
  static const String safeRoutes = '/map/safe-routes';

  // Headers
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Timeouts
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
  static const int sendTimeout = 30000;

  // Storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String isFirstTimeKey = 'is_first_time';
}