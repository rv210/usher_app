import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'services/firebase_options.dart';
import 'services/firebase_service.dart';
import 'services/bubble_service.dart';
import 'theme/app_theme.dart';
import 'views/login_view.dart';
import 'views/pending_denied_view.dart';
import 'views/dashboard_view.dart';
import 'views/calendar_view.dart';
import 'views/attendance_view.dart';
import 'views/database_view.dart';
import 'views/comms_view.dart';
import 'views/admin_approval_view.dart';
import 'views/settings_view.dart';
import 'views/splash_view.dart';
import 'views/app_tutorial_view.dart';
import 'views/app_coachmark_tour.dart';
import 'views/ushering_training_view.dart';
import 'views/wear_tally_view.dart';
import 'services/app_widget_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// Android pushes are sent data-only (see functions/src/index.ts) so this
// handler is the sole renderer while the app is backgrounded/killed - there
// is no `notification` block for Android to auto-display, which is what
// previously caused a second, OS-rendered banner alongside the one shown by
// onMessage's foreground handler in FirebaseService.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  debugPrint("System Push Notification Received: ${message.notification?.title ?? message.data['title']}");

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    final title = message.data['title'];
    final body = message.data['body'];
    if (title != null) {
      try {
        final isComms = (message.data['type'] == 'comms') ||
            title.toLowerCase().contains('comms') ||
            title.toLowerCase().contains('chat') ||
            title.toLowerCase().contains('message');

        if (isComms) {
          final sender = message.data['senderName'] ?? title;
          final text = message.data['message'] ?? body ?? '';
          final senderId = message.data['senderId'] ?? 'team_lead';
          final bubbled = await BubbleService.showBubbleNotification(
            senderName: sender,
            message: text,
            senderId: senderId,
            shortcutId: 'comms_$senderId',
          );
          if (bubbled) return;
        }

        final localNotifications = FlutterLocalNotificationsPlugin();
        await localNotifications.initialize(
          const InitializationSettings(
            android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          ),
        );
        final androidPlugin = localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.createNotificationChannel(
          const AndroidNotificationChannel(
            'high_importance_channel',
            'High Importance Notifications',
            description: 'Used for comms, schedule, and deployment alerts',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );
        final notificationId =
            (message.messageId ?? '${message.sentTime?.millisecondsSinceEpoch}_${title}_$body').hashCode & 0x7FFFFFFF;
        await localNotifications.show(
          notificationId,
          title,
          body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              channelDescription: 'Used for comms, schedule, and deployment alerts',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              enableVibration: true,
              playSound: true,
            ),
          ),
        );
      } catch (e) {
        debugPrint("Background local notification error: $e");
      }
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    debugPrint("No .env file loaded.");
  }

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }
  } catch (e) {
    debugPrint("Firebase initialization info: $e");
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => FirebaseService(),
      child: const UsherApp(),
    ),
  );
}

class UsherApp extends StatelessWidget {
  const UsherApp({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context);
    final isDark = firebaseService.themeMode == ThemeMode.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(statusBarColor: Colors.transparent),
      child: MaterialApp(
        title: 'Guardians of the Gate - Usher App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.getTheme(Brightness.light, firebaseService.activeStyleTheme),
        darkTheme: AppTheme.getTheme(Brightness.dark, firebaseService.activeStyleTheme),
        themeMode: firebaseService.themeMode,
        initialRoute: '/',
        routes: {
          '/': (context) => const MainShell(),
          '/comms': (context) => const BubbleCommsShell(),
          '/wear_tally': (context) => const WearTallyCounterView(),
        },
      ),
    );
  }
}

