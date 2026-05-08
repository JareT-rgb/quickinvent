import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class AuthRepository {
  final sb.SupabaseClient _client = sb.Supabase.instance.client;
  final _controller = StreamController<User?>.broadcast();

  AuthRepository() {
    // Escuchar todos los cambios de auth de Supabase y re-emitir
    _client.auth.onAuthStateChange.listen((event) {
      final u = event.session?.user;
      _controller.add(u != null ? User(email: u.email) : null);
    });
  }

  /// Emite el usuario actual inmediatamente y luego continúa escuchando cambios.
  Stream<User?> get authStateChanges async* {
    yield currentUser;
    yield* _controller.stream;
  }

  User? get currentUser {
    final u = _client.auth.currentUser;
    return u != null ? User(email: u.email) : null;
  }

  Future<void> signInWithEmail(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    // Forzar emisión inmediata para que AuthGate reconstruya sin depender
    // exclusivamente de onAuthStateChange.
    final u = response.user;
    _controller.add(u != null ? User(email: u.email) : null);
  }

  Future<void> signUpWithEmail(
    String email,
    String password, {
    String? fullName,
  }) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      data: fullName != null ? {'full_name': fullName} : null,
    );
    // Intentar iniciar sesión automáticamente después del registro.
    // Esto funciona si la "Confirmación de email" está desactivada en Supabase.
    // Si está activada, signInWithPassword lanzará un error que se mostrará en la UI.
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final u = response.user;
      _controller.add(u != null ? User(email: u.email) : null);
    } catch (e) {
      // Si falla el login automático, emitimos el estado actual
      // (probablemente null si la sesión no se creó).
      _controller.add(currentUser);
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> updateUserPassword(String newPassword) async {
    await _client.auth.updateUser(sb.UserAttributes(password: newPassword));
  }
}

class User {
  final String? email;
  User({this.email});
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});
