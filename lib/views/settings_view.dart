import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import 'app_tutorial_view.dart';
import 'ushering_training_view.dart';
import '../models/team_member.dart';
import '../widgets/user_avatar.dart';
import '../widgets/profile_background_picker.dart';

class SettingsView extends StatefulWidget {
  final VoidCallback? onStartCoachmarkTour;
  final GlobalKey? themePresetsKey;
  final GlobalKey? darkThemeKey;
  final GlobalKey? twoFactorKey;
  final Function(int tabIndex)? onNavigateToTab;

  const SettingsView({
    super.key,
    this.onStartCoachmarkTour,
    this.themePresetsKey,
    this.darkThemeKey,
    this.twoFactorKey,
    this.onNavigateToTab,
  });

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _notificationsEnabled = true;
  bool _biometricAvailable = false;
  bool _inSystemPreferences = false;
  String _biometricLabel = "Biometric";
  IconData _biometricIcon = LucideIcons.fingerprint;

  static const List<AppStyleTheme> _orderedThemes = [
    AppStyleTheme.guardiansGold,
    AppStyleTheme.behance,
    AppStyleTheme.behanceFigma,
    AppStyleTheme.burgundy,
    AppStyleTheme.figmaNeon,
    AppStyleTheme.terracotta,
    AppStyleTheme.emerald,
    AppStyleTheme.midnight,
    AppStyleTheme.paleGoldOlive,
  ];

  @override
  void initState() {
    super.initState();
    final service = Provider.of<FirebaseService>(context, listen: false);
    service.isBiometricAvailable().then((available) async {
      if (mounted) {
        final label = await service.getBiometricTypeLabel();
        setState(() {
          _biometricAvailable = available;
          _biometricLabel = label;
          _biometricIcon = label == "Face ID" ? LucideIcons.scanFace : LucideIcons.fingerprint;
        });
      }
    });
  }

  Future<void> _onBiometricToggled(bool value, FirebaseService firebaseService) async {
    if (!value) {
      await firebaseService.setBiometricEnabled(false);
      return;
    }

    final confirmed = await firebaseService.authenticateBiometrics(
      reason: "Authenticate with $_biometricLabel to enable biometric unlock",
    );
    if (confirmed) {
      await firebaseService.setBiometricEnabled(true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ $_biometricLabel unlock enabled!"),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Couldn't verify your identity. $_biometricLabel unlock was not enabled."),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _onTwoFactorToggled(bool value, FirebaseService firebaseService) async {
    final profile = firebaseService.userProfile;
    if (!value) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text("Disable 2FA?", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: Text("Are you sure you want to remove SMS two-step verification from your account?", style: GoogleFonts.inter(fontSize: 14)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Disable 2FA", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (confirm == true) {
        try {
          await firebaseService.toggleTwoFactorAuth(false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Two-Factor Authentication disabled.")),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
          }
        }
      }
      return;
    }

    final existingPhone = profile?.twoFactorPhone ?? profile?.phone ?? '';
    final phoneController = TextEditingController(text: existingPhone);

    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            const Icon(LucideIcons.shieldCheck, color: AppColors.secondary, size: 22),
            const SizedBox(width: 8),
            Text("Enable SMS 2FA", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "When enabled, signing in will require entering a 6-digit SMS security code sent to your phone number.",
              style: GoogleFonts.inter(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            Text("Mobile Phone Number", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: "(555) 000-0000",
                prefixIcon: Icon(LucideIcons.phone, size: 18),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Activate 2FA"),
          ),
        ],
      ),
    );

    if (proceed == true) {
      final phone = phoneController.text.trim();
      if (phone.isEmpty || phone.replaceAll(RegExp(r'[^\d]'), '').length < 7) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please enter a valid phone number for SMS 2FA.")),
          );
        }
        return;
      }