class BubbleCommsShell extends StatelessWidget {
  const BubbleCommsShell({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context);
    if (firebaseService.currentUser == null && !firebaseService.isUserSignedIn) {
      return const LoginView(initialMode: 'login');
    }
    return const Scaffold(
      body: DribbbleAmbientBackground(
        child: CommsView(),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentTab = 0; // Default to Dashboard
  double _edgeDragDistance = 0;
  bool _edgeDragTriggered = false;

  // GlobalKeys for Coachmark Tour spotlights
  final GlobalKey _hubNavKey = GlobalKey();
  final GlobalKey _rosterNavKey = GlobalKey();
  final GlobalKey _tallyNavKey = GlobalKey();
  final GlobalKey _directoryNavKey = GlobalKey();
  final GlobalKey _commsNavKey = GlobalKey();
  final GlobalKey _settingsNavKey = GlobalKey();
  final GlobalKey _adminNavKey = GlobalKey();

  // In-View Feature GlobalKeys for Coachmark Tour
  final GlobalKey _calendarSundayStripKey = GlobalKey();
  final GlobalKey _calendarAddDutyKey = GlobalKey();
  final GlobalKey _tallyCounterKey = GlobalKey();
  final GlobalKey _tallySubmitKey = GlobalKey();
  final GlobalKey _tallyHistoryKey = GlobalKey();
  final GlobalKey _tallyEditDeleteKey = GlobalKey();
  final GlobalKey _directoryAddMemberKey = GlobalKey();
  final GlobalKey _directoryContactActionsKey = GlobalKey();
  final GlobalKey _commsMediaActionsKey = GlobalKey();
  final GlobalKey _settingsDarkThemeKey = GlobalKey();
  final GlobalKey _settingsTwoFactorKey = GlobalKey();
  final GlobalKey _settingsThemePresetsKey = GlobalKey();

  bool _isCoachmarkActive = false;
  int _coachmarkStep = 0;

  GlobalKey _getNavKey(int index) {
    switch (index) {
      case 0:
        return _hubNavKey;
      case 1:
        return _rosterNavKey;
      case 2:
        return _tallyNavKey;
      case 3:
        return _directoryNavKey;
      case 4:
        return _commsNavKey;
      case 5:
        return _settingsNavKey;
      case 6:
        return _adminNavKey;
      default:
        return _hubNavKey;
    }
  }

  void _startCoachmarkTour({int startStep = 0}) {
    setState(() {
      _coachmarkStep = startStep;
      _isCoachmarkActive = true;
    });
    final steps = _buildCoachmarkSteps(
      Provider.of<FirebaseService>(context, listen: false).userProfile?.isAdmin == true,
      Theme.of(context).primaryColor,
    );
    if (startStep >= 0 && startStep < steps.length) {
      final tab = steps[startStep].targetTabIndex;
      if (tab != null && tab != _currentTab) {
        _onNavigateToTab(tab);
      }
    }
  }

  List<CoachmarkStep> _buildCoachmarkSteps(bool isAdmin, Color primaryColor) {
    return [
      CoachmarkStep(
        targetKey: _hubNavKey,
        title: 'Hub: Mission Control',
        description: 'Your central command center for live service countdowns, upcoming assignments, urgent alerts, and the app tutorial.',
        icon: LucideIcons.layoutDashboard,
        badgeText: 'Mission Hub',
        targetTabIndex: 0,
        isCircle: true,
        accentColor: primaryColor,
      ),
      CoachmarkStep(
        targetKey: _rosterNavKey,
        title: 'Roster & Duty Schedule',
        description: 'View upcoming service shifts, station assignments, team attendance, and coordinate sub-in coverage for schedules.',
        icon: LucideIcons.calendar,
        badgeText: 'Scheduling',
        targetTabIndex: 1,
        isCircle: false,
        accentColor: const Color(0xFF38BDF8),
      ),
      CoachmarkStep(
        targetKey: _calendarSundayStripKey,
        title: 'Sunday Schedule & Headcount',
        description: 'Browse weekly Sunday services, flip through calendar months, and track scheduled usher headcounts at a glance.',
        icon: LucideIcons.calendarDays,
        badgeText: 'Sunday Strip',
        targetTabIndex: 1,
        isCircle: false,
        accentColor: const Color(0xFFF59E0B),
      ),
      CoachmarkStep(
        targetKey: _calendarAddDutyKey,
        title: 'Assign Duty Stations',
        description: 'Tap "+" to open the deployment sheet: pick service type, assign ushers to Lead or Station posts, and select Sunday dates.',
        icon: LucideIcons.userPlus,
        badgeText: 'Duty Deployment',
        targetTabIndex: 1,
        isCircle: true,
        accentColor: const Color(0xFF10B981),
      ),
      CoachmarkStep(
        targetKey: _tallyNavKey,
        title: 'Live Sanctuary Tally',
        description: 'Record congregation headcounts, track section capacities, and stream service counts in real time.',
        icon: LucideIcons.binary,
        badgeText: 'Sanctuary Tally',
        targetTabIndex: 2,
        isCircle: false,
        accentColor: const Color(0xFF10B981),
      ),
      CoachmarkStep(
        targetKey: _tallyCounterKey,
        title: 'Live Headcount Counter',
        description: 'Tap anywhere on the dial for instant +1 (hold for -1), or use quick preset chips (+1, +5, +10, +25) with 1-tap Undo.',
        icon: LucideIcons.binary,
        badgeText: 'Live Counter',
        targetTabIndex: 2,
        isCircle: false,
        accentColor: const Color(0xFF10B981),
      ),
      CoachmarkStep(
        targetKey: _tallySubmitKey,
        title: 'Service Details & Submission',
        description: 'Choose service type (Sunday, Special Events, Communion), pick service date, add optional section notes, and submit to sync.',
        icon: LucideIcons.clipboardCheck,
        badgeText: 'Submit Count',
        targetTabIndex: 2,
        isCircle: false,
        accentColor: const Color(0xFFF59E0B),
        scrollAlignment: 0.1,
      ),
      CoachmarkStep(
        targetKey: _tallyHistoryKey,
        title: 'Recent Attendance Logs',
        description: 'Review historical attendance counts with usher notes, and use the edit pencil or trash icon to maintain records.',
        icon: LucideIcons.history,
        badgeText: 'Attendance History',
        targetTabIndex: 2,
        isCircle: false,
        accentColor: const Color(0xFF38BDF8),
        scrollAlignment: 0.1,
      ),
      CoachmarkStep(
        targetKey: _tallyEditDeleteKey,
        title: 'Edit & Delete Attendance Logs',
        description: 'Use the pencil icon to update service headcounts and notes, or tap the red trash can to delete inaccurate records.',
        icon: LucideIcons.fileEdit,
        badgeText: 'Manage Records',
        targetTabIndex: 2,
        isCircle: false,
        accentColor: const Color(0xFFEF4444),
        scrollAlignment: 0.1,
      ),
      CoachmarkStep(
        targetKey: _directoryNavKey,
        title: 'Directory & Team Roster',
        description: 'Search usher profiles, filter by Admin/Lead or Usher, and quick-call service Team Leads.',
        icon: LucideIcons.users,
        badgeText: 'Team Directory',
        targetTabIndex: 3,
        isCircle: false,
        accentColor: const Color(0xFFA855F7),
      ),
      CoachmarkStep(
        targetKey: _directoryAddMemberKey,
        title: 'Register & Add Usher',
        description: 'Tap the "+" member icon in the top header to register a new usher or team lead into the ministry roster.',
        icon: LucideIcons.userPlus,
        badgeText: 'Add Member',
        targetTabIndex: 3,
        isCircle: true,
        accentColor: const Color(0xFFA855F7),
      ),
      CoachmarkStep(
        targetKey: _directoryContactActionsKey,
        title: 'Quick Call & SMS Direct',
        description: 'Tap "Call" to dial an usher instantly, or tap "SMS" to send a direct text message for swift duty and shift coordination.',
        icon: LucideIcons.phoneCall,
        badgeText: 'Direct Contact',
        targetTabIndex: 3,
        isCircle: false,
        accentColor: const Color(0xFF10B981),
      ),
      CoachmarkStep(
        targetKey: _commsNavKey,
        title: 'Live Comms & Chat',
        description: 'Instant team channels, urgent alerts, and Android Chat Head Bubbles for rapid coordination.',
        icon: LucideIcons.messageSquare,
        badgeText: 'Instant Comms',
        targetTabIndex: 4,
        isCircle: false,
        accentColor: const Color(0xFFF59E0B),
      ),
      CoachmarkStep(
        targetKey: _commsMediaActionsKey,
        title: 'Urgent Alerts, Photos & GIFs',
        description: 'Tap the red badge to broadcast priority alerts (Medical/Security), snap live camera photos, or insert animated GIFs for team encouragement.',
        icon: LucideIcons.sparkles,
        badgeText: 'Alerts & Media',
        targetTabIndex: 4,
        isCircle: false,
        accentColor: const Color(0xFFEF4444),
      ),
      CoachmarkStep(
        targetKey: _settingsNavKey,
        title: 'Themes & Preferences',
        description: 'Switch dynamic visual themes, configure biometric unlock, and customize notification preferences.',
        icon: LucideIcons.sliders,
        badgeText: 'App Settings',
        targetTabIndex: 5,
        isCircle: false,
        accentColor: const Color(0xFFEC4899),
      ),
      CoachmarkStep(
        targetKey: _settingsDarkThemeKey,
        title: 'Dark Theme Mode',
        description: 'Switch effortlessly between dark and light aesthetics to suit sanctuary lighting or bright daytime services.',
        icon: LucideIcons.sunMedium,
        badgeText: 'Theme Mode',
        targetTabIndex: 5,
        isCircle: false,
        accentColor: const Color(0xFFF59E0B),
        scrollAlignment: 0.15,
      ),
      CoachmarkStep(
        targetKey: _settingsTwoFactorKey,
        title: 'Two-Factor Authentication (2FA)',
        description: 'Enhance ministry account security by requiring a 6-digit SMS verification code on sign-in.',
        icon: LucideIcons.shieldCheck,
        badgeText: 'Account Security',
        targetTabIndex: 5,
        isCircle: false,
        accentColor: const Color(0xFF38BDF8),
        scrollAlignment: 0.25,
      ),
      CoachmarkStep(
        targetKey: _settingsThemePresetsKey,
        title: 'App Styles & Theme Presets',
        description: 'Select curated visual themes: Sacred Burgundy, Figma Cyber Neon, Terracotta Warmth, or Sanctuary Emerald to transform the UI.',
        icon: LucideIcons.palette,
        badgeText: 'Theme Presets',
        targetTabIndex: 5,
        isCircle: false,
        accentColor: const Color(0xFFEC4899),
        scrollAlignment: 0.1,
      ),
      if (isAdmin)
        CoachmarkStep(
          targetKey: _adminNavKey,
          title: 'Admin/Lead Governance',
          description: 'Publish leadership bulletins, review usher approvals (Approve/Deny) for new registrations, and manage ministry permissions.',
          icon: LucideIcons.shieldCheck,
          badgeText: 'Admin/Lead',
          targetTabIndex: 6,
          isCircle: false,
          accentColor: const Color(0xFFEF4444),
        ),
    ];
  }

  // Splash is always shown for at least 3 seconds on every cold launch
  bool _splashDone = false;
  bool _hasPromptedTutorial = false;
  String? _lastPromptedUserId;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        setState(() => _splashDone = true);
      }
    });

