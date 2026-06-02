import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const primary = Color(0xFF2563EB);
  static const primaryDark = Color(0xFF3B82F6);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);

  static const double md = 16.0;

  static const radiusSm = BorderRadius.all(Radius.circular(8));
  static const radiusMd = BorderRadius.all(Radius.circular(12));
  static const radiusXl = BorderRadius.all(Radius.circular(24));

  static const cardShadow = [
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      surface: Colors.white,
      error: error,
    ),
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    textTheme: GoogleFonts.interTextTheme(),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF0F172A),
      elevation: 0,
      shadowColor: Color(0x14000000),
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: Color(0xFF0F172A),
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
    ),
    extensions: const [AppColors.light],
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryDark,
      brightness: Brightness.dark,
      primary: primaryDark,
      surface: const Color(0xFF1E293B),
      error: error,
    ),
    scaffoldBackgroundColor: const Color(0xFF0F172A),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E293B),
      foregroundColor: Color(0xFFF1F5F9),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: Color(0xFFF1F5F9),
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E293B),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF334155)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    extensions: const [AppColors.dark],
  );
}

class AppColors extends ThemeExtension<AppColors> {
  final Color success;
  final Color warning;
  final Color border;
  final Color textSecondary;
  final Color cardBackground;

  const AppColors({
    required this.success,
    required this.warning,
    required this.border,
    required this.textSecondary,
    required this.cardBackground,
  });

  static const light = AppColors(
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
    border: Color(0xFFE2E8F0),
    textSecondary: Color(0xFF64748B),
    cardBackground: Colors.white,
  );

  static const dark = AppColors(
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    border: Color(0xFF334155),
    textSecondary: Color(0xFF94A3B8),
    cardBackground: Color(0xFF1E293B),
  );

  @override
  AppColors copyWith({
    Color? success,
    Color? warning,
    Color? border,
    Color? textSecondary,
    Color? cardBackground,
  }) => AppColors(
    success: success ?? this.success,
    warning: warning ?? this.warning,
    border: border ?? this.border,
    textSecondary: textSecondary ?? this.textSecondary,
    cardBackground: cardBackground ?? this.cardBackground,
  );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      border: Color.lerp(border, other.border, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
    );
  }
}
