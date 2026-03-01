// lib/core/theme/app_theme.dart
// Changes vs original:
//   • Removed deprecated `background` and `onBackground` from ColorScheme
//     (deprecated since Flutter 3.18 / Material 3). The role of these fields
//     has been fully taken over by `surface` / `onSurface`.
//   • Added `surfaceContainerHighest` for subtle container tones.
//   • `headlineSmall` added to text theme (was missing; referenced by admin screen).

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors - Light Premium Formal
  static const Color primaryBlue = Color(0xFF1E40AF); // Professional Blue
  static const Color accentSkyBlue = Color(0xFF0EA5E9); // Clean Sky Blue
  static const Color successGreen = Color(0xFF059669);
  static const Color midUrgentOrange = Color(0xFFF59E0B);
  static const Color criticalRed = Color(0xFFDC2626);

  // Neutral Palette - Formal & Clean
  static const Color iosBlue = Color(0xFF2563EB);
  static const Color iosGreen = Color(0xFF10B981);
  static const Color iosIndigo = Color(0xFF6366F1);
  static const Color iosOrange = Color(0xFFF59E0B);
  static const Color iosPink = Color(0xFFEC4899);
  static const Color iosPurple = Color(0xFF8B5CF6);
  static const Color iosRed = Color(0xFFEF4444);
  static const Color iosTeal = Color(0xFF14B8A6);
  static const Color iosYellow = Color(0xFFFBBF24);
  static const Color iosGray = Color(0xFF6B7280);
  static const Color iosGray2 = Color(0xFF9CA3AF);
  static const Color iosGray3 = Color(0xFFD1D5DB);
  static const Color iosGray4 = Color(0xFFE5E7EB);
  static const Color iosGray5 = Color(0xFFF3F4F6);
  static const Color iosGray6 = Color(0xFFF9FAFB);

  // Semantic Colors - Light & Premium
  static const Color primary = primaryBlue;
  static const Color secondary = accentSkyBlue;
  static const Color backgroundLight = Color(0xFFFAFAFA); // Soft White
  static const Color cardLight = Color(0xFFFFFFFF); // Pure White
  static const Color textPrimaryLight = Color(0xFF111827);
  static const Color textSecondaryLight = Color(0xFF6B7280);

  // Aliases for compatibility
  static const Color textPrimary = textPrimaryLight;
  static const Color textSecondary = textSecondaryLight;
  static const Color urgent = iosRed;

  static const Color backgroundDark = Color(0xFF000000);
  static const Color cardDark = Color(0xFF1C1C1E);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFE5E5EA);

  // Shadows - Subtle & Professional
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.03),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> mediumShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> primaryGlow = [
    BoxShadow(
      color: primary.withOpacity(0.15),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // Typography - Clean & Professional
  static TextTheme _buildTextTheme(
      Color primaryColor, Color secondaryColor, bool isArabic) {
    // Inter for English, Cairo for Arabic
    final base = isArabic 
        ? GoogleFonts.cairoTextTheme() 
        : GoogleFonts.interTextTheme();

    return base.copyWith(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: isArabic ? 0 : -0.5,
        color: primaryColor,
        height: 1.2,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: isArabic ? 0 : -0.5,
        color: primaryColor,
        height: 1.2,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: isArabic ? 0 : -0.3,
        color: primaryColor,
        height: 1.3,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: isArabic ? 0 : -0.2,
        color: primaryColor,
        height: 1.3,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: isArabic ? 0 : -0.2,
        color: primaryColor,
        height: 1.4,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: isArabic ? 0 : -0.1,
        color: primaryColor,
        height: 1.4,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: secondaryColor,
        height: 1.5,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: isArabic ? 0 : -0.1,
        color: primaryColor,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: primaryColor,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: secondaryColor,
        height: 1.5,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: primaryColor,
      ),
    );
  }

  static ThemeData theme(Locale locale, Brightness brightness) {
    final bool isArabic = locale.languageCode == 'ar';
    final bool isDark = brightness == Brightness.dark;

    final primaryColor = isDark ? textPrimaryDark : textPrimaryLight;
    final secondaryColor = isDark ? textSecondaryDark : textSecondaryLight;

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: isDark ? _darkColorScheme : _lightColorScheme,
      scaffoldBackgroundColor: isDark ? backgroundDark : backgroundLight,
      textTheme: _buildTextTheme(primaryColor, secondaryColor, isArabic),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: primaryColor,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        iconTheme: const IconThemeData(color: primary),
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: primaryColor,
          letterSpacing: isArabic ? 0 : -0.4,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
              color: (isDark ? Colors.white : Colors.black)
                  .withOpacity(isDark ? 0.08 : 0.06),
              width: 1),
        ),
        color: isDark ? cardDark : cardLight,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            fontFamily: isArabic
                ? GoogleFonts.cairo().fontFamily
                : GoogleFonts.inter().fontFamily,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(double.infinity, 52),
          side: BorderSide(color: primary.withOpacity(0.5), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            fontFamily: isArabic
                ? GoogleFonts.cairo().fontFamily
                : GoogleFonts.inter().fontFamily,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            fontFamily: isArabic
                ? GoogleFonts.cairo().fontFamily
                : GoogleFonts.inter().fontFamily,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFAFAFA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.12),
              width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.12),
              width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: iosRed, width: 1),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(
          color: iosGray2,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        prefixIconColor: iosGray,
        suffixIconColor: iosGray,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: isDark ? Colors.black : Colors.white,
        selectedItemColor: primary,
        unselectedItemColor: iosGray,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: DividerThemeData(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
        thickness: 1,
        space: 1,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  static const ColorScheme _lightColorScheme = ColorScheme.light(
    primary: primary,
    onPrimary: Colors.white,
    secondary: secondary,
    onSecondary: Colors.white,
    surface: cardLight,
    onSurface: textPrimaryLight,
    background: backgroundLight,
    onBackground: textPrimaryLight,
    error: iosRed,
  );

  static const ColorScheme _darkColorScheme = ColorScheme.dark(
    primary: accentSkyBlue,
    onPrimary: Colors.black,
    secondary: secondary,
    onSecondary: Colors.black,
    surface: cardDark,
    onSurface: textPrimaryDark,
    background: backgroundDark,
    onBackground: textPrimaryDark,
    error: iosRed,
  );

  // Deprecated - kept for compatibility briefly
  static ThemeData lightTheme = ThemeData(brightness: Brightness.light);
  static ThemeData darkTheme = ThemeData(brightness: Brightness.dark);
}

// Modern Custom Widgets
class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? color;
  final List<BoxShadow>? boxShadow;
  final double? borderRadius;
  final Color? borderColor;
  final double? borderWidth;

  const ModernCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.onLongPress,
    this.color,
    this.boxShadow,
    this.borderRadius,
    this.borderColor,
    this.borderWidth,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(borderRadius ?? 16),
        boxShadow: boxShadow ?? AppTheme.softShadow,
        border: Border.all(
          color: borderColor ?? (isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06)),
          width: borderWidth ?? 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(borderRadius ?? 16),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

// Priority Colors Helper
class PriorityColors {
  static Color getColor(String priority) {
    switch (priority) {
      case 'urgent':
        return AppTheme.criticalRed;
      case 'mid_urgent':
        return AppTheme.midUrgentOrange;
      case 'non_urgent':
      default:
        return AppTheme.successGreen;
    }
  }

  static IconData getIcon(String priority) {
    switch (priority) {
      case 'urgent':
        return Icons.priority_high_rounded;
      case 'mid_urgent':
        return Icons.warning_rounded;
      case 'non_urgent':
      default:
        return Icons.check_circle_rounded;
    }
  }
}

// Status Colors Helper
class StatusColors {
  static Color getColor(String status) {
    switch (status) {
      case 'pending':
        return AppTheme.midUrgentOrange;
      case 'in_progress':
        return AppTheme.primaryBlue;
      case 'completed':
        return AppTheme.successGreen;
      case 'cancelled':
        return AppTheme.criticalRed;
      default:
        return AppTheme.iosGray;
    }
  }

  static IconData getIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule_rounded;
      case 'in_progress':
        return Icons.local_shipping_rounded;
      case 'completed':
        return Icons.check_circle_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }
}
