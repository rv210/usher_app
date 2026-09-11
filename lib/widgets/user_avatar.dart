import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import '../models/biblical_avatar.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  final String? photoPath;
  final String name;
  final double size;
  final double borderWidth;
  final Color? borderColor;
  final Color? backgroundColor;
  final bool showEditBadge;
  final bool showOnlineBadge;
  final Color? onlineBadgeColor;
  final VoidCallback? onTap;
  final VoidCallback? onEditTap;

  const UserAvatar({
    super.key,
    this.photoPath,
    required this.name,
    this.size = 52,
    this.borderWidth = 2,
    this.borderColor,
    this.backgroundColor,
    this.showEditBadge = false,
    this.showOnlineBadge = false,
    this.onlineBadgeColor,
    this.onTap,
    this.onEditTap,
  });

  String get initial {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == 'Usher') return 'U';
    return trimmed[0].toUpperCase();
  }

  bool get hasValidCustomPhoto {
    if (photoPath == null || photoPath!.trim().isEmpty) return false;
    final path = photoPath!.trim();
    if (path.startsWith('assets/') || path.startsWith('http://') || path.startsWith('https://')) {
      return true;
    }
    if (!kIsWeb) {
      return io.File(path).existsSync();
    }
    return true;
  }

  ImageProvider? get _imageProvider {
    if (!hasValidCustomPhoto) return null;
    final path = photoPath!.trim();
    if (path.startsWith('assets/')) {
      return AssetImage(path);
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }
    if (!kIsWeb) {
      return FileImage(io.File(path));
    }
    return NetworkImage(path);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = borderColor ?? Colors.white;
    final imageProvider = _imageProvider;

    Widget avatarCore = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: imageProvider == null ? backgroundColor : null,
        gradient: (imageProvider == null && backgroundColor == null) ? context.activeGradient : null,
        border: Border.all(color: effectiveBorderColor, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: imageProvider != null
            ? Image(
                image: imageProvider,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildInitialFallback(context),
              )
            : _buildInitialFallback(context),
      ),
    );

    if (onTap != null) {
      avatarCore = GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap!();
        },
        child: avatarCore,
      );
    }

    Widget display = avatarCore;

    if (showOnlineBadge) {
      final dotSize = (size * 0.28).clamp(10.0, 14.0);
      display = Stack(
        clipBehavior: Clip.none,
        children: [
          display,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: onlineBadgeColor ?? const Color(0xFF22C55E),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      );
    }

    if (showEditBadge) {
      final badgeSize = (size * 0.32).clamp(24.0, 32.0);
      display = Stack(
        clipBehavior: Clip.none,
        children: [
          display,
          Positioned(
            right: -2,
            bottom: -2,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                if (onEditTap != null) {
                  onEditTap!();
                } else if (onTap != null) {
                  onTap!();
                }
              },
              child: Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  LucideIcons.camera,
                  color: Colors.white,
                  size: badgeSize * 0.52,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return display;
  }

  Widget _buildInitialFallback(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        gradient: backgroundColor == null ? context.activeGradient : null,
      ),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.44,
          ),
        ),
      ),
    );
  }
}

