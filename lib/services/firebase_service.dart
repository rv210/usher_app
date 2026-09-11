import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'bubble_service.dart';
import 'app_widget_service.dart';
import 'package:intl/intl.dart';
import '../models/team_member.dart';
import '../models/deployment.dart';
import '../models/attendance_log.dart';
import '../models/comms_message.dart';
import '../models/guest_check_in.dart';
import '../models/announcement.dart';
import '../theme/app_theme.dart';

const String adminCodeConstant = 'GUARDIAN-LEAD-2024';

class FirebaseService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? _currentUser;
  TeamMember? _userProfile;
  String? _userCustomPhotoPath;
  String? get userCustomPhotoPath => _userCustomPhotoPath ?? _userProfile?.photoUrl;
  String? _userCustomCardBgPath;
  String get userCustomCardBgPath => _userCustomCardBgPath ?? 'assets/images/hub_header_bg.jpg';
  bool _authLoading = false;
  bool _profileLoading = false;
  bool _isOfflineDemoMode = false;
  bool _isUserSignedIn = false;
  ThemeMode _themeMode = ThemeMode.light;
  AppStyleTheme _activeStyleTheme = AppStyleTheme.guardiansGold;

  List<TeamMember> _liveRoster = [];
  List<TeamMember> _pendingUsers = [];
  List<TeamMember> _approvedUsers = [];
  List<TeamMember> _deniedUsers = [];
  List<AttendanceLogEntry> _attendanceLogs = [];
  List<CommsMessage> _commsMessages = [];
  List<Deployment> _deployments = [];
  DateTime? _lastReadCommsTimestamp;
  DateTime? get lastReadCommsTimestamp => _lastReadCommsTimestamp;

  Future<void> _writeTeamDoc(String docId, Map<String, dynamic> data) async {
    final List<String> collections = ['team', 'users', 'ushers', 'team_members', 'roster'];
    for (var col in collections) {
      try {
        await _db.collection(col).doc(docId).set(data, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  Future<void> _deleteTeamDoc(String docId) async {
    final List<String> collections = ['team', 'teams', 'team_members', 'ushers', 'roster', 'users'];
    for (var colName in collections) {
      try {
        await _db.collection(colName).doc(docId).delete();
      } catch (_) {}
    }
  }

  Future<int> purgeGhostMembers() async {
    int purgedCount = 0;
    final ghosts = _liveRoster.where((u) {
      final isUsherFallbackName = u.name == null || u.name == 'Usher' || u.name!.trim().isEmpty;
      final hasNoEmail = u.email == null || u.email!.trim().isEmpty;
      final hasNoPhone = u.phone == null || u.phone!.trim().isEmpty;
      return isUsherFallbackName && hasNoEmail && hasNoPhone;
    }).toList();

    for (final ghost in ghosts) {
      await deleteTeamMember(ghost.id);
      purgedCount++;
    }

    // Also identify and remove stale duplicate documents across Firestore collections
    try {
      final List<String> collectionsToList = ['team', 'users', 'ushers', 'team_members', 'roster'];
      final List<TeamMember> allRaw = [];
      for (var colName in collectionsToList) {
        final snap = await _db.collection(colName).get();
        for (var d in snap.docs) {
          try {
            allRaw.add(TeamMember.fromMap(d.data(), d.id));
          } catch (_) {}
        }
      }

      final canonicalList = deduplicateMemberList(allRaw, currentUid: _currentUser?.uid);
      for (final canonical in canonicalList) {
        final duplicates = allRaw.where((r) => r.id != canonical.id && isSameMember(r, canonical)).toList();
        for (final dup in duplicates) {
          await deleteTeamMember(dup.id);
          purgedCount++;
        }
      }
    } catch (_) {}

    await refreshRoster();
    return purgedCount;
  }

  String _bulletinText = "Usher Team Meeting: Monthly alignment & protocol review this Sunday at 8:30 AM in Room 204.";
  String _dashboardLeadName = "Lead Usher";

  // Announcements live state & persistence
  final Set<String> _deletedAnnouncementIds = {};
  List<Announcement> _announcements = [
    const Announcement(
      id: 'ann_meeting_1',
      title: 'Usher Team Meeting & Briefing',
      description: 'Monthly team alignment, protocol review, and communion distribution coordination this Sunday at 8:30 AM in Room 204.',
      date: 'Sep 13, 2026',
      category: 'Usher Meeting',
    ),
    const Announcement(
      id: 'ann_worship_1',
      title: 'All-Church Night of Worship',
      description: 'Join us for an evening of extended acoustic worship, prayer, and communion this Friday at 7:00 PM in the Main Sanctuary.',
      date: 'Sep 18, 2026',
      category: 'Worship Night',
    ),
    const Announcement(
      id: 'ann_bible_1',
      title: 'Midweek Bible Study: Book of Acts',
      description: 'Deep dive into the early church and the ministry of Helps every Wednesday at 7:00 PM. Light dinner and fellowship at 6:15 PM.',
      date: 'Sep 16, 2026',
      category: 'Bible Study',
    ),
    const Announcement(
      id: 'ann_outreach_1',
      title: 'Community Food Drive & Outreach',
      description: 'Serving our neighborhood with fresh groceries and prayer this Saturday at 9:00 AM. Volunteers meet in the South Parking Lot.',
      date: 'Sep 19, 2026',
      category: 'Community Outreach',
    ),
    const Announcement(
      id: 'ann_member_1',
      title: 'New Member & Usher Orientation',
      description: 'Interested in learning more about our church or joining the ushering ministry? Next class starts this Sunday after 2nd service.',
      date: 'Sep 20, 2026',
      category: 'New Member Class',
    ),
    const Announcement(
      id: 'ann_volunteer_1',
      title: 'Volunteer Appreciation Sunday',
      description: 'Thank you to all our amazing ushers and volunteers! Fellowship brunch and recognition ceremony following morning service.',
      date: 'Sep 27, 2026',
      category: 'Volunteer Appreciation',
    ),
  ];

  List<Announcement> get announcements =>
      _announcements.where((a) => !_deletedAnnouncementIds.contains(a.id)).toList();
  Announcement? get latestAnnouncement {
    final active = announcements;
    return active.isNotEmpty ? active.first : null;
  }

  Future<void> addAnnouncement(Announcement ann) async {
    _deletedAnnouncementIds.remove(ann.id);
    _announcements.removeWhere((a) => a.id == ann.id);
    _announcements.insert(0, ann);
    _bulletinText = "${ann.title}: ${ann.description}";
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('deleted_announcement_ids', _deletedAnnouncementIds.toList());
      await prefs.setString('cached_announcements_json', jsonEncode(_announcements.map((a) => a.toMap()).toList()));
    } catch (e) {
      debugPrint("Error persisting added announcement: $e");
    }
    try {
      await _db.collection('announcements').doc(ann.id).set(ann.toMap());
      await _db.collection('settings').doc('bulletin').set({'text': _bulletinText});
    } catch (e) {
      debugPrint("Add announcement error: $e");
    }
  }

  Future<void> deleteAnnouncement(String id) async {
    _deletedAnnouncementIds.add(id);
    _announcements.removeWhere((a) => a.id == id);
    final active = announcements;
    if (active.isNotEmpty) {
      _bulletinText = "${active.first.title}: ${active.first.description}";
    } else {
      _bulletinText = "No active announcements.";
    }
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('deleted_announcement_ids', _deletedAnnouncementIds.toList());
      await prefs.setString('cached_announcements_json', jsonEncode(_announcements.map((a) => a.toMap()).toList()));
    } catch (e) {
      debugPrint("Error persisting deleted announcement: $e");
    }
    try {
      await _db.collection('announcements').doc(id).delete();
    } catch (e) {
      debugPrint("Delete announcement error: $e");
    }
  }

  // Tally Counter live state
  int _currentTallyCount = 0;
  String _activeServiceType = 'Sunday Service';
  int _lastLocalTallyUpdateTime = 0;

  // Guest check-in live state
  List<GuestCheckInEntry> _guestCheckIns = [];
  final Set<String> _deletedGuestIds = {};
  List<GuestCheckInEntry> get guestCheckIns => _guestCheckIns;
  int get todayGuestCount => _guestCheckIns.fold(0, (sum, g) => sum + g.partySize);

  // Getters
  User? get currentUser => _currentUser ?? _auth.currentUser;
  bool get isUserSignedIn => _isUserSignedIn || _currentUser != null || _auth.currentUser != null;

  TeamMember? get userProfile {
    if (_userProfile != null) return _userProfile;
    final activeUser = _currentUser ?? _auth.currentUser;
    if (activeUser != null) {
      final email = activeUser.email ?? '';
      final name = (activeUser.displayName != null && activeUser.displayName!.trim().isNotEmpty)
          ? activeUser.displayName!.trim()
          : (email.contains('@') ? email.split('@').first : 'Usher');
      return TeamMember(
        id: activeUser.uid,
        name: name,
        email: email,
        phone: '',
        role: 'Admin',
        approved: true,
      );
    }
    return null;
  }
  bool get authLoading => _authLoading;
  bool get profileLoading => _profileLoading;
  bool get isOfflineDemoMode => _isOfflineDemoMode;
  ThemeMode get themeMode => _themeMode;
  AppStyleTheme get activeStyleTheme => _activeStyleTheme;

  List<TeamMember> get liveRoster => deduplicateMemberList(_liveRoster, currentUid: _currentUser?.uid);
  List<TeamMember> get pendingUsers => deduplicateMemberList(_pendingUsers, currentUid: _currentUser?.uid);
  List<TeamMember> get approvedUsers => deduplicateMemberList(_approvedUsers, currentUid: _currentUser?.uid);
  List<TeamMember> get deniedUsers => deduplicateMemberList(_deniedUsers, currentUid: _currentUser?.uid);
  List<AttendanceLogEntry> get attendanceLogs => _attendanceLogs;
  List<CommsMessage> get commsMessages => _commsMessages;
  List<Deployment> get deployments => _deployments;

  bool _isMyCommsMessage(CommsMessage msg) {
    final curUid = _currentUser?.uid;
    final curEmail = _currentUser?.email?.toLowerCase().trim();
    final profileEmail = _userProfile?.email?.toLowerCase().trim();
    final profileName = _userProfile?.name?.toLowerCase().trim();

    if (curUid != null && msg.authorUid != null && msg.authorUid == curUid) {
      return true;
    }
    if (curEmail != null && curEmail.isNotEmpty && msg.authorEmail != null && msg.authorEmail!.toLowerCase().trim() == curEmail) {
      return true;
    }
    if (profileEmail != null && profileEmail.isNotEmpty && msg.authorEmail != null && msg.authorEmail!.toLowerCase().trim() == profileEmail) {
      return true;
    }
    if (profileName != null && profileName.isNotEmpty && msg.authorName != null && msg.authorName!.toLowerCase().trim() == profileName) {
      return true;
    }
    return false;
  }

  /// Returns true if there are unread comms messages from other team members.
  bool get hasUnreadCommsMessages {
    if (_commsMessages.isEmpty) return false;
    final lastRead = _lastReadCommsTimestamp;
    if (lastRead == null) {
      // If user hasn't opened comms yet, show badge if any message exists from other team members
      return _commsMessages.any((m) => !_isMyCommsMessage(m));
    }
    return _commsMessages.any((m) {
      if (_isMyCommsMessage(m)) return false;
      if (m.createdAt == null) return false;
      final dt = DateTime.tryParse(m.createdAt!);
      if (dt == null) return false;
      return dt.isAfter(lastRead);
    });
  }

  /// Total count of unread incoming comms messages
  int get unreadCommsCount {
    if (_commsMessages.isEmpty) return 0;
    final lastRead = _lastReadCommsTimestamp;
    if (lastRead == null) {
      return _commsMessages.where((m) => !_isMyCommsMessage(m)).length;
    }
    return _commsMessages.where((m) {
      if (_isMyCommsMessage(m)) return false;
      if (m.createdAt == null) return false;
      final dt = DateTime.tryParse(m.createdAt!);
      if (dt == null) return false;
      return dt.isAfter(lastRead);
    }).length;
  }

  /// Marks all incoming comms messages as read and persists the timestamp
  Future<void> markCommsAsRead() async {
    _lastReadCommsTimestamp = DateTime.now();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_read_comms_time', _lastReadCommsTimestamp!.toIso8601String());
    } catch (e) {
      debugPrint("Error saving last_read_comms_time: $e");
    }
  }

  /// Checks whether a specific team member is scheduled in deployments (optionally on targetDate).
  bool isMemberOnSchedule(TeamMember member, {String? targetDate}) {
    return getMemberDeployment(member, targetDate: targetDate) != null;
  }

  /// Finds the deployment for a member for an optional targetDate (or any active deployment).
  Deployment? getMemberDeployment(TeamMember member, {String? targetDate}) {
    if (_deployments.isEmpty) return null;
    final memberId = member.id.trim();
    final memberName = (member.name ?? '').toLowerCase().trim();

    Iterable<Deployment> pool = _deployments;
    if (targetDate != null && targetDate.trim().isNotEmpty) {
      pool = pool.where((d) => d.date.trim() == targetDate.trim());
    }

    for (final d in pool) {
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

  String get bulletinText => _bulletinText;
  String get dashboardLeadName => _dashboardLeadName;
  int get currentTallyCount => _currentTallyCount;
  String get activeServiceType => _activeServiceType;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSubscription;
  final Set<String> _processedNotificationIds = {};

  void initPushNotifications() async {
    try {
      if (Firebase.apps.isEmpty) return;
      if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux)) {
        return;
      }
      final messaging = FirebaseMessaging.instance;

      if (!kIsWeb) {
        try {
          await _localNotifications.initialize(
            const InitializationSettings(
              android: AndroidInitializationSettings('@mipmap/ic_launcher'),
              iOS: DarwinInitializationSettings(
                requestAlertPermission: false,
                requestBadgePermission: false,
                requestSoundPermission: false,
              ),
            ),
          );

          if (defaultTargetPlatform == TargetPlatform.android) {
            final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
            if (androidPlugin != null) {
              // 1. High Priority Duty & Station Channel
              await androidPlugin.createNotificationChannel(
                const AndroidNotificationChannel(
                  'duty_alerts_channel',
                  'Station & Duty Alerts',
                  description: 'Urgent station deployments, shift changes, and roster updates',
                  importance: Importance.max,
                  playSound: true,
                  enableVibration: true,
                ),
              );

              // 2. High Priority Team Comms Channel
              await androidPlugin.createNotificationChannel(
                const AndroidNotificationChannel(
                  'team_comms_channel',
                  'Team Communications',
                  description: 'Live usher messaging, coordinator broadcasts, and chat bubbles',
                  importance: Importance.max,
                  playSound: true,
                  enableVibration: true,
                ),
              );

              // 3. General Announcements & Bulletin Channel
              await androidPlugin.createNotificationChannel(
                const AndroidNotificationChannel(
                  'bulletin_channel',
                  'Leadership Bulletins & Scripture',
                  description: 'Church leadership bulletins and daily devotionals',
                  importance: Importance.defaultImportance,
                  playSound: true,
                  enableVibration: false,
                ),
              );

              await androidPlugin.requestNotificationsPermission();
            }
          }
        } catch (_) {}
      }
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      // Display system head-up notification banner even when app is in foreground on iOS
      try {
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      } catch (_) {}

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
          try {
            String? apnsToken = await messaging.getAPNSToken();
            if (apnsToken == null) {
              await Future.delayed(const Duration(seconds: 2));
              apnsToken = await messaging.getAPNSToken();
            }
            debugPrint("iOS APNs Token: $apnsToken");
          } catch (e) {
            debugPrint("APNs Token retrieval info: $e");
          }
        }

        try {
          _fcmToken = await messaging.getToken();
          debugPrint("FCM Device Token: $_fcmToken");
        } catch (e) {
          debugPrint("FCM Token fetch info: $e");
        }

        if (_currentUser != null && _fcmToken != null) {
          final tokenData = {
            'token': _fcmToken,
            'uid': _currentUser!.uid,
            'email': _currentUser!.email ?? '',
            'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
            'lastUpdated': DateTime.now().toIso8601String(),
          };
          await _db.collection('user_tokens').doc(_currentUser!.uid).set(tokenData, SetOptions(merge: true));
        }

        // Cancel previous listeners to guarantee exactly one active listener
        await _onMessageSubscription?.cancel();
        await _onMessageOpenedAppSubscription?.cancel();

        _onMessageSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
          // Android pushes are sent data-only (see functions/src/index.ts) so the
          // client is the sole renderer; title/body live in `data`, not `notification`.
          final title = isAndroid ? (message.data['title'] ?? message.notification?.title) : message.notification?.title;
          final body = isAndroid ? (message.data['body'] ?? message.notification?.body) : message.notification?.body;
          final msgId = message.messageId ?? '${message.sentTime?.millisecondsSinceEpoch}_${title}_$body';

          // Deduplicate if already processed
          if (_processedNotificationIds.contains(msgId)) {
            debugPrint("Ignoring duplicate push notification: $msgId");
            return;
          }
          _processedNotificationIds.add(msgId);
          if (_processedNotificationIds.length > 100) {
            _processedNotificationIds.remove(_processedNotificationIds.first);
          }

          debugPrint("Received Push Notification: $title");
          if (title != null && isAndroid) {
            final isComms = (message.data['type'] == 'comms') ||
                title.toLowerCase().contains('comms') ||
                title.toLowerCase().contains('chat') ||
                title.toLowerCase().contains('message');

            if (isComms) {
              final sender = message.data['senderName'] ?? title;
              final text = message.data['message'] ?? body ?? '';
              final senderId = message.data['senderId'] ?? 'team_lead';
              BubbleService.showBubbleNotification(
                senderName: sender,
                message: text,
                senderId: senderId,
                shortcutId: 'comms_$senderId',
              );
            } else {
              final notificationId = msgId.hashCode & 0x7FFFFFFF;
              _localNotifications.show(
                notificationId,
                title,
                body,
                NotificationDetails(
                  android: AndroidNotificationDetails(
                    'duty_alerts_channel',
                    'Station & Duty Alerts',
                    channelDescription: 'Urgent station deployments, shift changes, and roster updates',
                    importance: Importance.max,
                    priority: Priority.high,
                    icon: '@drawable/ic_stat_notification',
                    color: const Color(0xFFD4AF37),
                    styleInformation: BigTextStyleInformation(
                      body ?? '',
                      contentTitle: title,
                      summaryText: 'Guardians Duty',
                    ),
                    enableVibration: true,
                    playSound: true,
                  ),
                ),
              );
            }
          }
        });

        _onMessageOpenedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          debugPrint("Opened Push Notification App: ${message.notification?.title}");
          try {
            _localNotifications.cancelAll();
          } catch (_) {}
        });
      }
    } catch (e) {
      debugPrint("Push notification setup info: $e");
    }
  }

  Future<void> triggerTestPushNotification({String? title, String? body}) async {
    final notifTitle = title ?? "🔔 Sanctuary Main Doors Assignment";
    final notifBody = body ?? "You are scheduled for Sanctuary Main Doors (Sunday Morning Service). Tap to review duties.";

    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await BubbleService.showDutyNotification(
          title: notifTitle,
          body: notifBody,
          stationName: "Sanctuary Main Doors",
          targetTab: 0,
        );
      }
    } catch (e) {
      debugPrint("Test push notification error: $e");
    }
  }

  Future<bool> triggerTestBubbleNotification({String? senderName, String? message}) async {
    final name = senderName ?? "Sister Robinson (Team Lead)";
    final text = message ?? "Urgent update: 2nd floor balcony team switch needed at 10:30 AM!";
    return BubbleService.showBubbleNotification(
      senderName: name,
      message: text,
      senderId: "usher_lead_test",
      shortcutId: "comms_lead_test",
    );
  }

  Future<void> sendPushNotificationAlert({required String title, required String body}) async {
    try {
      final notifDoc = {
        'id': 'notif_${DateTime.now().millisecondsSinceEpoch}',
        'title': title,
        'body': body,
        'sender': _userProfile?.name ?? 'Guardians Admin',
        'senderUid': _currentUser?.uid ?? '',
        'type': 'comms',
        'createdAt': DateTime.now().toIso8601String(),
      };
      await _db.collection('notifications').doc(notifDoc['id'] as String).set(notifDoc);
    } catch (e) {
      debugPrint("Push notification log error: $e");
    }
  }

  FirebaseService() {
    _currentUser = _auth.currentUser;
    if (_currentUser != null) {
      _isUserSignedIn = true;
    }
    _loadPreferences();
    _initService();
  }

  Future<void> _persistSession() async {
    _isUserSignedIn = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('user_signed_in_persistent', true);
      if (_userProfile != null) {
        await prefs.setString('cached_user_profile_json', jsonEncode(_userProfile!.toMap()));
        await prefs.setString('cached_user_profile_id', _userProfile!.id);
      } else if (_currentUser != null) {
        await prefs.setString('cached_user_profile_id', _currentUser!.uid);
      }
    } catch (e) {
      debugPrint("Error persisting session: $e");
    }
  }

  Future<void> _clearSession() async {
    _isUserSignedIn = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('user_signed_in_persistent', false);
      await prefs.remove('cached_user_profile_json');
      await prefs.remove('cached_user_profile_id');
    } catch (e) {
      debugPrint("Error clearing session: $e");
    }
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final migratedGold = prefs.getBool('guardians_gold_ui_migrated') ?? false;
      if (!migratedGold) {
        _themeMode = ThemeMode.light;
        _activeStyleTheme = AppStyleTheme.guardiansGold;
        await prefs.setBool('guardians_gold_ui_migrated', true);
        await prefs.setInt('app_style_theme', AppStyleTheme.guardiansGold.index);
        await prefs.setBool('app_theme_is_dark', false);
      } else {
        final themeIndex = prefs.getInt('app_style_theme');
        if (themeIndex != null && themeIndex >= 0 && themeIndex < AppStyleTheme.values.length) {
          _activeStyleTheme = AppStyleTheme.values[themeIndex];
        }
        final isDark = prefs.getBool('app_theme_is_dark');
        if (isDark != null) {
          _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
        }
      }

      _biometricEnabled = prefs.getBool('biometric_unlock_enabled') ?? false;
      _isLocked = false;
      _userCustomPhotoPath = prefs.getString('user_custom_photo_path');
      _userCustomCardBgPath = prefs.getString('user_custom_card_bg_path');

      final deletedAnnIds = prefs.getStringList('deleted_announcement_ids');
      if (deletedAnnIds != null) {
        _deletedAnnouncementIds.addAll(deletedAnnIds);
      }
      final cachedAnnStr = prefs.getString('cached_announcements_json');
      if (cachedAnnStr != null && cachedAnnStr.isNotEmpty) {
        try {
          final List decoded = jsonDecode(cachedAnnStr);
          final loaded = decoded.map((m) => Announcement.fromMap(m as Map<String, dynamic>)).toList();
          if (loaded.isNotEmpty) {
            _announcements = loaded;
          }
        } catch (e) {
          debugPrint("Error restoring cached announcements: $e");
        }
      }
      _announcements.removeWhere((a) => _deletedAnnouncementIds.contains(a.id));

      final persistentSignedIn = prefs.getBool('user_signed_in_persistent') ?? false;
      final cachedProfileStr = prefs.getString('cached_user_profile_json');
      if (cachedProfileStr != null && cachedProfileStr.isNotEmpty) {
        try {
          final map = jsonDecode(cachedProfileStr) as Map<String, dynamic>;
          final docId = prefs.getString('cached_user_profile_id') ?? (_currentUser?.uid ?? 'cached_user');
          _userProfile = TeamMember.fromMap(map, docId);
        } catch (e) {
          debugPrint("Error restoring cached user profile: $e");
        }
      }

      if (_userCustomPhotoPath == null && _userProfile?.photoUrl != null) {
        _userCustomPhotoPath = _userProfile!.photoUrl;
      }

      final lastReadStr = prefs.getString('last_read_comms_time');
      if (lastReadStr != null) {
        _lastReadCommsTimestamp = DateTime.tryParse(lastReadStr);
      }

      if (persistentSignedIn || _currentUser != null || _auth.currentUser != null) {
        _isUserSignedIn = true;
        if (_currentUser == null && _auth.currentUser != null) {
          _currentUser = _auth.currentUser;
        }
        if (_currentUser == null) {
          // Attempt silent auto-sign in using saved credentials
          final creds = await getBiometricCredentials();
          if (creds != null && creds['email'] != null && creds['password'] != null) {
            try {
              final userCred = await _auth.signInWithEmailAndPassword(
                email: creds['email']!,
                password: creds['password']!,
              );
              _currentUser = userCred.user;
            } catch (e) {
              debugPrint("Silent credential sign-in error: $e");
            }
          }
        }
        if (_currentUser != null) {
          _loadUserProfile(_currentUser!.uid);
          _listenToFirestore();
          initPushNotifications();
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint("Error loading stored theme preferences: $e");
    }
  }

  Future<void> setUserProfilePhoto(String? path) async {
    _userCustomPhotoPath = path;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (path == null) {
        await prefs.remove('user_custom_photo_path');
      } else {
        await prefs.setString('user_custom_photo_path', path);
      }
      if (_userProfile != null) {
        _userProfile = _userProfile!.copyWith(photoUrl: path);
        await prefs.setString('cached_user_profile_json', jsonEncode(_userProfile!.toMap()));
        if (_currentUser != null) {
          await _writeTeamDoc(_currentUser!.uid, {'photoUrl': path});
        }
      }
    } catch (e) {
      debugPrint("Error updating profile photo: $e");
    }
    notifyListeners();
  }

  Future<void> setUserProfileCardBackground(String? path, {AppStyleTheme? matchingTheme}) async {
    _userCustomCardBgPath = path;
    if (matchingTheme != null) {
      _activeStyleTheme = matchingTheme;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      if (path == null) {
        await prefs.remove('user_custom_card_bg_path');
      } else {
        await prefs.setString('user_custom_card_bg_path', path);
      }
      if (matchingTheme != null) {
        await prefs.setInt('app_style_theme', matchingTheme.index);
      }
      if (_currentUser != null) {
        final data = <String, dynamic>{'cardBgPath': path};
        if (matchingTheme != null) {
          data['preferredTheme'] = matchingTheme.name;
        }
        await _writeTeamDoc(_currentUser!.uid, data);
      }
    } catch (e) {
      debugPrint("Error updating profile card background: $e");
    }
    notifyListeners();
  }

  Future<bool> pickAndSetProfilePhoto({required ImageSource source}) async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (pickedFile == null) return false;

      if (!kIsWeb) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'profile_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedImage = await io.File(pickedFile.path).copy('${appDir.path}/$fileName');
        await setUserProfilePhoto(savedImage.path);
      } else {
        await setUserProfilePhoto(pickedFile.path);
      }
      return true;
    } catch (e) {
      debugPrint("Error picking profile image: $e");
      return false;
    }
  }

  Future<void> removeProfilePhoto() async {
    await setUserProfilePhoto(null);
  }

  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _biometricEnabled = false;
  bool _isLocked = false;

  bool get biometricEnabled => _biometricEnabled;
  bool get isLocked => _isLocked;

  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  Future<String> getBiometricTypeLabel() async {
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        final biometrics = await _localAuth.getAvailableBiometrics();
        if (biometrics.contains(BiometricType.face)) {
          return "Face ID";
        }
        if (biometrics.contains(BiometricType.fingerprint)) {
          return "Touch ID";
        }
        return "Face ID";
      }
      return "Fingerprint";
    } catch (_) {
      return (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) ? "Face ID" : "Fingerprint";
    }
  }

  Future<void> setBiometricEnabled(bool value) async {
    _biometricEnabled = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_unlock_enabled', value);
    } catch (_) {}
  }

  void lockIfNeeded() {
    if (_biometricEnabled && _currentUser != null) {
      _isLocked = true;
      notifyListeners();
    }
  }

  Future<void> saveBiometricCredentials(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('biometric_saved_email', email.trim());
      await prefs.setString('biometric_saved_password', base64Encode(utf8.encode(password)));
    } catch (e) {
      debugPrint("Error saving biometric credentials: $e");
    }
  }

  Future<Map<String, String>?> getBiometricCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('biometric_saved_email');
      final encPass = prefs.getString('biometric_saved_password');
      if (email != null && encPass != null && email.isNotEmpty && encPass.isNotEmpty) {
        final pass = utf8.decode(base64Decode(encPass));
        return {'email': email, 'password': pass};
      }
    } catch (e) {
      debugPrint("Error retrieving biometric credentials: $e");
    }
    return null;
  }

  Future<void> clearBiometricCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('biometric_saved_email');
      await prefs.remove('biometric_saved_password');
    } catch (_) {}
  }

  Future<bool> authenticateBiometrics({String? reason}) async {
    try {
      final canAuth = await isBiometricAvailable();
      if (!canAuth) return false;

      final label = await getBiometricTypeLabel();
      final defaultReason = (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS)
          ? "Authenticate with $label to unlock Guardians of the Gate"
          : "Touch fingerprint sensor to continue";

      return await _localAuth.authenticate(
        localizedReason: reason ?? defaultReason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );
    } catch (e) {
      debugPrint("Biometric authentication error: $e");
      return false;
    }
  }

  Future<bool> unlockWithBiometrics({String? reason}) async {
    final didAuth = await authenticateBiometrics(reason: reason);
    if (didAuth) {
      _isLocked = false;
      notifyListeners();
    }
    return didAuth;
  }

  Future<bool> loginWithBiometrics() async {
    try {
      final canAuth = await isBiometricAvailable();
      if (!canAuth) return false;

      final label = await getBiometricTypeLabel();
      final didAuthenticate = await authenticateBiometrics(
        reason: "Authenticate with $label to sign in",
      );

      if (!didAuthenticate) return false;

      _isLocked = false;

      if (_auth.currentUser != null) {
        _currentUser = _auth.currentUser;
        if (_currentUser != null) {
          _loadUserProfile(_currentUser!.uid);
        }
        await _persistSession();
        notifyListeners();
        return true;
      }

      final creds = await getBiometricCredentials();
      if (creds != null && creds['email'] != null && creds['password'] != null) {
        final success = await signIn(creds['email']!, creds['password']!);
        if (success) {
          _currentUser = _auth.currentUser;
          if (_currentUser != null) {
            _loadUserProfile(_currentUser!.uid);
          }
          await _persistSession();
          notifyListeners();
          return true;
        }
      }

      notifyListeners();
      return false;
    } catch (e) {
      debugPrint("Biometric login error: $e");
      return false;
    }
  }

  void _initService() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _currentUser = user;
        _isUserSignedIn = true;
        _loadUserProfile(user.uid);
        _listenToFirestore();
        initPushNotifications();
      } else {
        if (!_isUserSignedIn) {
          _currentUser = null;
          _userProfile = null;
          _authLoading = false;
          notifyListeners();
        }
      }
    }, onError: (err) {
      debugPrint("Auth state listener error: $err");
      _authLoading = false;
      notifyListeners();
    });
  }

  Future<bool> ensureWatchAuthenticated() async {
    // 1. If already authenticated, ensure profile and Firestore listeners are active
    if (_currentUser != null || _auth.currentUser != null) {
      if (_currentUser == null && _auth.currentUser != null) {
        _currentUser = _auth.currentUser;
      }
      _isUserSignedIn = true;
      if (_userProfile == null && _currentUser != null) {
        _loadUserProfile(_currentUser!.uid);
      }
      _listenToFirestore();
      return true;
    }

    // 2. Try saved credentials from persistent storage if available
    try {
      final creds = await getBiometricCredentials();
      if (creds != null && creds['email'] != null && creds['password'] != null) {
        final userCred = await _auth.signInWithEmailAndPassword(
          email: creds['email']!,
          password: creds['password']!,
        );
        _currentUser = userCred.user;
        _isUserSignedIn = true;
        if (_currentUser != null) {
          _loadUserProfile(_currentUser!.uid);
        }
        _listenToFirestore();
        await _persistSession();
        debugPrint("Watch authenticated via saved credentials as ${_currentUser?.email}");
        return true;
      }
    } catch (e) {
      debugPrint("Watch saved credential sign-in attempt: $e");
    }

    // 3. Auto-authenticate with church usher master account
    try {
      final userCred = await _auth.signInWithEmailAndPassword(
        email: 'robv88@live.com',
        password: 'Newport123',
      );
      _currentUser = userCred.user;
      _isUserSignedIn = true;
      if (_currentUser != null) {
        _loadUserProfile(_currentUser!.uid);
      }
      _listenToFirestore();
      await _persistSession();
      debugPrint("Watch auto-authenticated successfully as ${_currentUser?.email}");
      return true;
    } catch (e) {
      debugPrint("Watch church usher sign-in error: $e");
    }

    // 4. Secondary fallback: Anonymous sign-in
    try {
      final userCred = await _auth.signInAnonymously();
      _currentUser = userCred.user;
      _isUserSignedIn = true;
      _listenToFirestore();
      debugPrint("Watch authenticated anonymously as ${_currentUser?.uid}");
      return true;
    } catch (e) {
      debugPrint("Watch anonymous sign-in error: $e");
    }

    return false;
  }

  void toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('app_theme_is_dark', _themeMode == ThemeMode.dark);
    } catch (_) {}
    if (_currentUser != null) {
      try {
        await _writeTeamDoc(_currentUser!.uid, {'themeMode': _themeMode.name});
      } catch (_) {}
    }
  }

  void setAppStyleTheme(AppStyleTheme styleTheme) async {
    _activeStyleTheme = styleTheme;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('app_style_theme', styleTheme.index);
    } catch (_) {}
    if (_currentUser != null) {
      try {
        await _writeTeamDoc(_currentUser!.uid, {'preferredTheme': styleTheme.name});
      } catch (_) {}
    }
  }

  Future<void> _syncLiveTallyToFirestore() async {
    _lastLocalTallyUpdateTime = DateTime.now().millisecondsSinceEpoch;
    try {
      if (_currentUser == null && _auth.currentUser == null) {
        await ensureWatchAuthenticated();
      }
      await _db.collection('settings').doc('live_tally').set({
        'count': _currentTallyCount,
        'serviceType': _activeServiceType,
        'updatedAt': DateTime.now().toIso8601String(),
        'updatedBy': _userProfile?.name ?? 'Usher',
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Live tally cloud sync error: $e");
    }
  }

  void updateTallyCount(int delta) {
    _currentTallyCount = (_currentTallyCount + delta).clamp(0, 9999);
    _lastLocalTallyUpdateTime = DateTime.now().millisecondsSinceEpoch;
    AppWidgetService.updateTallyWidget(
      count: _currentTallyCount,
      serviceType: _activeServiceType,
    );
    notifyListeners();
    _syncLiveTallyToFirestore();
  }

  void resetTallyCount() {
    _currentTallyCount = 0;
    _lastLocalTallyUpdateTime = DateTime.now().millisecondsSinceEpoch;
    AppWidgetService.updateTallyWidget(
      count: 0,
      serviceType: _activeServiceType,
    );
    notifyListeners();
    _syncLiveTallyToFirestore();
  }

  void setActiveServiceType(String service) {
    _activeServiceType = service;
    _lastLocalTallyUpdateTime = DateTime.now().millisecondsSinceEpoch;
    AppWidgetService.updateTallyWidget(
      count: _currentTallyCount,
      serviceType: _activeServiceType,
    );
    notifyListeners();
    _syncLiveTallyToFirestore();
  }

  Future<void> submitAttendanceLog({
    required int headcount,
    required String serviceType,
    String? serviceDate,
    String? notes,
    String? submittedBy,
  }) async {
    // 1. Ensure client is authenticated before writing
    if (_currentUser == null && _auth.currentUser == null) {
      await ensureWatchAuthenticated();
    }

    final nowIso = DateTime.now().toIso8601String();
    final entry = AttendanceLogEntry(
      id: 'log_${DateTime.now().millisecondsSinceEpoch}',
      headcount: headcount,
      serviceType: serviceType,
      serviceDate: (serviceDate != null && serviceDate.trim().isNotEmpty)
          ? serviceDate.trim()
          : nowIso.split('T').first,
      notes: notes,
      submittedBy: submittedBy ?? _userProfile?.name ?? 'Usher',
      createdAt: nowIso,
    );

    _attendanceLogs.insert(0, entry);
    notifyListeners();

    try {
      await _db.collection('attendance').doc(entry.id).set(entry.toMap());
      await _db.collection('attendance_logs').doc(entry.id).set(entry.toMap());
      debugPrint("Attendance log saved to Firestore successfully: ${entry.id}");
    } catch (e) {
      debugPrint("Attendance log save error: $e");
      // If unauthenticated or permission denied, retry authentication and retry write once
      if (e.toString().contains('permission-denied') || e.toString().contains('unauthenticated')) {
        debugPrint("Retrying attendance write after re-authenticating...");
        final authed = await ensureWatchAuthenticated();
        if (authed) {
          try {
            await _db.collection('attendance').doc(entry.id).set(entry.toMap());
            await _db.collection('attendance_logs').doc(entry.id).set(entry.toMap());
            debugPrint("Retry attendance write succeeded!");
            return;
          } catch (retryErr) {
            debugPrint("Retry attendance write failed: $retryErr");
            rethrow;
          }
        }
      }
      rethrow;
    }
  }

  Future<void> editAttendanceLog(
    String logId, {
    required int headcount,
    required String serviceType,
    required String serviceDate,
    String? notes,
  }) async {
    final idx = _attendanceLogs.indexWhere((l) => l.id == logId);
    if (idx != -1) {
      final old = _attendanceLogs[idx];
      final updated = AttendanceLogEntry(
        id: old.id,
        headcount: headcount,
        serviceType: serviceType,
        serviceDate: serviceDate,
        notes: notes,
        submittedBy: old.submittedBy,
        createdAt: old.createdAt,
      );
      _attendanceLogs[idx] = updated;
      notifyListeners();

      try {
        await _db.collection('attendance').doc(logId).set(updated.toMap(), SetOptions(merge: true));
        await _db.collection('attendance_logs').doc(logId).set(updated.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint("Edit attendance log error: $e");
      }
    }
  }

  Future<void> deleteAttendanceLog(String logId) async {
    _attendanceLogs.removeWhere((l) => l.id == logId);
    notifyListeners();

    try {
      await _db.collection('attendance').doc(logId).delete();
      await _db.collection('attendance_logs').doc(logId).delete();
    } catch (e) {
      debugPrint("Delete attendance log error: $e");
    }
  }

  Future<void> postCommsMessage(String text, {String? imageUrl}) async {
    if (text.trim().isEmpty && (imageUrl == null || imageUrl.isEmpty)) return;

    final msg = CommsMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: text.trim(),
      imageUrl: imageUrl,
      authorName: _userProfile?.name ?? 'Usher',
      authorEmail: _userProfile?.email ?? '',
      authorUid: _currentUser?.uid ?? '',
      createdAt: DateTime.now().toIso8601String(),
    );

    _commsMessages.add(msg);
    notifyListeners();

    try {
      await _db.collection('communications').doc(msg.id).set(msg.toMap());
      await _db.collection('comms_messages').doc(msg.id).set(msg.toMap());
      final notifBody = msg.text.isNotEmpty
          ? msg.text
          : (msg.imageUrl != null && msg.imageUrl!.toLowerCase().contains('.gif')
              ? "🎞️ [GIF Shared]"
              : "📷 [Photo Shared]");
      sendPushNotificationAlert(
        title: msg.authorName ?? 'Guardians Comms',
        body: notifBody,
      );
    } catch (e) {
      debugPrint("Comms message post error: $e");
    }
  }

  Future<void> editCommsMessage(String messageId, String newText) async {
    if (newText.trim().isEmpty) return;
    final idx = _commsMessages.indexWhere((m) => m.id == messageId);
    if (idx != -1) {
      final old = _commsMessages[idx];
      final updated = CommsMessage(
        id: old.id,
        text: newText.trim(),
        authorEmail: old.authorEmail,
        authorName: old.authorName,
        authorUid: old.authorUid,
        createdAt: old.createdAt,
        edited: true,
      );
      _commsMessages[idx] = updated;
      notifyListeners();
    }

    try {
      await _db.collection('communications').doc(messageId).update({'text': newText.trim(), 'edited': true});
      await _db.collection('comms_messages').doc(messageId).update({'text': newText.trim(), 'edited': true});
    } catch (e) {
      debugPrint("Edit comms message error: $e");
    }
  }

  Future<void> deleteCommsMessage(String messageId) async {
    _commsMessages.removeWhere((m) => m.id == messageId);
    notifyListeners();

    try {
      await _db.collection('communications').doc(messageId).delete();
      await _db.collection('comms_messages').doc(messageId).delete();
    } catch (e) {
      debugPrint("Delete comms message error: $e");
    }
  }

  Future<void> clearAllCommsMessages() async {
    _commsMessages.clear();
    notifyListeners();

    try {
      final snap1 = await _db.collection('communications').get();
      for (final doc in snap1.docs) {
        await doc.reference.delete();
      }
      final snap2 = await _db.collection('comms_messages').get();
      for (final doc in snap2.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint("Clear all comms messages error: $e");
    }
  }

  Future<void> updateBulletin(String newText) async {
    _bulletinText = newText;
    notifyListeners();

    try {
      await _db.collection('settings').doc('bulletin').set({'text': newText});
    } catch (e) {
      debugPrint("Bulletin update error: $e");
    }
  }

  Future<void> addDeployment({
    required String station,
    required String usherName,
    required String serviceType,
    String? customEventName,
    String? usherId,
    String? role,
    String? date,
  }) async {
    final dep = Deployment(
      id: 'dep_${DateTime.now().millisecondsSinceEpoch}',
      date: date != null && date.isNotEmpty ? date : DateTime.now().toString().split(' ').first,
      usherId: usherId ?? 'u_${DateTime.now().millisecondsSinceEpoch}',
      usherName: usherName,
      serviceType: serviceType,
      customEventName: customEventName,
      station: station,
      role: role ?? 'Assigned Usher',
      verified: true,
    );

    _deployments.insert(0, dep);
    notifyListeners();

    try {
      await _db.collection('deployment_publishes').doc(dep.id).set(dep.toMap());
      await _db.collection('deployments').doc(dep.id).set(dep.toMap());
      sendPushNotificationAlert(
        title: "Station Duty Schedule Update",
        body: "Assigned $usherName to $station (${dep.role})",
      );
    } catch (e) {
      debugPrint("Deployment add error: $e");
    }
  }

  Future<void> subInDeployment(
    String deploymentId, {
    required String newUsherName,
    String? newUsherId,
    String? newRole,
  }) async {
    final idx = _deployments.indexWhere((d) => d.id == deploymentId);
    if (idx != -1) {
      final old = _deployments[idx];
      final updated = Deployment(
        id: old.id,
        date: old.date,
        usherId: newUsherId ?? old.usherId,
        usherName: newUsherName,
        serviceType: old.serviceType,
        station: old.station,
        role: newRole ?? old.role,
        verified: true,
      );

      _deployments[idx] = updated;
      notifyListeners();

      try {
        await _db.collection('deployments').doc(deploymentId).set(updated.toMap(), SetOptions(merge: true));
        await _db.collection('deployment_publishes').doc(deploymentId).set(updated.toMap(), SetOptions(merge: true));

        sendPushNotificationAlert(
          title: "Schedule Sub-In Update",
          body: "$newUsherName subbed in for ${old.usherName} at ${old.station}",
        );
      } catch (e) {
        debugPrint("Sub-in deployment error: $e");
      }
    }
  }

  Future<void> deleteDeployment(String id) async {
    final depToDelete = _deployments.where((d) => d.id == id).firstOrNull;
    _deployments.removeWhere((d) => d.id == id);
    notifyListeners();

    try {
      await _db.collection('deployments').doc(id).delete();
      await _db.collection('deployment_publishes').doc(id).delete();

      // Clean up any duplicates or ghost documents in both collections
      if (depToDelete != null) {
        final snapPublishes = await _db.collection('deployment_publishes')
            .where('date', isEqualTo: depToDelete.date)
            .where('station', isEqualTo: depToDelete.station)
            .where('usherName', isEqualTo: depToDelete.usherName)
            .get();
        for (final doc in snapPublishes.docs) {
          await doc.reference.delete();
        }

        final snapDeployments = await _db.collection('deployments')
            .where('date', isEqualTo: depToDelete.date)
            .where('station', isEqualTo: depToDelete.station)
            .where('usherName', isEqualTo: depToDelete.usherName)
            .get();
        for (final doc in snapDeployments.docs) {
          await doc.reference.delete();
        }
      }
    } catch (e) {
      debugPrint("Delete deployment error: $e");
    }
  }

  Future<void> clearAllDeployments() async {
    _deployments.clear();
    notifyListeners();

    try {
      final snap1 = await _db.collection('deployments').get();
      for (final doc in snap1.docs) {
        await doc.reference.delete();
      }
      final snap2 = await _db.collection('deployment_publishes').get();
      for (final doc in snap2.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint("Clear deployment error: $e");
    }
  }

  bool _pendingTwoFactor = false;
  String? _pendingTwoFactorPhone;
  bool _twoFactorCodeSent = false;
  String? _twoFactorVerificationId;
  ConfirmationResult? _twoFactorWebResult;
  String? _twoFactorError;

  bool get pendingTwoFactor => _pendingTwoFactor;
  String? get pendingTwoFactorPhone => _pendingTwoFactorPhone;
  bool get twoFactorCodeSent => _twoFactorCodeSent;
  String? get twoFactorError => _twoFactorError;

  Future<void> toggleTwoFactorAuth(bool enable, {String? phone}) async {
    if (_currentUser == null) return;
    final uid = _currentUser!.uid;
    final targetPhone = phone ?? _userProfile?.phone;

    if (enable && (targetPhone == null || targetPhone.trim().isEmpty)) {
      throw Exception("Please provide a valid mobile phone number for 2FA SMS security.");
    }

    final updateData = {
      'twoFactorEnabled': enable,
      if (targetPhone != null) 'twoFactorPhone': targetPhone.trim(),
    };

    if (_userProfile != null) {
      _userProfile = TeamMember(
        id: _userProfile!.id,
        name: _userProfile!.name,
        email: _userProfile!.email,
        phone: _userProfile!.phone,
        role: _userProfile!.role,
        approved: _userProfile!.approved,
        denied: _userProfile!.denied,
        createdAt: _userProfile!.createdAt,
        linkedTo: _userProfile!.linkedTo,
        fcmToken: _userProfile!.fcmToken,
        twoFactorEnabled: enable,
        twoFactorPhone: targetPhone,
      );
      notifyListeners();
    }

    await _writeTeamDoc(uid, updateData);
  }

  Future<bool> signIn(String email, String password) async {
    _authLoading = true;
    _pendingTwoFactor = false;
    _twoFactorCodeSent = false;
    _twoFactorError = null;
    notifyListeners();

    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final uid = cred.user!.uid;

      // Check if user has 2FA enabled
      final doc = await _db.collection('team').doc(uid).get();
      if (doc.exists) {
        final profile = TeamMember.fromMap(doc.data()!, doc.id);
        if (profile.twoFactorEnabled && ((profile.twoFactorPhone ?? profile.phone)?.isNotEmpty ?? false)) {
          final phone = profile.twoFactorPhone ?? profile.phone!;
          _pendingTwoFactor = true;
          _pendingTwoFactorPhone = phone;
          _userProfile = profile;

          await sendTwoFactorSmsCode(phone);
          _authLoading = false;
          notifyListeners();
          return false; // 2FA Challenge required
        }
      }

      await _persistSession();
      _authLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Auth error: $e");
      _authLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> sendTwoFactorSmsCode(String rawPhone) async {
    _authLoading = true;
    _twoFactorError = null;
    notifyListeners();

    final cleanPhone = rawPhone.replaceAll(RegExp(r'[^\d]'), '');
    final formatted = rawPhone.startsWith('+') ? rawPhone : '+1$cleanPhone';

    if (kIsWeb) {
      try {
        _twoFactorWebResult = await _auth.signInWithPhoneNumber(formatted);
        _twoFactorCodeSent = true;
        _authLoading = false;
        notifyListeners();
        return;
      } catch (e) {
        _twoFactorError = "Couldn't send 2FA SMS code: $e";
        _authLoading = false;
        notifyListeners();
        return;
      }
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      _twoFactorCodeSent = true;
      _authLoading = false;
      notifyListeners();
      return;
    }

    final completer = Completer<void>();
    await _auth.verifyPhoneNumber(
      phoneNumber: formatted,
      verificationCompleted: (PhoneAuthCredential credential) async {
        _twoFactorCodeSent = true;
        _authLoading = false;
        notifyListeners();
        if (!completer.isCompleted) completer.complete();
      },
      verificationFailed: (FirebaseAuthException e) {
        if (e.code == 'missing-app-token' ||
            e.code == 'app-not-authorized' ||
            (e.message?.contains('app identifier') ?? false) ||
            (e.message?.contains('Play Integrity') ?? false)) {
          _twoFactorError =
              "Firebase 2FA requires your Android SHA-1 fingerprint in Firebase Console, or this number added under 'Phone numbers for testing'.";
        } else {
          _twoFactorError = e.message ?? "2FA SMS dispatch failed.";
        }
        _authLoading = false;
        notifyListeners();
        if (!completer.isCompleted) completer.complete();
      },
      codeSent: (verId, _) {
        _twoFactorVerificationId = verId;
        _twoFactorCodeSent = true;
        _authLoading = false;
        notifyListeners();
        if (!completer.isCompleted) completer.complete();
      },
      codeAutoRetrievalTimeout: (verId) {
        _twoFactorVerificationId = verId;
      },
    );
    await completer.future;
  }

  Future<bool> verifyTwoFactorSmsCode(String code) async {
    _authLoading = true;
    _twoFactorError = null;
    notifyListeners();

    final cleanCode = code.trim();
    if (cleanCode.isEmpty) {
      _authLoading = false;
      notifyListeners();
      throw Exception("Please enter the 6-digit 2FA security code.");
    }

    try {
      if (kIsWeb && _twoFactorWebResult != null) {
        await _twoFactorWebResult!.confirm(cleanCode);
      } else if (_twoFactorVerificationId != null) {
        final credential = PhoneAuthProvider.credential(
          verificationId: _twoFactorVerificationId!,
          smsCode: cleanCode,
        );
        try {
          await _currentUser?.linkWithCredential(credential);
        } catch (_) {
          // If already linked, sign in directly with credential
          try {
            await _auth.signInWithCredential(credential);
          } catch (_) {}
        }
      }

      _pendingTwoFactor = false;
      _pendingTwoFactorPhone = null;
      _twoFactorCodeSent = false;
      _twoFactorVerificationId = null;
      _twoFactorWebResult = null;
      _twoFactorError = null;

      if (_currentUser != null) {
        _loadUserProfile(_currentUser!.uid);
      }

      await _persistSession();
      _authLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _authLoading = false;
      notifyListeners();
      throw Exception(e.code == 'invalid-verification-code'
          ? "The 2FA security code is incorrect. Please check and try again."
          : (e.message ?? "2FA verification failed."));
    } catch (e) {
      _authLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  void cancelTwoFactorVerification() {
    _pendingTwoFactor = false;
    _pendingTwoFactorPhone = null;
    _twoFactorCodeSent = false;
    _twoFactorVerificationId = null;
    _twoFactorWebResult = null;
    _twoFactorError = null;
    _auth.signOut();
    notifyListeners();
  }

  ConfirmationResult? _webConfirmationResult;
  String? _verificationId;
  String? _pendingPhone;
  TeamMember? _pendingPhoneMember;
  bool _phoneCodeSent = false;
  String? _phoneAuthError;

  String? get pendingPhone => _pendingPhone;
  bool get phoneCodeSent => _phoneCodeSent;
  String? get phoneAuthError => _phoneAuthError;

  String _normalizePhoneDigits(String? raw) {
    if (raw == null) return '';
    final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length == 11 && digits.startsWith('1')) {
      return digits.substring(1);
    }
    return digits;
  }

  bool _phonesMatch(String? p1, String? p2) {
    final d1 = _normalizePhoneDigits(p1);
    final d2 = _normalizePhoneDigits(p2);
    if (d1.isEmpty || d2.isEmpty) return false;
    return d1 == d2 || (d1.length >= 7 && d2.length >= 7 && (d1.endsWith(d2) || d2.endsWith(d1)));
  }

  Future<TeamMember?> findProfileByPhone(String rawPhone) async {
    final cleanPhone = _normalizePhoneDigits(rawPhone);
    if (cleanPhone.isEmpty || cleanPhone.length < 7) return null;

    // 1. Check in-memory live roster
    for (final m in _liveRoster) {
      if (_phonesMatch(m.phone, rawPhone) || _phonesMatch(m.twoFactorPhone, rawPhone)) {
        return m;
      }
    }

    // 2. Query Firestore collections
    final collections = ['team', 'users', 'ushers', 'team_members', 'roster'];
    for (final col in collections) {
      try {
        final snap = await _db.collection(col).get();
        for (final doc in snap.docs) {
          final m = TeamMember.fromMap(doc.data(), doc.id);
          if (_phonesMatch(m.phone, rawPhone) || _phonesMatch(m.twoFactorPhone, rawPhone)) {
            return m;
          }
        }
      } catch (_) {}
    }
    return null;
  }

  Future<void> sendPhoneSecurityCode(String rawPhone) async {
    _authLoading = true;
    _phoneAuthError = null;
    notifyListeners();

    final cleanPhone = _normalizePhoneDigits(rawPhone);
    if (cleanPhone.isEmpty || cleanPhone.length < 7) {
      _authLoading = false;
      notifyListeners();
      throw Exception("Please enter a valid 10-digit phone number.");
    }

    try {
      // 1. Strict Usher Profile Check: Require phone to exist in an usher profile
      final matchedMember = await findProfileByPhone(rawPhone);
      if (matchedMember == null) {
        _authLoading = false;
        notifyListeners();
        throw Exception("No usher profile found for $rawPhone. Please sign in with your email and password.");
      }

      _pendingPhone = rawPhone;
      _pendingPhoneMember = matchedMember;
      _phoneCodeSent = false;

      final formatted = rawPhone.startsWith('+') ? rawPhone : '+1$cleanPhone';

      if (kIsWeb) {
        _webConfirmationResult = await _auth.signInWithPhoneNumber(formatted);
        _phoneCodeSent = true;
        _authLoading = false;
        notifyListeners();
        return;
      }

      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
        _authLoading = false;
        notifyListeners();
        throw Exception("SMS verification is designed for mobile devices (iOS & Android). On Windows Desktop, please use 'Sign In with Email' or 'Register'.");
      }

      // Native mobile platforms report success/failure via callbacks
      final completer = Completer<void>();
      await _auth.verifyPhoneNumber(
        phoneNumber: formatted,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            final userCred = await _auth.signInWithCredential(credential);
            _currentUser = userCred.user;
            if (_currentUser != null) {
              final linked = TeamMember(
                id: _currentUser!.uid,
                name: matchedMember.name,
                email: matchedMember.email,
                phone: matchedMember.phone?.isNotEmpty == true ? matchedMember.phone : _pendingPhone,
                role: matchedMember.role,
                approved: matchedMember.approved,
                denied: matchedMember.denied,
                createdAt: matchedMember.createdAt,
                linkedTo: matchedMember.id,
                fcmToken: matchedMember.fcmToken,
                twoFactorEnabled: matchedMember.twoFactorEnabled,
                twoFactorPhone: matchedMember.twoFactorPhone,
              );
              _userProfile = linked;
              await _writeTeamDoc(_currentUser!.uid, linked.toMap());
            }
            _pendingPhone = null;
            _pendingPhoneMember = null;
            _phoneCodeSent = false;
          } catch (e) {
            _phoneAuthError = "Automatic verification failed. Please enter the code manually.";
          } finally {
            _authLoading = false;
            notifyListeners();
            if (!completer.isCompleted) completer.complete();
          }
        },
        verificationFailed: (e) {
          if (e.code == 'missing-app-token' ||
              e.code == 'app-not-authorized' ||
              (e.message?.contains('app identifier') ?? false) ||
              (e.message?.contains('Play Integrity') ?? false)) {
            _phoneAuthError =
                "Firebase Phone Auth requires your Android SHA-1 fingerprint added in Firebase Console, or this phone number registered under 'Phone numbers for testing' in Firebase Console.";
          } else {
            _phoneAuthError = e.message ?? "Phone verification failed.";
          }
          _pendingPhone = null;
          _pendingPhoneMember = null;
          _authLoading = false;
          notifyListeners();
          if (!completer.isCompleted) completer.complete();
        },
        codeSent: (verId, _) {
          _verificationId = verId;
          _phoneCodeSent = true;
          _authLoading = false;
          notifyListeners();
          if (!completer.isCompleted) completer.complete();
        },
        codeAutoRetrievalTimeout: (verId) {
          _verificationId = verId;
        },
      );
      await completer.future;

      if (_phoneAuthError != null) {
        throw Exception(_phoneAuthError);
      }
    } catch (e) {
      _authLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  void cancelPhoneVerification() {
    if (_phoneCodeSent || _verificationId != null || _authLoading || _pendingPhone != null) {
      _pendingPhone = null;
      _pendingPhoneMember = null;
      _phoneCodeSent = false;
      _phoneAuthError = null;
      _verificationId = null;
      _webConfirmationResult = null;
      Future.microtask(() => notifyListeners());
    }
  }

  Future<bool> verifyPhoneSecurityCode(String enteredCode) async {
    _authLoading = true;
    notifyListeners();

    final code = enteredCode.trim();
    if (code.isEmpty) {
      _authLoading = false;
      notifyListeners();
      throw Exception("Please enter the 6-digit security code.");
    }

    try {
      User? signedInUser;

      if (kIsWeb && _webConfirmationResult != null) {
        final userCred = await _webConfirmationResult!.confirm(code);
        signedInUser = userCred.user;
      } else if (_verificationId != null) {
        final cred = PhoneAuthProvider.credential(verificationId: _verificationId!, smsCode: code);
        final userCred = await _auth.signInWithCredential(cred);
        signedInUser = userCred.user;
      } else {
        throw Exception("Verification session expired. Please request a new code.");
      }

      _currentUser = signedInUser;
      if (signedInUser != null) {
        if (_pendingPhoneMember != null) {
          final original = _pendingPhoneMember!;
          final linked = TeamMember(
            id: signedInUser.uid,
            name: original.name,
            email: original.email,
            phone: original.phone?.isNotEmpty == true ? original.phone : _pendingPhone,
            role: original.role,
            approved: original.approved,
            denied: original.denied,
            createdAt: original.createdAt,
            linkedTo: original.id,
            fcmToken: original.fcmToken,
            twoFactorEnabled: original.twoFactorEnabled,
            twoFactorPhone: original.twoFactorPhone,
          );
          _userProfile = linked;
          await _writeTeamDoc(signedInUser.uid, linked.toMap());
        } else {
          _loadUserProfile(signedInUser.uid);
        }
      }

      _pendingPhone = null;
      _pendingPhoneMember = null;
      _webConfirmationResult = null;
      _verificationId = null;
      _phoneCodeSent = false;

      await _persistSession();
      _authLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _authLoading = false;
      notifyListeners();
      throw Exception(e.code == 'invalid-verification-code'
          ? "That code doesn't match. Please check and try again."
          : (e.message ?? "Verification failed."));
    } catch (e) {
      _authLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String input) async {
    final query = input.trim();
    if (query.isEmpty) {
      throw Exception("Please enter your registered email address or phone number.");
    }

    String emailToSend = query;

    // If query is a phone number or name, find matching usher in liveRoster/Firestore
    if (!query.contains('@')) {
      final cleanPhone = query.replaceAll(RegExp(r'[^\d]'), '');
      TeamMember? matchedMember;

      for (final m in _liveRoster) {
        final uPhone = (m.phone ?? '').replaceAll(RegExp(r'[^\d]'), '');
        final uName = (m.name ?? '').toLowerCase();
        if ((cleanPhone.isNotEmpty && uPhone.contains(cleanPhone)) ||
            (query.length >= 3 && uName.contains(query.toLowerCase()))) {
          matchedMember = m;
          break;
        }
      }

      if (matchedMember != null && matchedMember.email != null && matchedMember.email!.contains('@')) {
        emailToSend = matchedMember.email!;
      } else if (cleanPhone.isNotEmpty) {
        emailToSend = '$cleanPhone@usherapp.com';
      } else {
        throw Exception("No registered email found for '$query'. Please enter your email address.");
      }
    }

    try {
      await _auth.sendPasswordResetEmail(email: emailToSend);
    } on FirebaseAuthException catch (fe) {
      if (fe.code == 'user-not-found') {
        throw Exception("No account found matching '$emailToSend'. Please make sure your account is registered.");
      }
      throw Exception(fe.message ?? "Failed to send password reset email.");
    } catch (e) {
      throw Exception("Error sending password reset: ${e.toString().replaceAll(RegExp(r'\[.*?\]'), '').replaceAll('Exception: ', '').trim()}");
    }
  }

  Future<bool> signUp(String email, String password, String name, String phone, {String? adminCode}) async {
    _authLoading = true;
    notifyListeners();

    final bool isAdmin = (adminCode == adminCodeConstant);

    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final uid = cred.user!.uid;
      try {
        await cred.user!.updateDisplayName(name);
      } catch (_) {}

      final newMember = TeamMember(
        id: uid,
        name: name.isNotEmpty ? name : (email.contains('@') ? email.split('@').first : 'Usher'),
        email: email,
        phone: phone,
        role: isAdmin ? 'Admin' : 'Usher',
        approved: isAdmin,
        denied: false,
        createdAt: DateTime.now().toIso8601String(),
      );

      await _writeTeamDoc(uid, newMember.toMap());
      _userProfile = newMember;
      await _persistSession();
      _authLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Signup error: $e");
      _authLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _clearSession();
    try {
      await _auth.signOut();
    } catch (_) {}
    _currentUser = null;
    _userProfile = null;
    _isUserSignedIn = false;
    _isOfflineDemoMode = false;
    _isLocked = false;
    notifyListeners();
  }

  Future<void> approveUser(String userId) async {
    final idx = _liveRoster.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      final updated = TeamMember(
        id: _liveRoster[idx].id,
        name: _liveRoster[idx].name,
        email: _liveRoster[idx].email,
        phone: _liveRoster[idx].phone,
        role: _liveRoster[idx].role,
        approved: true,
        denied: false,
      );
      _liveRoster[idx] = updated;
      _pendingUsers.removeWhere((u) => u.id == userId);
      _approvedUsers.add(updated);
      notifyListeners();
    }

    await _writeTeamDoc(userId, {'approved': true, 'denied': false});
  }

  Future<void> denyUser(String userId) async {
    final idx = _liveRoster.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      final updated = TeamMember(
        id: _liveRoster[idx].id,
        name: _liveRoster[idx].name,
        email: _liveRoster[idx].email,
        phone: _liveRoster[idx].phone,
        role: _liveRoster[idx].role,
        approved: false,
        denied: true,
      );
      _liveRoster[idx] = updated;
      _pendingUsers.removeWhere((u) => u.id == userId);
      _deniedUsers.add(updated);
      notifyListeners();
    }

    await _writeTeamDoc(userId, {'approved': false, 'denied': true});
  }

  Future<void> promoteUserToAdmin(String query) async {
    final cleanQuery = query.replaceAll(RegExp(r'[^\d]'), '');
    final lowerQuery = query.toLowerCase().trim();

    for (int i = 0; i < _liveRoster.length; i++) {
      final u = _liveRoster[i];
      final uName = (u.name ?? '').toLowerCase();
      final uPhone = (u.phone ?? '').replaceAll(RegExp(r'[^\d]'), '');

      if (u.id == query ||
          (cleanQuery.isNotEmpty && uPhone.contains(cleanQuery)) ||
          (lowerQuery.isNotEmpty && uName.contains(lowerQuery))) {
        final updated = TeamMember(
          id: u.id,
          name: u.name,
          email: u.email,
          phone: u.phone,
          role: 'Admin',
          approved: true,
          denied: false,
          createdAt: u.createdAt,
          linkedTo: u.linkedTo,
          fcmToken: u.fcmToken,
        );

        _liveRoster[i] = updated;
        notifyListeners();
        await _writeTeamDoc(u.id, updated.toMap());
        break;
      }
    }
  }

  Future<void> addTeamMember({
    required String name,
    required String email,
    required String phone,
    required String role,
  }) async {
    final uid = 'user_${DateTime.now().millisecondsSinceEpoch}';
    final member = TeamMember(
      id: uid,
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
      role: role,
      approved: true,
      denied: false,
      createdAt: DateTime.now().toIso8601String(),
    );

    _liveRoster.add(member);
    _approvedUsers.add(member);
    notifyListeners();

    await _writeTeamDoc(uid, member.toMap());
  }

  Future<void> updateTeamMember(TeamMember member) async {
    final idx = _liveRoster.indexWhere((u) => u.id == member.id);
    if (idx != -1) {
      _liveRoster[idx] = member;
      notifyListeners();
    }

    await _writeTeamDoc(member.id, member.toMap());
  }

  Future<void> deleteTeamMember(String userId) async {
    _liveRoster.removeWhere((u) => u.id == userId);
    _approvedUsers.removeWhere((u) => u.id == userId);
    _pendingUsers.removeWhere((u) => u.id == userId);
    _deniedUsers.removeWhere((u) => u.id == userId);
    notifyListeners();

    await _deleteTeamDoc(userId);
  }

  void _loadUserProfile(String uid) async {
    try {
      var doc = await _db.collection('team').doc(uid).get();
      if (!doc.exists || doc.data() == null) {
        doc = await _db.collection('users').doc(uid).get();
      }
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _userProfile = TeamMember.fromMap(data, doc.id);
        if (data.containsKey('preferredTheme') && data['preferredTheme'] is String) {
          final themeName = data['preferredTheme'] as String;
          final match = AppStyleTheme.values.where((t) => t.name == themeName).firstOrNull;
          if (match != null) {
            _activeStyleTheme = match;
            try {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setInt('app_style_theme', match.index);
            } catch (_) {}
          }
        }
        if (data.containsKey('themeMode') && data['themeMode'] is String) {
          final modeStr = data['themeMode'] as String;
          if (modeStr == 'dark' || modeStr == 'light') {
            _themeMode = modeStr == 'dark' ? ThemeMode.dark : ThemeMode.light;
            try {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('app_theme_is_dark', _themeMode == ThemeMode.dark);
            } catch (_) {}
          }
        }
      } else if (_currentUser != null) {
        TeamMember? matched;
        if (_currentUser!.phoneNumber != null && _currentUser!.phoneNumber!.isNotEmpty) {
          matched = await findProfileByPhone(_currentUser!.phoneNumber!);
        }
        if (matched != null) {
          final linked = TeamMember(
            id: uid,
            name: matched.name,
            email: matched.email,
            phone: matched.phone?.isNotEmpty == true ? matched.phone : _currentUser!.phoneNumber,
            role: matched.role,
            approved: matched.approved,
            denied: matched.denied,
            createdAt: matched.createdAt,
            linkedTo: matched.id,
            fcmToken: matched.fcmToken,
            twoFactorEnabled: matched.twoFactorEnabled,
            twoFactorPhone: matched.twoFactorPhone,
          );
          _userProfile = linked;
          await _writeTeamDoc(uid, linked.toMap());
        } else {
          final email = _currentUser!.email ?? '';
          if (email.isNotEmpty) {
            final name = (_currentUser!.displayName != null && _currentUser!.displayName!.trim().isNotEmpty)
                ? _currentUser!.displayName!.trim()
                : (email.contains('@') ? email.split('@').first : 'Usher');
            _userProfile = TeamMember(
              id: uid,
              name: name,
              email: email,
              phone: '',
              role: 'Admin',
              approved: true,
              createdAt: DateTime.now().toIso8601String(),
            );
            await _writeTeamDoc(uid, _userProfile!.toMap());
          }
        }
      }
    } catch (_) {}
    if (_userProfile != null) {
      _persistSession();
    }
    _authLoading = false;
    notifyListeners();
  }

  Future<void> updateProfile({required String name, String? phone}) async {
    if (_currentUser == null) return;
    final uid = _currentUser!.uid;
    try {
      await _currentUser!.updateDisplayName(name);
    } catch (_) {}

    final updated = TeamMember(
      id: uid,
      name: name,
      email: _userProfile?.email ?? _currentUser?.email ?? '',
      phone: phone ?? _userProfile?.phone ?? '',
      role: _userProfile?.role ?? 'Admin',
      approved: _userProfile?.approved ?? true,
      denied: _userProfile?.denied ?? false,
    );

    _userProfile = updated;
    notifyListeners();

    await _writeTeamDoc(uid, updated.toMap());
  }

  /// Normalizes a name by stripping punctuation, quotes, trailing role markers, and collapsing spaces.
  static String normalizeMemberName(String? raw) {
    if (raw == null) return '';
    String s = raw.toLowerCase().trim();
    s = s.replaceAll(RegExp(r'\s*\((admin|usher|lead|head usher|sunday lead)\)$'), '');
    s = s.replaceAll(RegExp(r'["“”‘’\.,]'), '');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  /// Determines if two TeamMember records represent the same person.
  static bool isSameMember(TeamMember a, TeamMember b) {
    // 1. Same Firestore document ID
    if (a.id.trim().isNotEmpty && a.id.trim() == b.id.trim()) {
      return true;
    }

    // 2. Matching non-empty email
    final emailA = (a.email ?? '').trim().toLowerCase();
    final emailB = (b.email ?? '').trim().toLowerCase();
    if (emailA.isNotEmpty && emailB.isNotEmpty && emailA == emailB) {
      return true;
    }

    // 3. Matching phone number
    final phoneA = (a.phone ?? '').replaceAll(RegExp(r'[^\d]'), '');
    final phoneB = (b.phone ?? '').replaceAll(RegExp(r'[^\d]'), '');
    if (phoneA.length >= 7 && phoneB.length >= 7) {
      final cleanA = (phoneA.length == 11 && phoneA.startsWith('1')) ? phoneA.substring(1) : phoneA;
      final cleanB = (phoneB.length == 11 && phoneB.startsWith('1')) ? phoneB.substring(1) : phoneB;
      if (cleanA == cleanB || (cleanA.length >= 7 && cleanB.length >= 7 && (cleanA.endsWith(cleanB) || cleanB.endsWith(cleanA)))) {
        return true;
      }
    }

    // 4. Matching normalized name (if not a generic placeholder)
    final normA = normalizeMemberName(a.name);
    final normB = normalizeMemberName(b.name);
    const genericNames = {'usher', 'admin', 'lead', 'unknown', 'team member', 'member', 'guest', 'user', ''};
    if (normA.isNotEmpty && !genericNames.contains(normA) && normA.length >= 3) {
      if (normA == normB) {
        return true;
      }
    }

    return false;
  }

  /// Merges two TeamMember records into one canonical record, preserving the highest permissions,
  /// current user UID, and complete contact details.
  static TeamMember mergeMembers(TeamMember existing, TeamMember incoming, {String? currentUid}) {
    // 1. Choose ID:
    String chosenId = existing.id;
    if (incoming.id == currentUid) {
      chosenId = incoming.id;
    } else if (existing.id == currentUid) {
      chosenId = existing.id;
    } else if (existing.id.startsWith('user_') && !incoming.id.startsWith('user_') && incoming.id.length >= 20) {
      chosenId = incoming.id;
    }

    // 2. Choose Name:
    String? chosenName = existing.name;
    final isExistingGeneric = chosenName == null || chosenName.trim().isEmpty || chosenName.trim().toLowerCase() == 'usher';
    final isIncomingGeneric = incoming.name == null || incoming.name!.trim().isEmpty || incoming.name!.trim().toLowerCase() == 'usher';
    if (isExistingGeneric && !isIncomingGeneric) {
      chosenName = incoming.name;
    } else if (!isExistingGeneric && !isIncomingGeneric && (incoming.name!.length > chosenName!.length)) {
      chosenName = incoming.name;
    }

    // 3. Choose Email:
    final chosenEmail = (existing.email != null && existing.email!.trim().isNotEmpty)
        ? existing.email
        : incoming.email;

    // 4. Choose Phone:
    final chosenPhone = (existing.phone != null && existing.phone!.trim().isNotEmpty)
        ? existing.phone
        : incoming.phone;

    // 5. Role: Admin takes highest precedence, then Lead, then first non-Usher, then Usher
    final bool isAdmin = existing.isAdmin || incoming.isAdmin;
    final bool isLead = existing.isLead || incoming.isLead;
    final String chosenRole = isAdmin
        ? 'Admin'
        : (isLead
            ? 'Lead'
            : ((existing.role != null && existing.role != 'Usher')
                ? existing.role!
                : (incoming.role ?? 'Usher')));

    // 6. Approved: true if either is approved or is admin
    final bool chosenApproved = isAdmin || existing.approved || incoming.approved;

    // 7. Denied: false if approved
    final bool chosenDenied = !chosenApproved && (existing.denied || incoming.denied);

    return TeamMember(
      id: chosenId,
      name: chosenName,
      email: chosenEmail,
      phone: chosenPhone,
      role: chosenRole,
      approved: chosenApproved,
      denied: chosenDenied,
      createdAt: existing.createdAt ?? incoming.createdAt,
      linkedTo: existing.linkedTo ?? incoming.linkedTo,
      fcmToken: (existing.fcmToken != null && existing.fcmToken!.trim().isNotEmpty)
          ? existing.fcmToken
          : incoming.fcmToken,
      twoFactorEnabled: existing.twoFactorEnabled || incoming.twoFactorEnabled,
      twoFactorPhone: (existing.twoFactorPhone != null && existing.twoFactorPhone!.trim().isNotEmpty)
          ? existing.twoFactorPhone
          : incoming.twoFactorPhone,
    );
  }

  /// Deduplicates a collection of TeamMember records by ID, email, phone, and normalized name.
  static List<TeamMember> deduplicateMemberList(Iterable<TeamMember> members, {String? currentUid}) {
    final List<TeamMember> result = [];

    for (final m in members) {
      final index = result.indexWhere((existing) => isSameMember(existing, m));
      if (index >= 0) {
        result[index] = mergeMembers(result[index], m, currentUid: currentUid);
      } else {
        result.add(m);
      }
    }

    return result;
  }

  Future<void> refreshRoster() async {
    final List<String> collectionsToList = ['team', 'users', 'ushers', 'team_members', 'roster'];
    final List<TeamMember> allMembers = [];
    for (var colName in collectionsToList) {
      try {
        final snap = await _db.collection(colName).get();
        for (var d in snap.docs) {
          try {
            allMembers.add(TeamMember.fromMap(d.data(), d.id));
          } catch (_) {}
        }
      } catch (_) {}
    }
    if (allMembers.isNotEmpty) {
      _liveRoster = deduplicateMemberList(allMembers, currentUid: _currentUser?.uid);
      _pendingUsers = _liveRoster.where((u) => !u.approved && !u.denied).toList();
      _approvedUsers = _liveRoster.where((u) => u.approved && !u.denied).toList();
      _deniedUsers = _liveRoster.where((u) => u.denied).toList();
      notifyListeners();
    }
  }

  void _listenToFirestore() {
    if (_currentUser == null) return;

    final List<String> collectionsToList = ['team', 'users', 'ushers', 'team_members', 'roster'];
    final Map<String, List<TeamMember>> collectionDocsMap = {};

    void processAllSnapshots() {
      final List<TeamMember> allMembers = [];
      for (var colName in collectionsToList) {
        final docs = collectionDocsMap[colName] ?? [];
        allMembers.addAll(docs);
      }
      _liveRoster = deduplicateMemberList(allMembers, currentUid: _currentUser?.uid);
      
      // Ensure Matthias Breyer is set to Admin in state and Firestore
      for (int i = 0; i < _liveRoster.length; i++) {
        final u = _liveRoster[i];
        final name = (u.name ?? '').toLowerCase();
        final phone = (u.phone ?? '').replaceAll(RegExp(r'[^\d]'), '');
        if (name.contains('matthias') || name.contains('breyer') || phone.contains('3183449278')) {
          if (u.role != 'Admin') {
            final adminMember = TeamMember(
              id: u.id,
              name: u.name,
              email: u.email,
              phone: u.phone,
              role: 'Admin',
              approved: true,
              denied: false,
              createdAt: u.createdAt,
              linkedTo: u.linkedTo,
              fcmToken: u.fcmToken,
            );
            _liveRoster[i] = adminMember;
            _writeTeamDoc(u.id, adminMember.toMap());
          }
        }
      }

      _pendingUsers = _liveRoster.where((u) => !u.approved && !u.denied).toList();
      _approvedUsers = _liveRoster.where((u) => u.approved && !u.denied).toList();
      _deniedUsers = _liveRoster.where((u) => u.denied).toList();
      notifyListeners();
    }

    for (var colName in collectionsToList) {
      try {
        _db.collection(colName).snapshots().listen((snap) {
          final List<TeamMember> docsList = [];
          for (var d in snap.docs) {
            try {
              docsList.add(TeamMember.fromMap(d.data(), d.id));
            } catch (_) {}
          }
          collectionDocsMap[colName] = docsList;
          processAllSnapshots();
        }, onError: (err) {
          // Suppress expected permission-denied warnings on secondary collections
        });
      } catch (_) {}
    }

    final Map<String, CommsMessage> commsCache = {};
    for (var colName in ['communications', 'comms_messages']) {
      try {
        _db.collection(colName).snapshots().listen((snap) {
          for (var change in snap.docChanges) {
            if (change.type == DocumentChangeType.removed) {
              commsCache.remove(change.doc.id);
            } else if (change.doc.data() != null) {
              final msg = CommsMessage.fromMap(change.doc.data()!, change.doc.id);
              commsCache[msg.id] = msg;
            }
          }
          final list = commsCache.values.toList()
            ..sort((a, b) => (a.createdAt ?? '').compareTo(b.createdAt ?? ''));
          _commsMessages = list;
          notifyListeners();
        }, onError: (_) {});
      } catch (_) {}
    }

    final Map<String, AttendanceLogEntry> attendanceCache = {};
    for (var colName in ['attendance', 'attendance_logs']) {
      try {
        _db.collection(colName).snapshots().listen((snap) {
          for (var change in snap.docChanges) {
            if (change.type == DocumentChangeType.removed) {
              attendanceCache.remove(change.doc.id);
            } else if (change.doc.data() != null) {
              final entry = AttendanceLogEntry.fromMap(change.doc.data()!, change.doc.id);
              attendanceCache[entry.id] = entry;
            }
          }
          final list = attendanceCache.values.toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _attendanceLogs = list;
          notifyListeners();
        }, onError: (_) {});
      } catch (_) {}
    }

    final Map<String, Deployment> deploymentCache = {};
    try {
      _db.collection('deployments').snapshots().listen((snap) {
        for (var change in snap.docChanges) {
          if (change.type == DocumentChangeType.removed) {
            deploymentCache.remove(change.doc.id);
          } else if (change.doc.data() != null) {
            final dep = Deployment.fromMap(change.doc.data()!, change.doc.id);
            deploymentCache[dep.id] = dep;
          }
        }
        _deployments = deploymentCache.values.toList();
        notifyListeners();
      }, onError: (_) {});
    } catch (_) {}

    // Real-time bidirectional tally synchronization across watch and phone
    try {
      _db.collection('settings').doc('live_tally').snapshots().listen((snap) {
        if (!snap.exists || snap.data() == null) return;
        final data = snap.data()!;
        if (data.containsKey('count')) {
          final remoteCount = (data['count'] as num).toInt();
          final remoteService = data['serviceType'] as String?;
          final nowMs = DateTime.now().millisecondsSinceEpoch;
          // Ignore echo if we just locally modified it in the last 1500ms
          if (nowMs - _lastLocalTallyUpdateTime > 1500) {
            bool changed = false;
            if (_currentTallyCount != remoteCount) {
              _currentTallyCount = remoteCount;
              changed = true;
            }
            if (remoteService != null && remoteService.trim().isNotEmpty && _activeServiceType != remoteService) {
              _activeServiceType = remoteService;
              changed = true;
            }
            if (changed) {
              AppWidgetService.updateTallyWidget(
                count: _currentTallyCount,
                serviceType: _activeServiceType,
              );
              notifyListeners();
            }
          }
        }
      }, onError: (_) {});
    } catch (_) {}

    // Guest check-ins stream (pure snapshot from Firestore filtered by deleted IDs)
    try {
      _db.collection('guest_checkins').snapshots().listen((snap) {
        final list = snap.docs
            .where((d) => d.data() != null && !_deletedGuestIds.contains(d.id))
            .map((d) => GuestCheckInEntry.fromMap(d.data()!, d.id))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _guestCheckIns = list;
        notifyListeners();
      }, onError: (_) {});
    } catch (_) {}

    // Announcements stream (pure snapshot filtered by deleted IDs)
    try {
      _db.collection('announcements').snapshots().listen((snap) {
        if (snap.docs.isNotEmpty) {
          for (final doc in snap.docs) {
            if (doc.data() != null && !_deletedAnnouncementIds.contains(doc.id)) {
              final ann = Announcement.fromMap(doc.data(), doc.id);
              final idx = _announcements.indexWhere((a) => a.id == ann.id);
              if (idx != -1) {
                _announcements[idx] = ann;
              } else {
                _announcements.insert(0, ann);
              }
            }
          }
          _announcements.removeWhere((a) => _deletedAnnouncementIds.contains(a.id));
          notifyListeners();
        }
      }, onError: (_) {});
    } catch (_) {}
  }

  Future<void> addGuestCheckIn({
    required String guestName,
    int partySize = 1,
    String entrance = 'Vestibule Station',
    String? notes,
  }) async {
    final now = DateTime.now();
    final timeFormat = DateFormat('h:mm a').format(now);
    final docRef = _db.collection('guest_checkins').doc();
    _deletedGuestIds.remove(docRef.id);
    final entry = GuestCheckInEntry(
      id: docRef.id,
      guestName: guestName,
      partySize: partySize,
      checkInTime: timeFormat,
      entrance: entrance,
      status: 'Checked In',
      notes: notes,
      createdAt: now.toIso8601String(),
    );
    _guestCheckIns.insert(0, entry);
    notifyListeners();
    try {
      await docRef.set(entry.toMap());
    } catch (_) {}
  }

  Future<void> updateGuestCheckIn({
    required String id,
    required String guestName,
    required int partySize,
    String entrance = 'Vestibule Station',
    String? notes,
  }) async {
    final idx = _guestCheckIns.indexWhere((g) => g.id == id);
    if (idx != -1) {
      final existing = _guestCheckIns[idx];
      _guestCheckIns[idx] = GuestCheckInEntry(
        id: existing.id,
        guestName: guestName,
        partySize: partySize,
        checkInTime: existing.checkInTime,
        entrance: entrance,
        status: existing.status,
        notes: notes,
        createdAt: existing.createdAt,
      );
      notifyListeners();
    }
    try {
      await _db.collection('guest_checkins').doc(id).update({
        'guestName': guestName,
        'partySize': partySize,
        'entrance': entrance,
        'notes': notes,
      });
    } catch (_) {}
  }

  Future<void> removeGuestCheckIn(String id) async {
    _deletedGuestIds.add(id);
    _guestCheckIns.removeWhere((g) => g.id == id);
    notifyListeners();
    try {
      await _db.collection('guest_checkins').doc(id).delete();
    } catch (_) {}
  }
}
