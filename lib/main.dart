import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/firebase_options.dart';
import 'services/firebase_service.dart';
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
import 'package:lucide_icons_flutter/lucide_icons.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  debugPrint("System Push Notification Received: ${message.notification?.title}");
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
        home: const MainShell(),
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

  // Splash is always shown for at least 3 seconds on every cold launch
  bool _splashDone = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) setState(() => _splashDone = true);
    });
  }

  void _onNavigateToTab(int index) {
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
    final firebaseService = Provider.of<FirebaseService>(context);

    if (!_splashDone || firebaseService.authLoading) {
      return const DribbbleSplashScreen();
    }

    // Unauthenticated -> Direct to Login Screen
    if (firebaseService.currentUser == null) {
      return const LoginView(initialMode: 'login');
    }

    final profile = firebaseService.userProfile;

    // Pending or Denied Guard
    if (profile != null && !profile.approved) {
      return PendingDeniedView(isDenied: profile.denied);
    }

    final isWideScreen = MediaQuery.of(context).size.width >= 800;

    final List<Widget> pages = [
      DashboardView(onNavigateTab: _onNavigateToTab),
      const CalendarView(),
      const AttendanceView(),
      const DatabaseView(),
      const CommsView(),
      const SettingsView(),
      if (profile?.isAdmin == true) const AdminApprovalView(),
    ];

    final navItems = [
      {'icon': LucideIcons.layoutDashboard, 'label': 'Hub'},
      {'icon': LucideIcons.calendar, 'label': 'Roster'},
      {'icon': LucideIcons.binary, 'label': 'Tally'},
      {'icon': LucideIcons.users, 'label': 'Directory'},
      {'icon': LucideIcons.messageSquare, 'label': 'Comms'},
      {'icon': LucideIcons.sliders, 'label': 'Settings'},
      if (profile?.isAdmin == true) {'icon': LucideIcons.shieldCheck, 'label': 'Admin'},
    ];

    if (_currentTab >= pages.length) {
      _currentTab = 0;
    }

    if (isWideScreen) {
      return _withEdgeSwipeBack(Scaffold(
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
                                        Icon(
                                          item['icon'] as IconData,
                                          color: isSelected
                                              ? Colors.white
                                              : context.textSecondaryColor,
                                          size: 20,
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
    }

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
        {'icon': LucideIcons.shieldCheck, 'label': 'Admin', 'index': 6},
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

    return GestureDetector(
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
                                ? const Color(0xFF14100E).withValues(alpha: 0.92)
                                : Colors.white.withValues(alpha: 0.94),
                            child: Row(
                              children: [
                                // Left Nav Items
                                Expanded(
                                  child: Row(
                                    children: leftNavItems.map((item) {
                                      final isSelected = _currentTab == item['index'];
                                      return _buildNavItem(
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

  Widget _buildNavItem({
    required Map<String, dynamic> item,
    required bool isSelected,
    required Color activeColor,
    required Color inactiveColor,
    required bool isDark,
  }) {
    final icon = item['icon'] as IconData;
    final label = item['label'] as String;
    final index = item['index'] as int;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onNavigateToTab(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
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
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterHubButton({
    required BuildContext context,
    required LinearGradient activeGradient,
    required Color activeColor,
    required bool isDark,
    required bool isSelected,
  }) {
    return GestureDetector(
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
            color: isDark ? const Color(0xFF14100E) : Colors.white,
            boxShadow: [
              // Vibrant ambient theme glow
              BoxShadow(
                color: activeColor.withValues(alpha: isSelected ? 0.65 : 0.38),
                blurRadius: isSelected ? 22 : 14,
                spreadRadius: isSelected ? 3 : 0,
                offset: const Offset(0, 5),
              ),
              // Subtle outer collar edge contrast
              BoxShadow(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.14 : 0.08),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
          padding: const EdgeInsets.all(4.0),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: activeGradient,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.95),
                width: 3.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: activeColor.withValues(alpha: 0.45),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                LucideIcons.layoutDashboard,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }
}


