import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AppColors {
  // Warm Church Signature Palette
  static const Color primary = Color(0xFF8B1E3F); // Sacred Royal Burgundy
  static const Color primaryLight = Color(0xFFA83255); // Warm Crimson Rose
  static const Color primaryDark = Color(0xFF67112B); // Deep Velvet Wine

  static const Color secondary = Color(0xFFB45309); // Warm Sanctuary Bronze
  static const Color secondaryLight = Color(0xFFD97706); // Warm Golden Amber

  static const Color accent = Color(0xFFD97706); // Warm Golden Sanctuary Accent
  static const Color accentLight = Color(0xFFF59E0B); // Warm Radiant Gold

  static const Color sunset = Color(0xFFC2410C); // Warm Terracotta Sunset
  static const Color amber = Color(0xFFD97706); // Golden Warmth

  // Status Colors
  static const Color success = Color(0xFF15803D); // Warm Forest Emerald
  static const Color danger = Color(0xFFB91C1C); // Deep Crimson Red
  static const Color warning = Color(0xFFD97706); // Warm Amber Warning
  static const Color info = Color(0xFF1E3A8A); // Warm Sapphire Blue

  // Neutral Colors - Light Mode (Warm Linen / Ivory)
  static const Color bgLight = Color(0xFFFBF8F3);
  static const Color surfaceLight = Colors.white;
  static const Color cardLight = Colors.white;
  static const Color textPrimaryLight = Color(0xFF241B18); // Warm Deep Espresso
  static const Color textSecondaryLight = Color(0xFF6E6259); // Warm Slate Cocoa
  static const Color borderLight = Color(0xFFEBE3D8); // Warm Linen Border

  // Neutral Colors - OLED Dark Mode (Warm Sanctuary Dark)
  static const Color bgDark = Color(0xFF14100E);
  static const Color surfaceDark = Color(0xFF1E1714);
  static const Color cardDark = Color(0xFF27201C);
  static const Color textPrimaryDark = Color(0xFFFAF6F0); // Soft Warm Ivory
  static const Color textSecondaryDark = Color(0xFFA89E94); // Warm Sand Taupe
  static const Color borderDark = Color(0xFF3B312A); // Warm Dark Timber Border

  // Warm Sanctuary Linear Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF8B1E3F), Color(0xFFB43E51)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFB45309), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sunsetGradient = LinearGradient(
    colors: [Color(0xFF9E2A2B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [Color(0xFF15803D), Color(0xFF047857)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF27201C), Color(0xFF1E1714)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

enum AppStyleTheme {
  burgundy,
  figmaNeon,
  terracotta,
  emerald,
  midnight,
}

class AppThemeConfig {
  final AppStyleTheme style;
  final String name;
  final String badge;
  final String description;
  final IconData icon;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color bgLight;
  final Color bgDark;
  final LinearGradient gradient;

  const AppThemeConfig({
    required this.style,
    required this.name,
    required this.badge,
    required this.description,
    required this.icon,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.bgLight,
    required this.bgDark,
    required this.gradient,
  });
}

class AppThemePresets {
  static const Map<AppStyleTheme, AppThemeConfig> configs = {
    AppStyleTheme.burgundy: AppThemeConfig(
      style: AppStyleTheme.burgundy,
      name: "Sacred Burgundy",
      badge: "Dribbble Glass",
      description: "Sacred Royal Burgundy with Warm Sanctuary Amber & Glass",
      icon: LucideIcons.wine,
      primary: Color(0xFF8B1E3F),
      secondary: Color(0xFFB45309),
      accent: Color(0xFFD97706),
      bgLight: Color(0xFFFBF8F3),
      bgDark: Color(0xFF14100E),
      gradient: LinearGradient(colors: [Color(0xFF8B1E3F), Color(0xFFB43E51)]),
    ),
    AppStyleTheme.figmaNeon: AppThemeConfig(
      style: AppStyleTheme.figmaNeon,
      name: "Figma Cyber Neon",
      badge: "Figma Dark",
      description: "Electric Neon Cyan with Cyber Violet & Deep Space Navy",
      icon: LucideIcons.zap,
      primary: Color(0xFF00E5FF),
      secondary: Color(0xFF7C4DFF),
      accent: Color(0xFFFF007A),
      bgLight: Color(0xFFF0F4F8),
      bgDark: Color(0xFF0A0E1A),
      gradient: LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF)]),
    ),
    AppStyleTheme.terracotta: AppThemeConfig(
      style: AppStyleTheme.terracotta,
      name: "Terracotta Sunset",
      badge: "Dribbble Warmth",
      description: "Crimson Terracotta with Golden Amber & Warm Sand",
      icon: LucideIcons.sun,
      primary: Color(0xFFC2410C),
      secondary: Color(0xFFF59E0B),
      accent: Color(0xFFE11D48),
      bgLight: Color(0xFFFFFBEB),
      bgDark: Color(0xFF1C130E),
      gradient: LinearGradient(colors: [Color(0xFFC2410C), Color(0xFFF59E0B)]),
    ),
    AppStyleTheme.emerald: AppThemeConfig(
      style: AppStyleTheme.emerald,
      name: "Sanctuary Emerald",
      badge: "Figma Forest",
      description: "Royal Forest Emerald with Warm Mint & Sage",
      icon: LucideIcons.trees,
      primary: Color(0xFF047857),
      secondary: Color(0xFF10B981),
      accent: Color(0xFF059669),
      bgLight: Color(0xFFF0FDF4),
      bgDark: Color(0xFF061A14),
      gradient: LinearGradient(colors: [Color(0xFF047857), Color(0xFF10B981)]),
    ),
    AppStyleTheme.midnight: AppThemeConfig(
      style: AppStyleTheme.midnight,
      name: "Midnight Sapphire",
      badge: "Figma Royal",
      description: "Royal Sapphire Blue with Electric Indigo & Night Sky",
      icon: LucideIcons.moon,
      primary: Color(0xFF1E40AF),
      secondary: Color(0xFF6366F1),
      accent: Color(0xFF3B82F6),
      bgLight: Color(0xFFEFF6FF),
      bgDark: Color(0xFF0F172A),
      gradient: LinearGradient(colors: [Color(0xFF1E40AF), Color(0xFF6366F1)]),
    ),
  };
}

