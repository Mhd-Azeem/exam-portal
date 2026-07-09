import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'constants.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String role,
    required Map<String, dynamic> userData,
  }) async {
    await Future.wait([
      _storage.write(key: AppConstants.keyAccessToken, value: accessToken),
      _storage.write(key: AppConstants.keyRefreshToken, value: refreshToken),
      _storage.write(key: AppConstants.keyRole, value: role),
      _storage.write(key: AppConstants.keyUserData, value: jsonEncode(userData)),
    ]);
  }

  static Future<String?> getAccessToken() =>
      _storage.read(key: AppConstants.keyAccessToken);

  static Future<String?> getRefreshToken() =>
      _storage.read(key: AppConstants.keyRefreshToken);

  static Future<String?> getRole() =>
      _storage.read(key: AppConstants.keyRole);

  static Future<Map<String, dynamic>?> getUserData() async {
    final raw = await _storage.read(key: AppConstants.keyUserData);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<void> clearAll() => _storage.deleteAll();
}
