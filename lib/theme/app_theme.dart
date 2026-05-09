import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors - Ultra Premium
  static const Color primary = Color(0xFF10B981); // Emerald 500 (Vibrant & Trustworthy)
  static const Color primaryLight = Color(0xFF34D399); // Emerald 400
  static const Color primaryDark = Color(0xFF064E3B); // Emerald 900
  static const Color accent = Color(0xFF10B981); // Emerald 500
  
  // Neutral Colors - Modern Slate Palette
  static const Color textPrimary = Color(0xFF1B2E22); // Light mode text
  static const Color textSecondary = Color(0xFF4B6354); // Light mode secondary
  static const Color textMuted = Color(0xFF8BA694); 
  
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  
  // New Premium Dark Mode Palette (Slate Deep)
  static const Color backgroundDark = Color(0xFF020617); // Slate 950
  static const Color surfaceDark = Color(0xFF0F172A); // Slate 900
  static const Color borderDark = Color(0xFF1E293B); // Slate 800
  static const Color textPrimaryDark = Color(0xFFF8FAFC); // Slate 50
  static const Color textSecondaryDark = Color(0xFF94A3B8); // Slate 400
  
  static const Color divider = Color(0xFFE2E8F0); // Slate 200
  
  // Status Colors
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color info = Color(0xFF3B82F6); // Blue 500
  static const Color success = Color(0xFF10B981); // Emerald 500

  // Shape tokens
  static final BorderRadius radiusSmall = BorderRadius.circular(12);
  static final BorderRadius radiusMedium = BorderRadius.circular(20);
  static final BorderRadius radiusLarge = BorderRadius.circular(30);

  // Premium Shadows
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get deepShadow => [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.08),
      blurRadius: 40,
      offset: const Offset(0, 16),
      spreadRadius: -4,
    ),
  ];

  // Gradients
  static LinearGradient get primaryGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  static LinearGradient get darkGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
  );

  static BoxDecoration glassDecoration({bool isDark = false}) => BoxDecoration(
    color: isDark 
        ? const Color(0xFF1E293B).withValues(alpha: 0.7) 
        : Colors.white.withValues(alpha: 0.8),
    borderRadius: radiusMedium,
    border: Border.all(
      color: isDark 
          ? Colors.white.withValues(alpha: 0.08) 
          : const Color(0xFFE2E8F0).withValues(alpha: 0.5),
      width: 1,
    ),
  );

  // Transitions Theme
  static const PageTransitionsTheme _pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: ZoomPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
    },
  );

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Outfit',
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      secondary: accent,
      surface: surfaceLight,
      error: error,
    ),
    scaffoldBackgroundColor: backgroundLight,
    pageTransitionsTheme: _pageTransitions,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: textPrimary,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w900,
        color: textPrimary,
        letterSpacing: -1,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: radiusMedium,
        side: const BorderSide(color: Color(0xFFE8F5E9), width: 1.5), // Very light green border
      ),
      color: surfaceLight,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: radiusMedium),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.2),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: radiusMedium),
        side: const BorderSide(color: divider, width: 1.5),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: radiusMedium,
        borderSide: const BorderSide(color: divider, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radiusMedium,
        borderSide: const BorderSide(color: divider, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radiusMedium,
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      contentPadding: const EdgeInsets.all(20),
      hintStyle: const TextStyle(color: textMuted, fontSize: 14, fontWeight: FontWeight.w500),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 10,
      backgroundColor: primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: radiusMedium),
    ),
    dividerTheme: const DividerThemeData(color: divider, thickness: 1, space: 1),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      elevation: 0,
      backgroundColor: surfaceLight,
      selectedItemColor: primary,
      unselectedItemColor: textMuted,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Outfit',
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      primary: primary,
      onPrimary: Colors.white,
      secondary: primaryLight,
      surface: surfaceDark,
      error: const Color(0xFFF87171),
    ),
    scaffoldBackgroundColor: backgroundDark,
    pageTransitionsTheme: _pageTransitions,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: textPrimaryDark,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w900,
        color: textPrimaryDark,
        letterSpacing: -1,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: radiusMedium,
        side: const BorderSide(color: borderDark, width: 1.5),
      ),
      color: surfaceDark,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceDark,
      border: OutlineInputBorder(
        borderRadius: radiusMedium,
        borderSide: const BorderSide(color: borderDark, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radiusMedium,
        borderSide: const BorderSide(color: borderDark, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radiusMedium,
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      contentPadding: const EdgeInsets.all(20),
      hintStyle: const TextStyle(color: textSecondaryDark, fontSize: 14),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 10,
      backgroundColor: primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: radiusMedium),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: textPrimaryDark),
      bodyMedium: TextStyle(color: textSecondaryDark),
      titleLarge: TextStyle(color: textPrimaryDark),
    ),
  );
}
