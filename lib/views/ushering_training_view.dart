import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/training_module.dart';
import '../theme/app_theme.dart';
import 'book_reader_view.dart';

class UsheringTrainingView extends StatefulWidget {
  const UsheringTrainingView({super.key});

  @override
  State<UsheringTrainingView> createState() => _UsheringTrainingViewState();
}

class _UsheringTrainingViewState extends State<UsheringTrainingView> {
  final Set<int> _expandedIndices = {0}; // First module expanded by default
  String _searchQuery = "";

  void _toggleExpanded(int index) {
    setState(() {
      if (_expandedIndices.contains(index)) {
        _expandedIndices.remove(index);
      } else {
        _expandedIndices.add(index);
      }
    });
  }

  void _toggleAll(bool expand) {
    setState(() {
      if (expand) {
        _expandedIndices.addAll(
          List.generate(usheringTrainingModules.length, (i) => i),
        );
      } else {
        _expandedIndices.clear();
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

  int _getMatchingChapterIndex(int moduleIndex) {
    // Map module 0-7 to handbook chapter indices (0 to 5)
    switch (moduleIndex) {
      case 0:
        return 0; // Ch 1: Divine Calling
      case 1:
      case 2:
        return 1; // Ch 2: Sanctuary Order & Seating
      case 3:
        return 2; // Ch 3: Tithes & Offerings
      case 4:
      case 5:
        return 4; // Ch 5: Safety & Medical
      case 6:
      case 7:
        return 5; // Ch 6: Proverbs & Covenant
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredModules = usheringTrainingModules.where((m) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return m.title.toLowerCase().contains(q) ||
          m.summary.toLowerCase().contains(q) ||
          m.content.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ministry Handbook"),
        actions: [
          IconButton(
            tooltip: "Read Handbook in App",
            icon: const Icon(LucideIcons.bookOpen),
            onPressed: () => _openInAppReader(0),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(22),
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
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(LucideIcons.graduationCap, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Usher Handbook & SOP",
                              style: GoogleFonts.outfit(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              usheringTrainingAuthor,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
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
                    "Official Church Usher Standard Operating Procedures, sanctuary protocols, safety guidelines, and devotional scriptures.",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.4,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Theme.of(context).primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          icon: const Icon(LucideIcons.bookOpen, size: 18),
                          label: Text(
                            "Open In-App Handbook",
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          onPressed: () => _openInAppReader(0),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Search & Filter Bar
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
                        hintText: "Search training topics, safety, seating...",
                        hintStyle: GoogleFonts.inter(fontSize: 13.5, color: context.textSecondaryColor),
                        border: InputBorder.none,
                      ),
                      onChanged: (val) {
                        setState(() => _searchQuery = val);
                      },
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 16),
                      onPressed: () => setState(() => _searchQuery = ""),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Module Count & Expand All Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Training Modules (${filteredModules.length})",
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimaryColor,
                  ),
                ),
                TextButton(
                  onPressed: () => _toggleAll(_expandedIndices.length < usheringTrainingModules.length),
                  child: Text(
                    _expandedIndices.length < usheringTrainingModules.length ? "Expand All" : "Collapse All",
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Module List
            if (filteredModules.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(LucideIcons.bookX, size: 48, color: context.textSecondaryColor),
                      const SizedBox(height: 12),
                      Text(
                        "No matching modules found",
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Try a different search keyword",
                        style: GoogleFonts.inter(fontSize: 13, color: context.textSecondaryColor),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...List.generate(filteredModules.length, (index) {
                final module = filteredModules[index];
                final originalIndex = usheringTrainingModules.indexOf(module);
                final isExpanded = _expandedIndices.contains(originalIndex);
                final matchingChapterIdx = _getMatchingChapterIndex(originalIndex);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DribbbleGlassContainer(
                    borderRadius: 20,
                    padding: const EdgeInsets.all(18),
                    onTap: () => _toggleExpanded(originalIndex),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                gradient: context.activeGradient,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                "${originalIndex + 1}",
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    module.title,
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: context.textPrimaryColor),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    module.summary,
                                    style: GoogleFonts.inter(fontSize: 12.5, color: context.textSecondaryColor),
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
                        if (isExpanded) ...[
                          const SizedBox(height: 14),
                          Container(height: 1, color: context.borderThemeColor),
                          const SizedBox(height: 14),
                          SelectableText(
                            module.content,
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              height: 1.6,
                              color: context.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: Theme.of(context).primaryColor,
                              ),
                              icon: const Icon(LucideIcons.bookOpen, size: 16),
                              label: Text(
                                "Read in Ministry Handbook",
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12.5),
                              ),
                              onPressed: () => _openInAppReader(matchingChapterIdx),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
