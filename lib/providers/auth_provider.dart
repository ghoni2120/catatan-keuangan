import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/api_client.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';

enum AuthStatus {
  /// Memeriksa sesi tersimpan saat aplikasi dibuka.
  checking,

  /// Belum login (atau sesi sudah habis).
  unauthenticated,

  /// Sudah login.
  authenticated,

  /// Ada sesi tersimpan tetapi server tidak terjangkau (jangan paksa login ulang).
  unreachable,
}

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? service, ApiClient? api})
      : _service = service ?? AuthService(),
        _api = api ?? ApiClient.instance {
    _sessionSub = _api.onSessionExpired.listen((_) => _handleSessionExpired());
    init();
  }

  final AuthService _service;
  final ApiClient _api;
  StreamSubscription<void>? _sessionSub;

  AuthStatus _status = AuthStatus.checking;
  AuthUser? _user;
  String? _errorMessage;
  String? _notice;

  AuthStatus get status => _status;
  AuthUser? get user => _user;

  /// Pesan kegagalan saat status [AuthStatus.unreachable].
  String? get errorMessage => _errorMessage;

  /// Pesan informasi untuk layar login (mis. "Sesi berakhir").
  String? get notice => _notice;

  /// Memeriksa sesi tersimpan. Aman dipanggil ulang (tombol "Coba Lagi").
  Future<void> init() async {
    _status = AuthStatus.checking;
    _errorMessage = null;
    notifyListeners();
    try {
      final user = await _service.restoreSession();
      _user = user;
      _status = user == null ? AuthStatus.unauthenticated : AuthStatus.authenticated;
    } on ApiException catch (e) {
      _status = AuthStatus.unreachable;
      _errorMessage = e.message;
    }
    notifyListeners();
  }

  /// Melempar ApiException jika gagal (ditampilkan oleh layar login).
  Future<void> login({required String email, required String password}) async {
    final user = await _service.login(email: email, password: password);
    _startSession(user);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final user = await _service.register(name: name, email: email, password: password);
    _startSession(user);
  }

  Future<void> logout() async {
    await _service.logout();
    _user = null;
    _notice = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void _startSession(AuthUser user) {
    _user = user;
    _notice = null;
    _errorMessage = null;
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  void _handleSessionExpired() {
    if (_status != AuthStatus.authenticated) return;
    _user = null;
    _notice = 'Sesi Anda telah berakhir. Silakan login kembali.';
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  @override
  void dispose() {
    _sessionSub?.cancel();
    super.dispose();
  }
}