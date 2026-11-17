import 'api_client.dart';
import 'api_exception.dart';

class AuthUser {
  const AuthUser({required this.id, required this.name, required this.email});

  final String id;
  final String name;
  final String email;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
      );
}

class AuthService {
  AuthService({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await _api.post(
      '/auth/register',
      body: {'name': name, 'email': email, 'password': password},
      auth: false,
    );
    return _startSession(res.data as Map<String, dynamic>);
  }

  Future<AuthUser> login({required String email, required String password}) async {
    final res = await _api.post(
      '/auth/login',
      body: {'email': email, 'password': password},
      auth: false,
    );
    return _startSession(res.data as Map<String, dynamic>);
  }

  /// Dipanggil saat aplikasi dibuka. Mengembalikan user jika sesi masih valid,
  /// null jika harus login ulang. Melempar ApiException hanya jika server tidak terjangkau.
  Future<AuthUser?> restoreSession() async {
    if (!await _api.hasSession()) return null;
    try {
      final res = await _api.get('/auth/me');
      return AuthUser.fromJson(res.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.isAuthError) return null;
      rethrow;
    }
  }

  Future<void> logout() async {
    final refreshToken = await _api.readRefreshToken();
    try {
      if (refreshToken != null) {
        await _api.post('/auth/logout', body: {'refreshToken': refreshToken}, auth: false);
      }
    } on ApiException {
      // Server tidak terjangkau: tetap keluar di perangkat ini.
    } finally {
      await _api.clearSession();
    }
  }

  Future<AuthUser> _startSession(Map<String, dynamic> data) async {
    await _api.setSession(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
    return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
  }
}