Future<void> showPhotoPickerSheet(
  BuildContext context,
  FirebaseService firebaseService,
) async {
  final currentPhoto = firebaseService.userCustomPhotoPath;
  final hasPhoto = currentPhoto != null && currentPhoto.isNotEmpty;

  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      final bgColor = isDark ? const Color(0xFF101422) : Colors.white;
      final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
      final primaryColor = Theme.of(ctx).primaryColor;

      return SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              // Drag handle
              Container(
                width: 38,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "Profile Picture",
                style: GoogleFonts.outfit(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Choose a Biblical inspired portrait, take a photo, or upload from gallery",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),

              // SECTION: Biblical Inspired Portraits Rail
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.sparkles, size: 13, color: Color(0xFFF59E0B)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "BIBLICAL PORTRAITS",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(ctx);
                        showBiblicalAvatarGalleryDialog(context, firebaseService);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "View All (8)",
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(LucideIcons.chevronRight, size: 13, color: primaryColor),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Horizontal Scrollable Avatars Rail
              SizedBox(
                height: 122,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: kBiblicalAvatars.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (itemCtx, index) {
                    final avatar = kBiblicalAvatars[index];
                    final isSelected = currentPhoto == avatar.assetPath;

                    return GestureDetector(
                      onTap: () async {
                        HapticFeedback.selectionClick();
                        Navigator.pop(ctx);
                        await firebaseService.setUserProfilePhoto(avatar.assetPath);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("✅ Profile portrait updated to ${avatar.title} (${avatar.verse})"),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
                      child: Container(
                        width: 82,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? avatar.accentColor.withValues(alpha: isDark ? 0.2 : 0.1)
                              : (isDark ? const Color(0xFF161C2C) : const Color(0xFFF8FAFC)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? avatar.accentColor
                                : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? avatar.accentColor : Colors.white24,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      avatar.assetPath,
                                      width: 52,
                                      height: 52,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Positioned(
                                    right: -2,
                                    bottom: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(2.5),
                                      decoration: BoxDecoration(
                                        color: avatar.accentColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 1.5),
                                      ),
                                      child: const Icon(LucideIcons.check, size: 10, color: Colors.white),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              avatar.title,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                color: isSelected ? avatar.accentColor : textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                avatar.verse,
                                style: GoogleFonts.inter(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),

              // Option 1: Take Photo
              ListTile(
                dense: true,
                leading: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).primaryColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.camera, color: Theme.of(ctx).primaryColor, size: 18),
                ),
                title: Text(
                  "Take Photo",
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14.5, color: textColor),
                ),
                subtitle: Text("Use device camera", style: GoogleFonts.inter(fontSize: 11.5)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final success = await firebaseService.pickAndSetProfilePhoto(source: ImageSource.camera);
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("✅ Profile picture updated!"),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
              ),

              // Option 2: Choose from Gallery
              ListTile(
                dense: true,
                leading: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.image, color: AppColors.secondary, size: 18),
                ),
                title: Text(
                  "Choose from Gallery",
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14.5, color: textColor),
                ),
                subtitle: Text("Select from photos library", style: GoogleFonts.inter(fontSize: 11.5)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final success = await firebaseService.pickAndSetProfilePhoto(source: ImageSource.gallery);
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("✅ Profile picture updated!"),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
              ),

              // Option 3: Remove photo (if one exists)
              if (hasPhoto) ...[
                ListTile(
                  dense: true,
                  leading: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.trash2, color: AppColors.danger, size: 18),
                  ),
                  title: Text(
                    "Remove Profile Photo",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14.5, color: AppColors.danger),
                  ),
                  subtitle: Text("Revert to first initial monogram", style: GoogleFonts.inter(fontSize: 11.5)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await firebaseService.removeProfilePhoto();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Profile picture removed. Using first initial monogram."),
                        ),
                      );
                    }
                  },
                ),
              ],

              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}

/// Dedicated Biblical Avatar Gallery Dialog with full-size artwork previews and Scripture verses
Future<void> showBiblicalAvatarGalleryDialog(
  BuildContext context,
  FirebaseService firebaseService,
) async {
  final currentPhoto = firebaseService.userCustomPhotoPath;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      final bgColor = isDark ? const Color(0xFF0F1424) : Colors.white;
      final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

      return Container(
        height: MediaQuery.of(ctx).size.height * 0.85,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 30,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 42,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.sparkles, color: Color(0xFFF59E0B), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Biblical Inspired Portraits",
                          style: GoogleFonts.outfit(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        Text(
                          "Select a sacred Scripture artwork for your usher profile card",
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.x, size: 20, color: isDark ? Colors.white70 : Colors.black54),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),

            // Scrollable List of Full Cards
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                itemCount: kBiblicalAvatars.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final avatar = kBiblicalAvatars[index];
                  final isSelected = currentPhoto == avatar.assetPath;

                  return Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF161D30) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? avatar.accentColor
                            : (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0)),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? avatar.accentColor.withValues(alpha: 0.15)
                              : Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Artwork Thumbnail
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.asset(
                                  avatar.assetPath,
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              if (isSelected)
                                Positioned(
                                  right: -4,
                                  bottom: -4,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: avatar.accentColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(LucideIcons.check, size: 12, color: Colors.white),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 14),

                          // Text Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        avatar.title,
                                        style: GoogleFonts.outfit(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: avatar.accentColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        avatar.verse,
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: avatar.accentColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  avatar.subtitle,
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "“${avatar.verseText}”",
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: textColor.withValues(alpha: 0.85),
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: 34,
                                  child: ElevatedButton.icon(
                                    icon: Icon(
                                      isSelected ? LucideIcons.checkCheck : LucideIcons.image,
                                      size: 14,
                                    ),
                                    label: Text(
                                      isSelected ? "Current Profile Portrait" : "Set as Profile Picture",
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isSelected
                                          ? avatar.accentColor.withValues(alpha: 0.2)
                                          : avatar.accentColor,
                                      foregroundColor: isSelected ? avatar.accentColor : Colors.white,
                                      elevation: isSelected ? 0 : 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        side: BorderSide(
                                          color: avatar.accentColor,
                                          width: isSelected ? 1 : 0,
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                    ),
                                    onPressed: () async {
                                      HapticFeedback.selectionClick();
                                      Navigator.pop(ctx);
                                      await firebaseService.setUserProfilePhoto(avatar.assetPath);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text("✅ Profile portrait set to ${avatar.title}!"),
                                            backgroundColor: AppColors.success,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}
