import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/announcement.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import 'comms_view.dart';

class AnnouncementsView extends StatefulWidget {
  final List<Announcement>? initialAnnouncements;
  final bool? isAdminOverride;

  const AnnouncementsView({
    super.key,
    this.initialAnnouncements,
    this.isAdminOverride,
  });

  @override
  State<AnnouncementsView> createState() => _AnnouncementsViewState();
}

class _AnnouncementsViewState extends State<AnnouncementsView> {
  String _selectedCategory = 'All';
  final Set<String> _locallyDeletedIds = {};
  final Map<String, Announcement> _locallyUpdatedAnnouncements = {};

  final List<String> _categories = [
    'All',
    'Usher Meetings',
    'Worship Nights',
    'Bible Studies',
    'Outreach',
    'Orientation',
    'Appreciation',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    FirebaseService? firebaseService;
    try {
      firebaseService = Provider.of<FirebaseService>(context);
    } catch (_) {
      try {
        firebaseService = Provider.of<FirebaseService?>(context);
      } catch (_) {
        firebaseService = null;
      }
    }

    final profile = firebaseService?.userProfile;
    final isAdmin = widget.isAdminOverride ?? (profile?.isAdmin == true ||
        (profile?.role?.toLowerCase().contains('admin') == true) ||
        (profile?.role?.toLowerCase().contains('lead') == true) ||
        profile == null);

    const prefilledIds = {
      'ann_meeting_1',
      'ann_worship_1',
      'ann_bible_1',
      'ann_outreach_1',
      'ann_member_1',
      'ann_volunteer_1',
      'ann_1',
      'ann_2',
      'ann_3',
      'ann_4',
      'ann_5',
      'ann_6',
    };

    final baseAnnouncements = widget.initialAnnouncements ??
        firebaseService?.announcements ??
        const [];
    final allAnnouncements = baseAnnouncements
        .where((a) => !_locallyDeletedIds.contains(a.id) && !prefilledIds.contains(a.id))
        .map((a) => _locallyUpdatedAnnouncements[a.id] ?? a)
        .toList();
    final filteredAnnouncements = _selectedCategory == 'All'
        ? allAnnouncements
        : allAnnouncements.where((a) {
            final cat = a.category.toLowerCase();
            final filter = _selectedCategory.toLowerCase();
            return cat.contains(filter) || filter.contains(cat);
          }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF090D16) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 2,
        leading: IconButton(
          icon: Icon(
            LucideIcons.chevronLeft,
            color: context.textPrimaryColor,
            size: 24,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          "Announcements",
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: context.textPrimaryColor,
          ),
        ),
        centerTitle: true,
        actions: [
          if (isAdmin)
            IconButton(
              icon: Icon(
                LucideIcons.plus,
                color: theme.primaryColor,
                size: 22,
              ),
              tooltip: "Post Announcement",
              onPressed: () => _showAddAnnouncementModal(context, firebaseService, isDark),
            ),
        ],
      ),
      body: BehanceAmbientBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Filter Pills
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategory == cat;
                    return ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedCategory = cat);
                        }
                      },
                      selectedColor: theme.primaryColor.withValues(alpha: isDark ? 0.25 : 0.15),
                      backgroundColor: isDark ? const Color(0xFF161B2E) : const Color(0xFFF1F5F9),
                      labelStyle: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? theme.primaryColor
                            : (isDark ? Colors.white70 : const Color(0xFF475569)),
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? theme.primaryColor
                            : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                        width: isSelected ? 1.4 : 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    );
                  },
                ),
              ),

              // Announcements List
              Expanded(
                child: filteredAnnouncements.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.bellOff,
                              size: 48,
                              color: isDark ? Colors.white24 : Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _selectedCategory == 'All'
                                  ? "No active announcements"
                                  : "No announcements in this category",
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: context.textSecondaryColor,
                              ),
                            ),
                            if (isAdmin && _selectedCategory == 'All') ...[
                              const SizedBox(height: 6),
                              Text(
                                "Tap '+' or 'Post Notice' to create one",
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: context.textSecondaryColor.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        itemCount: filteredAnnouncements.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = filteredAnnouncements[index];
                          return _buildAnnouncementCard(
                            context,
                            announcement: item,
                            isDark: isDark,
                            isAdmin: isAdmin,
                            firebaseService: firebaseService,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showAddAnnouncementModal(context, firebaseService, isDark),
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              icon: const Icon(LucideIcons.megaphone, size: 18),
              label: Text(
                "Post Notice",
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  Widget _buildAnnouncementCard(
    BuildContext context, {
    required Announcement announcement,
    required bool isDark,
    required bool isAdmin,
    FirebaseService? firebaseService,
  }) {
    final catColor = announcement.categoryColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          _showAnnouncementDetails(
            context,
            announcement,
            isDark: isDark,
            firebaseService: firebaseService,
            isAdmin: isAdmin,
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF101422) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Leading Category Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: isDark ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: catColor.withValues(alpha: isDark ? 0.35 : 0.25),
                    width: 1,
                  ),
                ),
                child: Icon(
                  announcement.icon,
                  color: catColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Content Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Action Icons
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            announcement.title,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimaryColor,
                              height: 1.2,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(LucideIcons.messageSquareShare, size: 16, color: catColor),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          constraints: const BoxConstraints(),
                          tooltip: "Share to Comms",
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _showAnnouncementDetails(
                              context,
                              announcement,
                              isDark: isDark,
                              firebaseService: firebaseService,
                              isAdmin: isAdmin,
                            );
                          },
                        ),
                        if (isAdmin) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            icon: Icon(
                              LucideIcons.pencil,
                              size: 16,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            constraints: const BoxConstraints(),
                            tooltip: "Edit Announcement",
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              _showEditAnnouncementModal(
                                context,
                                announcement,
                                firebaseService,
                                isDark,
                              );
                            },
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(
                              LucideIcons.trash2,
                              size: 16,
                              color: Color(0xFFEF4444),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            constraints: const BoxConstraints(),
                            tooltip: "Delete Announcement",
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              _confirmDeleteAnnouncement(
                                context,
                                announcement,
                                firebaseService,
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Description
                    Text(
                      announcement.description,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        height: 1.45,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF4B5563),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Date & Category Footer (Wrap to prevent overflow on long category names)
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.calendar,
                              size: 13,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              announcement.date,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: isDark ? 0.20 : 0.10),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            announcement.category.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: catColor,
                              letterSpacing: 0.4,
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
    );
  }

  void _confirmDeleteAnnouncement(
    BuildContext context,
    Announcement item,
    FirebaseService? firebaseService,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF101422) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.trash2,
                color: Color(0xFFEF4444),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Delete Announcement?",
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimaryColor,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to delete \"${item.title}\"? This action will remove it for all ushers and cannot be undone.",
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.4,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF4B5563),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(
              "Cancel",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: context.textSecondaryColor,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              setState(() {
                _locallyDeletedIds.add(item.id);
                _locallyUpdatedAnnouncements.remove(item.id);
              });
              firebaseService?.deleteAnnouncement(item.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Announcement deleted")),
              );
            },
            child: Text(
              "Delete",
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showAnnouncementDetails(
    BuildContext context,
    Announcement item, {
    required bool isDark,
    FirebaseService? firebaseService,
    bool isAdmin = false,
  }) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF101422) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: item.categoryColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, color: item.categoryColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "${item.category} • ${item.date}",
                        style: GoogleFonts.inter(fontSize: 12, color: context.textSecondaryColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              item.description,
              style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: context.textPrimaryColor),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: OutlinedButton.icon(
                    icon: const Icon(LucideIcons.copy, size: 15),
                    label: const Text("Copy"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: BorderSide(
                        color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                      ),
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: "${item.title}\n\n${item.description}\n\n📅 Date: ${item.date}"));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Announcement copied to clipboard")),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    icon: const Icon(LucideIcons.messageSquareShare, size: 17),
                    label: Text(
                      "Share Notice",
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: item.categoryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      messenger.clearSnackBars();
                      Navigator.pop(ctx);
                      final commsText = "📢 [ANNOUNCEMENT • ${item.category.toUpperCase()}]\n*${item.title}*\n\n${item.description}\n\n📅 Date: ${item.date}";

                      FirebaseService? fb = firebaseService;
                      if (fb == null) {
                        try {
                          fb = Provider.of<FirebaseService>(context, listen: false);
                        } catch (_) {}
                      }

                      if (fb != null) {
                        await fb.postCommsMessage(commsText);
                      }

                      navigator.push(
                        MaterialPageRoute(builder: (_) => const CommsView()),
                      );
                    },
                  ),
                ),
              ],
            ),
            if (isAdmin) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(LucideIcons.pencil, size: 15),
                      label: Text(
                        "Edit Notice",
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(
                          color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                        ),
                        foregroundColor: isDark ? Colors.white70 : const Color(0xFF334155),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showEditAnnouncementModal(
                          context,
                          item,
                          firebaseService,
                          isDark,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(
                        LucideIcons.trash2,
                        size: 15,
                        color: Color(0xFFEF4444),
                      ),
                      label: Text(
                        "Delete",
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _confirmDeleteAnnouncement(
                          context,
                          item,
                          firebaseService,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ),
  ),
);
}

  void _showEditAnnouncementModal(
    BuildContext context,
    Announcement item,
    FirebaseService? firebaseService,
    bool isDark,
  ) {
    final titleCtl = TextEditingController(text: item.title);
    final descCtl = TextEditingController(text: item.description);

    final categories = [
      'Usher Meeting',
      'Worship Night',
      'Bible Study',
      'Community Outreach',
      'New Member Class',
      'Volunteer Appreciation',
    ];

    String selectedCategory = categories.firstWhere(
      (c) => c.toLowerCase() == item.category.toLowerCase(),
      orElse: () => item.category.isNotEmpty ? item.category : categories.first,
    );
    if (!categories.contains(selectedCategory)) {
      categories.insert(0, selectedCategory);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (sheetContext, setModalState) {
          final keyboard = MediaQuery.of(sheetContext).viewInsets.bottom;
          return Padding(
            padding: EdgeInsets.only(bottom: keyboard),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheetContext).size.height * 0.88,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF101422) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.black12,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              LucideIcons.pencil,
                              color: Theme.of(context).primaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Edit Announcement",
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Category Selector
                      Text(
                        "CATEGORY",
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: context.textSecondaryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: categories.map((cat) {
                          final isSelected = selectedCategory == cat;
                          return ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                HapticFeedback.selectionClick();
                                setModalState(() => selectedCategory = cat);
                              }
                            },
                            selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                            backgroundColor: isDark ? const Color(0xFF1A2234) : const Color(0xFFF1F5F9),
                            labelStyle: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : (isDark ? Colors.white70 : const Color(0xFF475569)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Title Field
                      Text(
                        "TITLE",
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: context.textSecondaryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: titleCtl,
                        textCapitalization: TextCapitalization.sentences,
                        style: GoogleFonts.inter(fontSize: 14, color: context.textPrimaryColor),
                        decoration: InputDecoration(
                          hintText: "e.g. Mandatory Usher Briefing",
                          hintStyle: GoogleFonts.inter(color: isDark ? Colors.white30 : Colors.black26),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1A2234) : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Description Field
                      Text(
                        "MESSAGE & DETAILS",
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: context.textSecondaryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: descCtl,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        style: GoogleFonts.inter(fontSize: 14, color: context.textPrimaryColor),
                        decoration: InputDecoration(
                          hintText: "Provide details, locations, times, or preparation notes...",
                          hintStyle: GoogleFonts.inter(color: isDark ? Colors.white30 : Colors.black26),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1A2234) : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          icon: const Icon(LucideIcons.check, size: 18),
                          label: Text(
                            "Save Changes",
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            final title = titleCtl.text.trim();
                            final desc = descCtl.text.trim();
                            if (title.isEmpty || desc.isEmpty) return;

                            final updatedAnn = item.copyWith(
                              title: title,
                              description: desc,
                              category: selectedCategory,
                            );

                            setState(() {
                              _locallyUpdatedAnnouncements[item.id] = updatedAnn;
                            });

                            firebaseService?.updateAnnouncement(updatedAnn);
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Announcement updated successfully!")),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddAnnouncementModal(
    BuildContext context,
    FirebaseService? firebaseService,
    bool isDark,
  ) {
    final titleCtl = TextEditingController();
    final descCtl = TextEditingController();
    String selectedCategory = 'Usher Meeting';

    final categories = [
      'Usher Meeting',
      'Worship Night',
      'Bible Study',
      'Community Outreach',
      'New Member Class',
      'Volunteer Appreciation',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (sheetContext, setModalState) {
          final keyboard = MediaQuery.of(sheetContext).viewInsets.bottom;
          return Padding(
            padding: EdgeInsets.only(bottom: keyboard),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheetContext).size.height * 0.88,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF101422) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.black12,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                  const SizedBox(height: 16),
                  Text(
                    "Create Announcement",
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category Selector
                  Text(
                    "CATEGORY",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: context.textSecondaryColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((cat) {
                      final isSelected = selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            HapticFeedback.selectionClick();
                            setModalState(() => selectedCategory = cat);
                          }
                        },
                        selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                        backgroundColor: isDark ? const Color(0xFF1A2234) : const Color(0xFFF1F5F9),
                        labelStyle: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : (isDark ? Colors.white70 : const Color(0xFF475569)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Title Field
                  Text(
                    "TITLE",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: context.textSecondaryColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleCtl,
                    textCapitalization: TextCapitalization.sentences,
                    style: GoogleFonts.inter(fontSize: 14, color: context.textPrimaryColor),
                    decoration: InputDecoration(
                      hintText: "e.g. Mandatory Usher Briefing",
                      hintStyle: GoogleFonts.inter(color: isDark ? Colors.white30 : Colors.black26),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1A2234) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Description Field
                  Text(
                    "MESSAGE & DETAILS",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: context.textSecondaryColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: descCtl,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    style: GoogleFonts.inter(fontSize: 14, color: context.textPrimaryColor),
                    decoration: InputDecoration(
                      hintText: "Provide details, locations, times, or preparation notes...",
                      hintStyle: GoogleFonts.inter(color: isDark ? Colors.white30 : Colors.black26),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1A2234) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: const Icon(LucideIcons.send, size: 18),
                      label: Text(
                        "Publish Notice",
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        final title = titleCtl.text.trim();
                        final desc = descCtl.text.trim();
                        if (title.isEmpty || desc.isEmpty) return;

                        final now = DateTime.now();
                        final formattedDate =
                            "${_monthName(now.month)} ${now.day}, ${now.year}";

                        final newAnn = Announcement(
                          id: 'ann_${now.millisecondsSinceEpoch}',
                          title: title,
                          description: desc,
                          date: formattedDate,
                          category: selectedCategory,
                          createdAt: now,
                        );

                        firebaseService?.addAnnouncement(newAnn);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Announcement published to all ushers!")),
                        );
                      },
                    ),
                  ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return (month >= 1 && month <= 12) ? months[month] : 'Jan';
  }
}
