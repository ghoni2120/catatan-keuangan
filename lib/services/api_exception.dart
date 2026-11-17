/// Error dari API atau jaringan. [message] sudah berbahasa Indonesia dan siap
/// ditampilkan langsung ke pengguna (SnackBar / dialog).
class ApiException implements Exception {
  ApiException({this.statusCode, required this.message, this.errors = const []});

  /// null = tidak ada respons dari server (jaringan putus / timeout).
  final int? statusCode;
  final String message;
  final List<dynamic> errors;

  bool get isNetworkError => statusCode == null;
  bool get isAuthError => statusCode == 401;

  @override
  String toString() => message;
}