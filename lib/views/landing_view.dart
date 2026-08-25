import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
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

    return Scaffold(
      body: Stack(
        children: [
          // Ambient Soft Lighting Orbs (Positioned safely away from text to ensure 100% contrast)
          Positioned(
            top: -160,
            right: -120,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).primaryColor.withValues(alpha: isDark ? 0.25 : 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -140,
            left: -100,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.secondary.withValues(alpha: isDark ? 0.2 : 0.1),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Branding Header Bar
                  DribbbleGlassContainer(
                    borderRadius: 22,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: context.activeGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).primaryColor.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset('assets/images/app_icon.jpg', fit: BoxFit.cover),
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
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimaryColor,
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      "MINISTRY HUB",
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Event Usher Portal",
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: context.textSecondaryColor,
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

                  const SizedBox(height: 20),

                  // Hero Showcase Glass Card
                  DribbbleGlassContainer(
                    borderRadius: 28,
                    padding: const EdgeInsets.all(24),
                    blur: 25,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DribbblePillBadge(
                          label: "MINISTRY OPERATIONAL EXCELLENCE",
                          icon: LucideIcons.sparkles,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Streamlined Usher Operations",
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            height: 1.15,
                            color: context.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Real-time headcount tallies, duty station scheduling, instant team announcements, and usher roster control.",
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            height: 1.5,
                            color: context.textSecondaryColor,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Interactive Feature Grid
                        Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFeatureTile(
                                    context,
                                    icon: LucideIcons.calendar,
                                    title: "Duty Roster",
                                    subtitle: "Auto-Fill & Sub-In",
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildFeatureTile(
                                    context,
                                    icon: LucideIcons.binary,
                                    title: "Live Tally Counter",
                                    subtitle: "Headcount & Dates",
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFeatureTile(
                                    context,
                                    icon: LucideIcons.messageSquare,
                                    title: "Instant Comms",
                                    subtitle: "Push Alerts & Comms",
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildFeatureTile(
                                    context,
                                    icon: LucideIcons.users,
                                    title: "Team Directory",
                                    subtitle: "Member Roles & Passcode",
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Mini Stats Pill Row
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.15)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(context, "100%", "Real-Time Sync"),
                              Container(width: 1, height: 24, color: Theme.of(context).primaryColor.withValues(alpha: 0.2)),
                              _buildStatItem(context, "Sub-In", "Shift Substitution"),
                              Container(width: 1, height: 24, color: Theme.of(context).primaryColor.withValues(alpha: 0.2)),
                              _buildStatItem(context, "FCM", "Push Alerts"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Scripture Stewardship Card
                  DribbbleGlassContainer(
                    borderRadius: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    child: Row(
                      children: [
                        Icon(LucideIcons.quote, size: 20, color: Theme.of(context).colorScheme.secondary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '"I would rather be a doorkeeper in the house of my God..."',
                                style: GoogleFonts.outfit(
                                  fontSize: 12.5,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w600,
                                  color: context.textPrimaryColor,
                                ),
                              ),
                              Text(
                                '— Psalm 84:10',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  DribbbleGlowButton(
                    label: "Create Account",
                    icon: LucideIcons.arrowRight,
                    onPressed: onGetStarted,
                    gradient: context.activeGradient,
                  ),
                  const SizedBox(height: 12),

                  DribbbleGlassContainer(
                    borderRadius: 16,
                    padding: EdgeInsets.zero,
                    onTap: onLogin,
                    child: Container(
                      height: 52,
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.logIn, size: 18, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            "Sign In to Account",
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.borderThemeColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: context.textPrimaryColor,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              color: context.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String val, String label) {
    return Column(
      children: [
        Text(
          val,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9.5,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      ],
    );
  }
}
