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
import 'views/landing_view.dart';
import 'views/login_view.dart';
import 'views/pending_denied_view.dart';
import 'views/dashboard_view.dart';
import 'views/calendar_view.dart';
import 'views/attendance_view.dart';
import 'views/database_view.dart';
import 'views/comms_view.dart';
import 'views/admin_approval_view.dart';
import 'views/settings_view.dart';
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
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

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
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
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

    return MaterialApp(
      title: 'Guardians of the Gate - Usher App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(Brightness.light, firebaseService.activeStyleTheme),
      darkTheme: AppTheme.getTheme(Brightness.dark, firebaseService.activeStyleTheme),
      themeMode: firebaseService.themeMode,
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  bool _showLoginFlow = false;
  String _loginMode = 'login';
  int _currentTab = 0; // Default to Dashboard

  void _onNavigateToTab(int index) {
    setState(() => _currentTab = index);
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context);

    if (firebaseService.authLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Unauthenticated -> Landing or Login
    if (firebaseService.currentUser == null) {
      if (_showLoginFlow) {
        return LoginView(
          initialMode: _loginMode,
          onBackToLanding: () => setState(() => _showLoginFlow = false),
        );
      }
      return LandingView(
        onGetStarted: () {
          setState(() {
            _loginMode = 'register';
            _showLoginFlow = true;
          });
        },
        onLogin: () {
          setState(() {
            _loginMode = 'login';
            _showLoginFlow = true;
          });
        },
      );
    }

    final profile = firebaseService.userProfile;

    // Pending or Denied Guard
    if (profile != null && !profile.approved) {
      return PendingDeniedView(isDenied: profile.denied);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
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
      return Scaffold(
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
      );
    }

    final activeGradient = context.activeGradient;

    return Scaffold(
      extendBody: true,
      body: DribbbleAmbientBackground(
        child: IndexedStack(
          index: _currentTab,
          children: pages,
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: DribbbleGlassContainer(
            borderRadius: 30,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            blur: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(navItems.length, (index) {
                final isSelected = _currentTab == index;
                final item = navItems[index];
                return GestureDetector(
                  onTap: () => _onNavigateToTab(index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.symmetric(
                      horizontal: isSelected ? 14 : 10,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected ? activeGradient : null,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Theme.of(context).primaryColor.withValues(alpha: 0.45),
                                blurRadius: 14,
                                spreadRadius: -2,
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
                          size: 20,
                          color: isSelected
                              ? Colors.white
                              : context.textSecondaryColor,
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 6),
                          Text(
                            item['label'] as String,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}


