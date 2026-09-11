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

  // Behance Creative Brand Palette
  static const Color behanceBlue = Color(0xFF0057FF); // Iconic Behance Royal Blue
  static const Color behanceCobalt = Color(0xFF0038FF); // Creative Deep Cobalt
  static const Color behanceDark = Color(0xFF090D18); // Portfolio Showcase Dark
  static const Color behanceSurfaceDark = Color(0xFF111625); // Gallery Obsidian Card
  static const Color behanceBorderDark = Color(0xFF1E273D); // Clean Hairline Border
  static const Color behanceCoral = Color(0xFFFF5A36); // Creative Coral Tangerine
  static const Color behanceCyan = Color(0xFF00C7FF); // Vibrant Cyan Highlight
  static const Color behanceCanvasLight = Color(0xFFF3F5FA); // Studio Canvas
  static const Color behanceSurfaceLight = Colors.white;

  // Figma Creative Design Tokens
  static const Color figmaViolet = Color(0xFFA259FF); // Figma Signature Purple
  static const Color figmaCyan = Color(0xFF1ABCFE); // Figma Vector Blue
  static const Color figmaGreen = Color(0xFF0ACF83); // Figma Component Green
  static const Color figmaCoral = Color(0xFFF24E1E); // Figma Accent Red-Orange
  static const Color figmaObsidian = Color(0xFF1E1E1E); // Figma Canvas Charcoal

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
  guardiansGold,
  burgundy,
  figmaNeon,
  terracotta,
  emerald,
  midnight,
  paleGoldOlive,
  behance,
  behanceFigma,
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
    AppStyleTheme.guardiansGold: AppThemeConfig(
      style: AppStyleTheme.guardiansGold,
      name: "Guardians Gold & White",
      badge: "Signature Flagship",
      description: "Crisp White Canvas with Radiant Sanctuary Gold & Subtle Shadow Elevators",
      icon: LucideIcons.crown,
      primary: Color(0xFFC79540),
      secondary: Color(0xFFE5BC6A),
      accent: Color(0xFFD4AF37),
      bgLight: Color(0xFFF9FAFC),
      bgDark: Color(0xFF10131B),
      gradient: LinearGradient(
        colors: [Color(0xFFE5BC6A), Color(0xFFC79540)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    ),
    AppStyleTheme.burgundy: AppThemeConfig(
      style: AppStyleTheme.burgundy,
      name: "Sacred Burgundy",
      badge: "Sanctuary Glass",
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
      badge: "Studio Warmth",
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
    AppStyleTheme.paleGoldOlive: AppThemeConfig(
      style: AppStyleTheme.paleGoldOlive,
      name: "Pale Gold & Olive",
      badge: "Sanctuary Classic",
      description: "Warm Pale Gold with Deep Dark Olive & Parchment",
      icon: LucideIcons.wheat,
      primary: Color(0xFFB8994A),
      secondary: Color(0xFF4A5220),
      accent: Color(0xFFF2DE9B),
      bgLight: Color(0xFFFAF6E8),
      bgDark: Color(0xFF202216),
      gradient: LinearGradient(
        colors: [Color(0xFF8A6F2E), Color(0xFFB8994A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    AppStyleTheme.behance: AppThemeConfig(
      style: AppStyleTheme.behance,
      name: "Behance Creative",
      badge: "Behance Pro",
      description: "Iconic Behance Royal Blue with Electric Cobalt & Creative Gallery Glass",
      icon: LucideIcons.palette,
      primary: Color(0xFF0057FF),
      secondary: Color(0xFF0038FF),
      accent: Color(0xFFFF5A36),
      bgLight: Color(0xFFF3F5FA),
      bgDark: Color(0xFF090D18),
      gradient: LinearGradient(
        colors: [Color(0xFF0057FF), Color(0xFF0091FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    AppStyleTheme.behanceFigma: AppThemeConfig(
      style: AppStyleTheme.behanceFigma,
      name: "Behance x Figma",
      badge: "Studio Pro",
      description: "Behance Electric Blue fused with Figma Purple, Cyan & Studio Tokens",
      icon: LucideIcons.layers,
      primary: Color(0xFF0057FF),
      secondary: Color(0xFFA259FF),
      accent: Color(0xFF1ABCFE),
      bgLight: Color(0xFFF5F5FA),
      bgDark: Color(0xFF0C0E14),
      gradient: LinearGradient(
        colors: [Color(0xFF0057FF), Color(0xFFA259FF), Color(0xFF1ABCFE)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  };
}

class AppTheme {
  static ThemeData getTheme(Brightness brightness, AppStyleTheme styleTheme) {
    final cfg = AppThemePresets.configs[styleTheme] ?? AppThemePresets.configs[AppStyleTheme.guardiansGold]!;
    final isDark = brightness == Brightness.dark;

    final primary = cfg.primary;
    final secondary = cfg.secondary;
    final bg = isDark ? cfg.bgDark : cfg.bgLight;
    final cardBg = isDark ? Color.alphaBlend(Colors.white.withValues(alpha: 0.05), cfg.bgDark) : Colors.white;
    final border = isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? const Color(0xFFFAF6F0) : const Color(0xFF1E2432);
    final textSecondary = isDark ? const Color(0xFFA89E94) : const Color(0xFF6B7280);

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
        onPrimary: const Color(0xFF161208),
        onSecondary: const Color(0xFF161208),
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
          side: BorderSide(color: border, width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: const Color(0xFF161208),
          elevation: 4,
          shadowColor: primary.withValues(alpha: 0.35),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),
    );
  }

  static ThemeData get lightTheme => getTheme(Brightness.light, AppStyleTheme.guardiansGold);
  static ThemeData get darkTheme => getTheme(Brightness.dark, AppStyleTheme.guardiansGold);
}

// BuildContext Helpers for Dynamic Theme Access
extension AppThemeContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  Color get primaryColor => Theme.of(this).primaryColor;
  Color get secondaryColor => Theme.of(this).colorScheme.secondary;
  Color get cardBgColor => Theme.of(this).cardTheme.color ?? Theme.of(this).colorScheme.surface;
  Color get textPrimaryColor => Theme.of(this).colorScheme.onSurface;
  Color get textSecondaryColor => Theme.of(this).textTheme.bodyMedium?.color ?? (Theme.of(this).brightness == Brightness.dark ? const Color(0xFFA89E94) : const Color(0xFF6B7280));
  Color get borderThemeColor => Theme.of(this).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0);

  LinearGradient get activeGradient {
    return LinearGradient(
      colors: [secondaryColor, primaryColor],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }
}

// ==========================================
// Behance & Figma Creative Architecture Suite
// ==========================================

class BehanceGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? borderColor;
  final Color? backgroundColor;
  final double blur;
  final VoidCallback? onTap;

  const BehanceGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16.0,
    this.borderColor,
    this.backgroundColor,
    this.blur = 0.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark
        ? (Theme.of(context).cardTheme.color ?? const Color(0xFF111625)).withValues(alpha: 0.82)
        : Colors.white;
    final defaultBorder = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : const Color(0xFFE2E8F0);

    final boxDecoration = BoxDecoration(
      color: backgroundColor ?? defaultBg,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? defaultBorder,
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.35)
              : Colors.black.withValues(alpha: 0.03),
          blurRadius: 10,
          spreadRadius: 0,
          offset: const Offset(0, 3),
        ),
      ],
    );

    Widget content = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: boxDecoration,
      child: child,
    );

    Widget container;
    if (blur > 0) {
      container = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: content,
        ),
      );
    } else {
      container = content;
    }

    if (margin != null) {
      container = Padding(padding: margin!, child: container);
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: container,
      );
    }
    return container;
  }
}

class BehanceActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final LinearGradient? gradient;
  final double height;
  final bool isLoading;

  const BehanceActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.gradient,
    this.height = 52.0,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveGradient = gradient ?? context.activeGradient;
    final isGold = effectiveGradient.colors.contains(const Color(0xFFC79540)) ||
        effectiveGradient.colors.contains(const Color(0xFFE5BC6A));
    final textColor = isGold ? const Color(0xFF161208) : Colors.white;
    final radius = height / 2;

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: effectiveGradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: effectiveGradient.colors.last.withValues(alpha: 0.35),
            blurRadius: 16,
            spreadRadius: -1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(radius),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: textColor, strokeWidth: 2.5),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, color: textColor, size: 19),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            label,
                            maxLines: 1,
                            style: GoogleFonts.outfit(
                              fontSize: 15.0,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class BehancePillBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;

  const BehancePillBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.32), width: 0.9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.9,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class BehanceStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? trend;
  final bool isPositive;
  final IconData icon;
  final Color iconColor;
  final LinearGradient? gradient;
  final VoidCallback? onTap;

  const BehanceStatCard({
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
    return BehanceGlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: gradient ?? LinearGradient(
                    colors: [iconColor.withValues(alpha: 0.22), iconColor.withValues(alpha: 0.06)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: iconColor.withValues(alpha: 0.28), width: 0.9),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              if (trend != null)
                BehancePillBadge(
                  label: trend!,
                  color: isPositive ? AppColors.success : AppColors.danger,
                  icon: isPositive ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.4,
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: context.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class BehanceSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;

  const BehanceSectionHeader({
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
                    Icon(icon, size: 19, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                        color: context.textPrimaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            ),
            child: Row(
              children: [
                Text(
                  actionLabel!,
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(LucideIcons.chevronRight, size: 15, color: Theme.of(context).primaryColor),
              ],
            ),
          ),
      ],
    );
  }
}

class BehanceAmbientBackground extends StatelessWidget {
  final Widget child;

  const BehanceAmbientBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    if (!isDark) {
      return Stack(
        children: [
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          // Top right subtle luminous glow
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primaryColor.withValues(alpha: 0.08),
                    primaryColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          // Mid-left subtle ambient aura
          Positioned(
            top: 200,
            left: -120,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    secondaryColor.withValues(alpha: 0.06),
                    secondaryColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          // Bottom right soft radiant reflection
          Positioned(
            bottom: -90,
            right: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primaryColor.withValues(alpha: 0.05),
                    primaryColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          child,
        ],
      );
    }

    return Stack(
      children: [
        Container(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        // Top right primary glow
        Positioned(
          top: -100,
          right: -80,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  primaryColor.withValues(alpha: 0.24),
                  primaryColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        // Mid-left secondary aura
        Positioned(
          top: 180,
          left: -120,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  secondaryColor.withValues(alpha: 0.18),
                  secondaryColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        // Bottom right subtle pulse
        Positioned(
          bottom: -80,
          right: -60,
          child: Container(
            width: 290,
            height: 290,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  primaryColor.withValues(alpha: 0.15),
                  primaryColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class FigmaBentoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? borderColor;
  final Color? backgroundColor;
  final LinearGradient? gradient;
  final VoidCallback? onTap;

  const FigmaBentoCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 18.0,
    this.borderColor,
    this.backgroundColor,
    this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark
        ? const Color(0xFF101422)
        : Colors.white;
    final defaultBorder = isDark
        ? Colors.white.withValues(alpha: 0.09)
        : const Color(0xFFE2E8F0);

    Widget content = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: gradient == null ? (backgroundColor ?? defaultBg) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? defaultBorder,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.30)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: content,
        ),
      );
    }
    return content;
  }
}

// Backward Compatibility Aliases for Legacy Dribbble Names
typedef DribbbleGlassContainer = BehanceGlassCard;
typedef DribbbleGlowButton = BehanceActionButton;
typedef DribbblePillBadge = BehancePillBadge;
typedef DribbbleStatCard = BehanceStatCard;
typedef DribbbleSectionHeader = BehanceSectionHeader;
typedef DribbbleAmbientBackground = BehanceAmbientBackground;



