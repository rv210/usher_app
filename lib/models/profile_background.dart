import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';

class ProfileBackground {
  final String id;
  final String title;
  final String subtitle;
  final String verse;
  final String? assetPath; // null represents clean glass without image
  final Color accentColor;
  final AppStyleTheme matchingTheme;
  final String themeName;
  final IconData themeIcon;
  final List<Color> previewColors;

  const ProfileBackground({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.verse,
    this.assetPath,
    required this.accentColor,
    required this.matchingTheme,
    required this.themeName,
    required this.themeIcon,
    required this.previewColors,
  });
}

const List<ProfileBackground> kProfileBackgrounds = [
  ProfileBackground(
    id: 'cathedral_sanctuary',
    title: 'Cathedral Sanctuary',
    subtitle: 'Sacred Stone & Stained Glass',
    verse: 'Psalm 84:1',
    assetPath: 'assets/images/hub_header_bg.jpg',
    accentColor: Color(0xFFC79540),
    matchingTheme: AppStyleTheme.guardiansGold,
    themeName: 'Guardians Gold',
    themeIcon: LucideIcons.crown,
    previewColors: [Color(0xFFC79540), Color(0xFFE5BC6A), Color(0xFFD4AF37)],
  ),
  ProfileBackground(
    id: 'mountaintop_cross',
    title: 'Mountaintop Sunrise Cross',
    subtitle: 'Dawn Light & Rugged Cross',
    verse: 'John 8:12',
    assetPath: 'assets/images/biblical/bg_mountaintop_cross.jpg',
    accentColor: Color(0xFFF59E0B),
    matchingTheme: AppStyleTheme.terracotta,
    themeName: 'Terracotta Sunrise',
    themeIcon: LucideIcons.sun,
    previewColors: [Color(0xFFC2410C), Color(0xFFF59E0B), Color(0xFFFF6B6B)],
  ),
  ProfileBackground(
    id: 'golden_temple',
    title: 'Golden Temple Sanctuary',
    subtitle: 'Ancient Pillars & Divine Glory',
    verse: '1 Kings 8:11',
    assetPath: 'assets/images/biblical/bg_golden_temple.jpg',
    accentColor: Color(0xFFD97706),
    matchingTheme: AppStyleTheme.paleGoldOlive,
    themeName: 'Ancient Temple Gold',
    themeIcon: LucideIcons.wheat,
    previewColors: [Color(0xFFD97706), Color(0xFFB8994A), Color(0xFFF2DE9B)],
  ),
  ProfileBackground(
    id: 'peaceful_waters',
    title: 'Quiet Waters & Pastures',
    subtitle: 'Tranquil River & Olive Groves',
    verse: 'Psalm 23:2',
    assetPath: 'assets/images/biblical/bg_peaceful_waters.jpg',
    accentColor: Color(0xFF10B981),
    matchingTheme: AppStyleTheme.emerald,
    themeName: 'Living Waters Emerald',
    themeIcon: LucideIcons.trees,
    previewColors: [Color(0xFF047857), Color(0xFF10B981), Color(0xFF06B6D4)],
  ),
  ProfileBackground(
    id: 'starry_communion',
    title: 'Night of Prayer & Worship',
    subtitle: 'Starlit Heavens & Glowing Lamp',
    verse: 'Psalm 19:1',
    assetPath: 'assets/images/biblical/bg_starry_communion.jpg',
    accentColor: Color(0xFF6366F1),
    matchingTheme: AppStyleTheme.midnight,
    themeName: 'Midnight Sapphire',
    themeIcon: LucideIcons.moon,
    previewColors: [Color(0xFF1E40AF), Color(0xFF6366F1), Color(0xFF8B5CF6)],
  ),
  ProfileBackground(
    id: 'clean_glass',
    title: 'Pure Minimal Glass',
    subtitle: 'Studio White & Ambient Glass',
    verse: 'Proverbs 4:18',
    assetPath: null,
    accentColor: Color(0xFF64748B),
    matchingTheme: AppStyleTheme.behanceFigma,
    themeName: 'Studio Pro Clean Glass',
    themeIcon: LucideIcons.layers,
    previewColors: [Color(0xFF0057FF), Color(0xFFA259FF), Color(0xFF1ABCFE)],
  ),
];
