import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'auth_screen.dart';
import 'main_navigation_screen.dart';

/// Penjaga halaman: menentukan layar yang tampil berdasarkan status login.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    switch (auth.status) {
      case AuthStatus.checking:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.unreachable:
        return _UnreachableView(
          message: auth.errorMessage ?? 'Server tidak dapat dijangkau.',
          onRetry: auth.init,
          onLogout: auth.logout,
        );
      case AuthStatus.unauthenticated:
        // Jika sesi berakhir saat halaman lain sedang terbuka, tutup semuanya
        // agar layar login benar-benar terlihat.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) Navigator.of(context).popUntil((route) => route.isFirst);
        });
        return const AuthScreen();
      case AuthStatus.authenticated:
        return const MainNavigationScreen();
    }
  }
}

class _UnreachableView extends StatelessWidget {
  const _UnreachableView({
    required this.message,
    required this.onRetry,
    required this.onLogout,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off, size: 64, color: theme.hintColor),
                const SizedBox(height: 16),
                Text(
                  'Tidak dapat terhubung',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.hintColor),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                ),
                const SizedBox(height: 8),
                TextButton(onPressed: onLogout, child: const Text('Keluar dari akun')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}