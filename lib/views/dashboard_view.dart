import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/deployment.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

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
    reference: "Psalm 84:10",
    text: "For a day in thy courts is better than a thousand. I had rather be a doorkeeper in the house of my God, than to dwell in the tents of wickedness.",
    category: "Usher Stewardship",
  ),
  BibleQuote(
    reference: "Colossians 3:23-24",
    text: "And whatsoever ye do, do it heartily, as to the Lord, and not unto men; Knowing that of the Lord ye shall receive the reward of the inheritance: for ye serve the Lord Christ.",
    category: "Service & Diligence",
  ),
  BibleQuote(
    reference: "Hebrews 13:2",
    text: "Be not forgetful to entertain strangers: for thereby some have entertained angels unawares.",
    category: "Hospitality & Welcome",
  ),
  BibleQuote(
    reference: "1 Corinthians 14:40",
    text: "Let all things be done decently and in order.",
    category: "Order & Reverence",
  ),
  BibleQuote(
    reference: "Romans 12:11-13",
    text: "Not slothful in business; fervent in spirit; serving the Lord; Rejoicing in hope; patient in tribulation; continuing instant in prayer; Distributing to the necessity of saints; given to hospitality.",
    category: "Faithful Spirit",
  ),
  BibleQuote(
    reference: "1 Peter 4:10",
    text: "As every man hath received the gift, even so minister the same one to another, as good stewards of the manifold grace of God.",
    category: "Grace & Stewardship",
  ),
  BibleQuote(
    reference: "Galatians 6:9",
    text: "And let us not be weary in well doing: for in due season we shall reap, if we faint not.",
    category: "Perseverance",
  ),
  BibleQuote(
    reference: "Proverbs 3:5-6",
    text: "Trust in the LORD with all thine heart; and lean not unto thine own understanding. In all thy ways acknowledge him, and he shall direct thy paths.",
    category: "Guidance & Faith",
  ),
  BibleQuote(
    reference: "Joshua 1:9",
    text: "Have not I commanded thee? Be strong and of a good courage; be not afraid, neither be thou dismayed: for the LORD thy God is with thee whithersoever thou goest.",
    category: "Courage & Strength",
  ),
];

class DashboardView extends StatefulWidget {
  final Function(int tabIndex) onNavigateTab;

  const DashboardView({
    super.key,
    required this.onNavigateTab,
  });

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int _quoteIndex = 0;

  @override
  void initState() {
    super.initState();
    _quoteIndex = DateTime.now().day % usherBibleQuotes.length;
  }

  void _nextQuote() {
    setState(() {
      _quoteIndex = (_quoteIndex + 1) % usherBibleQuotes.length;
    });
  }

