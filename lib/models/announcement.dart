import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class Announcement {
  final String id;
  final String title;
  final String description;
  final String date;
  final String category;
  final String? iconName;
  final String? authorName;
  final DateTime? createdAt;

  const Announcement({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.category,
    this.iconName,
    this.authorName,
    this.createdAt,
  });

  Announcement copyWith({
    String? id,
    String? title,
    String? description,
    String? date,
    String? category,
    String? iconName,
    String? authorName,
    DateTime? createdAt,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      category: category ?? this.category,
      iconName: iconName ?? this.iconName,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  IconData get icon {
    switch (category.toLowerCase()) {
      case 'usher meeting':
      case 'usher meetings':
      case 'meeting':
        return LucideIcons.megaphone;
      case 'worship night':
      case 'worship nights':
      case 'worship':
        return LucideIcons.music;
      case 'bible study':
      case 'bible studies':
        return LucideIcons.bookOpen;
      case 'community outreach':
      case 'outreach':
        return LucideIcons.calendarCheck;
      case 'new member class':
      case 'orientation':
        return LucideIcons.heart;
      case 'volunteer appreciation':
      case 'appreciation':
        return LucideIcons.users;
      default:
        return LucideIcons.bell;
    }
  }

  Color get categoryColor {
    switch (category.toLowerCase()) {
      case 'usher meeting':
      case 'usher meetings':
      case 'meeting':
        return const Color(0xFFC79540); // Guardians Warm Gold
      case 'worship night':
      case 'worship nights':
      case 'worship':
        return const Color(0xFF8B5CF6); // Violet
      case 'bible study':
      case 'bible studies':
        return const Color(0xFF3B82F6); // Blue
      case 'community outreach':
      case 'outreach':
        return const Color(0xFF10B981); // Emerald
      case 'new member class':
      case 'orientation':
        return const Color(0xFFEF4444); // Rose
      case 'volunteer appreciation':
      case 'appreciation':
        return const Color(0xFF0D9488); // Teal
      default:
        return const Color(0xFFC79540);
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date,
      'category': category,
      'iconName': iconName,
      'authorName': authorName,
      'createdAt': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  factory Announcement.fromMap(Map<String, dynamic> map, [String? id]) {
    return Announcement(
      id: id ?? map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: map['date'] ?? '',
      category: map['category'] ?? 'General',
      iconName: map['iconName'],
      authorName: map['authorName'],
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) : null,
    );
  }
}

const List<Announcement> kDefaultAnnouncements = [];
