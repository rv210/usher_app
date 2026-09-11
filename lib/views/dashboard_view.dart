import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/deployment.dart';
import '../models/team_member.dart';
import '../services/firebase_service.dart';
import '../services/app_widget_service.dart';
import '../theme/app_theme.dart';
import 'ushering_training_view.dart';
import 'app_tutorial_view.dart';
import 'attendance_view.dart';
import 'announcements_view.dart';
import '../widgets/user_avatar.dart';
import '../widgets/profile_background_picker.dart';
import 'comms_view.dart';

class BibleQuote {
  final String reference;
  final String text;
  final String category;

  const BibleQuote({
    required this.reference,
    required this.text,
    required this.category,
  });
}

const List<BibleQuote> usherBibleQuotes = [
  BibleQuote(
    reference: "Psalm 84:10 (NIV)",
    text: "Better is one day in your courts than a thousand elsewhere; I would rather be a doorkeeper in the house of my God than dwell in the tents of the wicked.",
    category: "Usher Stewardship",
  ),
  BibleQuote(
    reference: "Colossians 3:23-24 (NIV)",
    text: "Whatever you do, work at it with all your heart, as working for the Lord, not for human masters, since you know that you will receive an inheritance from the Lord as a reward. It is the Lord Christ you are serving.",
    category: "Service & Diligence",
  ),
  BibleQuote(
    reference: "Hebrews 13:2 (NIV)",
    text: "Do not forget to show hospitality to strangers, for by so doing some people have shown hospitality to angels without knowing it.",
    category: "Hospitality & Welcome",
  ),
  BibleQuote(
    reference: "1 Corinthians 14:40 (NIV)",
    text: "But everything should be done in a fitting and orderly way.",
    category: "Order & Reverence",
  ),
  BibleQuote(
    reference: "Romans 12:11-13 (NIV)",
    text: "Never be lacking in zeal, but keep your spiritual fervor, serving the Lord. Be joyful in hope, patient in affliction, faithful in prayer. Share with the Lord’s people who are in need. Practice hospitality.",
    category: "Faithful Spirit",
  ),
  BibleQuote(
    reference: "1 Peter 4:10 (NIV)",
    text: "Each of you should use whatever gift you have received to serve others, as faithful stewards of God’s grace in its various forms.",
    category: "Grace & Stewardship",
  ),
  BibleQuote(
    reference: "Galatians 6:9 (NIV)",
    text: "Let us not become weary in doing good, for at the proper time we will reap a harvest if we do not give up.",
    category: "Perseverance",
  ),
  BibleQuote(
    reference: "Proverbs 3:5-6 (NIV)",
    text: "Trust in the LORD with all your heart and lean not on your own understanding; in all your ways submit to him, and he will make your paths straight.",
    category: "Guidance & Faith",
  ),
  BibleQuote(
    reference: "Joshua 1:9 (NIV)",
    text: "Have I not commanded you? Be strong and courageous. Do not be afraid; do not be discouraged, for the LORD your God will be with you wherever you go.",
    category: "Courage & Strength",
  ),
  BibleQuote(
    reference: "Matthew 25:21 (NIV)",
    text: "Well done, good and faithful servant! You have been faithful with a few things; I will put you in charge of many things. Come and share your master’s happiness!",
    category: "Faithful Ministry",
  ),
  BibleQuote(
    reference: "Philippians 2:3-4 (NIV)",
    text: "Do nothing out of selfish ambition or vain conceit. Rather, in humility value others above yourselves, not looking to your own interests but each of you to the interests of the others.",
    category: "Humility & Service",
  ),
  BibleQuote(
    reference: "1 Peter 5:2-3 (NIV)",
    text: "Be shepherds of God’s flock that is under your care, watching over them—not because you must, but because you are willing, as God wants you to be; not pursuing dishonest gain, but eager to serve.",
    category: "Leadership & Service",
  ),
];

class DashboardView extends StatefulWidget {
  final Function(int tabIndex) onNavigateTab;
  final VoidCallback? onStartCoachmarkTour;

