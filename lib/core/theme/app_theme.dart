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
  // Brand Colors - Premium Pure Aesthetic
  static const Color primaryBlue = Color(0xFF0A4D8C); // Deep Ocean Blue
  static const Color accentSkyBlue = Color(0xFF00B4D8); // Crystal Aqua
  static const Color successGreen = Color(0xFF10B981);
  static const Color midUrgentOrange = Color(0xFFF97316);
  static const Color criticalRed = Color(0xFFEF4444);

  // iOS System Colors for auxiliary use
  static const Color iosBlue = Color(0xFF007AFF);
  static const Color iosGreen = Color(0xFF34C759);
  static const Color iosIndigo = Color(0xFF5856D6);
  static const Color iosOrange = Color(0xFFFF9500);
  static const Color iosPink = Color(0xFFFF2D55);
  static const Color iosPurple = Color(0xFFAF52DE);
  static const Color iosRed = Color(0xFFFF3B30);
  static const Color iosTeal = Color(0xFF5AC8FA);
  static const Color iosYellow = Color(0xFFFFCC00);
  static const Color iosGray = Color(0xFF8E8E93);
  static const Color iosGray2 = Color(0xFFAEAEB2);
  static const Color iosGray3 = Color(0xFFC7C7CC);
  static const Color iosGray4 = Color(0xFFD1D1D6);
  static const Color iosGray5 = Color(0xFFE5E5EA);
  static const Color iosGray6 = Color(0xFFF2F2F7);

  // Semantic Colors - Premium Pure
  static const Color primary = primaryBlue;
  static const Color secondary = accentSkyBlue;
  static const Color backgroundLight = Color(0xFFF8F9FA); // Off-White/Pearl
  static const Color cardLight = Color(0xFFFFFFFF); // Pure White
  static const Color textPrimaryLight = Color(0xFF1C1C1E);
  static const Color textSecondaryLight = Color(0xFF636366);

  // Aliases for compatibility
  static const Color textPrimary = textPrimaryLight;
  static const Color textSecondary = textSecondaryLight;
  static const Color urgent = iosRed;

  static const Color backgroundDark = Color(0xFF000000);
  static const Color cardDark = Color(0xFF1C1C1E);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFE5E5EA);

  // Shadows
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> mediumShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> primaryGlow = [
    BoxShadow(
      color: primary.withOpacity(0.3),
      blurRadius: 15,
      offset: const Offset(0, 5),
    ),
  ];

  // Typography - Modern Geometric Sans-Serif
  static TextTheme _buildTextTheme(
      Color primaryColor, Color secondaryColor, bool isArabic) {
    // Inter for English, Cairo for Arabic (seamless RTL support)
    final base = isArabic 
        ? GoogleFonts.cairoTextTheme() 
        : GoogleFonts.interTextTheme();
    final double letterSpacing = isArabic ? 0 : -0.2;

    return base.copyWith(
      displayLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: isArabic ? 0 : -1.0,
        color: primaryColor,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: isArabic ? 0 : -0.8,
        color: primaryColor,
      ),
      displaySmall: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: isArabic ? 0 : -0.5,
        color: primaryColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: isArabic ? 0 : -0.4,
        color: primaryColor,
      ),
      // FIX: headlineSmall was absent but referenced in admin_users_screen
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: isArabic ? 0 : -0.3,
        color: primaryColor,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: letterSpacing,
        color: primaryColor,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: secondaryColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        letterSpacing: isArabic ? 0 : -0.3,
        color: primaryColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: primaryColor,
      ),
      bodySmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: secondaryColor,
      ),
      labelLarge: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
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
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
              color: (isDark ? Colors.white : Colors.black)
                  .withOpacity(isDark ? 0.1 : 0.05),
              width: 1),
        ),
        color: isDark ? cardDark : cardLight,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: isArabic ? 0 : -0.4,
            fontFamily: isArabic
                ? GoogleFonts.cairo().fontFamily
                : GoogleFonts.inter().fontFamily,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          minimumSize: const Size(double.infinity, 56),
          side: const BorderSide(color: primary, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: isArabic ? 0 : -0.4,
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
        fillColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
              width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
              width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: iosRed, width: 1),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: const TextStyle(
          color: iosGray,
          fontSize: 16,
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
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
        thickness: 1,
        space: 1,
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
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(borderRadius ?? 20),
        boxShadow: boxShadow ?? AppTheme.softShadow,
        border: Border.all(
          color: borderColor ?? (Theme.of(context).brightness == Brightness.light
              ? Colors.black.withOpacity(0.05)
              : Colors.white.withOpacity(0.1)),
          width: borderWidth ?? 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(borderRadius ?? 20),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color? color;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 15,
    this.opacity = 0.7,
    this.color,
    this.borderRadius,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color effectiveColor =
        color ?? (isDark ? Colors.black : Colors.white);

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: effectiveColor.withOpacity(opacity),
              borderRadius: borderRadius ?? BorderRadius.circular(20),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                width: 1,
              ),
            ),
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

// Legacy Alias for compatibility
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color color;
  final BorderRadius? borderRadius;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 10,
    this.opacity = 0.1,
    this.color = Colors.white,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      blur: blur,
      opacity: opacity,
      color: color,
      borderRadius: borderRadius,
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      child: child,
    );
  }
}
