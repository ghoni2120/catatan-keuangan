import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/app_config.dart';
import 'api_exception.dart';
import 'token_storage.dart';

class ApiResponse {
  const ApiResponse({this.data, this.meta, this.message = ''});

  /// Isi field "data" dari respons backend.
  final dynamic data;

  /// Isi field "meta" (pagination), bila ada.
  final Map<String, dynamic>? meta;
  final String message;
}

/// Klien HTTP tunggal untuk seluruh aplikasi.
///  - menambahkan header Authorization otomatis
///  - jika server menjawab 401, token diperbarui lalu request diulang SEKALI
///  - jika banyak request gagal 401 bersamaan, refresh hanya dilakukan SATU kali
///    (penting: backend mencabut seluruh sesi bila refresh token lama dipakai ulang)
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  final http.Client _http = http.Client();
  final TokenStorage _tokens = TokenStorage();

  Future<bool>? _refreshing;
  final StreamController<void> _sessionExpired = StreamController<void>.broadcast();

  /// Terpancar saat sesi benar-benar habis (refresh token ditolak server).
  /// Dengarkan ini untuk mengembalikan pengguna ke layar login.
  Stream<void> get onSessionExpired => _sessionExpired.stream;

  // ------------------------------------------------------------ sesi

  Future<bool> hasSession() async => (await _tokens.readRefresh()) != null;
  Future<String?> readRefreshToken() => _tokens.readRefresh();

  Future<void> setSession({required String accessToken, required String refreshToken}) =>
      _tokens.save(access: accessToken, refresh: refreshToken);

  Future<void> clearSession() => _tokens.clear();

  // ------------------------------------------------------------ HTTP

  Future<ApiResponse> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  Future<ApiResponse> post(String path, {Object? body, bool auth = true}) =>
      _send('POST', path, body: body, auth: auth);

  Future<ApiResponse> put(String path, {Object? body}) => _send('PUT', path, body: body);

  Future<ApiResponse> patch(String path, {Object? body}) => _send('PATCH', path, body: body);

  Future<ApiResponse> delete(String path, {Map<String, String>? query}) =>
      _send('DELETE', path, query: query);

  // ------------------------------------------------------------ internal

  Future<ApiResponse> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    bool auth = true,
    bool canRetry = true,
  }) async {
    final uri = Uri.parse('${AppConfig.baseUrl}$path')
        .replace(queryParameters: (query == null || query.isEmpty) ? null : query);

    final String? accessUsed = auth ? await _tokens.readAccess() : null;
    final response = await _execute(method, uri, body, accessUsed);

    if (response.statusCode == 401 && auth && canRetry) {
      // Mungkin request lain sudah memperbarui token saat request ini berjalan
      final current = await _tokens.readAccess();
      var recovered = current != null && current != accessUsed;
      if (!recovered) recovered = await _refreshTokens();

      if (recovered) {
        return _send(method, path, query: query, body: body, auth: auth, canRetry: false);
      }
      _sessionExpired.add(null);
      throw ApiException(statusCode: 401, message: 'Sesi berakhir, silakan login kembali');
    }
    return _parse(response);
  }

  Future<http.Response> _execute(
    String method,
    Uri uri,
    Object? body,
    String? accessToken,
  ) async {
    final request = http.Request(method, uri);
    request.headers['Accept'] = 'application/json';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    if (accessToken != null) request.headers['Authorization'] = 'Bearer $accessToken';

    try {
      final streamed = await _http.send(request).timeout(AppConfig.requestTimeout);
      return await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw ApiException(message: 'Server tidak merespons. Coba lagi beberapa saat.');
    } catch (_) {
      throw ApiException(
        message: 'Tidak dapat terhubung ke server. Periksa koneksi internet dan pastikan backend berjalan.',
      );
    }
  }

  ApiResponse _parse(http.Response res) {
    Map<String, dynamic>? json;
    try {
      final decoded = res.body.isEmpty ? null : jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) json = decoded;
    } catch (_) {
      json = null;
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return ApiResponse(
        data: json?['data'],
        meta: json?['meta'] as Map<String, dynamic>?,
        message: (json?['message'] as String?) ?? '',
      );
    }

    throw ApiException(
      statusCode: res.statusCode,
      message: (json?['message'] as String?) ?? 'Terjadi kesalahan (${res.statusCode})',
      errors: (json?['errors'] as List<dynamic>?) ?? const [],
    );
  }

  /// Satu proses refresh untuk semua request yang menunggu.
  Future<bool> _refreshTokens() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<bool> _doRefresh() async {
    final refreshToken = await _tokens.readRefresh();
    if (refreshToken == null) return false;
    try {
      final res = await _send(
        'POST',
        '/auth/refresh',
        body: {'refreshToken': refreshToken},
        auth: false,
      );
      final data = res.data as Map<String, dynamic>;
      await _tokens.save(
        access: data['accessToken'] as String,
        refresh: data['refreshToken'] as String,
      );
      return true;
    } on ApiException catch (e) {
      if (e.isAuthError) {
        await _tokens.clear(); // refresh token ditolak: sesi memang sudah habis
        return false;
      }
      rethrow; // jaringan putus / server error: JANGAN mengeluarkan pengguna
    }
  }
}