    // Handle deep linking from Android widgets
    AppWidgetService.getInitialWidgetRoute().then((data) {
      if (data != null && mounted) {
        _handleWidgetRoute(data);
      }
    });
    AppWidgetService.setWidgetClickListener((data) {
      if (mounted) {
        _handleWidgetRoute(data);
      }
    });
  }

  void _handleWidgetRoute(Map<String, dynamic> data) {
    if (data.containsKey('target_tab')) {
      final tab = data['target_tab'] as int?;
      if (tab != null && tab >= 0) {
        _onNavigateToTab(tab);
      }
    } else if (data.containsKey('target_action')) {
      final action = data['target_action'] as String?;
      if (action == 'handbook') {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const UsheringTrainingView(initialTabIndex: 1),
          ),
        );
      }
    }
  }

  void _checkAndPromptTutorial(BuildContext context) async {
    if (!mounted) return;
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);
    final user = firebaseService.currentUser;
    final profile = firebaseService.userProfile;

    if (user == null || profile == null || !profile.approved) return;
    if (_hasPromptedTutorial || _lastPromptedUserId == user.uid) return;

    final shouldShowTour = await AppCoachmarkTour.shouldShowTour();
    if (!shouldShowTour) return;

    _hasPromptedTutorial = true;
    _lastPromptedUserId = user.uid;

    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;

    _showTutorialPromptDialog(context);
  }

  void _showTutorialPromptDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF141923)
            : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        actionsPadding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: context.activeGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome!",
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  Text(
                    "Interactive App Tutorial",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: context.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Text(
          "Would you like an interactive walkthrough of the app to learn where each feature is located?",
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.45,
            color: context.textPrimaryColor.withValues(alpha: 0.9),
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black).withValues(alpha: 0.2),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    AppCoachmarkTour.markCompleted();
                    _showHubTutorialNotice(context);
                  },
                  child: Text(
                    "No, Skip",
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.textSecondaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 3,
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Future.delayed(const Duration(milliseconds: 250), () {
                      if (mounted) {
                        _startCoachmarkTour(startStep: 0);
                      }
                    });
                  },
                  child: Text(
                    "Yes, Show Me",
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showHubTutorialNotice(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        backgroundColor: const Color(0xFF161C27),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.4),
            width: 1.2,
          ),
        ),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.layoutDashboard,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Tutorial in the Hub",
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "No problem! The app tutorial can be accessed anytime in the Hub rather than Settings.",
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: Colors.white70,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onNavigateToTab(int index) {
    HapticFeedback.selectionClick();
    if (index == 4) {
      try {
        Provider.of<FirebaseService>(context, listen: false).markCommsAsRead();
      } catch (_) {}
    }
    setState(() => _currentTab = index);
  }

  // Tabs are peers in an IndexedStack, not pushed routes, so iOS's native
  // edge-swipe-back gesture has nothing to attach to. This gives every tab
  // a left-edge swipe back to the Hub without restructuring tab state.
  Widget _withEdgeSwipeBack(Widget child) {
    final supportsEdgeSwipe = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);
    if (!supportsEdgeSwipe || _currentTab == 0) return child;

    return Stack(
      children: [
        child,
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: 24,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: (_) {
              _edgeDragDistance = 0;
              _edgeDragTriggered = false;
            },
            onHorizontalDragUpdate: (details) {
              if (_edgeDragTriggered) return;
              _edgeDragDistance += details.delta.dx;
              if (_edgeDragDistance > 60) {
                _edgeDragTriggered = true;
                _onNavigateToTab(0);
              }
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final bool isWatch = (size.width - size.height).abs() < 50 && size.shortestSide < 500;
    if (isWatch) {
      return const WearTallyCounterView();
    }

    final firebaseService = Provider.of<FirebaseService>(context);

    if (!_splashDone || firebaseService.authLoading) {
      return const DribbbleSplashScreen();
    }

    // Unauthenticated -> Direct to Login Screen
    if (firebaseService.currentUser == null && !firebaseService.isUserSignedIn) {
      _hasPromptedTutorial = false;
      _lastPromptedUserId = null;
      return const LoginView(initialMode: 'login');
    }

    final profile = firebaseService.userProfile;

    // Pending or Denied Guard
    if (profile != null && !profile.approved) {
      return PendingDeniedView(isDenied: profile.denied);
    }

    // Check if we should prompt the user for the tutorial on sign-in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndPromptTutorial(context);
    });

    final isWideScreen = MediaQuery.of(context).size.width >= 800;

    final List<Widget> pages = [
      DashboardView(
        onNavigateTab: _onNavigateToTab,
        onStartCoachmarkTour: () => _startCoachmarkTour(startStep: 0),
      ),
      CalendarView(
        sundayStripKey: _calendarSundayStripKey,
        addDutyKey: _calendarAddDutyKey,
      ),
      AttendanceView(
        counterKey: _tallyCounterKey,
        submitKey: _tallySubmitKey,
        historyKey: _tallyHistoryKey,
        editDeleteKey: _tallyEditDeleteKey,
      ),
      DatabaseView(
        addMemberKey: _directoryAddMemberKey,
        contactActionsKey: _directoryContactActionsKey,
      ),
      CommsView(
        mediaActionsKey: _commsMediaActionsKey,
      ),
      SettingsView(
        onStartCoachmarkTour: () => _startCoachmarkTour(startStep: 0),
        themePresetsKey: _settingsThemePresetsKey,
        darkThemeKey: _settingsDarkThemeKey,
        twoFactorKey: _settingsTwoFactorKey,
        onNavigateToTab: _onNavigateToTab,
      ),
      if (profile?.isAdmin == true) const AdminApprovalView(),
    ];

    final navItems = [
      {'icon': LucideIcons.layoutDashboard, 'label': 'Hub'},
      {'icon': LucideIcons.calendar, 'label': 'Roster'},
      {'icon': LucideIcons.binary, 'label': 'Tally'},
      {'icon': LucideIcons.users, 'label': 'Directory'},
      {'icon': LucideIcons.messageSquare, 'label': 'Comms'},
      {'icon': LucideIcons.sliders, 'label': 'Settings'},
      if (profile?.isAdmin == true) {'icon': LucideIcons.shieldCheck, 'label': 'Admin/Lead'},
    ];

    if (_currentTab >= pages.length) {
      _currentTab = 0;
    }

    final Widget rootShell;

    if (isWideScreen) {
      rootShell = _withEdgeSwipeBack(Scaffold(
        body: DribbbleAmbientBackground(
          child: Row(
            children: [
              // Floating Desktop Navigation Rail
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: DribbbleGlassContainer(
                  borderRadius: 24,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                  child: Column(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: AppThemePresets.configs[firebaseService.activeStyleTheme]?.gradient ?? AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.4),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.asset('assets/images/app_icon.jpg', fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: List.generate(navItems.length, (index) {
                              final isSelected = _currentTab == index;
                              final item = navItems[index];
                              final activeGradient = AppThemePresets.configs[firebaseService.activeStyleTheme]?.gradient ?? AppColors.primaryGradient;

                              return Padding(
                                key: _getNavKey(index),
                                padding: const EdgeInsets.symmetric(vertical: 6.0),
                                child: InkWell(
                                  onTap: () => _onNavigateToTab(index),
                                  borderRadius: BorderRadius.circular(16),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      gradient: isSelected ? activeGradient : null,
                                      color: isSelected ? null : Colors.transparent,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: Theme.of(context).primaryColor.withValues(alpha: 0.4),
                                                blurRadius: 12,
                                                offset: const Offset(0, 4),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                       children: [
                                         Stack(
                                           clipBehavior: Clip.none,
                                           children: [
                                             Icon(
                                               item['icon'] as IconData,
                                               color: isSelected
                                                   ? Colors.white
                                                   : context.textSecondaryColor,
                                               size: 20,
                                             ),
                                             if (index == 4 && firebaseService.hasUnreadCommsMessages)
                                               Positioned(
                                                 top: -2,
                                                 right: -2,
                                                 child: Container(
                                                   width: 7,
                                                   height: 7,
                                                   decoration: const BoxDecoration(
                                                     color: Color(0xFFEF4444),
                                                     shape: BoxShape.circle,
                                                   ),
                                                 ),
                                               ),
                                           ],
                                         ),
                                         const SizedBox(width: 12),
                                        Text(
                                          item['label'] as String,
                                          style: GoogleFonts.outfit(
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                            fontSize: 14,
                                            color: isSelected
                                              ? Colors.white
                                              : context.textSecondaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: IndexedStack(
                  index: _currentTab,
                  children: pages,
                ),
              ),
            ],
          ),
        ),
      ));
    } else {
      final activeGradient = context.activeGradient;
      final activeColor = Theme.of(context).primaryColor;
      final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
      final isDark = Theme.of(context).brightness == Brightness.dark;

      final isAdmin = profile?.isAdmin == true;

      final List<Map<String, dynamic>> leftNavItems;
      final List<Map<String, dynamic>> rightNavItems;

      if (isAdmin) {
        leftNavItems = [
          {'icon': LucideIcons.calendar, 'label': 'Roster', 'index': 1},
          {'icon': LucideIcons.binary, 'label': 'Tally', 'index': 2},
          {'icon': LucideIcons.users, 'label': 'Directory', 'index': 3},
        ];
        rightNavItems = [
          {'icon': LucideIcons.messageSquare, 'label': 'Comms', 'index': 4},
          {'icon': LucideIcons.sliders, 'label': 'Settings', 'index': 5},
          {'icon': LucideIcons.shieldCheck, 'label': 'Admin/Lead', 'index': 6},
        ];
      } else {
        leftNavItems = [
          {'icon': LucideIcons.calendar, 'label': 'Roster', 'index': 1},
          {'icon': LucideIcons.binary, 'label': 'Tally', 'index': 2},
        ];
        rightNavItems = [
          {'icon': LucideIcons.users, 'label': 'Directory', 'index': 3},
          {'icon': LucideIcons.messageSquare, 'label': 'Comms', 'index': 4},
          {'icon': LucideIcons.sliders, 'label': 'Settings', 'index': 5},
        ];
      }

      rootShell = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragUpdate: (details) {
          // If swiping downward anywhere on screen, dismiss on-screen keyboard to reveal bottom nav bar
          if (details.delta.dy > 5) {
            FocusManager.instance.primaryFocus?.unfocus();
          }
        },
        child: _withEdgeSwipeBack(Scaffold(
          extendBody: true,
          resizeToAvoidBottomInset: true,
          body: DribbbleAmbientBackground(
            child: IndexedStack(
              index: _currentTab,
              children: pages,
            ),
          ),
          bottomNavigationBar: isKeyboardVisible
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                    child: SizedBox(
                      height: 82,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.bottomCenter,
                        children: [
                          // Main Bar Container
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: 64,
                            child: DribbbleGlassContainer(
                              borderRadius: 28,
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                              blur: 24,
                              backgroundColor: isDark
                                  ? const Color(0xFF0B0F1C).withValues(alpha: 0.94)
                                  : Colors.white.withValues(alpha: 0.96),
                              child: Row(
                                children: [
                                  // Left Nav Items
                                  Expanded(
                                    child: Row(
                                      children: leftNavItems.map((item) {
                                        final isSelected = _currentTab == item['index'];
                                        return _buildNavItem(
                                          key: _getNavKey(item['index'] as int),
                                          item: item,
                                          isSelected: isSelected,
                                          activeColor: activeColor,
                                          inactiveColor: context.textSecondaryColor,
                                          isDark: isDark,
                                        );
                                      }).toList(),
                                    ),
                                  ),

                                  // Gap for Central Elevated Hub Button
                                  const SizedBox(width: 66),

                                  // Right Nav Items
                                  Expanded(
                                    child: Row(
                                      children: rightNavItems.map((item) {
                                        final isSelected = _currentTab == item['index'];
                                        return _buildNavItem(
                                          key: _getNavKey(item['index'] as int),
                                          item: item,
                                          isSelected: isSelected,
                                          activeColor: activeColor,
                                          inactiveColor: context.textSecondaryColor,
                                          isDark: isDark,
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Elevated Central Floating Hub Button
                          Positioned(
                            bottom: 14,
                            child: _buildCenterHubButton(
                              key: _hubNavKey,
                              context: context,
                              activeGradient: activeGradient,
                              activeColor: activeColor,
                              isDark: isDark,
                              isSelected: _currentTab == 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        )),
      );
    }

    final activeColor = Theme.of(context).primaryColor;
    final isAdmin = profile?.isAdmin == true;
    final steps = _buildCoachmarkSteps(isAdmin, activeColor);

    return Stack(
      children: [
        rootShell,
        if (_isCoachmarkActive)
          AppCoachmarkTour(
            steps: steps,
            initialStepIndex: _coachmarkStep,
            onStepChanged: (index) {
              setState(() => _coachmarkStep = index);
              if (index >= 0 && index < steps.length) {
                final tab = steps[index].targetTabIndex;
                if (tab != null && tab != _currentTab) {
                  _onNavigateToTab(tab);
                }
              }
            },
            onComplete: () {
              setState(() => _isCoachmarkActive = false);
            },
            onSkip: () {
              setState(() => _isCoachmarkActive = false);
              _showHubTutorialNotice(context);
            },
          ),
      ],
    );
  }

  Widget _buildNavItem({
    Key? key,
    required Map<String, dynamic> item,
    required bool isSelected,
    required Color activeColor,
    required Color inactiveColor,
    required bool isDark,
  }) {
    final icon = item['icon'] as IconData;
    final label = item['label'] as String;
    final index = item['index'] as int;
    final hasUnreadBadge = index == 4 && Provider.of<FirebaseService>(context).hasUnreadCommsMessages;

    return Expanded(
      child: GestureDetector(
        key: key,
        onTap: () => _onNavigateToTab(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? activeColor.withValues(alpha: isDark ? 0.22 : 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isSelected ? activeColor : inactiveColor,
                  ),
                ),
                if (hasUnreadBadge)
                  Positioned(
                    top: 1,
                    right: 4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? const Color(0xFF0B0F1C) : Colors.white,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? activeColor : inactiveColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterHubButton({
    Key? key,
    required BuildContext context,
    required LinearGradient activeGradient,
    required Color activeColor,
    required bool isDark,
    required bool isSelected,
  }) {
    return GestureDetector(
      key: key,
      onTap: () => _onNavigateToTab(0),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: isSelected ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Outer collar matching bar surface
            color: isDark ? const Color(0xFF0B0F1C) : Colors.white,
            boxShadow: [
              // Clean theme glow & elevation
              BoxShadow(
                color: isDark
                    ? activeColor.withValues(alpha: isSelected ? 0.55 : 0.30)
                    : activeColor.withValues(alpha: isSelected ? 0.25 : 0.14),
                blurRadius: isSelected ? 14 : 8,
                spreadRadius: isSelected ? 1 : 0,
                offset: const Offset(0, 4),
              ),
              // Subtle outer collar edge contrast
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(3.5),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: activeGradient,
              border: Border.all(
                color: Colors.white,
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: activeColor.withValues(alpha: 0.28),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                LucideIcons.layoutGrid,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}


