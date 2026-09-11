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

const List<Announcement> kDefaultAnnouncements = [
  Announcement(
    id: 'ann_1',
    title: 'Quarterly Usher Team Briefing',
    description: 'Mandatory usher meeting this Sunday at 8:15 AM in Conference Room B for station assignments and training review.',
    date: 'May 18, 2025',
    category: 'Usher Meeting',
  ),
  Announcement(
    id: 'ann_2',
    title: 'Night of Worship & Prayer',
    description: 'Join the entire church family for an evening of acoustic worship, intercession, and communion at 7:00 PM.',
    date: 'May 14, 2025',
    category: 'Worship Night',
  ),
  Announcement(
    id: 'ann_3',
    title: 'Wednesday Evening Bible Study',
    description: 'Walking through the Book of Romans chapter 8. Bring your study bibles and journals. Sanctuary East Wing.',
    date: 'May 10, 2025',
    category: 'Bible Study',
  ),
  Announcement(
    id: 'ann_4',
    title: 'Community Food Drive Outreach',
    description: 'Partnering with the city shelter for our seasonal grocery distribution. Volunteer slots open Saturday 9 AM.',
    date: 'May 03, 2025',
    category: 'Community Outreach',
  ),
  Announcement(
    id: 'ann_5',
    title: 'New Member Orientation Class',
    description: 'Learn more about church membership, ministry leadership, and ways to get connected. Starts at 1:30 PM.',
    date: 'Apr 27, 2025',
    category: 'New Member Class',
  ),
  Announcement(
    id: 'ann_6',
    title: 'Volunteer Appreciation Sunday',
    description: 'Celebrating all our dedicated usher and greeter servants after 2nd service with refreshments in Fellowship Hall.',
    date: 'Apr 20, 2025',
    category: 'Volunteer Appreciation',
  ),
];
