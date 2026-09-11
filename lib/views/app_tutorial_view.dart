import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class TutorialChapter {
  final String title;
  final String subtitle;
  final String category;
  final IconData icon;
  final List<String> highlights;
  final String platformTipAndroid;
  final String platformTipIos;
  final int? targetTabIndex;
  final String? actionLabel;

  const TutorialChapter({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.icon,
    required this.highlights,
    required this.platformTipAndroid,
    required this.platformTipIos,
    this.targetTabIndex,
    this.actionLabel,
  });
}

class AppTutorialView extends StatefulWidget {
  final void Function(int tabIndex)? onNavigateTab;
  final VoidCallback? onComplete;

  const AppTutorialView({
    super.key,
    this.onNavigateTab,
    this.onComplete,
  });

  static const String prefTutorialCompletedKey = 'has_completed_app_tutorial_v1';

  static Future<void> markTutorialAsCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefTutorialCompletedKey, true);
    } catch (_) {}
  }

  static Future<bool> shouldShowTutorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return !(prefs.getBool(prefTutorialCompletedKey) ?? false);
    } catch (_) {
      return false;
    }
  }

  static const List<TutorialChapter> chapters = [
    TutorialChapter(
      title: "Welcome to Guardians",
      subtitle: "The Sacred Calling of Church Ushering",
      category: "Pillar 1: Stewardship",
      icon: LucideIcons.shieldCheck,
      highlights: [
        "Hospitality First: Welcome congregation members, visitors, and families with warmth and grace.",
        "Reverence & Order: Maintain sacred decorum, assist pastors, and oversee sanctuary flow (1 Cor 14:40).",
        "Team Unity: Real-time coordination across all church entrances, balcony, and overflow areas.",
      ],
      platformTipAndroid: "Android tip: Keep notifications enabled so you never miss duty announcements or station changes.",
      platformTipIos: "iOS tip: Enable Face ID / Touch ID in Settings for effortless, high-security 1-second sign-in.",
      targetTabIndex: 0,
      actionLabel: "Explore the Hub",
    ),
    TutorialChapter(
      title: "The Hub & Shift Roster",
      subtitle: "Your Operational Command Center",
      category: "Pillar 2: Scheduling",
      icon: LucideIcons.calendarCheck,
      highlights: [
        "Live Duty Status: Check your current shift assignment and status right from the Hub home screen.",
        "Sunday Roster: View dates, scheduled service times, and station assignments in the Roster calendar.",
        "Sub-In Feature: Request or volunteer for sub-in coverage with fellow ushers ahead of time if you have schedule conflicts.",
      ],
      platformTipAndroid: "Android tip: The live date badge dynamically computes Sunday rosters with full daylight-saving immunity.",
      platformTipIos: "iOS tip: Swipe from the left edge of any tab to immediately return to the Hub at any time.",
      targetTabIndex: 1,
      actionLabel: "View Roster",
    ),
    TutorialChapter(
      title: "Live Attendance Tally",
      subtitle: "Instant Multi-Station Headcounts",
      category: "Pillar 3: Metrics & Headcount",
      icon: LucideIcons.binary,
      highlights: [
        "Independent Counters: Count Sanctuary, Balcony, and Overflow sections simultaneously.",
        "Quick Steppers: Tap +1, +5, +10, or -1 buttons to count rapidly during worship or offering.",
        "Live Cloud Sync: Totals update automatically in real-time so team leads and pastors see verified numbers.",
      ],
      platformTipAndroid: "Android tip: Tally works completely offline if connectivity drops, then auto-syncs when reconnected.",
      platformTipIos: "iOS tip: High-contrast large numerical displays ensure fast counting in dim sanctuary lighting.",
      targetTabIndex: 2,
      actionLabel: "Try Tally",
    ),
    TutorialChapter(
      title: "Team Directory",
      subtitle: "Direct Access to Fellow Guardians",
      category: "Pillar 4: Fellowship",
      icon: LucideIcons.users,
      highlights: [
        "Verified Roster: View full names, ministry roles (Team Leads, Ushers, Admin), and duty status.",
        "One-Tap Contact: Call or text any team member or service Team Lead directly using the phone icon.",
        "Quick Search: Filter by name or station to find team members in seconds.",
      ],
      platformTipAndroid: "Android tip: Direct dial launches your native phone app with the usher's phone pre-formatted.",
      platformTipIos: "iOS tip: Tap the phone icon to trigger native iOS action sheet for phone calls and iMessage.",
      targetTabIndex: 3,
      actionLabel: "Open Directory",
    ),
    TutorialChapter(
      title: "Team Comms & Bubbles",
      subtitle: "Real-Time Chat & Floating Notifications",
      category: "Pillar 5: Communication",
      icon: LucideIcons.messageSquare,
      highlights: [
        "Instant Chat: Fast team communications for station switches, supply requests, and prayer needs.",
        "GIPHY Integration: Add joyful and encouraging celebration GIFs with a tap.",
        "Push Notifications: Stay informed even when the app is minimized or your phone is locked.",
      ],
      platformTipAndroid: "Android 11+ Bubbles: Comms supports Android Conversation Bubbles for floating on-screen team messaging.",
      platformTipIos: "iOS tip: Swipe down anywhere in Comms to instantly dismiss the keyboard and reveal your messages.",
      targetTabIndex: 4,
      actionLabel: "Open Comms",
    ),
    TutorialChapter(
      title: "Handbook, Training & Security",
      subtitle: "Excellence in Service & Account Protection",
      category: "Pillar 6: Excellence & Safety",
      icon: LucideIcons.bookOpen,
      highlights: [
        "Usher SOP Handbook: Built-in book reader with church guidelines, protocol, and scripture (NIV).",
        "Training Modules: Interactive training courses with progress tracking and knowledge checks.",
        "Two-Factor Authentication: Safeguard your account with SMS 6-digit verification codes.",
      ],
      platformTipAndroid: "Android tip: Customize your visual experience with 5 custom theme presets: Burgundy, Pale Gold, Emerald, Navy, and Onyx.",
      platformTipIos: "iOS tip: Face ID biometric protection keeps unauthorized persons from opening the usher operational console.",
      targetTabIndex: 5,
      actionLabel: "Go to Settings",
    ),
  ];

  @override
  State<AppTutorialView> createState() => _AppTutorialViewState();
}

