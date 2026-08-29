import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/team_member.dart';
import '../models/deployment.dart';
import '../models/attendance_log.dart';
import '../models/comms_message.dart';
import '../theme/app_theme.dart';

const String adminCodeConstant = 'GUARDIAN-LEAD-2024';

class FirebaseService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? _currentUser;
  TeamMember? _userProfile;
  bool _authLoading = false;
  bool _profileLoading = false;
  bool _isOfflineDemoMode = false;
  ThemeMode _themeMode = ThemeMode.light;
  AppStyleTheme _activeStyleTheme = AppStyleTheme.burgundy;

  List<TeamMember> _liveRoster = [];
  List<TeamMember> _pendingUsers = [];
  List<TeamMember> _approvedUsers = [];
  List<TeamMember> _deniedUsers = [];
  List<AttendanceLogEntry> _attendanceLogs = [];
  List<CommsMessage> _commsMessages = [];
  List<Deployment> _deployments = [];

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
    final ghosts = _liveRoster.where((u) {
      final isUsherFallbackName = u.name == null || u.name == 'Usher' || u.name!.trim().isEmpty;
      final hasNoEmail = u.email == null || u.email!.trim().isEmpty;
      final hasNoPhone = u.phone == null || u.phone!.trim().isEmpty;
      return isUsherFallbackName && hasNoEmail && hasNoPhone;
    }).toList();

    for (final ghost in ghosts) {
      await deleteTeamMember(ghost.id);
    }
    return ghosts.length;
  }

  String _bulletinText = "Welcome to Guardians of the Gate usher portal.";
  String _dashboardLeadName = "Lead Usher";

  // Tally Counter live state
  int _currentTallyCount = 0;
  String _activeServiceType = 'Sunday Morning Service';

  // Getters
  User? get currentUser => _currentUser;
  TeamMember? get userProfile {
    if (_userProfile != null) return _userProfile;
    if (_currentUser != null) {
      final email = _currentUser!.email ?? '';
      final name = (_currentUser!.displayName != null && _currentUser!.displayName!.trim().isNotEmpty)
          ? _currentUser!.displayName!.trim()
          : (email.contains('@') ? email.split('@').first : 'Usher');
      return TeamMember(
        id: _currentUser!.uid,
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

  List<TeamMember> get liveRoster => _liveRoster;
  List<TeamMember> get pendingUsers => _pendingUsers;
  List<TeamMember> get approvedUsers => _approvedUsers;
  List<TeamMember> get deniedUsers => _deniedUsers;
  List<AttendanceLogEntry> get attendanceLogs => _attendanceLogs;
  List<CommsMessage> get commsMessages => _commsMessages;
  List<Deployment> get deployments => _deployments;

  String get bulletinText => _bulletinText;
  String get dashboardLeadName => _dashboardLeadName;
  int get currentTallyCount => _currentTallyCount;
  String get activeServiceType => _activeServiceType;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  void initPushNotifications() async {
    try {
      if (Firebase.apps.isEmpty) return;
      final messaging = FirebaseMessaging.instance;
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

      if (!kIsWeb) {
        try {
          await messaging.subscribeToTopic('comms');
          await messaging.subscribeToTopic('all_ushers');
        } catch (_) {}
      }

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
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
            'platform': kIsWeb ? 'web' : 'mobile',
            'lastUpdated': DateTime.now().toIso8601String(),
          };
          await _db.collection('user_tokens').doc(_currentUser!.uid).set(tokenData, SetOptions(merge: true));
        }

        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint("Received Push Notification: ${message.notification?.title}");
        });

        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          debugPrint("Opened Push Notification App: ${message.notification?.title}");
        });
      }
    } catch (e) {
      debugPrint("Push notification setup info: $e");
    }
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
    _loadPreferences();
    _initService();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt('app_style_theme');
      if (themeIndex != null && themeIndex >= 0 && themeIndex < AppStyleTheme.values.length) {
        _activeStyleTheme = AppStyleTheme.values[themeIndex];
      }
      final isDark = prefs.getBool('app_theme_is_dark');
      if (isDark != null) {
        _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading stored theme preferences: $e");
    }
  }

  void _initService() {
    _auth.authStateChanges().listen((User? user) {
      _currentUser = user;
      if (user != null) {
        _loadUserProfile(user.uid);
        _listenToFirestore();
        initPushNotifications();
      } else {
        _userProfile = null;
        _authLoading = false;
        notifyListeners();
      }
    }, onError: (err) {
      debugPrint("Auth state listener error: $err");
      _authLoading = false;
      notifyListeners();
    });
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

  void updateTallyCount(int delta) {
    _currentTallyCount = (_currentTallyCount + delta).clamp(0, 9999);
    notifyListeners();
  }

  void resetTallyCount() {
    _currentTallyCount = 0;
    notifyListeners();
  }

  void setActiveServiceType(String service) {
    _activeServiceType = service;
    notifyListeners();
  }

  Future<void> submitAttendanceLog({
    required int headcount,
    required String serviceType,
    String? serviceDate,
    String? notes,
  }) async {
    final nowIso = DateTime.now().toIso8601String();
    final entry = AttendanceLogEntry(
      id: 'log_${DateTime.now().millisecondsSinceEpoch}',
      headcount: headcount,
      serviceType: serviceType,
      serviceDate: (serviceDate != null && serviceDate.trim().isNotEmpty)
          ? serviceDate.trim()
          : nowIso.split('T').first,
      notes: notes,
      submittedBy: _userProfile?.name ?? 'Usher',
      createdAt: nowIso,
    );

    _attendanceLogs.insert(0, entry);
    notifyListeners();

    try {
      await _db.collection('attendance').doc(entry.id).set(entry.toMap());
      await _db.collection('attendance_logs').doc(entry.id).set(entry.toMap());
    } catch (e) {
      debugPrint("Attendance log save error: $e");
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

  Future<void> postCommsMessage(String text) async {
    if (text.trim().isEmpty) return;

    final msg = CommsMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: text.trim(),
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
      sendPushNotificationAlert(
        title: msg.authorName ?? 'Guardians Comms',
        body: msg.text,
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
    _deployments.removeWhere((d) => d.id == id);
    notifyListeners();
    try {
      await _db.collection('deployment_publishes').doc(id).delete();
      await _db.collection('deployments').doc(id).delete();
    } catch (e) {
      debugPrint("Delete deployment error: $e");
    }
  }

  Future<void> clearAllDeployments() async {
    final list = List<Deployment>.from(_deployments);
    _deployments.clear();
    notifyListeners();
    for (final dep in list) {
      try {
        await _db.collection('deployments').doc(dep.id).delete();
      } catch (e) {
        debugPrint("Clear deployment error: $e");
      }
    }
  }

  Future<bool> signIn(String email, String password) async {
    _authLoading = true;
    notifyListeners();
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
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

  ConfirmationResult? _webConfirmationResult;
  String? _verificationId;
  String? _phoneSecurityCode;
  String? _pendingPhone;
  TeamMember? _pendingPhoneMember;

  String? get phoneSecurityCode => _phoneSecurityCode;
  String? get pendingPhone => _pendingPhone;

  Future<String> sendPhoneSecurityCode(String rawPhone) async {
    _authLoading = true;
    notifyListeners();

    final cleanPhone = rawPhone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanPhone.isEmpty || cleanPhone.length < 7) {
      _authLoading = false;
      notifyListeners();
      throw Exception("Please enter a valid phone number.");
    }

    final formatted = rawPhone.startsWith('+') ? rawPhone : '+1$cleanPhone';

    try {
      final collections = ['team', 'users', 'ushers', 'roster'];
      TeamMember? matchedMember;

      for (var colName in collections) {
        final snap = await _db.collection(colName).get();
        for (var doc in snap.docs) {
          final m = TeamMember.fromMap(doc.data(), doc.id);
          final userPhone = (m.phone ?? '').replaceAll(RegExp(r'[^\d]'), '');
          if (userPhone.isNotEmpty &&
              (userPhone == cleanPhone || userPhone.endsWith(cleanPhone) || cleanPhone.endsWith(userPhone))) {
            matchedMember = m;
            break;
          }
        }
        if (matchedMember != null) break;
      }

      if (matchedMember == null) {
        _authLoading = false;
        notifyListeners();
        throw Exception("No registered usher found matching phone number $rawPhone.");
      }

      final code = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
      _phoneSecurityCode = code;
      _pendingPhone = rawPhone;
      _pendingPhoneMember = matchedMember;

      // Trigger Production Phone Auth SMS dispatch
      if (kIsWeb) {
        try {
          _webConfirmationResult = await _auth.signInWithPhoneNumber(formatted);
          debugPrint("Web production SMS verification triggered for $formatted");
        } catch (e) {
          debugPrint("Web production SMS trigger info: $e");
        }
      } else {
        try {
          await _auth.verifyPhoneNumber(
            phoneNumber: formatted,
            verificationCompleted: (PhoneAuthCredential credential) async {
              final userCred = await _auth.signInWithCredential(credential);
              _currentUser = userCred.user;
              _userProfile = matchedMember;
              _authLoading = false;
              notifyListeners();
            },
            verificationFailed: (e) => debugPrint("Native phone SMS error: ${e.message}"),
            codeSent: (verId, _) {
              _verificationId = verId;
              notifyListeners();
            },
            codeAutoRetrievalTimeout: (verId) {
              _verificationId = verId;
            },
          );
        } catch (e) {
          debugPrint("Native production SMS trigger error: $e");
        }
      }

      _authLoading = false;
      notifyListeners();
      return code;
    } catch (e) {
      _authLoading = false;
      notifyListeners();
      rethrow;
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
      if (kIsWeb && _webConfirmationResult != null) {
        try {
          final userCred = await _webConfirmationResult!.confirm(code);
          _currentUser = userCred.user;
        } catch (e) {
          debugPrint("Web confirm verification error: $e");
        }
      } else if (_verificationId != null) {
        try {
          final cred = PhoneAuthProvider.credential(verificationId: _verificationId!, smsCode: code);
          final userCred = await _auth.signInWithCredential(cred);
          _currentUser = userCred.user;
        } catch (e) {
          debugPrint("Native confirm verification error: $e");
        }
      }

      if (_pendingPhoneMember != null) {
        _userProfile = _pendingPhoneMember;
      }

      _phoneSecurityCode = null;
      _pendingPhone = null;
      _pendingPhoneMember = null;
      _webConfirmationResult = null;
      _verificationId = null;

      _authLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _authLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> signInWithPhone(String rawPhone, String password) async {
    _authLoading = true;
    notifyListeners();

    final cleanPhone = rawPhone.replaceAll(RegExp(r'[^\d]'), '');
    final lowerRaw = rawPhone.toLowerCase().trim();

    if (cleanPhone.isEmpty && lowerRaw.isEmpty) {
      _authLoading = false;
      notifyListeners();
      throw Exception("Please enter your registered phone number.");
    }

    if (password.trim().isEmpty) {
      _authLoading = false;
      notifyListeners();
      throw Exception("Please enter your password.");
    }

    try {
      // 1. Check in liveRoster memory first
      TeamMember? matchedMember;
      for (final m in _liveRoster) {
        final uPhone = (m.phone ?? '').replaceAll(RegExp(r'[^\d]'), '');
        final uName = (m.name ?? '').toLowerCase();
        final uEmail = (m.email ?? '').toLowerCase();

        final phoneMatch = cleanPhone.isNotEmpty &&
            uPhone.isNotEmpty &&
            (uPhone == cleanPhone ||
             uPhone.endsWith(cleanPhone) ||
             cleanPhone.endsWith(uPhone) ||
             (cleanPhone.length >= 7 && uPhone.contains(cleanPhone)));

        final nameMatch = lowerRaw.length >= 3 && uName.contains(lowerRaw);
        final emailMatch = lowerRaw.length >= 3 && uEmail.contains(lowerRaw);

        if (phoneMatch || nameMatch || emailMatch) {
          matchedMember = m;
          break;
        }
      }

      // 2. If not found in memory, query Firestore collections
      if (matchedMember == null) {
        final collections = ['team', 'users', 'ushers', 'roster', 'teams', 'team_members'];
        for (var colName in collections) {
          try {
            final snap = await _db.collection(colName).get();
            for (var doc in snap.docs) {
              final m = TeamMember.fromMap(doc.data(), doc.id);
              final userPhone = (m.phone ?? '').replaceAll(RegExp(r'[^\d]'), '');
              final uName = (m.name ?? '').toLowerCase();
              final uEmail = (m.email ?? '').toLowerCase();

              final phoneMatch = cleanPhone.isNotEmpty &&
                  userPhone.isNotEmpty &&
                  (userPhone == cleanPhone ||
                   userPhone.endsWith(cleanPhone) ||
                   cleanPhone.endsWith(userPhone) ||
                   (cleanPhone.length >= 7 && userPhone.contains(cleanPhone)));

              final nameMatch = lowerRaw.length >= 3 && uName.contains(lowerRaw);
              final emailMatch = lowerRaw.length >= 3 && uEmail.contains(lowerRaw);

              if (phoneMatch || nameMatch || emailMatch) {
                matchedMember = m;
                break;
              }
            }
          } catch (_) {}
          if (matchedMember != null) break;
        }
      }

      if (matchedMember == null) {
        _authLoading = false;
        notifyListeners();
        throw Exception("No registered usher found matching '$rawPhone'. Please ask your Lead Usher or Admin to add your phone number to the directory.");
      }

      // 3. Authenticate with FirebaseAuth using registered email or phone fallback email
      final primaryEmail = (matchedMember.email != null && matchedMember.email!.contains('@'))
          ? matchedMember.email!.trim()
          : '${cleanPhone.isNotEmpty ? cleanPhone : matchedMember.id}@usherapp.com';
      final fallbackEmail = '${cleanPhone.isNotEmpty ? cleanPhone : matchedMember.id}@usherapp.com';

      // Attempt 1: Primary Email Sign-In
      try {
        final userCred = await _auth.signInWithEmailAndPassword(
          email: primaryEmail,
          password: password,
        );
        _currentUser = userCred.user;
        _userProfile = matchedMember;
        _authLoading = false;
        notifyListeners();
        return true;
      } on FirebaseAuthException catch (fe1) {
        if (fe1.code == 'user-not-found') {
          // Provision login account automatically for existing roster usher
          try {
            final newCred = await _auth.createUserWithEmailAndPassword(
              email: primaryEmail,
              password: password,
            );
            _currentUser = newCred.user;
            _userProfile = matchedMember;
            _authLoading = false;
            notifyListeners();
            return true;
          } catch (_) {}
        }

        // Attempt 2: Fallback Phone Email Sign-In if primaryEmail was different
        if (primaryEmail != fallbackEmail) {
          try {
            final userCred = await _auth.signInWithEmailAndPassword(
              email: fallbackEmail,
              password: password,
            );
            _currentUser = userCred.user;
            _userProfile = matchedMember;
            _authLoading = false;
            notifyListeners();
            return true;
          } on FirebaseAuthException catch (fe2) {
            if (fe2.code == 'user-not-found') {
              try {
                final newCred = await _auth.createUserWithEmailAndPassword(
                  email: fallbackEmail,
                  password: password,
                );
                _currentUser = newCred.user;
                _userProfile = matchedMember;
                _authLoading = false;
                notifyListeners();
                return true;
              } catch (_) {}
            }
          } catch (_) {}
        }

        _authLoading = false;
        notifyListeners();
        if (fe1.code == 'wrong-password' || fe1.code == 'invalid-credential') {
          throw Exception("Incorrect password for usher ${matchedMember.name ?? rawPhone}. Please re-enter your password.");
        } else {
          throw Exception(fe1.message ?? "Authentication failed.");
        }
      } catch (e) {
        _authLoading = false;
        notifyListeners();
        throw Exception("Phone sign in error: ${e.toString().replaceAll(RegExp(r'\[.*?\]'), '').replaceAll('Exception: ', '').trim()}");
      }
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
    try {
      await _auth.signOut();
    } catch (_) {}
    _currentUser = null;
    _userProfile = null;
    _isOfflineDemoMode = false;
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
        final email = _currentUser!.email ?? '';
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
    } catch (_) {}
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

  Future<void> refreshRoster() async {
    final List<String> collectionsToList = ['team', 'users', 'ushers', 'team_members', 'roster'];
    final Map<String, TeamMember> merged = {};
    for (var colName in collectionsToList) {
      try {
        final snap = await _db.collection(colName).get();
        for (var d in snap.docs) {
          try {
            final u = TeamMember.fromMap(d.data(), d.id);
            merged[u.id] = u;
          } catch (_) {}
        }
      } catch (_) {}
    }
    if (merged.isNotEmpty) {
      _liveRoster = merged.values.toList();
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
      final Map<String, TeamMember> merged = {};
      for (var colName in collectionsToList) {
        final docs = collectionDocsMap[colName] ?? [];
        for (var u in docs) {
          if (!merged.containsKey(u.id)) {
            merged[u.id] = u;
          }
        }
      }
      _liveRoster = merged.values.toList();
      
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
    for (var colName in ['deployment_publishes', 'deployments']) {
      try {
        _db.collection(colName).snapshots().listen((snap) {
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
    }
  }
}