class AppTheme {
  static ThemeData getTheme(Brightness brightness, AppStyleTheme styleTheme) {
    final cfg = AppThemePresets.configs[styleTheme] ?? AppThemePresets.configs[AppStyleTheme.burgundy]!;
    final isDark = brightness == Brightness.dark;

    final primary = cfg.primary;
    final secondary = cfg.secondary;
    final bg = isDark ? cfg.bgDark : cfg.bgLight;
    final cardBg = isDark ? Color.alphaBlend(Colors.white.withValues(alpha: 0.05), cfg.bgDark) : Colors.white;
    final border = isDark ? Colors.white.withValues(alpha: 0.12) : primary.withValues(alpha: 0.15);
    final textPrimary = isDark ? const Color(0xFFFAF6F0) : const Color(0xFF241B18);
    final textSecondary = isDark ? const Color(0xFFA89E94) : const Color(0xFF6E6259);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: primary,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        secondary: secondary,
        surface: cardBg,
        error: AppColors.danger,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.outfitTextTheme(isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: textPrimary),
        titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: textPrimary),
        titleMedium: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge: GoogleFonts.inter(color: textPrimary),
        bodyMedium: GoogleFonts.inter(color: textSecondary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: primary.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),
    );
  }

  static ThemeData get lightTheme => getTheme(Brightness.light, AppStyleTheme.burgundy);
  static ThemeData get darkTheme => getTheme(Brightness.dark, AppStyleTheme.burgundy);
}

