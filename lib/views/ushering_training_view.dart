import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/training_module.dart';
import '../theme/app_theme.dart';
import 'book_reader_view.dart';

class UsheringTrainingView extends StatefulWidget {
  final int initialTabIndex; // 0 for Modules, 1 for Handbook

  const UsheringTrainingView({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<UsheringTrainingView> createState() => _UsheringTrainingViewState();
}

class _UsheringTrainingViewState extends State<UsheringTrainingView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<int> _expandedModuleIndices = {0}; // First module expanded by default
  final Set<int> _inlineExcerptIndices = {}; // Track inline handbook previews
  String _moduleSearchQuery = "";
  String _handbookSearchQuery = "";

  List<dynamic> _handbookChapters = [];
  bool _isLoadingHandbook = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
    _loadHandbookData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHandbookData() async {
    try {
      final jsonString = await rootBundle.loadString('assets/usher_handbook.json');
      final data = json.decode(jsonString) as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _handbookChapters = data['chapters'] as List<dynamic>? ?? [];
          _isLoadingHandbook = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading handbook data: $e");
      if (mounted) setState(() => _isLoadingHandbook = false);
    }
  }

  void _toggleModuleExpanded(int index) {
    setState(() {
      if (_expandedModuleIndices.contains(index)) {
        _expandedModuleIndices.remove(index);
      } else {
        _expandedModuleIndices.add(index);
      }
    });
  }

  void _toggleAllModules(bool expand) {
    setState(() {
      if (expand) {
        _expandedModuleIndices.addAll(
          List.generate(usheringTrainingModules.length, (i) => i),
        );
      } else {
        _expandedModuleIndices.clear();
      }
    });
  }

  void _toggleInlineExcerpt(int index) {
    setState(() {
      if (_inlineExcerptIndices.contains(index)) {
        _inlineExcerptIndices.remove(index);
      } else {
        _inlineExcerptIndices.add(index);
      }
    });
  }

  void _openInAppReader([int chapterIndex = 0]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookReaderView(initialChapterIndex: chapterIndex),
      ),
    );
  }

  void _jumpToPairedChapter(int chapterIndex) {
    _openInAppReader(chapterIndex);
  }

  void _jumpToPairedModule(int moduleIndex) {
    setState(() {
      _tabController.animateTo(0);
      _expandedModuleIndices.add(moduleIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Usher Handbook & Modules",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: "Read Handbook in App",
            icon: const Icon(LucideIcons.bookOpen),
            onPressed: () => _openInAppReader(0),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)
                  .withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                gradient: context.activeGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: context.textSecondaryColor,
              labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13.5),
              unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13.5),
              tabs: const [
                Tab(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.graduationCap, size: 15),
                        SizedBox(width: 6),
                        Text("Modules (8)"),
                      ],
                    ),
                  ),
                ),
                Tab(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.bookOpen, size: 15),
                        SizedBox(width: 6),
                        Text("Handbook (6)"),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: Practical Training SOP Modules
          _buildModulesTab(context),

          // TAB 2: Official Church Usher Handbook Chapters
          _buildHandbookTab(context),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: TRAINING MODULES (PAIRED VIEW)
  // ==========================================
  Widget _buildModulesTab(BuildContext context) {
    final filteredModules = usheringTrainingModules.where((m) {
      if (_moduleSearchQuery.trim().isEmpty) return true;
      final q = _moduleSearchQuery.toLowerCase();
      return m.title.toLowerCase().contains(q) ||
          m.summary.toLowerCase().contains(q) ||
          m.content.toLowerCase().contains(q) ||
          m.pairedChapterTitle.toLowerCase().contains(q) ||
          m.keyScripture.toLowerCase().contains(q);
    }).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        children: [
          // Pairing Banner Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: context.activeGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(LucideIcons.link2, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Paired SOP Modules",
                            style: GoogleFonts.outfit(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            "Each module pairs with an official Handbook chapter",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  "Actionable checklists, crowd-flow protocols, and safety guidelines cross-referenced directly with doctrine and scripture in the Usher Handbook.",
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    height: 1.45,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Theme.of(context).primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          elevation: 2,
                        ),
                        icon: const Icon(LucideIcons.bookOpen, size: 16),
                        label: Text(
                          "Read Full In-App Handbook",
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12.5),
                        ),
                        onPressed: () => _openInAppReader(0),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Search Bar
          DribbbleGlassContainer(
            borderRadius: 18,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Row(
              children: [
                Icon(LucideIcons.search, size: 18, color: context.textSecondaryColor),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    style: GoogleFonts.inter(fontSize: 14, color: context.textPrimaryColor),
                    decoration: InputDecoration(
                      hintText: "Search SOP modules, safety, seating, communion...",
                      hintStyle: GoogleFonts.inter(fontSize: 13, color: context.textSecondaryColor),
                      border: InputBorder.none,
                    ),
                    onChanged: (val) {
                      setState(() => _moduleSearchQuery = val);
                    },
                  ),
                ),
                if (_moduleSearchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 16),
                    onPressed: () => setState(() => _moduleSearchQuery = ""),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Header Row with Expand / Collapse
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  "Training Modules (${filteredModules.length})",
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () => _toggleAllModules(_expandedModuleIndices.length < usheringTrainingModules.length),
                child: Text(
                  _expandedModuleIndices.length < usheringTrainingModules.length ? "Expand All" : "Collapse All",
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Module Cards
          if (filteredModules.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(LucideIcons.bookX, size: 44, color: context.textSecondaryColor),
                    const SizedBox(height: 10),
                    Text(
                      "No matching modules found",
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else
            ...List.generate(filteredModules.length, (index) {
              final module = filteredModules[index];
              final originalIndex = usheringTrainingModules.indexOf(module);
              final isExpanded = _expandedModuleIndices.contains(originalIndex);
              final showExcerpt = _inlineExcerptIndices.contains(originalIndex);

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: DribbbleGlassContainer(
                  borderRadius: 22,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row (Tappable to expand/collapse)
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _toggleModuleExpanded(originalIndex),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                gradient: context.activeGradient,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                "${originalIndex + 1}",
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    module.title,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15.5,
                                      color: context.textPrimaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    module.summary,
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      color: context.textSecondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                              color: context.textSecondaryColor,
                              size: 20,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Paired Chapter Link Pill (Always Visible)
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _jumpToPairedChapter(module.pairedChapterIndex),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.09),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.bookOpen, size: 13, color: Theme.of(context).primaryColor),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  "Paired with ${module.pairedChapterTitle}",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(LucideIcons.externalLink, size: 11, color: Theme.of(context).primaryColor),
                            ],
                          ),
                        ),
                      ),

                      if (isExpanded) ...[
                        const SizedBox(height: 14),
                        Divider(height: 1, color: context.borderThemeColor),
                        const SizedBox(height: 14),

                        // Key Scripture Pill
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)
                                .withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.borderThemeColor),
                          ),
                          child: Row(
                            children: [
                              Icon(LucideIcons.quote, size: 15, color: Theme.of(context).primaryColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Scripture Anchor: ${module.keyScripture}",
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w600,
                                    color: context.textPrimaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Practical Takeaway Highlight Card
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.28),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(LucideIcons.sparkles, size: 16, color: Theme.of(context).primaryColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Practical Takeaway",
                                      style: GoogleFonts.outfit(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      module.practicalTakeaway,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: context.textPrimaryColor,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Complete Module SOP Content
                        SelectableText(
                          module.content,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            height: 1.6,
                            color: context.textPrimaryColor,
                          ),
                        ),

                        // Optional Inline Excerpt Toggle
                        if (showExcerpt && module.pairedChapterIndex < _handbookChapters.length) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1B1920) : const Color(0xFFFAF7F2)),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(LucideIcons.bookOpenCheck, size: 16, color: Theme.of(context).primaryColor),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Handbook Excerpt • ${module.pairedChapterTitle}",
                                        style: GoogleFonts.cinzel(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _getChapterExcerpt(module.pairedChapterIndex),
                                  style: GoogleFonts.lora(
                                    fontSize: 12.5,
                                    height: 1.55,
                                    fontStyle: FontStyle.italic,
                                    color: context.textPrimaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Dual Paired Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  foregroundColor: context.textSecondaryColor,
                                ),
                                icon: Icon(
                                  showExcerpt ? LucideIcons.eyeOff : LucideIcons.eye,
                                  size: 15,
                                ),
                                label: Text(
                                  showExcerpt ? "Hide Excerpt" : "Quick Excerpt",
                                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onPressed: () => _toggleInlineExcerpt(originalIndex),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 2,
                              ),
                              icon: const Icon(LucideIcons.bookOpen, size: 15),
                              label: Text(
                                "Read in Handbook",
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              onPressed: () => _jumpToPairedChapter(module.pairedChapterIndex),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: OFFICIAL HANDBOOK (PAIRED VIEW)
  // ==========================================
  Widget _buildHandbookTab(BuildContext context) {
    if (_isLoadingHandbook) {
      return Center(
        child: CircularProgressIndicator(color: Theme.of(context).primaryColor),
      );
    }

    final filteredChapters = _handbookChapters.where((c) {
      if (_handbookSearchQuery.trim().isEmpty) return true;
      final q = _handbookSearchQuery.toLowerCase();
      final title = (c['title'] as String? ?? '').toLowerCase();
      final subtitle = (c['subtitle'] as String? ?? '').toLowerCase();
      final partTitle = (c['part_title'] as String? ?? '').toLowerCase();
      return title.contains(q) || subtitle.contains(q) || partTitle.contains(q);
    }).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        children: [
          // Handbook Overview Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: context.activeGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(LucideIcons.bookOpen, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Church Usher Ministry Handbook",
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            "Official Doctrine & Biblical Operating Procedures",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  "Read all 6 foundational chapters in classical book typography with custom paper themes, adjustable fonts, and bookmarking.",
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    height: 1.45,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    elevation: 2,
                  ),
                  icon: const Icon(LucideIcons.bookOpenCheck, size: 16),
                  label: Text(
                    "Start Reading Chapter 1",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12.5),
                  ),
                  onPressed: () => _openInAppReader(0),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Search Bar
          DribbbleGlassContainer(
            borderRadius: 18,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Row(
              children: [
                Icon(LucideIcons.search, size: 18, color: context.textSecondaryColor),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    style: GoogleFonts.inter(fontSize: 14, color: context.textPrimaryColor),
                    decoration: InputDecoration(
                      hintText: "Search handbook chapters, parts, scriptures...",
                      hintStyle: GoogleFonts.inter(fontSize: 13, color: context.textSecondaryColor),
                      border: InputBorder.none,
                    ),
                    onChanged: (val) {
                      setState(() => _handbookSearchQuery = val);
                    },
                  ),
                ),
                if (_handbookSearchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 16),
                    onPressed: () => setState(() => _handbookSearchQuery = ""),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          Text(
            "Handbook Chapters (${filteredChapters.length})",
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.textPrimaryColor,
            ),
          ),

          const SizedBox(height: 10),

          // Chapter Cards with Paired Module Links
          ...List.generate(filteredChapters.length, (index) {
            final ch = filteredChapters[index] as Map<String, dynamic>;
            final chIdx = _handbookChapters.indexOf(ch);
            final pairedModules = getModulesForChapter(chIdx);

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: DribbbleGlassContainer(
                borderRadius: 22,
                padding: const EdgeInsets.all(18),
                onTap: () => _openInAppReader(chIdx),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Chapter Row (Tappable to read)
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _openInAppReader(chIdx),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "CHAPTER ${chIdx + 1}",
                                  style: GoogleFonts.cinzel(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "•  ${ch['read_time_minutes'] ?? 5} min read",
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: context.textSecondaryColor,
                                ),
                              ),
                              const Spacer(),
                              Icon(LucideIcons.chevronRight, size: 18, color: context.textSecondaryColor),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Title
                          Text(
                            ch['title'] as String? ?? '',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimaryColor,
                            ),
                          ),

                          if ((ch['subtitle'] as String? ?? '').isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              ch['subtitle'] as String,
                              style: GoogleFonts.lora(
                                fontSize: 12.5,
                                fontStyle: FontStyle.italic,
                                color: context.textSecondaryColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),
                    Divider(height: 1, color: context.borderThemeColor),
                    const SizedBox(height: 12),

                    // Paired Modules Tag
                    if (pairedModules.isNotEmpty) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(
                              LucideIcons.graduationCap,
                              size: 15,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Paired SOP Modules:",
                                  style: GoogleFonts.outfit(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: context.textSecondaryColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: pairedModules.map((m) {
                                    final mIdx = usheringTrainingModules.indexOf(m);
                                    return InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () => _jumpToPairedModule(mIdx),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Theme.of(context).primaryColor.withValues(alpha: 0.25),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              m.title.split(':').first,
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).primaryColor,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(LucideIcons.arrowUpRight, size: 10, color: Theme.of(context).primaryColor),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Action Buttons
                    Row(
                      children: [
                        if (pairedModules.isNotEmpty)
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Theme.of(context).primaryColor,
                                side: BorderSide(
                                  color: Theme.of(context).primaryColor.withValues(alpha: 0.4),
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              icon: const Icon(LucideIcons.graduationCap, size: 14),
                              label: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  "View SOP Module",
                                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                              onPressed: () => _jumpToPairedModule(usheringTrainingModules.indexOf(pairedModules.first)),
                            ),
                          ),
                        if (pairedModules.isNotEmpty) const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              elevation: 2,
                            ),
                            icon: const Icon(LucideIcons.bookOpen, size: 14),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                "Read Chapter",
                                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                            onPressed: () => _openInAppReader(chIdx),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _getChapterExcerpt(int chapterIndex) {
    if (chapterIndex < 0 || chapterIndex >= _handbookChapters.length) return "";
    final ch = _handbookChapters[chapterIndex] as Map<String, dynamic>;
    final paragraphs = ch['paragraphs'] as List<dynamic>? ?? [];
    for (final p in paragraphs) {
      if (p['type'] == 'scripture') {
        return "“${p['text']}” — ${p['reference'] ?? ''}";
      }
      if (p['type'] == 'text') {
        final txt = p['text'] as String? ?? '';
        if (txt.length > 200) {
          return "${txt.substring(0, 195)}...";
        }
        return txt;
      }
    }
    return "";
  }
}
