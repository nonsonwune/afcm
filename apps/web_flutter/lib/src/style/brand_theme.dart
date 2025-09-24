import 'package:flutter/material.dart';

/// Centralised design tokens for the minimal AFCM brand treatment.
class AfcmTheme {
  AfcmTheme._();

  static const Color _slate950 = Color(0xFF0F172A);
  static const Color _slate900 = Color(0xFF111827);
  static const Color _slate700 = Color(0xFF334155);
  static const Color _slate500 = Color(0xFF64748B);
  static const Color _slate200 = Color(0xFFE2E8F0);
  static const Color _slate100 = Color(0xFFF1F5F9);
  static const Color _white = Colors.white;
  static const Color _azure500 = Color(0xFF2563EB);
  static const Color _azure400 = Color(0xFF3B82F6);
  static const Color _sand100 = Color(0xFFFDF6EC);
  static const Color _sand400 = Color(0xFFF97316);

  /// Light mode theme for the marketing experience.
  static ThemeData light() {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: _azure500,
      brightness: Brightness.light,
    );
    final colorScheme = baseScheme.copyWith(
      primary: _azure500,
      secondary: _slate900,
      surface: _white,
      surfaceContainerHighest: _slate100,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      textTheme: _textTheme,
      cardTheme: CardThemeData(
        color: _white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData.fromDefaults(
        primaryColor: _azure500,
        secondaryColor: _slate100,
        labelStyle: const TextStyle(fontWeight: FontWeight.w500),
      ).copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        selectedColor: _azure500.withOpacity(0.12),
        labelPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          backgroundColor: _azure500,
          foregroundColor: _white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: _slate900,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: const DividerThemeData(color: _slate200),
      listTileTheme: const ListTileThemeData(
        iconColor: _slate700,
        textColor: _slate900,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _white,
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: _slate200),
          borderRadius: BorderRadius.circular(16),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: _azure400, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: const TextStyle(color: _slate500),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _slate900,
        contentTextStyle: const TextStyle(color: _white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      extensions: <ThemeExtension<dynamic>>[
        AfcmPalette(
          heroBackground: _sand100,
          heroAccent: _sand400,
          subtleCard: _slate100,
        ),
      ],
    );
  }

  /// Dark theme keeps legibility minimal while mirroring key tokens.
  static ThemeData dark() {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: _azure400,
      brightness: Brightness.dark,
    );
    final colorScheme = baseScheme.copyWith(
      primary: _azure400,
      secondary: _slate200,
      surface: _slate900,
      surfaceContainerHighest: _slate900,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _slate950,
      textTheme: _textTheme.apply(bodyColor: _slate100, displayColor: _white),
      cardTheme: CardThemeData(
        color: _slate900,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      chipTheme: ChipThemeData.fromDefaults(
        primaryColor: _azure400,
        secondaryColor: _slate700,
        labelStyle: const TextStyle(fontWeight: FontWeight.w500),
      ).copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        selectedColor: _azure400.withOpacity(0.2),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          backgroundColor: _azure400,
          foregroundColor: _white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: _white,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme:
          DividerThemeData(color: _slate700.withOpacity(0.6)),
      listTileTheme: const ListTileThemeData(
        iconColor: _slate200,
        textColor: _slate100,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _slate900,
        border: OutlineInputBorder(
        borderSide: BorderSide(color: _slate700.withOpacity(0.7)),
          borderRadius: BorderRadius.circular(16),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: _azure400, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: TextStyle(color: _slate500.withOpacity(0.9)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _slate900,
        contentTextStyle: const TextStyle(color: _white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      extensions: <ThemeExtension<dynamic>>[
        AfcmPalette(
          heroBackground: _slate900,
          heroAccent: _azure500.withOpacity(0.25),
          subtleCard: _slate900,
        ),
      ],
    );
  }

  static const TextTheme _textTheme = TextTheme(
    displayLarge: TextStyle(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    ),
    headlineLarge: TextStyle(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
    ),
    headlineMedium: TextStyle(
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
    ),
    headlineSmall: TextStyle(
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
    ),
    titleLarge: TextStyle(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    ),
    titleMedium: TextStyle(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
    ),
    titleSmall: TextStyle(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    ),
    bodyLarge: TextStyle(
      fontWeight: FontWeight.w400,
      letterSpacing: 0.15,
    ),
    bodyMedium: TextStyle(
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
    ),
    bodySmall: TextStyle(
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
    ),
    labelLarge: TextStyle(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    ),
    labelMedium: TextStyle(
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
    labelSmall: TextStyle(
      fontWeight: FontWeight.w500,
      letterSpacing: 0.6,
    ),
  );
}

/// Extra palette values that are convenient to query from widgets.
class AfcmPalette extends ThemeExtension<AfcmPalette> {
  const AfcmPalette({
    required this.heroBackground,
    required this.heroAccent,
    required this.subtleCard,
  });

  final Color heroBackground;
  final Color heroAccent;
  final Color subtleCard;

  @override
  AfcmPalette copyWith({
    Color? heroBackground,
    Color? heroAccent,
    Color? subtleCard,
  }) {
    return AfcmPalette(
      heroBackground: heroBackground ?? this.heroBackground,
      heroAccent: heroAccent ?? this.heroAccent,
      subtleCard: subtleCard ?? this.subtleCard,
    );
  }

  @override
  AfcmPalette lerp(ThemeExtension<AfcmPalette>? other, double t) {
    if (other is! AfcmPalette) return this;
    return AfcmPalette(
      heroBackground: Color.lerp(heroBackground, other.heroBackground, t)!,
      heroAccent: Color.lerp(heroAccent, other.heroAccent, t)!,
      subtleCard: Color.lerp(subtleCard, other.subtleCard, t)!,
    );
  }
}

extension AfcmThemeExtras on ThemeData {
  AfcmPalette get palette => extension<AfcmPalette>()!;
}