// BuildContext Helpers for Dynamic Theme Access
extension AppThemeContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  Color get primaryColor => Theme.of(this).primaryColor;
  Color get secondaryColor => Theme.of(this).colorScheme.secondary;
  Color get cardBgColor => Theme.of(this).cardTheme.color ?? Theme.of(this).colorScheme.surface;
  Color get textPrimaryColor => Theme.of(this).colorScheme.onSurface;
  Color get textSecondaryColor => Theme.of(this).textTheme.bodyMedium?.color ?? (Theme.of(this).brightness == Brightness.dark ? const Color(0xFFA89E94) : const Color(0xFF6E6259));
  Color get borderThemeColor => Theme.of(this).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.12) : Theme.of(this).primaryColor.withValues(alpha: 0.15);

  LinearGradient get activeGradient {
    return LinearGradient(
      colors: [primaryColor, secondaryColor],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}

// Custom Dribbble UI Widgets
class DribbbleGlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? borderColor;
  final Color? backgroundColor;
  final double blur;
  final VoidCallback? onTap;

  const DribbbleGlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20.0,
    this.borderColor,
    this.backgroundColor,
    this.blur = 15.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark
        ? Theme.of(context).cardTheme.color ?? const Color(0xFF1F2937).withValues(alpha: 0.6)
        : Colors.white.withValues(alpha: 0.85);
    final defaultBorder = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Theme.of(context).primaryColor.withValues(alpha: 0.15);

    Widget container = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          margin: margin,
          decoration: BoxDecoration(
            color: backgroundColor ?? defaultBg,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? defaultBorder,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Theme.of(context).primaryColor.withValues(alpha: 0.08),
                blurRadius: 20,
                spreadRadius: -4,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: container,
      );
    }
    return container;
  }
}

class DribbbleGlowButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final LinearGradient? gradient;
  final double height;
  final bool isLoading;

  const DribbbleGlowButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.gradient,
    this.height = 54.0,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveGradient = gradient ?? context.activeGradient;

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: effectiveGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: effectiveGradient.colors.first.withValues(alpha: 0.45),
            blurRadius: 18,
            spreadRadius: -2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        label,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class DribbblePillBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;

  const DribbblePillBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class DribbbleStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? trend;
  final bool isPositive;
  final IconData icon;
  final Color iconColor;
  final LinearGradient? gradient;
  final VoidCallback? onTap;

  const DribbbleStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.trend,
    this.isPositive = true,
    this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DribbbleGlassContainer(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: gradient ?? LinearGradient(
                    colors: [iconColor.withValues(alpha: 0.25), iconColor.withValues(alpha: 0.08)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: iconColor.withValues(alpha: 0.3), width: 1),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              if (trend != null)
                DribbblePillBadge(
                  label: trend!,
                  color: isPositive ? AppColors.success : AppColors.danger,
                  icon: isPositive ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: context.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class DribbbleSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;

  const DribbbleSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                      color: context.textPrimaryColor,
                    ),
                  ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: context.textSecondaryColor,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: Row(
              children: [
                Text(
                  actionLabel!,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(LucideIcons.chevronRight, size: 16, color: Theme.of(context).primaryColor),
              ],
            ),
          ),
      ],
    );
  }
}

class DribbbleAmbientBackground extends StatelessWidget {
  final Widget child;

  const DribbbleAmbientBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return Stack(
      children: [
        // Background color scaffold match
        Container(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        // Ambient glowing top right blob
        Positioned(
          top: -120,
          right: -100,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  primaryColor.withValues(alpha: isDark ? 0.22 : 0.15),
                  primaryColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        // Ambient glowing bottom left blob
        Positioned(
          bottom: -100,
          left: -80,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  secondaryColor.withValues(alpha: isDark ? 0.18 : 0.12),
                  secondaryColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        // Main Content
        child,
      ],
    );
  }
}