      try {
        await firebaseService.toggleTwoFactorAuth(true, phone: phone);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(LucideIcons.shieldCheck, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text("Two-Factor Authentication is now active!"),
                ],
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      }
    }
  }

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

    if (!_inSystemPreferences) {
      return _buildProfileHub(context, firebaseService, profile, isDark);
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => setState(() => _inSystemPreferences = false),
        ),
        title: const Text("System Preferences"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(20, 10, 20, MediaQuery.of(context).size.width >= 800 ? 30 : 85),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Profile Hero Glass Card with Selected Background
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      // Atmospheric Background Image
                      Positioned.fill(
                        child: Image.asset(
                          firebaseService.userCustomCardBgPath,
                          fit: BoxFit.cover,
                          alignment: const Alignment(0.0, -0.2),
                          errorBuilder: (_, __, ___) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFF0F172A),
                                  const Color(0xFF1E293B),
                                  Theme.of(context).primaryColor.withValues(alpha: 0.8),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Dark Cinematic Vignette Overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.70),
                                Colors.black.withValues(alpha: 0.45),
                                Colors.black.withValues(alpha: 0.80),
                              ],
                              stops: const [0.0, 0.45, 1.0],
                            ),
                          ),
                        ),
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            UserAvatar(
                              photoPath: firebaseService.userCustomPhotoPath,
                              name: name,
                              size: 58,
                              borderWidth: 2,
                              borderColor: Colors.white,
                              showEditBadge: true,
                              onTap: () => showPhotoPickerSheet(context, firebaseService),
                              onEditTap: () => showPhotoPickerSheet(context, firebaseService),
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
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        constraints: const BoxConstraints(),
                                        padding: EdgeInsets.zero,
                                        icon: const Icon(LucideIcons.edit2, size: 16, color: Colors.white70),
                                        tooltip: "Edit Profile Name",
                                        onPressed: () => _showEditProfileDialog(context, firebaseService, name, profile?.phone ?? ''),
                                      ),
                                    ],
                                  ),
                                  if (email.isNotEmpty)
                                    Text(
                                      email,
                                      style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
                                    ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      DribbblePillBadge(
                                        label: isAdminUser ? "Admin/Lead" : (profile?.displayRole ?? "Usher"),
                                        color: Theme.of(context).primaryColor,
                                      ),
                                      InkWell(
                                        onTap: () {
                                          HapticFeedback.lightImpact();
                                          showBiblicalAvatarGalleryDialog(context, firebaseService);
                                        },
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: const Color(0xFFF59E0B).withValues(alpha: 0.6),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(LucideIcons.sparkles, size: 12, color: Color(0xFFFBBF24)),
                                              const SizedBox(width: 4),
                                              Text(
                                                "Biblical Portraits",
                                                style: GoogleFonts.inter(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: const Color(0xFFFDE68A),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () {
                                          HapticFeedback.lightImpact();
                                          showProfileBackgroundPickerSheet(context, firebaseService);
                                        },
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.16),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: Colors.white.withValues(alpha: 0.35),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(LucideIcons.image, size: 12, color: Colors.white),
                                              const SizedBox(width: 4),
                                              Text(
                                                "Card Background",
                                                style: GoogleFonts.inter(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
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
                    ],
                  ),
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
                      key: widget.darkThemeKey,
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
                    Divider(height: 1, color: context.borderThemeColor),
                    SwitchListTile(
                      key: widget.twoFactorKey,
                      title: Text("Two-Factor Authentication (2FA)", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                      subtitle: Text("Require 6-digit SMS verification code on sign-in", style: GoogleFonts.inter(fontSize: 12)),
                      secondary: Icon(LucideIcons.shieldCheck, color: profile?.twoFactorEnabled == true ? AppColors.success : Theme.of(context).primaryColor),
                      value: profile?.twoFactorEnabled ?? false,
                      activeThumbColor: AppColors.success,
                      onChanged: (val) => _onTwoFactorToggled(val, firebaseService),
                    ),
                    if (_biometricAvailable) ...[
                      Divider(height: 1, color: context.borderThemeColor),
                      SwitchListTile(
                        title: Text("$_biometricLabel Unlock", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                        subtitle: Text("Enable $_biometricLabel for quick 1-tap sign-in", style: GoogleFonts.inter(fontSize: 12)),
                        secondary: Icon(_biometricIcon, color: Theme.of(context).primaryColor),
                        value: firebaseService.biometricEnabled,
                        activeThumbColor: Theme.of(context).primaryColor,
                        onChanged: (val) => _onBiometricToggled(val, firebaseService),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 26),

              Container(
                key: widget.themePresetsKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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

                    // Theme Selector Cards List (Prioritizing Behance & Figma Showcase)
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _orderedThemes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final key = _orderedThemes[index];
                        final cfg = AppThemePresets.configs[key]!;
                        final isSelected = firebaseService.activeStyleTheme == key;

                        return BehanceGlassCard(
                          borderRadius: 16,
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
                                        Flexible(
                                          child: Text(
                                            cfg.name,
                                            style: GoogleFonts.outfit(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: context.textPrimaryColor,
                                            ),
                                            overflow: TextOverflow.ellipsis,
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
            ],
          ),
        ),

        const SizedBox(height: 32),

              DribbbleGlowButton(
                label: "Sign Out of Account",
                icon: LucideIcons.logOut,
                onPressed: () => _confirmSignOut(context, firebaseService),
                gradient: context.activeGradient,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHub(
    BuildContext context,
    FirebaseService firebaseService,
    TeamMember? profile,
    bool isDark,
  ) {
    final name = (profile?.name != null && profile!.name!.isNotEmpty)
        ? profile.name!
        : (firebaseService.currentUser?.displayName ?? "Daniel Carter");
    final memberDep = profile != null ? firebaseService.getMemberDeployment(profile) : null;
    final stationName = memberDep?.station ?? "Main Sanctuary";
    final roleName = profile?.displayRole ?? (profile?.isAdmin == true ? "Admin/Lead" : "Usher");

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: isDark ? Colors.white : const Color(0xFF4F46E5),
            size: 22,
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              widget.onNavigateToTab?.call(0);
            }
          },
        ),
        centerTitle: false,
        title: Text(
          "Profile / Settings",
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Profile Hero Card with Selected Biblical Background
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      // Atmospheric Background Image
                      Positioned.fill(
                        child: Image.asset(
                          firebaseService.userCustomCardBgPath,
                          fit: BoxFit.cover,
                          alignment: const Alignment(0.0, -0.2),
                          errorBuilder: (_, __, ___) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFF0F172A),
                                  const Color(0xFF1E293B),
                                  Theme.of(context).primaryColor.withValues(alpha: 0.8),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Dark Cinematic Vignette Overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.70),
                                Colors.black.withValues(alpha: 0.45),
                                Colors.black.withValues(alpha: 0.82),
                              ],
                              stops: const [0.0, 0.45, 1.0],
                            ),
                          ),
                        ),
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Circular Avatar with Photo Upload & Initial Fallback
                                UserAvatar(
                                  photoPath: firebaseService.userCustomPhotoPath,
                                  name: name,
                                  size: 74,
                                  borderWidth: 2.5,
                                  borderColor: Colors.white.withValues(alpha: 0.9),
                                  showEditBadge: true,
                                  onTap: () => showPhotoPickerSheet(context, firebaseService),
                                  onEditTap: () => showPhotoPickerSheet(context, firebaseService),
                                ),
                                const SizedBox(width: 16),
                                // User Details Column
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              name,
                                              style: GoogleFonts.outfit(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          IconButton(
                                            constraints: const BoxConstraints(),
                                            padding: EdgeInsets.zero,
                                            icon: const Icon(LucideIcons.edit2, size: 14, color: Colors.white70),
                                            tooltip: "Edit Display Name",
                                            onPressed: () => _showEditProfileDialog(context, firebaseService, name, profile?.phone ?? ''),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "$roleName  •  $stationName",
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white.withValues(alpha: 0.85),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        "\"Let all that you do be done in love.\"",
                                        style: GoogleFonts.outfit(
                                          fontSize: 12.5,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.white.withValues(alpha: 0.85),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "1 Corinthians 16:14",
                                        style: GoogleFonts.inter(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFFFBBF24),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Action Pills Row
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                // Biblical Portraits Gallery Button
                                InkWell(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    showBiblicalAvatarGalleryDialog(context, firebaseService);
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFF59E0B).withValues(alpha: 0.6),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(LucideIcons.sparkles, size: 13, color: Color(0xFFFBBF24)),
                                        const SizedBox(width: 5),
                                        Text(
                                          "Biblical Portraits",
                                          style: GoogleFonts.inter(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFFFDE68A),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Profile Card Background Button
                                InkWell(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    showProfileBackgroundPickerSheet(context, firebaseService);
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6.5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.35),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(LucideIcons.image, size: 13, color: Colors.white),
                                        const SizedBox(width: 5),
                                        Text(
                                          "Card Background",
                                          style: GoogleFonts.inter(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
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
              ),

              const SizedBox(height: 28),

              // Grouped Menu Card
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      context,
                      icon: LucideIcons.calendar,
                      label: "My Schedule",
                      isDark: isDark,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onNavigateToTab?.call(1);
                      },
                    ),
                    Divider(height: 1, indent: 54, endIndent: 16, color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9)),
                    _buildMenuItem(
                      context,
                      icon: LucideIcons.clipboardCheck,
                      label: "Check-In History",
                      isDark: isDark,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onNavigateToTab?.call(2);
                      },
                    ),
                    Divider(height: 1, indent: 54, endIndent: 16, color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9)),
                    _buildMenuItem(
                      context,
                      icon: LucideIcons.briefcase,
                      label: "Training & Resources",
                      isDark: isDark,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const UsheringTrainingView(initialTabIndex: 0)),
                        );
                      },
                    ),
                    Divider(height: 1, indent: 54, endIndent: 16, color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9)),
                    _buildMenuItem(
                      context,
                      icon: LucideIcons.bell,
                      label: "Announcements",
                      isDark: isDark,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onNavigateToTab?.call(4);
                      },
                    ),
                    Divider(height: 1, indent: 54, endIndent: 16, color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9)),
                    _buildMenuItem(
                      context,
                      icon: LucideIcons.settings,
                      label: "Settings",
                      isDark: isDark,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _inSystemPreferences = true);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // Log Out Button
              GestureDetector(
                onTap: () => _confirmSignOut(context, firebaseService),
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFC7D2FE),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.logOut,
                        size: 18,
                        color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Log Out",
                        style: GoogleFonts.outfit(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5),
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
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1E2432),
                ),
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, FirebaseService firebaseService) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text("Log Out?", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(
          "Are you sure you want to log out of your usher account?",
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              firebaseService.signOut();
            },
            child: const Text("Log Out"),
          ),
        ],
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
                      child: const Icon(LucideIcons.palette, color: Colors.white, size: 20),
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
                      Text("Behance & Figma Component Playground", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      BehanceGlassCard(
                        borderRadius: 16,
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Interactive Behance & Figma UI Components", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            const Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                BehancePillBadge(label: "LIVE SYSTEM OK", icon: LucideIcons.checkCircle, color: AppColors.success),
                                BehancePillBadge(label: "BEHANCE PRO", icon: LucideIcons.palette, color: AppColors.behanceBlue),
                                BehancePillBadge(label: "FIGMA STUDIO", icon: LucideIcons.layers, color: AppColors.figmaViolet),
                              ],
                            ),
                            const SizedBox(height: 16),
                            BehanceActionButton(
                              label: "Behance & Figma Action Button",
                              icon: LucideIcons.sparkles,
                              onPressed: () {},
                              gradient: AppThemePresets.configs[AppStyleTheme.behanceFigma]!.gradient,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
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
