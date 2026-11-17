import 'package:flutter/material.dart';

import '../services/api_exception.dart';

bool _apiBusy = false;

/// Menjalankan aksi yang memanggil API (simpan, hapus, transfer, dst.).
///
///  - menampilkan spinner yang memblokir layar selama proses berjalan, sehingga
///    ketukan ganda tidak membuat data ganda;
///  - jika gagal, menampilkan pesan error dari server di SnackBar;
///  - mengembalikan true jika berhasil, false jika gagal.
///
/// Contoh:
///   final ok = await runApi(context, () => provider.addWallet(wallet));
///   if (ok && mounted) Navigator.pop(context);
Future<bool> runApi(BuildContext context, Future<void> Function() action) async {
  if (_apiBusy) return false;
  _apiBusy = true;

  final navigator = Navigator.of(context, rootNavigator: true);
  final messenger = ScaffoldMessenger.of(context);

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) => const PopScope(
      canPop: false,
      child: Center(child: CircularProgressIndicator()),
    ),
  );

  try {
    await action();
    return true;
  } on ApiException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
    return false;
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Terjadi kesalahan tak terduga. Coba lagi.')),
    );
    return false;
  } finally {
    // Jika sesi habis, AuthGate sudah menutup semua halaman (termasuk spinner ini).
    if (navigator.canPop()) navigator.pop();
    _apiBusy = false;
  }
}
