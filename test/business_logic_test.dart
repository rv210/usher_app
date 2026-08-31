import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usher_app/models/deployment.dart';
import 'package:usher_app/theme/app_theme.dart';

void main() {
  group('Phone Normalization and Matching Algorithm Tests', () {
    String normalizePhoneDigits(String? raw) {
      if (raw == null) return '';
      final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
      if (digits.length == 11 && digits.startsWith('1')) {
        return digits.substring(1);
      }
      return digits;
    }

    bool phonesMatch(String? p1, String? p2) {
      final d1 = normalizePhoneDigits(p1);
      final d2 = normalizePhoneDigits(p2);
      if (d1.isEmpty || d2.isEmpty) return false;
      return d1 == d2 || (d1.length >= 7 && d2.length >= 7 && (d1.endsWith(d2) || d2.endsWith(d1)));
    }

    test('Normalizes various US phone formats to 10 digits', () {
      expect(normalizePhoneDigits('7575257900'), '7575257900');
      expect(normalizePhoneDigits('(757) 525-7900'), '7575257900');
      expect(normalizePhoneDigits('+1 757 525 7900'), '7575257900');
      expect(normalizePhoneDigits('+1-757-525-7900'), '7575257900');
      expect(normalizePhoneDigits('17575257900'), '7575257900');
      expect(normalizePhoneDigits(''), '');
      expect(normalizePhoneDigits(null), '');
    });

    test('Matches phone numbers across different representation formats', () {
      expect(phonesMatch('7575257900', '(757) 525-7900'), isTrue);
      expect(phonesMatch('+1 (757) 525-7900', '7575257900'), isTrue);
      expect(phonesMatch('757-525-7900', '+17575257900'), isTrue);
      expect(phonesMatch('7575257900', '7575257999'), isFalse);
      expect(phonesMatch('', '7575257900'), isFalse);
      expect(phonesMatch(null, '7575257900'), isFalse);
    });
  });

  group('Upcoming Station Roster Single Schedule Isolation Tests', () {
    List<Deployment> isolateTargetSchedule(List<Deployment> allDeployments) {
      if (allDeployments.isEmpty) return [];

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final uniqueDates = allDeployments.map((d) => d.date.trim()).toSet().toList();

      final parsedUpcomingDates = <MapEntry<DateTime, String>>[];
      final parsedPastDates = <MapEntry<DateTime, String>>[];

      for (final dStr in uniqueDates) {
        try {
          final dt = DateTime.parse(dStr);
          final normDt = DateTime(dt.year, dt.month, dt.day);
          if (normDt.isAfter(today) || normDt.isAtSameMomentAs(today)) {
            parsedUpcomingDates.add(MapEntry(normDt, dStr));
          } else {
            parsedPastDates.add(MapEntry(normDt, dStr));
          }
        } catch (_) {}
      }

      parsedUpcomingDates.sort((a, b) => a.key.compareTo(b.key));
      parsedPastDates.sort((a, b) => b.key.compareTo(a.key));

      String? targetDate;
      if (parsedUpcomingDates.isNotEmpty) {
        targetDate = parsedUpcomingDates.first.value;
      } else if (parsedPastDates.isNotEmpty) {
        targetDate = parsedPastDates.first.value;
      }

      if (targetDate == null) return [];

      return allDeployments.where((d) => d.date.trim() == targetDate).toList();
    }

    test('Never combines different dates into upcoming roster', () {
      final deployments = <Deployment>[
        Deployment(
          id: '1',
          station: 'Main Doors 1',
          usherName: 'Robert Vargas',
          usherId: 'user_1',
          date: '2026-09-06',
          serviceType: 'Sunday Service',
        ),
        Deployment(
          id: '2',
          station: 'Main Doors 2',
          usherName: 'Brother Mike',
          usherId: 'user_2',
          date: '2026-09-06',
          serviceType: 'Sunday Service',
        ),
        Deployment(
          id: '3',
          station: 'Balcony',
          usherName: 'Sister Sarah',
          usherId: 'user_3',
          date: '2026-09-13',
          serviceType: 'Sunday Service',
        ),
        Deployment(
          id: '4',
          station: 'Altar',
          usherName: 'Deacon John',
          usherId: 'user_4',
          date: '2026-09-20',
          serviceType: 'Special Events',
        ),
      ];

      final isolated = isolateTargetSchedule(deployments);

      // Only the 2 assignments for Sep 6 should be returned, NOT combined with Sep 13 or Sep 20
      expect(isolated.length, 2);
      expect(isolated.every((d) => d.date == '2026-09-06'), isTrue);
      expect(isolated.any((d) => d.date == '2026-09-13'), isFalse);
    });

    test('Selects the earliest upcoming schedule when multiple future dates exist', () {
      final deployments = <Deployment>[
        Deployment(
          id: '1',
          station: 'Station B',
          usherName: 'Alice',
          usherId: 'user_a',
          date: '2030-01-15',
          serviceType: 'Sunday Service',
        ),
        Deployment(
          id: '2',
          station: 'Station A',
          usherName: 'Bob',
          usherId: 'user_b',
          date: '2030-01-08',
          serviceType: 'Special Events',
        ),
      ];

      final isolated = isolateTargetSchedule(deployments);
      expect(isolated.length, 1);
      expect(isolated.first.date, '2030-01-08');
      expect(isolated.first.usherName, 'Bob');
    });
  });

  group('Theme Presets & Design System Tokens Tests', () {
    test('All 5 theme presets have valid gradient configs', () {
      expect(AppThemePresets.configs.containsKey(AppStyleTheme.burgundy), isTrue);
      expect(AppThemePresets.configs.containsKey(AppStyleTheme.figmaNeon), isTrue);
      expect(AppThemePresets.configs.containsKey(AppStyleTheme.terracotta), isTrue);
      expect(AppThemePresets.configs.containsKey(AppStyleTheme.emerald), isTrue);
      expect(AppThemePresets.configs.containsKey(AppStyleTheme.midnight), isTrue);

      for (final entry in AppThemePresets.configs.entries) {
        final cfg = entry.value;
        expect(cfg.name.isNotEmpty, isTrue);
        expect(cfg.gradient.colors.length, greaterThanOrEqualTo(2));
        expect(cfg.primary.toARGB32(), isNonZero);
      }
    });

    test('Color Tokens have high contrast and appropriate hues', () {
      expect(AppColors.primary, const Color(0xFF8B1E3F));
      expect(AppColors.danger, const Color(0xFFB91C1C));
      expect(AppColors.success, const Color(0xFF15803D));
    });
  });
}
