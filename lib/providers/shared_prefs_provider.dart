import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized Provider for SharedPreferences to avoid UnimplementedErrors
/// when multiple files define the same provider name.
/// 
/// This MUST be overridden in ProviderScope in main.dart.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in main.dart');
});
