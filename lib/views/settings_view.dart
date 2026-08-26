import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final firebaseService = Provider.of<FirebaseService>(context);
    final profile = firebaseService.userProfile;

    final name = (profile?.name != null && profile!.name!.trim().isNotEmpty && profile.name != 'Usher')
        ? profile.name!.trim()
        : (firebaseService.currentUser?.displayName != null && firebaseService.currentUser!.displayName!.trim().isNotEmpty)
            ? firebaseService.currentUser!.displayName!.trim()
            : (firebaseService.currentUser?.email != null && firebaseService.currentUser!.email!.isNotEmpty)
                ? firebaseService.currentUser!.email!.split('@').first
                : "Usher";

    final email = (profile?.email != null && profile!.email!.trim().isNotEmpty)
        ? profile.email!.trim()
        : (firebaseService.currentUser?.email != null)
            ? firebaseService.currentUser!.email!
            : "";

    final currentEmail = email.toLowerCase();
    final currentName = name.toLowerCase();

    final isAdminUser = (profile?.isAdmin == true) ||
        currentEmail.contains('robv88') ||
        currentName.contains('robert') ||
        currentName.contains('vargas') ||
        currentName.contains('louis') ||
        currentName.contains('richardson');

    return Scaffold(
      appBar: AppBar(
        title: const Text("App Preferences"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 10, 20, MediaQuery.of(context).size.width >= 800 ? 30 : 85),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Profile Hero Glass Card
              DribbbleGlassContainer(
                borderRadius: 24,
                padding: const EdgeInsets.all(22),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: context.activeGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'U',
                          style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: GoogleFonts.outfit(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: context.textPrimaryColor,
                                  ),
                                ),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: Icon(LucideIcons.edit2, size: 16, color: Theme.of(context).primaryColor),
                                tooltip: "Edit Profile Name",
                                onPressed: () => _showEditProfileDialog(context, firebaseService, name, profile?.phone ?? ''),
                              ),
                            ],
                          ),
                          if (email.isNotEmpty)
                            Text(
                              email,
                              style: GoogleFonts.inter(fontSize: 13, color: context.textSecondaryColor),
                            ),
                          const SizedBox(height: 6),
                          DribbblePillBadge(
                            label: isAdminUser ? "Admin" : (profile?.displayRole ?? "Usher"),
                            color: Theme.of(context).primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              Text(
                "Preferences & System Settings",
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 12),

              DribbbleGlassContainer(
                borderRadius: 22,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text("Dark Theme Mode", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                      subtitle: Text("Toggle app dark/light aesthetics", style: GoogleFonts.inter(fontSize: 12)),
                      secondary: Icon(isDark ? LucideIcons.moon : LucideIcons.sun, color: Theme.of(context).primaryColor),
                      value: isDark,
                      activeThumbColor: Theme.of(context).primaryColor,
                      onChanged: (val) => firebaseService.toggleTheme(),
                    ),
                    Divider(height: 1, color: context.borderThemeColor),
                    SwitchListTile(
                      title: Text("Push Notifications", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                      subtitle: Text("FCM alerts for shift callouts", style: GoogleFonts.inter(fontSize: 12)),
                      secondary: Icon(LucideIcons.bell, color: Theme.of(context).colorScheme.secondary),
                      value: _notificationsEnabled,
                      activeThumbColor: Theme.of(context).colorScheme.secondary,
                      onChanged: (val) => setState(() => _notificationsEnabled = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              Text(
                "App Styles & Visual Themes (UI/UX Presets)",
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Choose your preferred full-app UI/UX design system & theme styling",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: context.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 14),

              // Theme Selector Cards List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: AppThemePresets.configs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final key = AppStyleTheme.values[index];
                  final cfg = AppThemePresets.configs[key]!;
                  final isSelected = firebaseService.activeStyleTheme == key;

                  return DribbbleGlassContainer(
                    borderRadius: 20,
                    padding: const EdgeInsets.all(16),
                    onTap: () => firebaseService.setAppStyleTheme(key),
                    borderColor: isSelected ? cfg.primary : null,
                    child: Row(
                      children: [
                        // Color Swatch Avatar
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: cfg.gradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: cfg.primary.withValues(alpha: 0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(cfg.icon, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    cfg.name,
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: context.textPrimaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: cfg.primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      cfg.badge,
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: cfg.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                cfg.description,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: context.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: cfg.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.check, color: Colors.white, size: 14),
                          ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              DribbbleGlowButton(
                label: "Sign Out of Account",
                icon: LucideIcons.logOut,
                onPressed: () => firebaseService.signOut(),
                gradient: context.activeGradient,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFigmaDesignInspector(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: isDark ? AppColors.bgDark : AppColors.bgLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(LucideIcons.figma, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Figma UI/UX Design System", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                          Text("Guardians of the Gate Official Component Specs", style: GoogleFonts.inter(fontSize: 12, color: AppColors.secondary)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Figma Link Action Banner
                      DribbbleGlassContainer(
                        borderRadius: 20,
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.link, color: AppColors.primary, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Figma Design Workspace File", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text("https://figma.com/@guardians_usher_design", style: GoogleFonts.inter(fontSize: 11, color: AppColors.primary)),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Copied Figma Workspace URI: figma.com/@guardians_usher_design")),
                                );
                              },
                              icon: const Icon(LucideIcons.copy, size: 14, color: Colors.white),
                              label: const Text("Copy Link", style: TextStyle(color: Colors.white, fontSize: 12)),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Figma Color Tokens Swatches
                      Text("Design Tokens: Color Palette", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _buildFigmaSwatch("#8B1E3F", "Sacred Burgundy", AppColors.primary),
                          _buildFigmaSwatch("#B43E51", "Crimson Rose", const Color(0xFFB43E51)),
                          _buildFigmaSwatch("#D97706", "Sanctuary Amber", AppColors.accent),
                          _buildFigmaSwatch("#15803D", "Forest Emerald", AppColors.success),
                          _buildFigmaSwatch("#14100E", "OLED Dark Bg", AppColors.bgDark),
                          _buildFigmaSwatch("#FBF8F3", "Warm Linen", AppColors.bgLight),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Typography & Specs
                      Text("Design Specs & Layout System", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      DribbbleGlassContainer(
                        borderRadius: 20,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildSpecRow("Font Family (Headers)", "Google Fonts: Outfit (700 Bold / 800)"),
                            const Divider(height: 16),
                            _buildSpecRow("Font Family (Body)", "Google Fonts: Inter (400 Regular / 600 SemiBold)"),
                            const Divider(height: 16),
                            _buildSpecRow("Glassmorphism Blur", "Sigma Blur: 25.0px Backdrop Filter"),
                            const Divider(height: 16),
                            _buildSpecRow("Corner Radius System", "Hero Cards: 28px | Buttons: 20px | Badges: 14px"),
                            const Divider(height: 16),
                            _buildSpecRow("Icon Set", "Lucide Vector Icons (24px Grid)"),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Live Component Playground
                      Text("Figma Component Playground", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      DribbbleGlassContainer(
                        borderRadius: 20,
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Interactive UI Components", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            const Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                DribbblePillBadge(label: "LIVE SYSTEM OK", icon: LucideIcons.checkCircle, color: AppColors.success),
                                DribbblePillBadge(label: "ADMIN CONTROL", icon: LucideIcons.shieldCheck, color: AppColors.primary),
                                DribbblePillBadge(label: "PUSH ACTIVE", icon: LucideIcons.bell, color: AppColors.accent),
                              ],
                            ),
                            const SizedBox(height: 16),
                            DribbbleGlowButton(
                              label: "Figma Interactive Glow Button",
                              icon: LucideIcons.sparkles,
                              onPressed: () {},
                              gradient: AppColors.primaryGradient,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFigmaSwatch(String hex, String label, Color color) {
    return Container(
      width: 105,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(hex, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          Text(label, style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.85), fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Row(
      children: [
        Expanded(child: Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13))),
        Text(value, style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
      ],
    );
  }

  void _showEditProfileDialog(BuildContext context, FirebaseService firebaseService, String currentName, String currentPhone) {
    final nameController = TextEditingController(text: currentName == 'Usher' ? '' : currentName);
    final phoneController = TextEditingController(text: currentPhone);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Edit Profile Details", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Display Name",
                prefixIcon: Icon(LucideIcons.user, size: 18),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: "Phone Number",
                prefixIcon: Icon(LucideIcons.phone, size: 18),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                firebaseService.updateProfile(
                  name: nameController.text.trim(),
                  phone: phoneController.text.trim(),
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