  Widget _buildBibleQuoteCard(BuildContext context, bool isDark) {
    final quote = usherBibleQuotes[_quoteIndex];
    return GestureDetector(
      onTap: _nextQuote,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.bookOpen, size: 16, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  "SCRIPTURE OF THE DAY",
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "\"${quote.text}\"",
              style: GoogleFonts.inter(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                height: 1.5,
                color: context.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  quote.reference,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: context.textSecondaryColor.withValues(alpha: 0.8),
                  ),
                ),
                Text(
                  quote.category,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
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

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Trigger UI update
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).size.width >= 800 ? 30 : 85),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: context.activeGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).primaryColor.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'U',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Welcome back,",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: context.textSecondaryColor,
                              ),
                            ),
                            Text(
                              name,
                              style: GoogleFonts.outfit(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: context.textPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    DribbblePillBadge(
                      label: isAdminUser ? "Admin" : (profile?.displayRole ?? "Usher"),
                      icon: isAdminUser ? LucideIcons.shieldAlert : LucideIcons.userCheck,
                      color: isAdminUser ? Theme.of(context).primaryColor : AppColors.success,
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // Scripture of the Day Card
                _buildBibleQuoteCard(context, isDark),

                const SizedBox(height: 16),

                // Leadership Bulletin Banner (Dribbble Multi-Stop Gradient)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: context.activeGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: -2,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(LucideIcons.megaphone, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "LEADERSHIP BULLETIN",
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: Colors.white.withValues(alpha: 0.95),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "Today",
                              style: GoogleFonts.inter(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        firebaseService.bulletinText,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Live Tally Counter & Quick Attendance Card
                Text(
                  "Live Operations",
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 12),

                DribbbleGlassContainer(
                  borderRadius: 24,
                  padding: const EdgeInsets.all(20),
                  onTap: () => widget.onNavigateTab(2), // Navigate to Attendance view
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: context.activeGradient,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.4),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(LucideIcons.binary, color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Digital Tally Counter",
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: context.textPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.success,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "Live: ${firebaseService.currentTallyCount} attendees",
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(LucideIcons.chevronRight, color: Theme.of(context).primaryColor, size: 20),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Duty Deployments Section (Newest Sunday Schedule)
                Builder(
                  builder: (context) {
                    final allDeployments = firebaseService.deployments;
                    final now = DateTime.now();
                    final daysUntilSunday = (DateTime.sunday - now.weekday + 7) % 7;
                    final upcomingSunday = daysUntilSunday == 0 ? now : now.add(Duration(days: daysUntilSunday));
                    final sundayStr = DateFormat('yyyy-MM-dd').format(upcomingSunday);
                    final sundayShortStr = DateFormat('MMM d').format(upcomingSunday);

                    List<Deployment> sundayDeployments = allDeployments.where((d) {
                      return d.date == sundayStr ||
                             d.date.contains(sundayShortStr) ||
                             d.date.contains(DateFormat('MM/dd/yyyy').format(upcomingSunday));
                    }).toList();

                    final displayList = sundayDeployments.isNotEmpty ? sundayDeployments : allDeployments;

                    final sortedRoster = List<Deployment>.from(displayList)
                      ..sort((a, b) {
                        final aLead = a.role.toLowerCase().contains('lead usher') || (a.role.toLowerCase().contains('lead') && !a.role.toLowerCase().contains('head'));
                        final bLead = b.role.toLowerCase().contains('lead usher') || (b.role.toLowerCase().contains('lead') && !b.role.toLowerCase().contains('head'));
                        if (aLead && !bLead) return -1;
                        if (!aLead && bLead) return 1;
                        return 0;
                      });

                    String formattedBadgeDate(String rawDate) {
                      if (rawDate.isEmpty) return DateFormat('MMM d, yyyy').format(upcomingSunday).toUpperCase();
                      try {
                        if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(rawDate)) {
                          final dt = DateTime.parse(rawDate);
                          return DateFormat('MMM d, yyyy').format(dt).toUpperCase();
                        }
                      } catch (_) {}
                      return rawDate.toUpperCase();
                    }

                    final String activeRosterDate = sortedRoster.isNotEmpty ? sortedRoster.first.date : '';
                    final displayDateTitle = sundayDeployments.isNotEmpty
                        ? "SUNDAY ROSTER • ${DateFormat('MMM d, yyyy').format(upcomingSunday).toUpperCase()}"
                        : (activeRosterDate.isNotEmpty
                            ? "SUNDAY ROSTER • ${formattedBadgeDate(activeRosterDate)}"
                            : "SUNDAY ROSTER • ${DateFormat('MMM d, yyyy').format(upcomingSunday).toUpperCase()}");

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Upcoming Station Roster",
                                  style: GoogleFonts.outfit(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: context.textPrimaryColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(LucideIcons.calendarCheck, size: 12, color: Theme.of(context).primaryColor),
                                      const SizedBox(width: 5),
                                      Text(
                                        displayDateTitle,
                                        style: GoogleFonts.outfit(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).primaryColor,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
                        const SizedBox(height: 12),

                        // Deployment List
                        sortedRoster.isEmpty
                            ? DribbbleGlassContainer(
                                borderRadius: 18,
                                padding: const EdgeInsets.all(20),
                                child: Center(
                                  child: Text(
                                    "No station deployments scheduled for next Sunday yet.",
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: context.textSecondaryColor,
                                    ),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: sortedRoster.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final dep = sortedRoster[index];
                                  final roleLower = dep.role.toLowerCase();
                                  final isLead = roleLower.contains('lead usher') || (roleLower.contains('lead') && !roleLower.contains('head'));

                                  return DribbbleGlassContainer(
                                    borderRadius: 18,
                                    padding: const EdgeInsets.all(16),
                                    borderColor: isLead ? Theme.of(context).primaryColor : null,
                                    backgroundColor: isLead
                                        ? Theme.of(context).primaryColor.withValues(alpha: isDark ? 0.15 : 0.08)
                                        : null,
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            gradient: isLead ? context.activeGradient : null,
                                            color: isLead ? null : Theme.of(context).primaryColor.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(14),
                                            boxShadow: isLead
                                                ? [
                                                    BoxShadow(
                                                      color: Theme.of(context).primaryColor.withValues(alpha: 0.4),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 3),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Icon(
                                            isLead ? LucideIcons.crown : LucideIcons.mapPin,
                                            color: isLead ? Colors.white : Theme.of(context).primaryColor,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      dep.station,
                                                      style: GoogleFonts.outfit(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                        color: context.textPrimaryColor,
                                                      ),
                                                    ),
                                                  ),
                                                  if (isLead) ...[
                                                    const SizedBox(width: 6),
                                                    DribbblePillBadge(
                                                      label: "LEAD",
                                                      icon: LucideIcons.crown,
                                                      color: Theme.of(context).primaryColor,
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                "${dep.usherName} • ${dep.role}",
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  fontWeight: isLead ? FontWeight.bold : FontWeight.normal,
                                                  color: isLead
                                                      ? Theme.of(context).primaryColor
                                                      : context.textSecondaryColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        DribbblePillBadge(
                                          label: dep.verified ? "Confirmed" : "Pending",
                                          color: dep.verified ? AppColors.success : AppColors.amber,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 26),

                // Quick Navigation Grid
                Text(
                  "Quick Hub Actions",
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 14),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.4,
                  children: [
                    _buildNavCard(
                      context,
                      title: "Usher Directory",
                      subtitle: "${firebaseService.liveRoster.length} Active Members",
                      icon: LucideIcons.users,
                      gradient: context.activeGradient,
                      onTap: () => widget.onNavigateTab(3),
                    ),
                    _buildNavCard(
                      context,
                      title: "Team Comms",
                      subtitle: "${firebaseService.commsMessages.length} Messages",
                      icon: LucideIcons.messageSquare,
                      gradient: context.activeGradient,
                      onTap: () => widget.onNavigateTab(4),
                    ),
                    _buildNavCard(
                      context,
                      title: "Station Roster",
                      subtitle: "Duty Deployments",
                      icon: LucideIcons.calendar,
                      gradient: context.activeGradient,
                      onTap: () => widget.onNavigateTab(1),
                    ),
                    _buildNavCard(
                      context,
                      title: "System Settings",
                      subtitle: "Theme & Preferences",
                      icon: LucideIcons.sliders,
                      gradient: context.activeGradient,
                      onTap: () => widget.onNavigateTab(5),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return DribbbleGlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.first.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: context.textSecondaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

