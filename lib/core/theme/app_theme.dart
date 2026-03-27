import 'package:flutter/material.dart';


class GlucoraColors extends ThemeExtension<GlucoraColors> {
  final Color primary;      
  final Color primaryDark;  
  final Color accent;       
  final Color background;   
  final Color surface;      
  final Color textPrimary;  
  final Color textSecondary;
  final Color error;        
  final Color warning;      
  final Color success;      

  const GlucoraColors({
    required this.primary,
    required this.primaryDark,
    required this.accent,
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.error,
    required this.warning,
    required this.success,
  });

  @override
  ThemeExtension<GlucoraColors> copyWith({
    Color? primary,
    Color? primaryDark,
    Color? accent,
    Color? background,
    Color? surface,
    Color? textPrimary,
    Color? textSecondary,
    Color? error,
    Color? warning,
    Color? success,
  }) {
    return GlucoraColors(
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      accent: accent ?? this.accent,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      error: error ?? this.error,
      warning: warning ?? this.warning,
      success: success ?? this.success,
    );
  }

  @override
  ThemeExtension<GlucoraColors> lerp(covariant ThemeExtension<GlucoraColors>? other, double t) {
    if (other is! GlucoraColors) return this;
    return GlucoraColors(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      error: Color.lerp(error, other.error, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      success: Color.lerp(success, other.success, t)!,
    );
  }
}

final lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: const Color(0xFF199A8E),
  scaffoldBackgroundColor: const Color(0xFFF4F7FA),
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF199A8E),
    secondary: Color(0xFF2BB6A3),
    error: Color(0xFFEF1616),
    surface: Colors.white,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1A7A6E),
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  extensions: [
    const GlucoraColors(
      primary: Color(0xFF199A8E),
      primaryDark: Color(0xFF1A7A6E),
      accent: Color(0xFF2BB6A3),
      background: Color(0xFFF4F7FA),
      surface: Colors.white,
      textPrimary: Color(0xFF1A1A2E),
      textSecondary: Color(0xFF888888),
      error: Color(0xFFEF1616),
      warning: Color(0xFFFF9F40),
      success: Color(0xFF2BB6A3),
    ),
  ],
);

final darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: const Color(0xFF199A8E),
  scaffoldBackgroundColor: const Color(0xFF121212),
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF199A8E),
    secondary: Color(0xFF2BB6A3),
    error: Color(0xFFEF1616),
    surface: Color(0xFF1E1E1E),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF0F5E54), 
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  extensions: [
    const GlucoraColors(
      primary: Color(0xFF199A8E),
      primaryDark: Color(0xFF0F5E54),
      accent: Color(0xFF2BB6A3),
      background: Color(0xFF121212),
      surface: Color(0xFF1E1E1E),
      textPrimary: Color(0xFFF0F0F0),
      textSecondary: Color(0xFFA0A0A0),
      error: Color(0xFFEF1616),
      warning: Color(0xFFFF9F40),
      success: Color(0xFF2BB6A3),
    ),
  ],
);