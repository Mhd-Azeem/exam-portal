import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../core/secure_storage.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String? role;
  final Map<String, dynamic>? user;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.role,
    this.user,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? role,
    Map<String, dynamic>? user,
    String? error,
  }) =>
      AuthState(
        status: status ?? this.status,
        role: role ?? this.role,
        user: user ?? this.user,
        error: error,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _checkStoredSession();
  }

  Future<void> _checkStoredSession() async {
    final token = await SecureStorageService.getAccessToken();
    final role = await SecureStorageService.getRole();
    final user = await SecureStorageService.getUserData();
    if (token != null && role != null) {
      state = AuthState(status: AuthStatus.authenticated, role: role, user: user);
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String username, String password) async {
    state = state.copyWith(status: AuthStatus.unknown, error: null);
    try {
      final resp = await ApiClient.post('/auth/login', data: {
        'username': username,
        'password': password,
      });
      final data = resp.data as Map<String, dynamic>;
      await SecureStorageService.saveTokens(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
        role: data['role'] as String,
        userData: data['user'] as Map<String, dynamic>,
      );
      state = AuthState(
        status: AuthStatus.authenticated,
        role: data['role'] as String,
        user: data['user'] as Map<String, dynamic>,
      );
    } on Exception catch (e) {
      String msg = 'Login failed. Check credentials.';
      if (e.toString().contains('401')) msg = 'Invalid username or password.';
      state = AuthState(status: AuthStatus.unauthenticated, error: msg);
    }
  }

  Future<void> logout() async {
    await SecureStorageService.clearAll();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (_) => AuthNotifier(),
);
