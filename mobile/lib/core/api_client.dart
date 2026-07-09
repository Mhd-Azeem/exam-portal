import 'package:dio/dio.dart';
import 'constants.dart';
import 'secure_storage.dart';

class ApiClient {
  static final Dio _dio = _buildDio();

  static Dio get dio => _dio;

  static Dio _buildDio() {
    final dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBase,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));
    dio.interceptors.add(_AuthInterceptor(dio));
    return dio;
  }

  // Convenience wrappers
  static Future<Response> get(String path, {Map<String, dynamic>? params}) =>
      _dio.get(path, queryParameters: params);

  static Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  static Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);

  static Future<Response> delete(String path) => _dio.delete(path);

  static Future<Response> postFormData(String path, FormData data) =>
      _dio.post(path, data: data, options: Options(contentType: 'multipart/form-data'));
}

class _AuthInterceptor extends Interceptor {
  final Dio _dio;
  bool _isRefreshing = false;

  _AuthInterceptor(this._dio);

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await SecureStorageService.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshToken = await SecureStorageService.getRefreshToken();
        if (refreshToken == null) {
          await _handleLogout(handler, err);
          return;
        }
        // Attempt token refresh using a fresh Dio to avoid interceptor loop
        final refreshDio = Dio(BaseOptions(baseUrl: AppConstants.apiBase));
        final refreshResp = await refreshDio.post(
          '/auth/refresh',
          options: Options(headers: {'Authorization': 'Bearer $refreshToken'}),
        );
        final newToken = refreshResp.data['access_token'] as String;
        // Persist new access token (keep existing refresh token)
        final role = await SecureStorageService.getRole();
        final userData = await SecureStorageService.getUserData();
        await SecureStorageService.saveTokens(
          accessToken: newToken,
          refreshToken: refreshToken,
          role: role ?? '',
          userData: userData ?? {},
        );
        // Retry the original request with the new token
        err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        final retryResponse = await _dio.fetch(err.requestOptions);
        handler.resolve(retryResponse);
      } catch (_) {
        await _handleLogout(handler, err);
      } finally {
        _isRefreshing = false;
      }
    } else {
      handler.next(err);
    }
  }

  Future<void> _handleLogout(
      ErrorInterceptorHandler handler, DioException err) async {
    await SecureStorageService.clearAll();
    handler.next(err);
  }
}
