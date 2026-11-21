import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const sage = Color(0xFFAFC8B4);
  static const forest = Color(0xFF3E5F4D);
  static const cream = Color(0xFFF4EBDD);
  static const sand = Color(0xFFD8C7A6);
  static const darkBg = Color(0xFF1A2421);
  static const darkCard = Color(0xFF24332D);
}

class AppTheme {
  // Títulos en Nunito, cuerpo en Inter.
  static TextTheme _textTheme(Color color) {
    final base = ThemeData.light().textTheme;

    TextStyle? heading(TextStyle? s) =>
        GoogleFonts.nunito(textStyle: s, fontWeight: FontWeight.w700, color: color);
    TextStyle? body(TextStyle? s) => GoogleFonts.inter(textStyle: s, color: color);

    return TextTheme(
      displayLarge: heading(base.displayLarge),
      displayMedium: heading(base.displayMedium),
      displaySmall: heading(base.displaySmall),
      headlineLarge: heading(base.headlineLarge),
      headlineMedium: heading(base.headlineMedium),
      headlineSmall: heading(base.headlineSmall),
      titleLarge: heading(base.titleLarge),
      titleMedium: heading(base.titleMedium),
      titleSmall: body(base.titleSmall),
      bodyLarge: body(base.bodyLarge),
      bodyMedium: body(base.bodyMedium),
      bodySmall: body(base.bodySmall),
      labelLarge: body(base.labelLarge),
      labelMedium: body(base.labelMedium),
      labelSmall: body(base.labelSmall),
    );
  }

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color card,
    required Color text,
    required Color primary,
    required Color onPrimary,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.forest,
      brightness: brightness,
    ).copyWith(
      primary: primary,
      onPrimary: onPrimary,
      secondary: AppColors.sage,
      surface: card,
      onSurface: text,
    );

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: AppColors.sage.withValues(alpha: 0.6)),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      textTheme: _textTheme(text),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: primary, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
    );
  }

  static ThemeData light() => _build(
        brightness: Brightness.light,
        background: AppColors.cream,
        card: Colors.white,
        text: AppColors.forest,
        primary: AppColors.forest,
        onPrimary: AppColors.cream,
      );

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        background: AppColors.darkBg,
        card: AppColors.darkCard,
        text: AppColors.cream,
        primary: AppColors.sage,
        onPrimary: AppColors.darkBg,
      );
}