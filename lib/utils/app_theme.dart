import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.surface,
      primaryColor: AppColors.primary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.danger,
        background: AppColors.surface,
      ),
      // Typography mapping
      textTheme: GoogleFonts.nunitoTextTheme().copyWith(
        displayLarge: GoogleFonts.sora(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.sora(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        displaySmall: GoogleFonts.sora(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        headlineLarge: GoogleFonts.sora(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        headlineMedium: GoogleFonts.sora(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        headlineSmall: GoogleFonts.sora(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        titleLarge: GoogleFonts.sora(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.sora(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        titleSmall: GoogleFonts.sora(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.nunito(color: AppColors.textPrimary),
        bodyMedium: GoogleFonts.nunito(color: AppColors.textPrimary),
        bodySmall: GoogleFonts.nunito(color: AppColors.textSecondary),
        labelLarge: GoogleFonts.nunito(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        labelMedium: GoogleFonts.nunito(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        labelSmall: GoogleFonts.nunito(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: GoogleFonts.sora(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceCard,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF121212),
      primaryColor: AppColors.primary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: const Color(0xFF1E1E1E),
        error: AppColors.danger,
        background: const Color(0xFF121212),
      ),
      // Typography mapping
      textTheme: GoogleFonts.nunitoTextTheme().copyWith(
        displayLarge: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.bold),
        displaySmall: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.w600),
        headlineLarge: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.w600),
        headlineMedium: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.w600),
        headlineSmall: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.w600),
        titleLarge: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.w600),
        titleSmall: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.nunito(color: Colors.white),
        bodyMedium: GoogleFonts.nunito(color: Colors.white),
        bodySmall: GoogleFonts.nunito(color: Colors.white70),
        labelLarge: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w600),
        labelMedium: GoogleFonts.nunito(color: Colors.white70, fontWeight: FontWeight.w500),
        labelSmall: GoogleFonts.nunito(color: Colors.white70, fontWeight: FontWeight.w500),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.sora(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
