class AppConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://azeemmhd1105.pythonanywhere.com',
  );
  static const String apiBase = '$baseUrl/api';

  // Secure storage keys
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyRole = 'role';
  static const String keyUserId = 'user_id';
  static const String keyUserData = 'user_data';

  // Grade colours (hex strings used in theme)
  static const Map<String, int> gradeColors = {
    'A': 0xFF065F46,
    'B': 0xFF1E40AF,
    'C': 0xFF713F12,
    'S': 0xFF9A3412,
    'F': 0xFF991B1B,
  };
  static const Map<String, int> gradeBgColors = {
    'A': 0xFFD1FAE5,
    'B': 0xFFDBEAFE,
    'C': 0xFFFEF9C3,
    'S': 0xFFFED7AA,
    'F': 0xFFFEE2E2,
  };
}
