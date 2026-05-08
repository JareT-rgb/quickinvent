import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_shell.dart';
import 'splash_screen.dart';
import '../repositories/auth_repository.dart';
import '../screens/login_screen.dart';

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    // Si estamos mostrando el splash, lo devolvemos primero
    if (_showSplash) {
      return SplashScreen(
        onFinish: () => setState(() => _showSplash = false),
      );
    }

    // Una vez terminado el splash, verificamos la autenticación
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          return const AppShell();
        }
        return const LoginScreen();
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        body: Center(child: Text('Error: $err')),
      ),
    );
  }
}