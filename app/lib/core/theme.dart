import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta "Sage & Linen"
class AppColors {
  static const sage = Color(0xFFAFC8B4); // Primary
  static const forest = Color(0xFF3E5F4D); // Secondary / CTA
  static const linen = Color(0xFFF4EBDD); // Fondo claro
  static const sand = Color(0xFFD8C7A6); // Acento cálido
  static const darkBg = Color(0xFF1A2421); // Fondo oscuro
  static const darkCard = Color(0xFF24322D);
}

class AppTheme {
  static TextTheme _textTheme(TextTheme base, Color color) {
    final body = GoogleFonts.interTextTheme(base).apply(
      bodyColor: color,
      displayColor: color,
    );
    TextStyle? heading(TextStyle? s) => GoogleFonts.nunito(textStyle: s, color: color);
    return body.copyWith(
      displayLarge: heading(body.displayLarge),
      displayMedium: heading(body.displayMedium),
      displaySmall: heading(body.displaySmall),
      headlineLarge: heading(body.headlineLarge),
      headlineMedium: heading(body.headlineMedium),
      headlineSmall: heading(body.headlineSmall),
      titleLarge: heading(body.titleLarge),
    );
  }

  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: AppColors.forest,
      onPrimary: Colors.white,
      secondary: AppColors.sage,
      onSecondary: AppColors.forest,
      tertiary: AppColors.sand,
      surface: Colors.white,
      onSurface: AppColors.forest,
    );
    final base = ThemeData(brightness: Brightness.light, useMaterial3: true);
    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.linen,
      textTheme: _textTheme(base.textTheme, AppColors.forest),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.linen,
        foregroundColor: AppColors.forest,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 1,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: _buttonTheme(AppColors.forest, Colors.white),
      inputDecorationTheme: _inputTheme(Colors.white),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.sage,
      ),
    );
  }

  static ThemeData get dark {
    const cream = AppColors.linen;
    const scheme = ColorScheme.dark(
      primary: AppColors.sage,
      onPrimary: AppColors.darkBg,
      secondary: AppColors.forest,
      onSecondary: cream,
      tertiary: AppColors.sand,
      surface: AppColors.darkCard,
      onSurface: cream,
    );
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.darkBg,
      textTheme: _textTheme(base.textTheme, cream),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBg,
        foregroundColor: cream,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: _buttonTheme(AppColors.sage, AppColors.darkBg),
      inputDecorationTheme: _inputTheme(AppColors.darkCard),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: AppColors.darkCard,
        indicatorColor: AppColors.forest,
      ),
    );
  }

  static ElevatedButtonThemeData _buttonTheme(Color bg, Color fg) =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      );

  static InputDecorationTheme _inputTheme(Color fill) => InputDecorationTheme(
        filled: true,
        fillColor: fill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      );
}
