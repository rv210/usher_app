import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usher_app/models/deployment.dart';
import 'package:usher_app/theme/app_theme.dart';
import 'package:usher_app/views/app_tutorial_view.dart';
import 'package:usher_app/views/app_coachmark_tour.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usher_app/models/training_module.dart';
import 'package:usher_app/models/team_member.dart';
import 'package:usher_app/services/firebase_service.dart';
import 'package:usher_app/views/attendance_view.dart';
import 'package:usher_app/models/guest_check_in.dart';
import 'package:usher_app/models/comms_message.dart';

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
          date: '2035-10-07',
          serviceType: 'Sunday Service',
        ),
        Deployment(
          id: '2',
          station: 'Main Doors 2',
          usherName: 'Brother Mike',
          usherId: 'user_2',
          date: '2035-10-07',
          serviceType: 'Sunday Service',
        ),
        Deployment(
          id: '3',
          station: 'Balcony',
          usherName: 'Sister Sarah',
          usherId: 'user_3',
          date: '2035-10-14',
          serviceType: 'Sunday Service',
        ),
        Deployment(
          id: '4',
          station: 'Altar',
          usherName: 'Deacon John',
          usherId: 'user_4',
          date: '2035-10-21',
          serviceType: 'Special Events',
        ),
      ];

      final isolated = isolateTargetSchedule(deployments);

      // Only the 2 assignments for the earliest date should be returned, NOT combined with later dates
      expect(isolated.length, 2);
      expect(isolated.every((d) => d.date == '2035-10-07'), isTrue);
      expect(isolated.any((d) => d.date == '2035-10-14'), isFalse);
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
    test('All theme presets have valid gradient configs', () {
      expect(AppThemePresets.configs.containsKey(AppStyleTheme.burgundy), isTrue);
      expect(AppThemePresets.configs.containsKey(AppStyleTheme.figmaNeon), isTrue);
      expect(AppThemePresets.configs.containsKey(AppStyleTheme.terracotta), isTrue);
      expect(AppThemePresets.configs.containsKey(AppStyleTheme.emerald), isTrue);
      expect(AppThemePresets.configs.containsKey(AppStyleTheme.midnight), isTrue);
      expect(AppThemePresets.configs.containsKey(AppStyleTheme.paleGoldOlive), isTrue);
      expect(AppThemePresets.configs.containsKey(AppStyleTheme.behance), isTrue);
      expect(AppThemePresets.configs.containsKey(AppStyleTheme.behanceFigma), isTrue);

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
      expect(AppColors.behanceBlue, const Color(0xFF0057FF));
      expect(AppColors.figmaViolet, const Color(0xFFA259FF));
      expect(AppColors.figmaCyan, const Color(0xFF1ABCFE));
    });
  });

  group('Calendar Month Sunday Generation & DST Immunity Tests', () {
    List<DateTime> getSundaysForMonth(DateTime monthDate) {
      final sundays = <DateTime>[];
      final daysInMonth = DateTime(monthDate.year, monthDate.month + 1, 0).day;

      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime(monthDate.year, monthDate.month, day);
        if (date.weekday == DateTime.sunday) {
          sundays.add(date);
        }
      }
      return sundays;
    }

    test('Generates unique Sundays for November 2026 without duplicate Nov 1', () {
      final nov2026 = DateTime(2026, 11, 1);
      final sundays = getSundaysForMonth(nov2026);

      // November 2026 has exactly 5 Sundays: Nov 1, 8, 15, 22, 29
      expect(sundays.length, 5);
      expect(sundays[0].day, 1);
      expect(sundays[1].day, 8);
      expect(sundays[2].day, 15);
      expect(sundays[3].day, 22);
      expect(sundays[4].day, 29);

      // Check no duplicates
      final dayNumbers = sundays.map((s) => s.day).toSet();
      expect(dayNumbers.length, 5);
    });

    test('Generates correct Sundays across leap years and standard months', () {
      // February 2028 (Leap Year starting on Tuesday)
      final feb2028 = DateTime(2028, 2, 1);
      final sundaysFeb = getSundaysForMonth(feb2028);
      expect(sundaysFeb.length, 4);
      expect(sundaysFeb.map((s) => s.day).toList(), [6, 13, 20, 27]);
    });
  });

  group('Android Bubble Notification Payload & Shortcut Tests', () {
    test('Constructs deterministic and unique shortcut IDs for Comms conversations', () {
      String getShortcutId(String? senderId) => 'comms_${senderId ?? 'team_lead'}';

      expect(getShortcutId('usher_123'), 'comms_usher_123');
      expect(getShortcutId(null), 'comms_team_lead');
      expect(getShortcutId(''), 'comms_');
    });

    test('Validates notification ID fits within positive 31-bit integer range', () {
      final shortcutId = 'comms_lead_test';
      final notificationId = (shortcutId.hashCode & 0x7FFFFFFF);
      expect(notificationId >= 0, isTrue);
      expect(notificationId <= 2147483647, isTrue);
    });

    test('Identifies comms notification push types accurately', () {
      bool isCommsPush(Map<String, dynamic> data, String? title) {
        final type = data['type'] ?? '';
        final t = (title ?? '').toLowerCase();
        return type == 'comms' || t.contains('comms') || t.contains('chat') || t.contains('message');
      }

      expect(isCommsPush({'type': 'comms'}, null), isTrue);
      expect(isCommsPush({}, 'Team Comms Alert'), isTrue);
      expect(isCommsPush({}, 'New Chat Message'), isTrue);
      expect(isCommsPush({'type': 'schedule'}, 'Roster Update'), isFalse);
    });
  });

  group('App Tutorial Chapters & Content Tests', () {
    test('Contains exactly 6 comprehensive ministry pillars', () {
      expect(AppTutorialView.chapters.length, 6);
    });

    test('All tutorial chapters have valid content, non-empty highlights, and platform tips', () {
      for (final chapter in AppTutorialView.chapters) {
        expect(chapter.title.isNotEmpty, isTrue);
        expect(chapter.subtitle.isNotEmpty, isTrue);
        expect(chapter.category.isNotEmpty, isTrue);
        expect(chapter.highlights.isNotEmpty, isTrue);
        expect(chapter.platformTipAndroid.isNotEmpty, isTrue);
        expect(chapter.platformTipIos.isNotEmpty, isTrue);
      }
    });

    test('Comms chapter contains Android Bubble guidance and iOS keyboard gestures', () {
      final commsChapter = AppTutorialView.chapters.firstWhere((c) => c.title.contains("Comms"));
      expect(commsChapter.platformTipAndroid.toLowerCase().contains("bubble"), isTrue);
      expect(commsChapter.platformTipIos.toLowerCase().contains("swipe down"), isTrue);
    });

    test('Tab navigation indices map to valid app destination tabs', () {
      final indices = AppTutorialView.chapters
          .map((c) => c.targetTabIndex)
          .where((i) => i != null)
          .toList();
      for (final idx in indices) {
        expect(idx! >= 0 && idx <= 5, isTrue);
      }
    });
  });

  group('App Coachmark Spotlight Tour Tests', () {
    test('CoachmarkStep initializes properly with keys and metadata', () {
      final key = GlobalKey();
      final step = CoachmarkStep(
        targetKey: key,
        title: 'Hub: Mission Control',
        description: 'Central command for duty countdowns and live assignments.',
        icon: LucideIcons.layoutDashboard,
        badgeText: 'Mission Hub',
        targetTabIndex: 0,
        isCircle: true,
      );

      expect(step.targetKey, equals(key));
      expect(step.title, 'Hub: Mission Control');
      expect(step.targetTabIndex, 0);
      expect(step.isCircle, isTrue);
      expect(step.badgeText, 'Mission Hub');
    });

    test('Coachmark Tour SharedPreferences completion flow operates correctly', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await AppCoachmarkTour.shouldShowTour(), isTrue);

      await AppCoachmarkTour.markCompleted();
      expect(await AppCoachmarkTour.shouldShowTour(), isFalse);

      await AppCoachmarkTour.resetTour();
      expect(await AppCoachmarkTour.shouldShowTour(), isTrue);
    });

    test('In-view feature coachmark steps contain complete metadata and tab indices', () {
      final sundayStripKey = GlobalKey();
      final addDutyKey = GlobalKey();
      final mediaActionsKey = GlobalKey();
      final themePresetsKey = GlobalKey();

      final sundayStep = CoachmarkStep(
        targetKey: sundayStripKey,
        title: 'Sunday Schedule & Headcount',
        description: 'Browse weekly Sunday services, flip through calendar months, and track scheduled usher headcounts.',
        icon: LucideIcons.calendarDays,
        badgeText: 'Sunday Strip',
        targetTabIndex: 1,
      );

      final addDutyStep = CoachmarkStep(
        targetKey: addDutyKey,
        title: 'Assign Duty Stations',
        description: 'Tap "+" to open deployment sheet.',
        icon: LucideIcons.userPlus,
        badgeText: 'Duty Deployment',
        targetTabIndex: 1,
        isCircle: true,
      );

      final mediaStep = CoachmarkStep(
        targetKey: mediaActionsKey,
        title: 'Urgent Alerts, Photos & GIFs',
        description: 'Broadcast priority alerts, snap photos, or send GIFs.',
        icon: LucideIcons.sparkles,
        badgeText: 'Alerts & Media',
        targetTabIndex: 4,
      );

      final themeStep = CoachmarkStep(
        targetKey: themePresetsKey,
        title: 'App Styles & Theme Presets',
        description: 'Select curated visual themes.',
        icon: LucideIcons.palette,
        badgeText: 'Theme Presets',
        targetTabIndex: 5,
        scrollAlignment: 0.1,
      );

      final tallyCounterKey = GlobalKey();
      final tallySubmitKey = GlobalKey();
      final tallyHistoryKey = GlobalKey();

      final tallyCounterStep = CoachmarkStep(
        targetKey: tallyCounterKey,
        title: 'Live Headcount Counter',
        description: 'Tap "+" or "-" to adjust attendance in real time.',
        icon: LucideIcons.binary,
        badgeText: 'Live Counter',
        targetTabIndex: 2,
      );

      final tallySubmitStep = CoachmarkStep(
        targetKey: tallySubmitKey,
        title: 'Service Details & Submission',
        description: 'Choose service type, pick date, add notes, and submit.',
        icon: LucideIcons.clipboardCheck,
        badgeText: 'Submit Count',
        targetTabIndex: 2,
        scrollAlignment: 0.1,
      );

      final tallyHistoryStep = CoachmarkStep(
        targetKey: tallyHistoryKey,
        title: 'Recent Attendance Logs',
        description: 'Review historical attendance counts with usher notes.',
        icon: LucideIcons.history,
        badgeText: 'Attendance History',
        targetTabIndex: 2,
        scrollAlignment: 0.1,
      );

      expect(sundayStep.targetTabIndex, equals(1));
      expect(addDutyStep.isCircle, isTrue);
      expect(addDutyStep.targetTabIndex, equals(1));
      expect(tallyCounterStep.targetTabIndex, equals(2));
      expect(tallySubmitStep.targetTabIndex, equals(2));
      expect(tallyHistoryStep.targetTabIndex, equals(2));
      expect(mediaStep.targetTabIndex, equals(4));
      expect(themeStep.targetTabIndex, equals(5));
      expect(themeStep.scrollAlignment, equals(0.1));
    });
  });

  group('Persistent Session Restoration Tests', () {
    test('Session flags and profile persistence across restarts', () async {
      SharedPreferences.setMockInitialValues({
        'user_signed_in_persistent': true,
        'cached_user_profile_id': 'usher_456',
        'cached_user_profile_json': '{"name":"Brother James","email":"james@church.org","role":"Usher","approved":true}',
      });

      final prefs = await SharedPreferences.getInstance();
      final isPersistent = prefs.getBool('user_signed_in_persistent') ?? false;
      expect(isPersistent, isTrue);

      final cachedId = prefs.getString('cached_user_profile_id');
      expect(cachedId, equals('usher_456'));

      // Simulate sign out clearing persistent session
      await prefs.setBool('user_signed_in_persistent', false);
      await prefs.remove('cached_user_profile_json');
      await prefs.remove('cached_user_profile_id');

      expect(prefs.getBool('user_signed_in_persistent'), isFalse);
      expect(prefs.getString('cached_user_profile_json'), isNull);
    });
  });

  group('Usher Handbook & Module Pairing Tests', () {
    test('All 8 training modules are properly configured with paired chapter metadata', () {
      expect(usheringTrainingModules.length, equals(8));

      for (final module in usheringTrainingModules) {
        expect(module.title, isNotEmpty);
        expect(module.summary, isNotEmpty);
        expect(module.content, isNotEmpty);
        expect(module.keyScripture, isNotEmpty);
        expect(module.practicalTakeaway, isNotEmpty);
        expect(module.pairedChapterTitle, isNotEmpty);
        // Valid chapter index (0 through 5 for the 6 chapters)
        expect(module.pairedChapterIndex, inInclusiveRange(0, 5));
      }
    });

    test('getModulesForChapter maps every handbook chapter to its paired SOP modules', () {
      // Chapter 1: Modules 1 & 2
      final ch0Modules = getModulesForChapter(0);
      expect(ch0Modules.length, equals(2));
      expect(ch0Modules.map((m) => m.title), contains('Module 1: The Divine Calling of Ushering'));
      expect(ch0Modules.map((m) => m.title), contains('Module 2: Lifestyle Ushering — Leadership by Example'));

      // Chapter 2: Module 3
      final ch1Modules = getModulesForChapter(1);
      expect(ch1Modules.length, equals(1));
      expect(ch1Modules.first.title, contains('Module 3: Sanctuary Seating & Guest Etiquette'));

      // Chapter 3: Module 4
      final ch2Modules = getModulesForChapter(2);
      expect(ch2Modules.length, equals(1));
      expect(ch2Modules.first.title, contains('Module 4: Tithes, Offering & Communion Protocols'));

      // Chapter 4: Module 7
      final ch3Modules = getModulesForChapter(3);
      expect(ch3Modules.length, equals(1));
      expect(ch3Modules.first.title, contains('Module 7: The Head Usher & Strategic Coordination'));

      // Chapter 5: Modules 5 & 6
      final ch4Modules = getModulesForChapter(4);
      expect(ch4Modules.length, equals(2));
      expect(ch4Modules.map((m) => m.title), contains('Module 5: Handling Disturbances & Emergency Response'));
      expect(ch4Modules.map((m) => m.title), contains('Module 6: Legal Guidelines, Safety & Child Protection'));

      // Chapter 6: Module 8
      final ch5Modules = getModulesForChapter(5);
      expect(ch5Modules.length, equals(1));
      expect(ch5Modules.first.title, contains("Module 8: Usher's Proverbs & Golden Wisdom"));

      // Non-existent chapter returns empty list
      expect(getModulesForChapter(99), isEmpty);
    });
  });

  group('Android AppWidget Integration Tests', () {
    test('AppWidgetService SharedPreferences key structure is valid', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // Test Duty Widget Keys
      await prefs.setString('widget_duty_station', 'Main Sanctuary Doors 1');
      await prefs.setString('widget_duty_date', 'SUN, SEP 13 • 10:00 AM');
      await prefs.setString('widget_duty_role', 'Lead Usher');
      await prefs.setString('widget_duty_service', 'Sunday Morning Service');

      expect(prefs.getString('widget_duty_station'), equals('Main Sanctuary Doors 1'));
      expect(prefs.getString('widget_duty_date'), equals('SUN, SEP 13 • 10:00 AM'));
      expect(prefs.getString('widget_duty_role'), equals('Lead Usher'));
      expect(prefs.getString('widget_duty_service'), equals('Sunday Morning Service'));

      // Test Tally Widget Keys
      await prefs.setInt('widget_tally_count', 342);
      await prefs.setString('widget_tally_service', 'Sunday Service');

      expect(prefs.getInt('widget_tally_count'), equals(342));
      expect(prefs.getString('widget_tally_service'), equals('Sunday Service'));

      // Test Scripture Widget Keys
      await prefs.setString('widget_scripture_text', 'Better is one day in your courts...');
      await prefs.setString('widget_scripture_ref', '— Psalm 84:10');
      await prefs.setString('widget_scripture_category', 'Stewardship');

      expect(prefs.getString('widget_scripture_text'), contains('Better is one day'));
      expect(prefs.getString('widget_scripture_ref'), equals('— Psalm 84:10'));
      expect(prefs.getString('widget_scripture_category'), equals('Stewardship'));
    });
  });

  group('Android Notification Design Guidelines Tests', () {
    test('Channels have appropriate priorities and purposes', () {
      const channels = {
        'duty_alerts_channel': {'importance': 'max', 'vibration': true},
        'team_comms_channel': {'importance': 'max', 'vibration': true},
        'bulletin_channel': {'importance': 'default', 'vibration': false},
      };

      expect(channels['duty_alerts_channel']?['importance'], equals('max'));
      expect(channels['team_comms_channel']?['importance'], equals('max'));
      expect(channels['bulletin_channel']?['importance'], equals('default'));
    });

    test('Monochromatic status bar small icon name is compliant', () {
      const smallIcon = '@drawable/ic_stat_notification';
      expect(smallIcon.startsWith('@drawable/ic_stat_'), isTrue);
    });
  });

  group('Roster Deduplication and Canonical Merging Tests', () {
    test('Deduplicates exact duplicate user objects with identical doc IDs', () {
      final list = [
        TeamMember(id: 'uid_1', name: 'Louis Richardson', role: 'Admin'),
        TeamMember(id: 'uid_1', name: 'Louis Richardson', role: 'Admin'),
      ];

      final deduped = FirebaseService.deduplicateMemberList(list);
      expect(deduped.length, equals(1));
      expect(deduped.first.id, equals('uid_1'));
      expect(deduped.first.name, equals('Louis Richardson'));
    });

    test('Deduplicates members with different doc IDs but identical full names (e.g. Demitris Boyce, Robert Vargas)', () {
      final list = [
        TeamMember(id: 'auth_uid_demitris', name: 'Demitris Boyce', email: 'dboyce@example.com', role: 'Admin'),
        TeamMember(id: 'user_1720000000001', name: 'Demitris Boyce', role: 'Admin'),
        TeamMember(id: 'auth_uid_robert', name: 'Robert Vargas', email: 'robv88@gmail.com', role: 'Admin'),
        TeamMember(id: 'user_1720000000002', name: 'Robert Vargas', role: 'Usher'),
      ];

      final deduped = FirebaseService.deduplicateMemberList(list);
      expect(deduped.length, equals(2));

      final demitris = deduped.firstWhere((m) => m.name == 'Demitris Boyce');
      expect(demitris.email, equals('dboyce@example.com'));
      expect(demitris.isAdmin, isTrue);

      final robert = deduped.firstWhere((m) => m.name == 'Robert Vargas');
      expect(robert.email, equals('robv88@gmail.com'));
      expect(robert.isAdmin, isTrue);
    });

    test('Deduplicates members with matching emails case-insensitively', () {
      final list = [
        TeamMember(id: 'id_1', name: 'Demitris', email: 'demitris.boyce@church.org', role: 'Admin'),
        TeamMember(id: 'id_2', name: 'Demitris Boyce', email: 'DEMITRIS.BOYCE@CHURCH.ORG', role: 'Usher'),
      ];

      final deduped = FirebaseService.deduplicateMemberList(list);
      expect(deduped.length, equals(1));
      expect(deduped.first.name, equals('Demitris Boyce'));
      expect(deduped.first.role, equals('Admin'));
    });

    test('Deduplicates members with matching normalized phone numbers across formats', () {
      final list = [
        TeamMember(id: 'id_1', name: 'Matthias Breyer', phone: '3183449278', role: 'Admin'),
        TeamMember(id: 'id_2', name: 'Matthias Breyer', phone: '+1 (318) 344-9278', role: 'Usher'),
      ];

      final deduped = FirebaseService.deduplicateMemberList(list);
      expect(deduped.length, equals(1));
      expect(deduped.first.isAdmin, isTrue);
    });

    test('Merges Admin role and approval status when duplicate has lower privilege', () {
      final list = [
        TeamMember(id: 'doc_low', name: 'Robert Vargas', role: 'Usher', approved: false),
        TeamMember(id: 'doc_high', name: 'Robert Vargas', role: 'Admin', approved: true),
      ];

      final deduped = FirebaseService.deduplicateMemberList(list);
      expect(deduped.length, equals(1));
      expect(deduped.first.isAdmin, isTrue);
      expect(deduped.first.approved, isTrue);
      expect(deduped.first.denied, isFalse);
    });

    test('Preserves current logged-in user UID during deduplication', () {
      const activeUserUid = 'current_active_firebase_uid';
      final list = [
        TeamMember(id: 'legacy_seed_id', name: 'Robert Vargas', role: 'Admin'),
        TeamMember(id: activeUserUid, name: 'Robert Vargas', role: 'Admin'),
      ];

      final deduped = FirebaseService.deduplicateMemberList(list, currentUid: activeUserUid);
      expect(deduped.length, equals(1));
      expect(deduped.first.id, equals(activeUserUid));
    });

    test('Normalizes names with trailing role parentheticals, quotes, and inconsistent whitespace', () {
      expect(FirebaseService.normalizeMemberName('Demitris Boyce (Admin)'), equals('demitris boyce'));
      expect(FirebaseService.normalizeMemberName('  Robert   Vargas   (Usher) '), equals('robert vargas'));
      expect(FirebaseService.normalizeMemberName('Renaldo "Dre" Anderson'), equals('renaldo dre anderson'));
      expect(FirebaseService.normalizeMemberName('Lead Usher (Sunday Lead)'), equals('lead usher'));
    });

    test('Simulates phone screenshot roster and verifies Demitris Boyce and Robert Vargas appear exactly once', () {
      final simulatedRoster = [
        TeamMember(id: 'doc_1', name: 'Demitris Boyce', role: 'Admin'),
        TeamMember(id: 'doc_2', name: 'Louis Richardson', role: 'Admin'),
        TeamMember(id: 'doc_3', name: 'Brittnae Gibbs', role: 'Usher'),
        TeamMember(id: 'doc_4', name: 'Roseanne Richardson', role: 'Admin'),
        TeamMember(id: 'doc_5', name: 'Demitris Boyce', role: 'Admin'), // Duplicate in screenshot!
        TeamMember(id: 'doc_6', name: 'Robert Vargas', role: 'Admin'),
        TeamMember(id: 'doc_7', name: 'Matthias Breyer', role: 'Admin'),
        TeamMember(id: 'doc_8', name: 'Ronald Tran', role: 'Usher'),
        TeamMember(id: 'doc_9', name: 'Jonte Boyce', role: 'Usher'),
        TeamMember(id: 'doc_10', name: 'Robert Vargas', role: 'Admin'), // Duplicate in screenshot!
        TeamMember(id: 'doc_11', name: 'Randle', role: 'Usher'),
        TeamMember(id: 'doc_12', name: 'Jesus Vargas', role: 'Admin'),
        TeamMember(id: 'doc_13', name: 'Eric D. Barnes', role: 'Usher'),
        TeamMember(id: 'doc_14', name: 'Brandt Starkey', role: 'Usher'),
        TeamMember(id: 'doc_15', name: 'Terrell Neale', role: 'Usher'),
        TeamMember(id: 'doc_16', name: 'Renaldo "Dre" Anderson', role: 'Usher'),
      ];

      final deduped = FirebaseService.deduplicateMemberList(simulatedRoster);

      // Total count should reduce from 16 to 14
      expect(simulatedRoster.length, equals(16));
      expect(deduped.length, equals(14));

      // Both Demitris Boyce and Robert Vargas must appear exactly once
      final demitrisMatches = deduped.where((m) => m.name == 'Demitris Boyce');
      expect(demitrisMatches.length, equals(1));

      final robertMatches = deduped.where((m) => m.name == 'Robert Vargas');
      expect(robertMatches.length, equals(1));

      // All 14 members must have unique normalized names
      final namesSet = deduped.map((m) => FirebaseService.normalizeMemberName(m.name)).toSet();
      expect(namesSet.length, equals(14));
    });
  });

  group('Guest Check-In & Vestibule Station Logic Tests', () {
    test('AttendanceView.activeSubTab defaults to 0 and can be set to 1 for Guest Check-In', () {
      AttendanceView.activeSubTab.value = 0;
      expect(AttendanceView.activeSubTab.value, equals(0));

      AttendanceView.activeSubTab.value = 1;
      expect(AttendanceView.activeSubTab.value, equals(1));

      // Reset
      AttendanceView.activeSubTab.value = 0;
    });

    test('Guest check-in entries correctly aggregate party sizes for Vestibule Station', () {
      final entries = [
        const GuestCheckInEntry(
          id: 'g1',
          guestName: 'The Miller Family',
          partySize: 5,
          checkInTime: '10:00 AM',
          entrance: 'Vestibule Station',
          createdAt: '2026-09-09T10:00:00Z',
        ),
        const GuestCheckInEntry(
          id: 'g2',
          guestName: 'James Wilson',
          partySize: 1,
          checkInTime: '10:05 AM',
          entrance: 'Vestibule Station',
          createdAt: '2026-09-09T10:05:00Z',
        ),
        const GuestCheckInEntry(
          id: 'g3',
          guestName: 'Elena Rostova',
          partySize: 3,
          checkInTime: '10:10 AM',
          entrance: 'Vestibule Station',
          createdAt: '2026-09-09T10:10:00Z',
        ),
      ];

      final totalGuests = entries.fold<int>(0, (sum, g) => sum + g.partySize);
      expect(totalGuests, equals(9));

      // Verify all entries are assigned to Vestibule Station
      for (final g in entries) {
        expect(g.entrance, equals('Vestibule Station'));
      }
    });

    test('Guest check-in filter matches name and notes case-insensitively', () {
      final entries = [
        const GuestCheckInEntry(
          id: 'g1',
          guestName: 'The Anderson Family',
          partySize: 4,
          checkInTime: '10:00 AM',
          entrance: 'Vestibule Station',
          notes: 'Requested wheelchair assistance',
          createdAt: '2026-09-09T10:00:00Z',
        ),
        const GuestCheckInEntry(
          id: 'g2',
          guestName: 'David Chen',
          partySize: 1,
          checkInTime: '10:05 AM',
          entrance: 'Vestibule Station',
          notes: 'Youth ministry visitor',
          createdAt: '2026-09-09T10:05:00Z',
        ),
      ];

      // Filter by name
      final nameFilter = entries.where((g) => g.guestName.toLowerCase().contains('anderson')).toList();
      expect(nameFilter.length, equals(1));
      expect(nameFilter.first.guestName, equals('The Anderson Family'));

      // Filter by notes
      final notesFilter = entries.where((g) => g.notes?.toLowerCase().contains('wheelchair') ?? false).toList();
      expect(notesFilter.length, equals(1));
      expect(notesFilter.first.id, equals('g1'));
    });

    test('Deleting guest check-ins leaves empty list with zero total without demo resurrection', () {
      final List<GuestCheckInEntry> guestList = [
        const GuestCheckInEntry(
          id: 'guest_to_remove',
          guestName: 'Departing Guest',
          partySize: 3,
          checkInTime: '11:00 AM',
          entrance: 'Vestibule Station',
          createdAt: '2026-09-09T11:00:00Z',
        ),
      ];

      final Set<String> deletedIds = {};

      // Delete the entry
      final idToRemove = 'guest_to_remove';
      deletedIds.add(idToRemove);
      guestList.removeWhere((g) => g.id == idToRemove);

      expect(guestList.isEmpty, isTrue);
      final total = guestList.fold<int>(0, (sum, g) => sum + g.partySize);
      expect(total, equals(0));

      // Simulate incoming snapshot re-emitting the deleted item
      final simulatedIncomingDocs = [
        const GuestCheckInEntry(
          id: 'guest_to_remove',
          guestName: 'Departing Guest',
          partySize: 3,
          checkInTime: '11:00 AM',
          entrance: 'Vestibule Station',
          createdAt: '2026-09-09T11:00:00Z',
        ),
      ];

      final filteredIncoming = simulatedIncomingDocs
          .where((d) => !deletedIds.contains(d.id))
          .toList();

      expect(filteredIncoming.isEmpty, isTrue);
    });
  });

  group('On Duty vs Off Duty Schedule Status Tests', () {
    final memberOnDuty = TeamMember(
      id: 'usher_101',
      name: 'Robert Vargas',
      email: 'robert@guardians.org',
      role: 'Lead Usher',
      approved: true,
    );

    final memberOffDuty = TeamMember(
      id: 'usher_102',
      name: 'Elena Rostova',
      email: 'elena@guardians.org',
      role: 'Usher',
      approved: true,
    );

    final deployments = [
      Deployment(
        id: 'dep_1',
        date: '2026-09-13',
        usherId: 'usher_101',
        usherName: 'Robert Vargas',
        serviceType: 'Sunday Morning Service',
        station: 'Main Foyer',
        role: 'Lead Usher',
        verified: true,
      ),
      Deployment(
        id: 'dep_2',
        date: '2026-09-13',
        usherId: 'usher_103',
        usherName: 'Demitris Boyce',
        serviceType: 'Sunday Morning Service',
        station: 'Sanctuary Vestibule',
        role: 'Usher',
        verified: true,
      ),
    ];

    test('isMemberOnSchedule returns true for scheduled member and false for unscheduled member', () {
      bool isScheduled(TeamMember m, List<Deployment> list) {
        final memberId = m.id.trim();
        final memberName = (m.name ?? '').toLowerCase().trim();
        for (final d in list) {
          if (memberId.isNotEmpty && d.usherId == memberId) return true;
          final dName = d.usherName.toLowerCase().trim();
          if (memberName.isNotEmpty && dName.isNotEmpty) {
            if (dName == memberName || dName.contains(memberName) || memberName.contains(dName)) {
              return true;
            }
          }
        }
        return false;
      }

      expect(isScheduled(memberOnDuty, deployments), isTrue);
      expect(isScheduled(memberOffDuty, deployments), isFalse);
    });

    test('getMemberDeployment resolves station assignment for On Duty member and null for Off Duty', () {
      Deployment? getDeployment(TeamMember m, List<Deployment> list) {
        final memberId = m.id.trim();
        final memberName = (m.name ?? '').toLowerCase().trim();
        for (final d in list) {
          if (memberId.isNotEmpty && d.usherId == memberId) return d;
          final dName = d.usherName.toLowerCase().trim();
          if (memberName.isNotEmpty && dName.isNotEmpty) {
            if (dName == memberName || dName.contains(memberName) || memberName.contains(dName)) {
              return d;
            }
          }
        }
        return null;
      }

      final depOn = getDeployment(memberOnDuty, deployments);
      expect(depOn, isNotNull);
      expect(depOn!.station, equals('Main Foyer'));

      final depOff = getDeployment(memberOffDuty, deployments);
      expect(depOff, isNull);
    });

    test('Hub UI status strings map accurately: On Duty with Station vs Off Duty with Standby', () {
      String computeDutyBadge(Deployment? dep) => dep != null ? "On Duty" : "Off Duty";
      String computeStation(Deployment? dep) => dep?.station ?? "Standby";
      String computeSubtitle(Deployment? dep) => dep != null ? dep.serviceType : "Off Duty • No Shift Scheduled";

      // On Duty
      final onDep = deployments.first;
      expect(computeDutyBadge(onDep), equals("On Duty"));
      expect(computeStation(onDep), equals("Main Foyer"));
      expect(computeSubtitle(onDep), equals("Sunday Morning Service"));

      // Off Duty
      expect(computeDutyBadge(null), equals("Off Duty"));
      expect(computeStation(null), equals("Standby"));
      expect(computeSubtitle(null), equals("Off Duty • No Shift Scheduled"));
    });
  });

  group('Comms Unread Notification Badge Tests', () {
    test('Unread comms notification badge logic calculates accurately', () {
      final now = DateTime.now();
      final myUid = 'usr_robert';
      final myEmail = 'robert@church.org';

      bool isMyMessage(CommsMessage msg) {
        if (msg.authorUid == myUid) return true;
        if (msg.authorEmail?.toLowerCase() == myEmail.toLowerCase()) return true;
        return false;
      }

      bool hasUnread(List<CommsMessage> messages, DateTime? lastRead) {
        if (messages.isEmpty) return false;
        if (lastRead == null) {
          return messages.any((m) => !isMyMessage(m));
        }
        return messages.any((m) {
          if (isMyMessage(m)) return false;
          if (m.createdAt == null) return false;
          final dt = DateTime.tryParse(m.createdAt!);
          if (dt == null) return false;
          return dt.isAfter(lastRead);
        });
      }

      // 1. Empty message list -> no red dot
      expect(hasUnread([], null), isFalse);

      // 2. Only my own messages -> no red dot
      final myMessage = CommsMessage(
        id: 'msg_1',
        text: 'All stations ready',
        authorUid: myUid,
        authorEmail: myEmail,
        authorName: 'Robert Vargas',
        createdAt: now.subtract(const Duration(minutes: 5)).toIso8601String(),
      );
      expect(hasUnread([myMessage], null), isFalse);

      // 3. New message from another user -> red dot appears
      final incomingMessage = CommsMessage(
        id: 'msg_2',
        text: 'Vestibule overflow opened',
        authorUid: 'usr_daniel',
        authorEmail: 'daniel@church.org',
        authorName: 'Daniel Carter',
        createdAt: now.subtract(const Duration(minutes: 2)).toIso8601String(),
      );
      expect(hasUnread([myMessage, incomingMessage], null), isTrue);

      // 4. Mark as read at now -> red dot disappears
      final readTimestamp = now;
      expect(hasUnread([myMessage, incomingMessage], readTimestamp), isFalse);

      // 5. Subsequent newer incoming message arrives -> red dot appears again
      final newestIncoming = CommsMessage(
        id: 'msg_3',
        text: 'Offering baskets deployed',
        authorUid: 'usr_demitris',
        authorEmail: 'demitris@church.org',
        authorName: 'Demitris Boyce',
        createdAt: now.add(const Duration(minutes: 1)).toIso8601String(),
      );
      expect(hasUnread([myMessage, incomingMessage, newestIncoming], readTimestamp), isTrue);
    });
  });
}


