import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';

class LandingView extends StatelessWidget {
  final VoidCallback onGetStarted;
  final VoidCallback onLogin;

  const LandingView({
    super.key,
    required this.onGetStarted,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final activeGradient = context.activeGradient;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgDark : AppColors.bgLight,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor.withValues(alpha: isDark ? 0.22 : 0.10),
              isDark ? AppColors.bgDark : AppColors.bgLight,
              isDark ? const Color(0xFF0F0B0A) : const Color(0xFFF7F5F4),
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top App Header Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.cardDark.withValues(alpha: 0.85)
                        : Colors.white.withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.25),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // 3D Illuminated App Crest Avatar
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: activeGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.45),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/images/app_icon.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Guardians of the Gate",
                              style: GoogleFonts.outfit(
                                fontSize: 18.5,
                                fontWeight: FontWeight.bold,
                                color: context.textPrimaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: primaryColor.withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: AppColors.success,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        "MINISTRY HUB",
                                        style: GoogleFonts.outfit(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          color: primaryColor,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    "Sanctuary Operations",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: context.textSecondaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Hero Presentation Card
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.cardDark.withValues(alpha: 0.90)
                        : Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.25),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Live Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.sparkles, size: 14, color: primaryColor),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                "SANCTUARY OPERATIONAL EXCELLENCE",
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: primaryColor,
                                  letterSpacing: 0.8,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Main Headline
                      Text(
                        "Ministry Stewardship,\nElevated.",
                        style: GoogleFonts.outfit(
                          fontSize: 29,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                          letterSpacing: -0.5,
                          color: context.textPrimaryColor,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Subtitle description
                      Text(
                        "Real-time duty station rosters, live attendance tallies, instant usher broadcasts, and church SOP handbook.",
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          height: 1.55,
                          color: context.textSecondaryColor,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 2x2 Showcase Feature Grid
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildFeatureCard(
                                  context,
                                  icon: LucideIcons.mapPin,
                                  title: "Station Roster",
                                  subtitle: "Duty Deployments",
                                  badgeText: "1-Tap Sub-In",
                                  accentColor: primaryColor,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildFeatureCard(
                                  context,
                                  icon: LucideIcons.binary,
                                  title: "Live Headcount",
                                  subtitle: "Digital Tally Tracker",
                                  badgeText: "Real-Time",
                                  accentColor: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _buildFeatureCard(
                                  context,
                                  icon: LucideIcons.bellRing,
                                  title: "Team Comms",
                                  subtitle: "Push Broadcasts",
                                  badgeText: "FCM Push",
                                  accentColor: AppColors.accent,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildFeatureCard(
                                  context,
                                  icon: LucideIcons.bookOpen,
                                  title: "SOP Training",
                                  subtitle: "Ministry Handbook",
                                  badgeText: "In-App Reader",
                                  accentColor: theme.colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Micro Metrics Strip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(context, "100%", "Live Sync", primaryColor),
                            Container(
                              width: 1,
                              height: 26,
                              color: primaryColor.withValues(alpha: 0.25),
                            ),
                            _buildStatItem(context, "Sub-In", "Shift Relief", AppColors.success),
                            Container(
                              width: 1,
                              height: 26,
                              color: primaryColor.withValues(alpha: 0.25),
                            ),
                            _buildStatItem(context, "Cloud", "Auto Push", AppColors.accent),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Illuminated Sacred Scripture Banner
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withValues(alpha: isDark ? 0.10 : 0.06),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: AppColors.amber.withValues(alpha: 0.35),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.amber.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.quote,
                          size: 18,
                          color: AppColors.amber,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '"For a day in your courts is better than a thousand elsewhere. I would rather be a doorkeeper in the house of my God..."',
                              style: GoogleFonts.lora(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                height: 1.45,
                                color: context.textPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '— Psalm 84:10',
                              style: GoogleFonts.cinzel(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                                color: AppColors.amber,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // Primary Call to Action
                DribbbleGlowButton(
                  label: "Create Usher Account",
                  icon: LucideIcons.arrowRight,
                  onPressed: onGetStarted,
                  gradient: activeGradient,
                ),

                const SizedBox(height: 12),

                // Secondary Sign In CTA Button
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.cardDark.withValues(alpha: 0.8)
                        : Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: context.borderThemeColor,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: onLogin,
                      child: Container(
                        height: 54,
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.logIn, size: 18, color: primaryColor),
                            const SizedBox(width: 10),
                            Text(
                              "Sign In to Existing Account",
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: context.textPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Security & Encryption Footnote
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.shieldCheck,
                      size: 13,
                      color: context.textSecondaryColor.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        "256-BIT ENCRYPTION • ACTIVE CLOUD FIREBASE SYNC",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.7,
                          color: context.textSecondaryColor.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color accentColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1A18) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: context.borderThemeColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: accentColor),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              color: context.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String val, String label, Color color) {
    return Column(
      children: [
        Text(
          val,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: context.textSecondaryColor,
          ),
        ),
      ],
    );
  }
}
