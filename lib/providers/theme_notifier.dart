import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gestiona el estado del tema de la aplicación (claro, oscuro o sistema)
/// y persiste la selección del usuario.
class ThemeNotifier extends Notifier<ThemeMode> {
  late final SharedPreferences _prefs;
  static const _themeKey = 'themeMode';

  @override
  ThemeMode build() {
    // El método build es responsable de crear el estado inicial.
    // Obtenemos la instancia de SharedPreferences aquí.
    _prefs = ref.watch(sharedPreferencesProvider);
    final themeIndex = _prefs.getInt(_themeKey);
    // Si no hay un tema guardado, se usa el del sistema por defecto.
    return ThemeMode.values[themeIndex ?? ThemeMode.system.index];
  }

  /// Actualiza el tema de la aplicación y guarda la preferencia.
  Future<void> setThemeMode(ThemeMode themeMode) async {
    if (state != themeMode) {
      state = themeMode;
      await _prefs.setInt(_themeKey, themeMode.index);
    }
  }
}

/// Provider para acceder al [ThemeNotifier] y su estado.
final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);

/// Provider que expone si el tema actual es oscuro.
final isDarkModeProvider = Provider<bool>((ref) => ref.watch(themeProvider) == ThemeMode.dark);

/// Provider que expone la instancia de [SharedPreferences].
/// Debe ser anulado (overridden) en el `ProviderScope` al iniciar la app.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());