  const DashboardView({
    super.key,
    required this.onNavigateTab,
    this.onStartCoachmarkTour,
  });

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int get _todayQuoteIndex {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    return (now.year * 365 + dayOfYear) % usherBibleQuotes.length;
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning,";
    if (hour < 17) return "Good Afternoon,";
    return "Good Evening,";
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncNativeWidgets();
    });
  }

  void _syncNativeWidgets() {
    final quote = usherBibleQuotes[_todayQuoteIndex];
    AppWidgetService.updateScriptureWidget(
      text: quote.text,
      reference: quote.reference,
      category: quote.category,
    );

    if (!mounted) return;
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);
    AppWidgetService.updateTallyWidget(
      count: firebaseService.currentTallyCount,
      serviceType: firebaseService.activeServiceType,
    );

    final activeDep = _getUserUpcomingDeployment(firebaseService, firebaseService.userProfile);
    if (activeDep != null) {
      AppWidgetService.updateDutyWidget(
        station: activeDep.station,
        date: activeDep.date,
        role: activeDep.role,
        serviceType: activeDep.serviceType,
      );
    } else {
      AppWidgetService.updateDutyWidget(
        station: "Off Duty",
        date: "Standby",
        role: "Off Duty",
        serviceType: "No Shift Scheduled",
      );
    }
  }

  Deployment? _getUserUpcomingDeployment(FirebaseService firebaseService, TeamMember? profile) {
    final allDeployments = firebaseService.deployments;
    if (allDeployments.isEmpty) return null;

    DateTime? tryParseDate(String s) {
      final trimmed = s.trim();
      if (trimmed.isEmpty) return null;
      try {
        return DateTime.parse(trimmed);
      } catch (_) {
        try {
          final parts = trimmed.split('/');
          if (parts.length == 3) {
            return DateTime(int.parse(parts[2]), int.parse(parts[0]), int.parse(parts[1]));
          }
        } catch (_) {}
      }
      return null;
    }

    final uniqueDates = <String>{};
    for (final d in allDeployments) {
      if (d.date.trim().isNotEmpty) {
        uniqueDates.add(d.date.trim());
      }
    }

    String? targetDate;
    if (uniqueDates.isNotEmpty) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final upcomingDates = <DateTime, String>{};
      final pastDates = <DateTime, String>{};

      for (final raw in uniqueDates) {
        final dt = tryParseDate(raw);
        if (dt != null) {
          final dayOnly = DateTime(dt.year, dt.month, dt.day);
          if (dayOnly.isAtSameMomentAs(today) || dayOnly.isAfter(today)) {
            upcomingDates[dayOnly] = raw;
          } else {
            pastDates[dayOnly] = raw;
          }
        }
      }

      if (upcomingDates.isNotEmpty) {
        final sortedUpcoming = upcomingDates.keys.toList()..sort((a, b) => a.compareTo(b));
        targetDate = upcomingDates[sortedUpcoming.first];
      } else if (pastDates.isNotEmpty) {
        final sortedPast = pastDates.keys.toList()..sort((a, b) => b.compareTo(a));
        targetDate = pastDates[sortedPast.first];
      } else {
        targetDate = uniqueDates.first;
      }
    }

    final currentUserId = firebaseService.currentUser?.uid ?? '';
    final currentUserName = (profile?.name ?? '').toLowerCase().trim();

    // 1. Check if the current user is directly scheduled on the target schedule date
    if (targetDate != null) {
      final singleSchedule = allDeployments.where((d) => d.date.trim() == targetDate).toList();
      for (final d in singleSchedule) {
        if (currentUserId.isNotEmpty && d.usherId == currentUserId) return d;
        final dName = d.usherName.toLowerCase().trim();
        if (currentUserName.isNotEmpty && (dName == currentUserName || dName.contains(currentUserName) || currentUserName.contains(dName))) {
          return d;
        }
      }
    }

    // 2. Check if the user is scheduled on any other upcoming date in deployments
    for (final d in allDeployments) {
      if (currentUserId.isNotEmpty && d.usherId == currentUserId) return d;
      final dName = d.usherName.toLowerCase().trim();
      if (currentUserName.isNotEmpty && (dName == currentUserName || dName.contains(currentUserName) || currentUserName.contains(dName))) {
        return d;
      }
    }

    // 3. User is not on any schedule -> Off Duty
    return null;
  }

  Widget _buildEditorialScripture(BuildContext context, bool isDark) {
    final quote = usherBibleQuotes[_todayQuoteIndex];

    // Sacred gold palette — independent of app theme
    const goldDeep    = Color(0xFFB8860B);  // dark goldenrod
    const goldBright  = Color(0xFFD4AF37);  // classic gold
    const goldLight   = Color(0xFFFFD700);  // pure gold highlight
    const goldGlow    = Color(0xFFF5C842);  // warm glow
    const parchmentDk = Color(0xFF1A1508);  // dark parchment bg
    const parchmentMd = Color(0xFF231C0A);  // mid dark parchment
    const parchmentLt = Color(0xFFFBF3DC);  // light parchment
    const inkDark     = Color(0xFF1A120A);  // dark ink text

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      // Outer gilded frame
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [goldBright, goldDeep, goldGlow, goldDeep, goldBright],
          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: goldBright.withValues(alpha: 0.55),
            blurRadius: 22,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.40),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        // Gilded border thickness
        padding: const EdgeInsets.all(3),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(17.5),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17.5),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [parchmentDk, parchmentMd, parchmentDk]
                    : [const Color(0xFFFEF9ED), parchmentLt, const Color(0xFFFDF4D8)],
              ),
            ),
            child: Stack(
              children: [
                // Large Sacred Cross Watermark
                Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: isDark ? 0.07 : 0.05,
                      child: Center(
                        child: Icon(
                          LucideIcons.cross,
                          size: 200,
                          color: goldDeep,
                        ),
                      ),
                    ),
                  ),
                ),

                // Corner accent flourishes (top-left)
                Positioned(
                  top: 8,
                  left: 8,
                  child: IgnorePointer(
                    child: Icon(
                      LucideIcons.sparkles,
                      size: 14,
                      color: goldBright.withValues(alpha: isDark ? 0.50 : 0.40),
                    ),
                  ),
                ),
                // Corner accent flourishes (top-right)
                Positioned(
                  top: 8,
                  right: 8,
                  child: IgnorePointer(
                    child: Icon(
                      LucideIcons.sparkles,
                      size: 14,
                      color: goldBright.withValues(alpha: isDark ? 0.50 : 0.40),
                    ),
                  ),
                ),

                // Card Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Sacred Cross Icon Header
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [goldLight, goldBright, goldDeep],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: goldBright.withValues(alpha: 0.6),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Icon(
                          LucideIcons.cross,
                          size: 18,
                          color: isDark ? parchmentDk : Colors.white,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // "DAILY SCRIPTURE" Title
                      Text(
                        "DAILY SCRIPTURE",
                        style: GoogleFonts.cinzel(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3.0,
                          color: goldDeep,
                          shadows: [
                            Shadow(
                              color: goldBright.withValues(alpha: 0.6),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Category badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            colors: [goldDeep, goldBright],
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.star,
                              size: 9,
                              color: isDark ? parchmentDk : Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              quote.category.toUpperCase(),
                              style: GoogleFonts.cinzel(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: isDark ? parchmentDk : Colors.white,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              LucideIcons.star,
                              size: 9,
                              color: isDark ? parchmentDk : Colors.white,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Gilded ornate divider
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Colors.transparent, goldGlow, goldLight, goldGlow, Colors.transparent],
                        ).createShader(bounds),
                        child: Container(
                          height: 1.5,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Scripture Text
                      Text(
                        "\u201c${quote.text}\u201d",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.merriweather(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          height: 1.65,
                          fontWeight: FontWeight.w400,
                          color: isDark ? const Color(0xFFF5EDD6) : inkDark,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Gilded ornate divider (bottom)
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Colors.transparent, goldGlow, goldLight, goldGlow, Colors.transparent],
                        ).createShader(bounds),
                        child: Container(
                          height: 1.5,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Reference
                      Text(
                        "— ${quote.reference}",
                        style: GoogleFonts.cinzel(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: goldDeep,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Action Buttons Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Copy Button
                          InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Clipboard.setData(ClipboardData(text: "\"${quote.text}\" — ${quote.reference}"));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Row(
                                    children: [
                                      Icon(LucideIcons.checkCheck, color: Color(0xFF10B981), size: 18),
                                      SizedBox(width: 8),
                                      Text("Scripture copied to clipboard!"),
                                    ],
                                  ),
                                  backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: goldBright, width: 1.2),
                                color: goldBright.withValues(alpha: isDark ? 0.12 : 0.08),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.copy, size: 13, color: goldDeep),
                                  const SizedBox(width: 5),
                                  Text(
                                    "Copy",
                                    style: GoogleFonts.cinzel(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: goldDeep,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          // Share to Comms Button
                          InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () async {
                              HapticFeedback.mediumImpact();
                              final commsText = "✝️ [DAILY SCRIPTURE • ${quote.category.toUpperCase()}]\n\"${quote.text}\"\n— ${quote.reference}";
                              await Provider.of<FirebaseService>(context, listen: false).postCommsMessage(commsText);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).clearSnackBars();
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const CommsView()),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                gradient: const LinearGradient(
                                  colors: [goldDeep, goldBright, goldGlow],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: goldBright.withValues(alpha: 0.45),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.messageSquareShare,
                                    size: 13,
                                    color: isDark ? parchmentDk : Colors.white,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    "Share to Comms",
                                    style: GoogleFonts.cinzel(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? parchmentDk : Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeadershipBulletinStrip(BuildContext context, FirebaseService firebaseService, bool isDark) {
    final primaryColor = Theme.of(context).primaryColor;
    final latest = firebaseService.latestAnnouncement;
    final displayTitle = latest?.title ?? "Leadership Bulletin";
    final displayText = latest != null 
        ? "${latest.description}"
        : firebaseService.bulletinText;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AnnouncementsView()),
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1712) : const Color(0xFFFFFDF9),
                border: Border(
                  left: BorderSide(color: primaryColor, width: 3.5),
                  top: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0), width: 1),
                  right: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0), width: 1),
                  bottom: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0), width: 1),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(LucideIcons.megaphone, size: 16, color: primaryColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "ANNOUNCEMENTS",
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF261D0F) : const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "Today",
                                style: GoogleFonts.inter(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                                ),
                              ),
                            ),
                            const Spacer(),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "View All",
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(LucideIcons.chevronRight, size: 13, color: primaryColor),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          displayTitle,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          displayText,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            height: 1.35,
                            color: context.textSecondaryColor,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveOperationsHUD(
    BuildContext context,
    FirebaseService firebaseService,
    String stationName,
    String stationSubtitle,
    bool isOnSchedule,
    bool isDark,
  ) {
    final primaryColor = Theme.of(context).primaryColor;
    final guestCount = firebaseService.todayGuestCount;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101422) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Split Metrics: Tally & Station
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Tally Counter
                Expanded(
                  flex: 11,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => widget.onNavigateTab(2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(LucideIcons.binary, size: 15, color: primaryColor),
                            const SizedBox(width: 6),
                            Text(
                              "HEADCOUNT TALLY",
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: primaryColor,
                              ),
                            ),
                            const Spacer(),
                            Icon(LucideIcons.chevronRight, size: 14, color: context.textSecondaryColor),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${firebaseService.currentTallyCount}",
                          style: GoogleFonts.outfit(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            height: 1.0,
                            letterSpacing: -0.5,
                            color: context.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                "Sanctuary Count",
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: context.textSecondaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Vertical Hairline Separator
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  width: 1,
                  height: 70,
                  color: isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFE2E8F0),
                ),

                // Right: Duty Station
                Expanded(
                  flex: 10,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.onNavigateTab(1);
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.compass,
                              size: 15,
                              color: isOnSchedule ? primaryColor : context.textSecondaryColor,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                "DUTY STATION",
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: isOnSchedule ? primaryColor : context.textSecondaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: isOnSchedule
                                    ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5))
                                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isOnSchedule
                                      ? (isDark ? const Color(0xFF059669) : const Color(0xFFA7F3D0))
                                      : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                                  width: 0.6,
                                ),
                              ),
                              child: Text(
                                isOnSchedule ? "ON DUTY" : "OFF DUTY",
                                style: GoogleFonts.outfit(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  color: isOnSchedule
                                      ? const Color(0xFF059669)
                                      : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                ),
                              ),
                            ),
                            const Spacer(),
                            Icon(LucideIcons.chevronRight, size: 14, color: context.textSecondaryColor),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          stationName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            height: 1.0,
                            letterSpacing: -0.4,
                            color: context.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stationSubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Horizontal Hairline Divider
          Divider(
            height: 1,
            thickness: 1,
            color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9),
          ),

          // Bottom Integrated Dock Strip: Guest Check-In
          InkWell(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            onTap: () {
              HapticFeedback.selectionClick();
              AttendanceView.activeSubTab.value = 1;
              widget.onNavigateTab(2);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(LucideIcons.userCheck, size: 15, color: Color(0xFF059669)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "Guest Check-In",
                              style: GoogleFonts.outfit(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: context.textPrimaryColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF059669) : const Color(0xFFA7F3D0),
                                  width: 0.6,
                                ),
                              ),
                              child: Text(
                                "LIVE",
                                style: GoogleFonts.outfit(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF059669),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          guestCount > 0
                              ? "$guestCount Guests Checked In Today"
                              : "Sanctuary Vestibule Station",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: context.activeGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Check In",
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(LucideIcons.arrowRight, size: 12, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required String tag,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF101422) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: accentColor.withValues(alpha: isDark ? 0.30 : 0.22),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: isDark ? 0.12 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: accentColor, size: 18),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tag,
                      style: GoogleFonts.inter(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      color: context.textSecondaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDispatchModal({
    required BuildContext context,
    required FirebaseService firebaseService,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required String tag,
    required String emoji,
    required String currentStation,
    required String userName,
    required bool isDark,
  }) {
    final stationOptions = [
      "Main Sanctuary",
      "Nursery",
      "Hallway",
      "Restrooms",
      "Kid Church",
      "Jr.Kids",
      "Side Door",
    ];
    String selectedStation = stationOptions.contains(currentStation)
        ? currentStation
        : "Main Sanctuary";
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (sheetContext, setModalState) {
          final keyboardBottom = MediaQuery.of(sheetContext).viewInsets.bottom;
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.90,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF101422) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  22,
                  12,
                  22,
                  keyboardBottom > 0 ? keyboardBottom + 16 : 28,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Grab Handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Header with Incident Icon & Details
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: accentColor, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  title,
                                  style: GoogleFonts.outfit(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    color: context.textPrimaryColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    tag,
                                    style: GoogleFonts.inter(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: accentColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                color: context.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Station / Location Selector
                  Text(
                    "Incident Station / Location",
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: stationOptions.map((st) {
                      final isSelected = selectedStation == st;
                      return ChoiceChip(
                        label: Text(st),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            HapticFeedback.selectionClick();
                            setModalState(() => selectedStation = st);
                          }
                        },
                        selectedColor: accentColor.withValues(alpha: isDark ? 0.28 : 0.15),
                        backgroundColor: isDark ? const Color(0xFF1E2436) : const Color(0xFFF1F5F9),
                        labelStyle: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? accentColor
                              : (isDark ? Colors.white70 : const Color(0xFF475569)),
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? accentColor
                              : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                          width: isSelected ? 1.4 : 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  // Quick Note Field
                  Text(
                    "Optional Note for Responders",
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      color: context.textPrimaryColor,
                    ),
                    decoration: InputDecoration(
                      hintText: "E.g., Row 14, guest needs wheelchair or water...",
                      hintStyle: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF161B2E) : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: accentColor, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Transmit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: accentColor.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        HapticFeedback.heavyImpact();
                        final note = noteController.text.trim();
                        final alertText =
                            "$emoji [RAPID DISPATCH • $tag • $selectedStation]: $title requested by $userName.${note.isNotEmpty ? ' Note: $note' : ''}";
                        firebaseService.postCommsMessage(alertText);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(icon, color: Colors.white, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "$title dispatched to all active ushers",
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: accentColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.radio, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            "Broadcast Dispatch to Team",
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final firebaseService = Provider.of<FirebaseService>(context);
    final profile = firebaseService.userProfile;
    final name = (profile?.name != null && profile!.name!.trim().isNotEmpty && profile.name != 'Usher')
        ? profile.name!.trim()
        : (firebaseService.currentUser?.displayName != null && firebaseService.currentUser!.displayName!.trim().isNotEmpty)
            ? firebaseService.currentUser!.displayName!.trim()
            : (firebaseService.currentUser?.email != null && firebaseService.currentUser!.email!.isNotEmpty)
                ? firebaseService.currentUser!.email!.split('@').first
                : "Usher";
    final currentEmail = (profile?.email ?? firebaseService.currentUser?.email ?? '').toLowerCase();
    final currentName = name.toLowerCase();

    final isAdminUser = (profile?.isAdmin == true) ||
        currentEmail.contains('robv88') ||
        currentName.contains('robert') ||
        currentName.contains('vargas') ||
        currentName.contains('louis') ||
        currentName.contains('richardson');

    final activeDeployment = _getUserUpcomingDeployment(firebaseService, profile);
    final isOnSchedule = activeDeployment != null;
    final stationName = activeDeployment?.station ?? "Standby";
    final stationSubtitle = activeDeployment != null
        ? (activeDeployment.customEventName != null && activeDeployment.customEventName!.isNotEmpty
            ? activeDeployment.customEventName!
            : activeDeployment.serviceType)
        : "Off Duty • No Shift Scheduled";

    final displayName = (name == 'Usher' || name.isEmpty)
        ? "Daniel Carter"
        : name.trim();
    final displayStation = activeDeployment?.station ?? "Main Sanctuary";
    final roleName = isAdminUser ? "Admin/Lead" : (profile?.displayRole ?? "Usher");

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: BehanceAmbientBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              // Trigger UI update
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(16, 14, 16, MediaQuery.of(context).size.width >= 800 ? 30 : 90),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sanctuary Hero Header Banner (Mockup Faithful)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                          blurRadius: 18,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        children: [
                          // Atmospheric Background Image
                          Positioned.fill(
                            child: Image.asset(
                              firebaseService.userCustomCardBgPath,
                              fit: BoxFit.cover,
                              alignment: const Alignment(0.0, -0.2),
                              errorBuilder: (_, __, ___) => Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(0xFF0F172A),
                                      const Color(0xFF1E293B),
                                      Theme.of(context).primaryColor.withValues(alpha: 0.8),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Dark Cinematic Vignette Overlay
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.65),
                                    Colors.black.withValues(alpha: 0.35),
                                    Colors.black.withValues(alpha: 0.75),
                                  ],
                                  stops: const [0.0, 0.45, 1.0],
                                ),
                              ),
                            ),
                          ),
                          // Content Row
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Left Column: Greeting, First Name, Role & Station
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _getGreeting(),
                                        style: GoogleFonts.inter(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white.withValues(alpha: 0.9),
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        displayName,
                                        style: GoogleFonts.outfit(
                                          fontSize: 25,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: -0.5,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          // Role Badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 2.5),
                                            decoration: BoxDecoration(
                                              color: isAdminUser
                                                  ? const Color(0xFF261D0F).withValues(alpha: 0.85)
                                                  : const Color(0xFF064E3B).withValues(alpha: 0.6),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: isAdminUser
                                                    ? const Color(0xFFF59E0B).withValues(alpha: 0.75)
                                                    : const Color(0xFF10B981).withValues(alpha: 0.75),
                                                width: 0.8,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  isAdminUser ? LucideIcons.shieldCheck : LucideIcons.userCheck,
                                                  size: 11,
                                                  color: isAdminUser ? const Color(0xFFFBBF24) : const Color(0xFF34D399),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  isAdminUser ? "ADMIN/LEAD" : (profile?.displayRole ?? "USHER").toUpperCase(),
                                                  style: GoogleFonts.inter(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w800,
                                                    color: isAdminUser ? const Color(0xFFFDE68A) : const Color(0xFFA7F3D0),
                                                    letterSpacing: 0.8,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Station Badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 2.5),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.white.withValues(alpha: 0.25),
                                                width: 0.8,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  LucideIcons.mapPin,
                                                  size: 11,
                                                  color: Colors.white70,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  displayStation,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white.withValues(alpha: 0.9),
                                                    letterSpacing: 0.3,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                // Right Column: Actions (Background picker & Notification Bell) & Avatar
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Customize Card Background Button
                                        GestureDetector(
                                          onTap: () {
                                            HapticFeedback.lightImpact();
                                            showProfileBackgroundPickerSheet(context, firebaseService);
                                          },
                                          child: Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.15),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white.withValues(alpha: 0.25),
                                                width: 1,
                                              ),
                                            ),
                                            child: const Icon(
                                              LucideIcons.image,
                                              color: Colors.white,
                                              size: 17,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Notification Bell with Conditional Red Badge
                                        GestureDetector(
                                          onTap: () {
                                            HapticFeedback.lightImpact();
                                            firebaseService.markCommsAsRead();
                                            widget.onNavigateTab(4);
                                          },
                                          child: Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              Container(
                                                width: 38,
                                                height: 38,
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(alpha: 0.14),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.white.withValues(alpha: 0.2),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: const Icon(
                                                  LucideIcons.bell,
                                                  color: Colors.white,
                                                  size: 19,
                                                ),
                                              ),
                                              if (firebaseService.hasUnreadCommsMessages)
                                                Positioned(
                                                  top: 2,
                                                  right: 2,
                                                  child: Container(
                                                    width: 10,
                                                    height: 10,
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFEF4444),
                                                      shape: BoxShape.circle,
                                                      border: Border.all(color: Colors.black54, width: 1.5),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // Circular Avatar (Custom photo or first initial monogram)
                                    UserAvatar(
                                      photoPath: firebaseService.userCustomPhotoPath,
                                      name: name,
                                      size: 52,
                                      borderWidth: 2,
                                      borderColor: Colors.white,
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        widget.onNavigateTab(5);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Horizontal Status Ribbon (Date)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.calendarDays,
                          size: 13,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('EEEE, MMM d, y').format(DateTime.now()),
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Scripture of the Day (Editorial Magazine Style)
                  _buildEditorialScripture(context, isDark),

                  const SizedBox(height: 10),

                  // Leadership Bulletin (Slim Accent Strip)
                  _buildLeadershipBulletinStrip(context, firebaseService, isDark),

                  const SizedBox(height: 14),

                  // Section Header: Live Operations
                  BehanceSectionHeader(
                    title: "Live Operations",
                    subtitle: "Active service monitoring & station metrics",
                    icon: LucideIcons.activity,
                  ),
                  const SizedBox(height: 8),

                  // Consolidated Command HUD Console (Tally + Station + Guest Check-In)
                  _buildLiveOperationsHUD(
                    context,
                    firebaseService,
                    stationName,
                    stationSubtitle,
                    isOnSchedule,
                    isDark,
                  ),

                  const SizedBox(height: 18),

                  // Training & Resources Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Training & Resources",
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimaryColor,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const UsheringTrainingView()),
                        ),
                        child: Text(
                          "Open Library",
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Dual Sleek SOP & Handbook Pills
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const UsheringTrainingView(initialTabIndex: 0),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF101422) : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFE2E8F0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(LucideIcons.graduationCap, size: 16, color: Theme.of(context).primaryColor),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "8 SOP Modules",
                                        style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: context.textPrimaryColor,
                                        ),
                                      ),
                                      Text(
                                        "Step-by-step guides",
                                        style: GoogleFonts.inter(
                                          fontSize: 10.5,
                                          color: context.textSecondaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const UsheringTrainingView(initialTabIndex: 1),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF101422) : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFE2E8F0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(LucideIcons.bookOpen, size: 16, color: Theme.of(context).primaryColor),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "6 Handbook Ch.",
                                        style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: context.textPrimaryColor,
                                        ),
                                      ),
                                      Text(
                                        "Church policy & ethos",
                                        style: GoogleFonts.inter(
                                          fontSize: 10.5,
                                          color: context.textSecondaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Spotlight Tour Integrated Strip
                  const SizedBox(height: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      if (widget.onStartCoachmarkTour != null) {
                        widget.onStartCoachmarkTour!();
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AppTutorialView(
                              onNavigateTab: widget.onNavigateTab,
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: isDark ? 0.08 : 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(LucideIcons.sparkles, size: 15, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Spotlight Tour: Walk through live features",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: context.textPrimaryColor,
                              ),
                            ),
                          ),
                          Icon(LucideIcons.chevronRight, size: 14, color: Theme.of(context).primaryColor),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Duty Deployments Section (Newest Upcoming Schedule Only)
                  Builder(
                    builder: (context) {
                      final allDeployments = firebaseService.deployments;

                      DateTime? tryParseDate(String s) {
                        final trimmed = s.trim();
                        if (trimmed.isEmpty) return null;
                        try {
                          return DateTime.parse(trimmed);
                        } catch (_) {
                          try {
                            final parts = trimmed.split('/');
                            if (parts.length == 3) {
                              return DateTime(int.parse(parts[2]), int.parse(parts[0]), int.parse(parts[1]));
                            }
                          } catch (_) {}
                        }
                        return null;
                      }

                      // 1. Gather all unique non-empty dates
                      final uniqueDates = <String>{};
                      for (final d in allDeployments) {
                        if (d.date.trim().isNotEmpty) {
                          uniqueDates.add(d.date.trim());
                        }
                      }

                      String? targetDate;
                      DateTime? targetDateTime;

                      if (uniqueDates.isNotEmpty) {
                        final now = DateTime.now();
                        final today = DateTime(now.year, now.month, now.day);

                        final upcomingDates = <DateTime, String>{};
                        final pastDates = <DateTime, String>{};

                        for (final raw in uniqueDates) {
                          final dt = tryParseDate(raw);
                          if (dt != null) {
                            final dayOnly = DateTime(dt.year, dt.month, dt.day);
                            if (dayOnly.isAtSameMomentAs(today) || dayOnly.isAfter(today)) {
                              upcomingDates[dayOnly] = raw;
                            } else {
                              pastDates[dayOnly] = raw;
                            }
                          }
                        }

                        if (upcomingDates.isNotEmpty) {
                          final sortedUpcoming = upcomingDates.keys.toList()..sort((a, b) => a.compareTo(b));
                          targetDateTime = sortedUpcoming.first;
                          targetDate = upcomingDates[targetDateTime];
                        } else if (pastDates.isNotEmpty) {
                          final sortedPast = pastDates.keys.toList()..sort((a, b) => b.compareTo(a));
                          targetDateTime = sortedPast.first;
                          targetDate = pastDates[targetDateTime];
                        } else {
                          targetDate = uniqueDates.first;
                        }
                      }

                      final singleScheduleList = targetDate != null
                          ? allDeployments.where((d) => d.date.trim() == targetDate).toList()
                          : <Deployment>[];

                      final sortedRoster = List<Deployment>.from(singleScheduleList)
                        ..sort((a, b) {
                          final aLead = a.role.toLowerCase().contains('lead usher') ||
                              (a.role.toLowerCase().contains('lead') && !a.role.toLowerCase().contains('head'));
                          final bLead = b.role.toLowerCase().contains('lead usher') ||
                              (b.role.toLowerCase().contains('lead') && !b.role.toLowerCase().contains('head'));
                          if (aLead && !bLead) return -1;
                          if (!aLead && bLead) return 1;
                          return a.station.compareTo(b.station);
                        });

                      String displayDateTitle = "NO UPCOMING SCHEDULE";
                      if (sortedRoster.isNotEmpty) {
                        final first = sortedRoster.first;
                        final serviceName = first.serviceType.toUpperCase();
                        final customEvent = (first.customEventName != null && first.customEventName!.trim().isNotEmpty)
                            ? " (${first.customEventName!.trim().toUpperCase()})"
                            : "";
                        final formattedDate = targetDateTime != null
                            ? DateFormat('MMM d, yyyy').format(targetDateTime).toUpperCase()
                            : (targetDate != null ? targetDate.toUpperCase() : "");
                        displayDateTitle = "$serviceName$customEvent • $formattedDate";

                        final currentUserId = firebaseService.currentUser?.uid ?? '';
                        final currentUserName = (profile?.name ?? '').toLowerCase().trim();
                        final userDep = sortedRoster.where(
                          (d) => (currentUserId.isNotEmpty && d.usherId == currentUserId) ||
                              (currentUserName.isNotEmpty && (d.usherName.toLowerCase().trim() == currentUserName || d.usherName.toLowerCase().contains(currentUserName))),
                        ).firstOrNull;

                        if (userDep != null) {
                          AppWidgetService.updateDutyWidget(
                            station: userDep.station,
                            date: formattedDate.isNotEmpty ? formattedDate : (targetDate ?? 'Next Service'),
                            role: userDep.role,
                            serviceType: userDep.serviceType,
                          );
                        } else {
                          AppWidgetService.updateDutyWidget(
                            station: "Off Duty",
                            date: "Standby",
                            role: "Off Duty",
                            serviceType: "No Shift Scheduled",
                          );
                        }
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Upcoming Station Roster",
                                      style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: context.textPrimaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.25)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(LucideIcons.calendarCheck, size: 12, color: Theme.of(context).primaryColor),
                                          const SizedBox(width: 5),
                                          Flexible(
                                            child: Text(
                                              displayDateTitle,
                                              style: GoogleFonts.outfit(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).primaryColor,
                                                letterSpacing: 0.5,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () => widget.onNavigateTab(1),
                                child: Text(
                                  "View All",
                                  style: GoogleFonts.outfit(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Single Unified Hairline Container for Roster
                          sortedRoster.isEmpty
                              ? Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF101422) : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "No upcoming station deployments scheduled yet.",
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: context.textSecondaryColor,
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF101422) : Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFE2E8F0),
                                      width: 1.0,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      padding: EdgeInsets.zero,
                                      itemCount: sortedRoster.length,
                                      separatorBuilder: (ctx, i) => Divider(
                                        height: 1,
                                        thickness: 1,
                                        color: isDark ? Colors.white.withValues(alpha: 0.07) : const Color(0xFFF1F5F9),
                                      ),
                                      itemBuilder: (context, index) {
                                        final dep = sortedRoster[index];
                                        final roleLower = dep.role.toLowerCase().trim();
                                        final isLead = roleLower == 'lead usher' || roleLower == 'lead' || roleLower == 'lead usher (sunday lead)';

                                        return Container(
                                          color: isLead
                                              ? Theme.of(context).primaryColor.withValues(alpha: isDark ? 0.10 : 0.04)
                                              : Colors.transparent,
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  gradient: isLead ? context.activeGradient : null,
                                                  color: isLead ? null : Theme.of(context).primaryColor.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Icon(
                                                  isLead ? LucideIcons.crown : LucideIcons.mapPin,
                                                  color: isLead ? Colors.white : Theme.of(context).primaryColor,
                                                  size: 16,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      dep.station,
                                                      style: GoogleFonts.outfit(
                                                        fontSize: 14.5,
                                                        fontWeight: FontWeight.bold,
                                                        color: context.textPrimaryColor,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      "${dep.usherName} • ${dep.role}",
                                                      style: GoogleFonts.inter(
                                                        fontSize: 12,
                                                        color: isLead
                                                            ? Theme.of(context).primaryColor
                                                            : context.textSecondaryColor,
                                                        fontWeight: isLead ? FontWeight.w600 : FontWeight.normal,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              if (isLead) ...[
                                                DribbblePillBadge(
                                                  label: "LEAD",
                                                  icon: LucideIcons.crown,
                                                  color: Theme.of(context).primaryColor,
                                                ),
                                                const SizedBox(width: 6),
                                              ],
                                              DribbblePillBadge(
                                                label: dep.verified ? "Confirmed" : "Pending",
                                                color: dep.verified ? AppColors.success : AppColors.amber,
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Rapid Incident Dispatch Section (replaces redundant Quick Hub Actions)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          LucideIcons.radio,
                          size: 16,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Rapid Incident Dispatch",
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimaryColor,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              "LIVE PROTOCOL",
                              style: GoogleFonts.outfit(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.55,
                    children: [
                      _buildIncidentCard(
                        context: context,
                        title: "Medical Aid",
                        subtitle: "First Aid / 911 EMT",
                        icon: LucideIcons.heartPulse,
                        accentColor: const Color(0xFFEF4444),
                        tag: "MEDICAL",
                        isDark: isDark,
                        onTap: () => _showDispatchModal(
                          context: context,
                          firebaseService: firebaseService,
                          title: "Medical Alert",
                          subtitle: "Immediate first aid & EMT response",
                          icon: LucideIcons.heartPulse,
                          accentColor: const Color(0xFFEF4444),
                          tag: "MEDICAL",
                          emoji: "🚨",
                          currentStation: displayStation,
                          userName: displayName,
                          isDark: isDark,
                        ),
                      ),
                      _buildIncidentCard(
                        context: context,
                        title: "Lead Assistance",
                        subtitle: "Discreet Support",
                        icon: LucideIcons.shieldAlert,
                        accentColor: const Color(0xFFF59E0B),
                        tag: "LEAD",
                        isDark: isDark,
                        onTap: () => _showDispatchModal(
                          context: context,
                          firebaseService: firebaseService,
                          title: "Lead Assistance",
                          subtitle: "Lead usher presence requested at post",
                          icon: LucideIcons.shieldAlert,
                          accentColor: const Color(0xFFF59E0B),
                          tag: "LEAD",
                          emoji: "🛡️",
                          currentStation: displayStation,
                          userName: displayName,
                          isDark: isDark,
                        ),
                      ),
                      _buildIncidentCard(
                        context: context,
                        title: "Sanctuary Full",
                        subtitle: "Open Overflow",
                        icon: LucideIcons.users,
                        accentColor: const Color(0xFF8B5CF6),
                        tag: "CAPACITY",
                        isDark: isDark,
                        onTap: () => _showDispatchModal(
                          context: context,
                          firebaseService: firebaseService,
                          title: "Sanctuary Full",
                          subtitle: "Main seating at capacity • Open overflow",
                          icon: LucideIcons.users,
                          accentColor: const Color(0xFF8B5CF6),
                          tag: "CAPACITY",
                          emoji: "⚠️",
                          currentStation: displayStation,
                          userName: displayName,
                          isDark: isDark,
                        ),
                      ),
                      _buildIncidentCard(
                        context: context,
                        title: "Spill / Custodial",
                        subtitle: "Aisle Cleanup",
                        icon: LucideIcons.sparkles,
                        accentColor: const Color(0xFF0D9488),
                        tag: "FACILITY",
                        isDark: isDark,
                        onTap: () => _showDispatchModal(
                          context: context,
                          firebaseService: firebaseService,
                          title: "Facility / Spill",
                          subtitle: "Cleanup / spill attention required",
                          icon: LucideIcons.sparkles,
                          accentColor: const Color(0xFF0D9488),
                          tag: "FACILITY",
                          emoji: "🧹",
                          currentStation: displayStation,
                          userName: displayName,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