class _AppTutorialViewState extends State<AppTutorialView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  List<TutorialChapter> get chapters => AppTutorialView.chapters;

  void _onNext() {
    HapticFeedback.mediumImpact();
    if (_currentPage < chapters.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishTutorial();
    }
  }

  void _onPrevious() {
    HapticFeedback.lightImpact();
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _finishTutorial([int? navigateToIndex]) async {
    HapticFeedback.heavyImpact();
    await AppTutorialView.markTutorialAsCompleted();
    if (mounted) {
      if (widget.onComplete != null) {
        widget.onComplete!();
      } else {
        Navigator.of(context).maybePop();
      }
      if (navigateToIndex != null && widget.onNavigateTab != null) {
        widget.onNavigateTab!(navigateToIndex);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final isIos = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: DribbbleAmbientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top Navigation Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Step Counter Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.compass, size: 14, color: theme.primaryColor),
                          const SizedBox(width: 6),
                          Text(
                            "Step ${_currentPage + 1} of ${chapters.length}",
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Device OS Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isIos ? LucideIcons.apple : (isAndroid ? LucideIcons.smartphone : LucideIcons.laptop),
                            size: 13,
                            color: context.textSecondaryColor,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isIos ? "iOS Guide" : (isAndroid ? "Android Guide" : "Web Guide"),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: context.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Skip Tour Button
                    TextButton(
                      onPressed: () => _finishTutorial(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        "Skip",
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Animated Page Indicator Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: List.generate(chapters.length, (index) {
                    final isCurrent = index == _currentPage;
                    final isPast = index < _currentPage;
                    return Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 4,
                        margin: EdgeInsets.only(right: index == chapters.length - 1 ? 0 : 6),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? theme.primaryColor
                              : (isPast ? theme.primaryColor.withValues(alpha: 0.5) : (isDark ? Colors.white24 : Colors.black12)),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Walkthrough Carousel Cards
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (page) {
                    setState(() => _currentPage = page);
                  },
                  itemCount: chapters.length,
                  itemBuilder: (context, index) {
                    final chapter = chapters[index];
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Hero Card
                          DribbbleGlassContainer(
                            borderRadius: 24,
                            padding: const EdgeInsets.all(22),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        gradient: context.activeGradient,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: theme.primaryColor.withValues(alpha: 0.35),
                                            blurRadius: 14,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Icon(chapter.icon, color: Colors.white, size: 26),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            chapter.category.toUpperCase(),
                                            style: GoogleFonts.outfit(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.1,
                                              color: theme.primaryColor,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            chapter.title,
                                            style: GoogleFonts.outfit(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: context.textPrimaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  chapter.subtitle,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: context.textSecondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Highlights Checklist Card
                          DribbbleGlassContainer(
                            borderRadius: 24,
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "What You Can Do",
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: context.textPrimaryColor,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                ...chapter.highlights.map((highlight) {
                                  final parts = highlight.split(':');
                                  final prefix = parts.first;
                                  final body = parts.length > 1 ? parts.sublist(1).join(':') : '';

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.only(top: 2),
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: AppColors.success.withValues(alpha: 0.15),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(LucideIcons.check, size: 12, color: AppColors.success),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: RichText(
                                            text: TextSpan(
                                              style: GoogleFonts.inter(
                                                fontSize: 13.5,
                                                height: 1.45,
                                                color: context.textPrimaryColor,
                                              ),
                                              children: [
                                                TextSpan(
                                                  text: "$prefix: ",
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                                TextSpan(
                                                  text: body.isNotEmpty ? body.trim() : prefix,
                                                  style: TextStyle(color: context.textSecondaryColor),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Device Platform Tip Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1B1924) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: theme.primaryColor.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: theme.primaryColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    isIos ? LucideIcons.apple : (isAndroid ? LucideIcons.smartphone : LucideIcons.info),
                                    size: 16,
                                    color: theme.primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isIos ? "iOS Specific Pro-Tip" : (isAndroid ? "Android Specific Pro-Tip" : "Pro-Tip"),
                                        style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: theme.primaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        isIos ? chapter.platformTipIos : chapter.platformTipAndroid,
                                        style: GoogleFonts.inter(
                                          fontSize: 12.5,
                                          height: 1.4,
                                          color: context.textSecondaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Jump Directly to Tab Button (if configured)
                          if (chapter.targetTabIndex != null && widget.onNavigateTab != null) ...[
                            const SizedBox(height: 14),
                            Center(
                              child: TextButton.icon(
                                onPressed: () => _finishTutorial(chapter.targetTabIndex),
                                icon: Icon(LucideIcons.arrowUpRight, size: 16, color: theme.primaryColor),
                                label: Text(
                                  chapter.actionLabel ?? "Open Feature",
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: theme.primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Bottom Navigation Controls
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: Row(
                  children: [
                    // Back Button
                    if (_currentPage > 0)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: OutlinedButton(
                          onPressed: _onPrevious,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: context.textPrimaryColor,
                            side: BorderSide(color: context.borderThemeColor),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.arrowLeft, size: 16),
                              const SizedBox(width: 6),
                              Text("Back", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),

                    // Next / Get Started Button
                    Expanded(
                      child: DribbbleGlowButton(
                        label: _currentPage == chapters.length - 1 ? "Complete Tour & Get Started" : "Next Chapter",
                        icon: _currentPage == chapters.length - 1 ? LucideIcons.sparkles : LucideIcons.arrowRight,
                        onPressed: _onNext,
                        gradient: context.activeGradient,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
