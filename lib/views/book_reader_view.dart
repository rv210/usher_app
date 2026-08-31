import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ReadingTheme { parchment, warmSepia, cleanWhite, dark, oledBlack }

class BookReaderView extends StatefulWidget {
  final int initialChapterIndex;

  const BookReaderView({
    super.key,
    this.initialChapterIndex = 0,
  });

  @override
  State<BookReaderView> createState() => _BookReaderViewState();
}

class _BookReaderViewState extends State<BookReaderView> {
  List<dynamic> _chapters = [];
  int _currentChapterIndex = 0;
  bool _isLoading = true;
  bool _hideControls = false;

  // Reading Preferences
  double _fontSize = 17.5;
  final double _lineHeight = 1.75;
  ReadingTheme _readingTheme = ReadingTheme.parchment;
  bool _useBookSerif = true;
  final Set<String> _bookmarkedChapterIds = {};

  final ScrollController _scrollController = ScrollController();
  double _scrollProgress = 0.0;

  static const String _prefChapterKey = 'usher_handbook_last_chapter_idx';
  static const String _prefFontSizeKey = 'usher_handbook_font_size_v4';
  static const String _prefThemeKey = 'usher_handbook_theme_v4';
  static const String _prefFontTypeKey = 'usher_handbook_serif_v4';
  static const String _prefBookmarksKey = 'usher_handbook_bookmarks';

  @override
  void initState() {
    super.initState();
    _currentChapterIndex = widget.initialChapterIndex;
    _scrollController.addListener(_onScroll);
    _loadBookData();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final max = _scrollController.position.maxScrollExtent;
      final current = _scrollController.position.pixels;
      if (max > 0) {
        setState(() {
          _scrollProgress = (current / max).clamp(0.0, 1.0);
        });
      }
    }
  }

  Future<void> _loadBookData() async {
    try {
      final jsonString = await rootBundle.loadString('assets/usher_handbook.json');
      final data = json.decode(jsonString) as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();

      final savedChapter = prefs.getInt(_prefChapterKey);
      final savedFontSize = prefs.getDouble(_prefFontSizeKey);
      final savedTheme = prefs.getString(_prefThemeKey);
      final savedSerif = prefs.getBool(_prefFontTypeKey);
      final savedBookmarks = prefs.getStringList(_prefBookmarksKey);

      setState(() {
        _chapters = data['chapters'] as List<dynamic>;
        if (widget.initialChapterIndex == 0 && savedChapter != null && savedChapter < _chapters.length) {
          _currentChapterIndex = savedChapter;
        }
        if (savedFontSize != null) _fontSize = savedFontSize;
        if (savedSerif != null) _useBookSerif = savedSerif;
        if (savedBookmarks != null) _bookmarkedChapterIds.addAll(savedBookmarks);
        if (savedTheme != null) {
          _readingTheme = ReadingTheme.values.firstWhere(
            (t) => t.name == savedTheme,
            orElse: () => ReadingTheme.parchment,
          );
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading handbook JSON: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefChapterKey, _currentChapterIndex);
    await prefs.setDouble(_prefFontSizeKey, _fontSize);
    await prefs.setString(_prefThemeKey, _readingTheme.name);
    await prefs.setBool(_prefFontTypeKey, _useBookSerif);
    await prefs.setStringList(_prefBookmarksKey, _bookmarkedChapterIds.toList());
  }

  void _goToChapter(int index) {
    if (index < 0 || index >= _chapters.length) return;
    setState(() {
      _currentChapterIndex = index;
      _scrollProgress = 0.0;
    });
    _savePreferences();
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _toggleBookmark() {
    final chId = (_chapters[_currentChapterIndex] as Map<String, dynamic>)['id'] as String;
    setState(() {
      if (_bookmarkedChapterIds.contains(chId)) {
        _bookmarkedChapterIds.remove(chId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bookmark removed"), duration: Duration(seconds: 1)),
        );
      } else {
        _bookmarkedChapterIds.add(chId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Chapter bookmarked!"), duration: Duration(seconds: 1)),
        );
      }
    });
    _savePreferences();
  }

  Color _getBgColor() {
    switch (_readingTheme) {
      case ReadingTheme.parchment:
        return const Color(0xFFFAF7F0); // Warm classical book paper
      case ReadingTheme.warmSepia:
        return const Color(0xFFF5EEDB);
      case ReadingTheme.cleanWhite:
        return const Color(0xFFFFFFFF);
      case ReadingTheme.dark:
        return const Color(0xFF19161B);
      case ReadingTheme.oledBlack:
        return Colors.black;
    }
  }

  Color _getSurfaceColor() {
    switch (_readingTheme) {
      case ReadingTheme.parchment:
        return const Color(0xFFEFECE4);
      case ReadingTheme.warmSepia:
        return const Color(0xFFEAE0C8);
      case ReadingTheme.cleanWhite:
        return const Color(0xFFF6F6F8);
      case ReadingTheme.dark:
        return const Color(0xFF242028);
      case ReadingTheme.oledBlack:
        return const Color(0xFF141416);
    }
  }

  Color _getTextColor() {
    switch (_readingTheme) {
      case ReadingTheme.parchment:
        return const Color(0xFF221F1D); // Deep rich book ink
      case ReadingTheme.warmSepia:
        return const Color(0xFF4A3728);
      case ReadingTheme.cleanWhite:
        return const Color(0xFF1F1C1B);
      case ReadingTheme.dark:
        return const Color(0xFFEFEBF2);
      case ReadingTheme.oledBlack:
        return const Color(0xFFEDEAE8);
    }
  }

  Color _getSecondaryTextColor() {
    switch (_readingTheme) {
      case ReadingTheme.parchment:
        return const Color(0xFF6E6862);
      case ReadingTheme.warmSepia:
        return const Color(0xFF7A654E);
      case ReadingTheme.cleanWhite:
        return const Color(0xFF6B6865);
      case ReadingTheme.dark:
        return const Color(0xFFA39DAA);
      case ReadingTheme.oledBlack:
        return const Color(0xFF908E94);
    }
  }

  Color _getAccentBorderColor() {
    switch (_readingTheme) {
      case ReadingTheme.parchment:
        return const Color(0xFFDFD9CE);
      case ReadingTheme.warmSepia:
        return const Color(0xFFD6C8AA);
      case ReadingTheme.cleanWhite:
        return const Color(0xFFE5E2DE);
      case ReadingTheme.dark:
        return const Color(0xFF332E3A);
      case ReadingTheme.oledBlack:
        return const Color(0xFF26262B);
    }
  }

  TextStyle _getBodyFont({bool isItalic = false, FontWeight weight = FontWeight.w400}) {
    final color = _getTextColor();
    if (_useBookSerif) {
      return GoogleFonts.lora(
        fontSize: _fontSize,
        height: _lineHeight,
        color: color,
        fontWeight: weight,
        fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
      );
    } else {
      return GoogleFonts.inter(
        fontSize: _fontSize,
        height: _lineHeight,
        color: color,
        fontWeight: weight,
        fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
      );
    }
  }

  void _showTableOfContents() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _getSurfaceColor(),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollCtl) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _getSecondaryTextColor().withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Icon(LucideIcons.bookOpen, color: Theme.of(context).primaryColor, size: 22),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Table of Contents",
                            style: GoogleFonts.cinzel(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _getTextColor(),
                            ),
                          ),
                          Text(
                            "Guardians Usher Ministry Handbook & SOP",
                            style: GoogleFonts.lora(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: _getSecondaryTextColor(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Divider(color: _getAccentBorderColor()),
                Expanded(
                  child: ListView.separated(
                    controller: scrollCtl,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    itemCount: _chapters.length,
                    separatorBuilder: (_, _) => Divider(color: _getAccentBorderColor().withValues(alpha: 0.5), height: 1),
                    itemBuilder: (context, idx) {
                      final ch = _chapters[idx] as Map<String, dynamic>;
                      final isCurrent = idx == _currentChapterIndex;
                      final isBookmarked = _bookmarkedChapterIds.contains(ch['id']);

                      return ListTile(
                        onTap: () {
                          Navigator.pop(ctx);
                          _goToChapter(idx);
                        },
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        tileColor: isCurrent ? Theme.of(context).primaryColor.withValues(alpha: 0.12) : null,
                        leading: Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCurrent
                                ? Theme.of(context).primaryColor
                                : _getSecondaryTextColor().withValues(alpha: 0.12),
                          ),
                          child: Text(
                            "${idx + 1}",
                            style: GoogleFonts.cinzel(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isCurrent ? Colors.white : _getTextColor(),
                            ),
                          ),
                        ),
                        title: Text(
                          ch['title'] as String,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 14.5,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                            color: isCurrent ? Theme.of(context).primaryColor : _getTextColor(),
                          ),
                        ),
                        subtitle: Text(
                          "Pages ${ch['start_page']}–${ch['end_page']} • ${ch['read_time_minutes']} min read",
                          style: GoogleFonts.inter(fontSize: 11, color: _getSecondaryTextColor()),
                        ),
                        trailing: isBookmarked
                            ? Icon(LucideIcons.bookmarkCheck, color: Theme.of(context).primaryColor, size: 18)
                            : null,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showReadingSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _getSurfaceColor(),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: _getSecondaryTextColor().withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Icon(LucideIcons.slidersHorizontal, size: 20, color: _getTextColor()),
                      const SizedBox(width: 10),
                      Text(
                        "Reading Appearance",
                        style: GoogleFonts.cinzel(fontSize: 17, fontWeight: FontWeight.bold, color: _getTextColor()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Reading Themes
                  Text("PAPER PALETTE", style: GoogleFonts.cinzel(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: _getSecondaryTextColor())),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _themeButton(ReadingTheme.parchment, "Parchment", const Color(0xFFFAF7F0), const Color(0xFF221F1D), setModalState),
                      const SizedBox(width: 8),
                      _themeButton(ReadingTheme.warmSepia, "Sepia", const Color(0xFFF5EEDB), const Color(0xFF4A3728), setModalState),
                      const SizedBox(width: 8),
                      _themeButton(ReadingTheme.cleanWhite, "White", const Color(0xFFFFFFFF), const Color(0xFF1F1C1B), setModalState),
                      const SizedBox(width: 8),
                      _themeButton(ReadingTheme.dark, "Dark", const Color(0xFF242028), const Color(0xFFEFEBF2), setModalState),
                      const SizedBox(width: 8),
                      _themeButton(ReadingTheme.oledBlack, "OLED", Colors.black, Colors.white, setModalState),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Font Size
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("FONT SIZE", style: GoogleFonts.cinzel(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: _getSecondaryTextColor())),
                      Text("${_fontSize.toInt()} pt", style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                    ],
                  ),
                  Row(
                    children: [
                      Text("A", style: GoogleFonts.lora(fontSize: 14, fontWeight: FontWeight.bold, color: _getSecondaryTextColor())),
                      Expanded(
                        child: Slider(
                          value: _fontSize,
                          min: 14,
                          max: 26,
                          divisions: 12,
                          activeColor: Theme.of(context).primaryColor,
                          inactiveColor: _getSecondaryTextColor().withValues(alpha: 0.2),
                          onChanged: (val) {
                            setState(() => _fontSize = val);
                            setModalState(() {});
                            _savePreferences();
                          },
                        ),
                      ),
                      Text("A", style: GoogleFonts.lora(fontSize: 24, fontWeight: FontWeight.bold, color: _getTextColor())),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Line Spacing & Font Family
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("TYPEFACE", style: GoogleFonts.cinzel(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: _getSecondaryTextColor())),
                      SegmentedButton<bool>(
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return Theme.of(context).primaryColor;
                            }
                            return _getSecondaryTextColor().withValues(alpha: 0.1);
                          }),
                          foregroundColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return Colors.white;
                            }
                            return _getTextColor();
                          }),
                        ),
                        segments: const [
                          ButtonSegment<bool>(value: true, label: Text("Classic Serif", style: TextStyle(fontWeight: FontWeight.bold))),
                          ButtonSegment<bool>(value: false, label: Text("Modern Sans", style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        selected: {_useBookSerif},
                        onSelectionChanged: (val) {
                          setState(() => _useBookSerif = val.first);
                          setModalState(() {});
                          _savePreferences();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _themeButton(ReadingTheme t, String label, Color bg, Color textC, StateSetter setModalState) {
    final isSelected = _readingTheme == t;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _readingTheme = t);
          setModalState(() {});
          _savePreferences();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Theme.of(context).primaryColor : _getAccentBorderColor(),
              width: isSelected ? 2.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: textC,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSearchModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _getSurfaceColor(),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        String query = "";
        return StatefulBuilder(
          builder: (context, setSearchState) {
            List<Map<String, dynamic>> results = [];
            if (query.trim().length >= 2) {
              final qLower = query.toLowerCase();
              for (int cIdx = 0; cIdx < _chapters.length; cIdx++) {
                final ch = _chapters[cIdx] as Map<String, dynamic>;
                final full = (ch['full_text'] as String? ?? '').toLowerCase();
                if (full.contains(qLower)) {
                  final idx = full.indexOf(qLower);
                  final start = (idx - 40).clamp(0, full.length);
                  final end = (idx + qLower.length + 60).clamp(0, full.length);
                  final snippet = (ch['full_text'] as String).substring(start, end).replaceAll('\n', ' ');

                  results.add({
                    'chapter_index': cIdx,
                    'chapter_title': ch['title'],
                    'snippet': "...$snippet...",
                  });
                }
              }
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, scrollCtl) {
                return Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: _getSecondaryTextColor().withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        autofocus: true,
                        style: GoogleFonts.lora(fontSize: 15, color: _getTextColor()),
                        decoration: InputDecoration(
                          hintText: "Search throughout handbook...",
                          hintStyle: GoogleFonts.lora(color: _getSecondaryTextColor()),
                          prefixIcon: Icon(LucideIcons.search, color: Theme.of(context).primaryColor, size: 20),
                          filled: true,
                          fillColor: _getBgColor(),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (val) {
                          setSearchState(() => query = val);
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: results.isEmpty
                          ? Center(
                              child: Text(
                                query.trim().length < 2 ? "Type at least 2 characters to search" : "No passages found",
                                style: GoogleFonts.lora(fontStyle: FontStyle.italic, color: _getSecondaryTextColor()),
                              ),
                            )
                          : ListView.separated(
                              controller: scrollCtl,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              itemCount: results.length,
                              separatorBuilder: (_, _) => Divider(color: _getAccentBorderColor()),
                              itemBuilder: (context, rIdx) {
                                final res = results[rIdx];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _goToChapter(res['chapter_index'] as int);
                                  },
                                  title: Text(
                                    res['chapter_title'] as String,
                                    style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).primaryColor),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      res['snippet'] as String,
                                      style: GoogleFonts.lora(fontSize: 13, height: 1.4, color: _getTextColor()),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildOpeningParagraphWithDropCap(String text, TextStyle bodyStyle, Color textColor) {
    if (text.trim().isEmpty) return const SizedBox.shrink();

    final cleanText = text.trim();
    final firstChar = cleanText[0].toUpperCase();
    final remaining = cleanText.substring(1).trimLeft();

    // Small-caps lead-in for first 3-4 words
    final words = remaining.split(' ');
    final leadInCount = words.length >= 3 ? 3 : words.length;
    final leadInWords = words.take(leadInCount).join(' ').toUpperCase();
    final afterLeadIn = words.skip(leadInCount).join(' ');

    if (words.length <= 10) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(right: 8, top: 0),
              child: Text(
                firstChar,
                style: GoogleFonts.playfairDisplay(
                  fontSize: (_fontSize * 3.4).clamp(52.0, 78.0),
                  fontWeight: FontWeight.w800,
                  height: 0.84,
                  color: textColor,
                ),
              ),
            ),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: bodyStyle,
                  children: [
                    TextSpan(
                      text: "$leadInWords ",
                      style: bodyStyle.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        fontSize: _fontSize * 0.94,
                      ),
                    ),
                    TextSpan(text: afterLeadIn),
                  ],
                ),
                textAlign: TextAlign.justify,
              ),
            ),
          ],
        ),
      );
    }

    final sideWords = words.take(9).toList();
    final bottomWords = words.skip(9).toList();

    final sideLeadIn = sideWords.take(leadInCount).join(' ').toUpperCase();
    final sideRest = sideWords.skip(leadInCount).join(' ');
    final bottomText = bottomWords.join(' ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(right: 8, top: 0),
                child: Text(
                  firstChar,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: (_fontSize * 3.4).clamp(52.0, 78.0),
                    fontWeight: FontWeight.w800,
                    height: 0.84,
                    color: textColor,
                  ),
                ),
              ),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: bodyStyle,
                    children: [
                      TextSpan(
                        text: "$sideLeadIn ",
                        style: bodyStyle.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          fontSize: _fontSize * 0.94,
                        ),
                      ),
                      TextSpan(text: sideRest),
                    ],
                  ),
                  textAlign: TextAlign.justify,
                ),
              ),
            ],
          ),
          if (bottomText.isNotEmpty) ...[
            const SizedBox(height: 2),
            _buildRichSelectableText(bottomText, bodyStyle),
          ],
        ],
      ),
    );
  }

  /// Prominent, unified Scripture Callout Card ensuring Bible verse & reference are never divided
  Widget _buildScriptureCard(Map<String, dynamic> pObj) {
    final text = (pObj['text'] as String? ?? '').trim();
    final reference = (pObj['reference'] as String? ?? '').trim();
    final primary = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Container(
        decoration: BoxDecoration(
          color: _readingTheme == ReadingTheme.parchment
              ? const Color(0xFFF3ECE0)
              : _readingTheme == ReadingTheme.warmSepia
                  ? const Color(0xFFEBE0C7)
                  : _readingTheme == ReadingTheme.cleanWhite
                      ? const Color(0xFFF7F7FA)
                      : primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: primary.withValues(alpha: 0.28),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: primary, width: 5),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Pill: HOLY SCRIPTURE + Reference Badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.bookOpenCheck,
                        size: 14,
                        color: primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "HOLY SCRIPTURE",
                      style: GoogleFonts.cinzel(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                        color: primary,
                      ),
                    ),
                    const Spacer(),
                    if (reference.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: primary.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          reference,
                          style: GoogleFonts.cinzel(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                // Scripture Verse Text
                SelectableText.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: "“$text”",
                        style: GoogleFonts.playfairDisplay(
                          fontSize: _fontSize * 1.06,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                          height: 1.65,
                          color: _getTextColor(),
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.justify,
                ),

                if (reference.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "— $reference",
                      style: GoogleFonts.cinzel(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Automatically highlights scripture citations inside paragraphs
  Widget _buildRichSelectableText(String text, TextStyle baseStyle) {
    final refRegex = RegExp(
      r'(\(?(?:1\s+|2\s+|3\s+|First\s+|Second\s+)?[A-Z][a-zA-Z\.]+\s+\d+:\d+(?:[\-\,\d\s]*\d)?\)?|\b(?:Acts\s+6:8|Acts\s+6:3-5|1\s+Corinthians\s+12:28|1\s+Corinthians\s+14:40|Ephesians\s+4:27|Colossians\s+3:23,24|Romans\s+12:7|Psalm\s+84:10)\b)',
    );

    final matches = refRegex.allMatches(text);
    if (matches.isEmpty) {
      return SelectableText(
        text,
        style: baseStyle,
        textAlign: TextAlign.justify,
      );
    }

    final spans = <TextSpan>[];
    int currentIndex = 0;

    for (final match in matches) {
      if (match.start > currentIndex) {
        spans.add(TextSpan(
          text: text.substring(currentIndex, match.start),
          style: baseStyle,
        ));
      }

      final matchedText = match.group(0)!;
      spans.add(TextSpan(
        text: matchedText,
        style: baseStyle.copyWith(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ));

      currentIndex = match.end;
    }

    if (currentIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentIndex),
        style: baseStyle,
      ));
    }

    return SelectableText.rich(
      TextSpan(children: spans),
      textAlign: TextAlign.justify,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _getBgColor(),
        body: Center(
          child: CircularProgressIndicator(color: Theme.of(context).primaryColor),
        ),
      );
    }

    if (_chapters.isEmpty) {
      return Scaffold(
        backgroundColor: _getBgColor(),
        appBar: AppBar(backgroundColor: _getSurfaceColor(), elevation: 0),
        body: Center(
          child: Text("No handbook content loaded", style: _getBodyFont()),
        ),
      );
    }

    final currentChapter = _chapters[_currentChapterIndex] as Map<String, dynamic>;
    final paragraphs = currentChapter['paragraphs'] as List<dynamic>? ?? [];
    final chId = currentChapter['id'] as String;
    final isBookmarked = _bookmarkedChapterIds.contains(chId);
    final hasPrev = _currentChapterIndex > 0;
    final hasNext = _currentChapterIndex < _chapters.length - 1;

    return Scaffold(
      backgroundColor: _getBgColor(),
      appBar: _hideControls
          ? null
          : AppBar(
              backgroundColor: _getSurfaceColor(),
              elevation: 0,
              centerTitle: false,
              leading: IconButton(
                icon: Icon(LucideIcons.arrowLeft, color: _getTextColor()),
                onPressed: () => Navigator.pop(context),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Ministry Handbook",
                    style: GoogleFonts.cinzel(fontSize: 15, fontWeight: FontWeight.bold, color: _getTextColor()),
                  ),
                  Text(
                    "Chapter ${_currentChapterIndex + 1} of ${_chapters.length} • ${currentChapter['read_time_minutes']} min read",
                    style: GoogleFonts.inter(fontSize: 11, color: _getSecondaryTextColor()),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: "Search in Handbook",
                  icon: Icon(LucideIcons.search, color: _getTextColor(), size: 20),
                  onPressed: _showSearchModal,
                ),
                IconButton(
                  tooltip: isBookmarked ? "Remove Bookmark" : "Bookmark Chapter",
                  icon: Icon(
                    isBookmarked ? LucideIcons.bookmarkCheck : LucideIcons.bookmark,
                    color: isBookmarked ? Theme.of(context).primaryColor : _getTextColor(),
                    size: 20,
                  ),
                  onPressed: _toggleBookmark,
                ),
                IconButton(
                  tooltip: "Table of Contents",
                  icon: Icon(LucideIcons.list, color: _getTextColor(), size: 20),
                  onPressed: _showTableOfContents,
                ),
                IconButton(
                  tooltip: "Text & Theme",
                  icon: Icon(LucideIcons.settings2, color: _getTextColor(), size: 20),
                  onPressed: _showReadingSettings,
                ),
              ],
            ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => setState(() => _hideControls = !_hideControls),
          child: Column(
            children: [
              // Reading Progress Bar
              if (!_hideControls)
                LinearProgressIndicator(
                  value: _scrollProgress,
                  backgroundColor: _getAccentBorderColor(),
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                  minHeight: 2.5,
                ),

              // Main Book Content Canvas (Max Width Box for Desktop/Tablet Comfort)
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(28, 20, 28, 60),
                      itemCount: paragraphs.length + 2, // header, paragraphs, and chapter navigation footer
                      itemBuilder: (context, idx) {
                        // 1. Classical Chapter Opener Header (Matching the Mockup)
                        if (idx == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 14, bottom: 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Chapter Number Header in Spaced Small Caps
                                Text(
                                  "CHAPTER ${_currentChapterIndex + 1}",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.cinzel(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 4.0,
                                    color: _getTextColor(),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Center Ornamental Divider Vignette (—— 🪞 ——)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 75,
                                      child: Divider(
                                        color: _getTextColor().withValues(alpha: 0.35),
                                        thickness: 1.1,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 14),
                                      child: _VignetteEmblem(
                                        color: _getTextColor().withValues(alpha: 0.75),
                                        size: 26,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 75,
                                      child: Divider(
                                        color: _getTextColor().withValues(alpha: 0.35),
                                        thickness: 1.1,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Chapter Title
                                Text(
                                  currentChapter['title'] as String,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: _getTextColor(),
                                    height: 1.25,
                                  ),
                                ),
                                if ((currentChapter['subtitle'] as String? ?? '').isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    currentChapter['subtitle'] as String,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.lora(
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                      color: _getSecondaryTextColor(),
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }

                        // 3. Chapter Footer & Previous / Next Navigation Card
                        if (idx == paragraphs.length + 1) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 40, bottom: 20),
                            child: Container(
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: _getSurfaceColor(),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: _getAccentBorderColor()),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(LucideIcons.checkCircle2, color: Theme.of(context).primaryColor, size: 20),
                                      const SizedBox(width: 10),
                                      Text(
                                        "You've completed Chapter ${_currentChapterIndex + 1}",
                                        style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, fontSize: 14, color: _getTextColor()),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  Row(
                                    children: [
                                      if (hasPrev)
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: _getTextColor(),
                                              side: BorderSide(color: _getAccentBorderColor()),
                                              padding: const EdgeInsets.symmetric(vertical: 14),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                            ),
                                            icon: const Icon(LucideIcons.chevronLeft, size: 16),
                                            label: Text("Previous", style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, fontSize: 12)),
                                            onPressed: () => _goToChapter(_currentChapterIndex - 1),
                                          ),
                                        )
                                      else
                                        const Spacer(),
                                      const SizedBox(width: 12),
                                      if (hasNext)
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Theme.of(context).primaryColor,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 14),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                            ),
                                            icon: const Icon(LucideIcons.chevronRight, size: 16),
                                            label: Text("Next Chapter", style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, fontSize: 12)),
                                            onPressed: () => _goToChapter(_currentChapterIndex + 1),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        // 2. Individual Paragraph Rendering
                        final pObj = paragraphs[idx - 1] as Map<String, dynamic>;
                        final pType = pObj['type'] as String? ?? 'text';
                        final pText = pObj['text'] as String? ?? '';

                        // Section Header
                        if (pType == 'heading') {
                          return Padding(
                            padding: const EdgeInsets.only(top: 26, bottom: 14),
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    pText,
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _getTextColor(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // Standout Unified Scripture Callout Box
                        if (pType == 'scripture') {
                          return _buildScriptureCard(pObj);
                        }

                        // Bullet / Numbered Points
                        if (pType == 'bullet' || pType == 'numbered') {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 4, right: 10),
                                  child: Icon(
                                    LucideIcons.chevronRight,
                                    size: 16,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                Expanded(
                                  child: _buildRichSelectableText(
                                    pText.replaceFirst(RegExp(r'^[•\-\*]\s*'), ''),
                                    _getBodyFont(),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // Quote Block
                        if (pType == 'quote') {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _getSurfaceColor(),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: _getAccentBorderColor()),
                              ),
                              child: SelectableText(
                                pText,
                                style: _getBodyFont(isItalic: true),
                              ),
                            ),
                          );
                        }

                        // First Paragraph of Chapter -> Drop Cap & Small Caps Lead-In
                        if (idx == 1) {
                          return _buildOpeningParagraphWithDropCap(
                            pText,
                            _getBodyFont(),
                            _getTextColor(),
                          );
                        }

                        // Regular Narrative Paragraph with highlighted citations
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: _buildRichSelectableText(
                            pText,
                            _getBodyFont(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for the vintage ornamental hand mirror vignette from the mockup
class _VignetteEmblem extends StatelessWidget {
  final Color color;
  final double size;

  const _VignetteEmblem({required this.color, this.size = 26});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 1.3),
      painter: _HandMirrorVignettePainter(color: color),
    );
  }
}

class _HandMirrorVignettePainter extends CustomPainter {
  final Color color;

  _HandMirrorVignettePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Draw the oval mirror frame with gentle classic tilt
    canvas.save();
    canvas.translate(w * 0.5, h * 0.38);
    canvas.rotate(-0.16);

    final ovalRect = Rect.fromCenter(
      center: Offset.zero,
      width: w * 0.65,
      height: h * 0.52,
    );
    canvas.drawOval(ovalRect, strokePaint);

    // Inner reflection arc
    final innerArc = Rect.fromCenter(
      center: const Offset(-1.5, -1),
      width: w * 0.42,
      height: h * 0.34,
    );
    final arcPaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    canvas.drawArc(innerArc, 3.8, 1.8, false, arcPaint);

    // Handle
    final handlePath = Path()
      ..moveTo(0, h * 0.26)
      ..lineTo(0, h * 0.62)
      ..cubicTo(w * 0.05, h * 0.68, -w * 0.05, h * 0.72, 0, h * 0.76);
    canvas.drawPath(handlePath, strokePaint);

    // Pommel dot
    canvas.drawCircle(Offset(0, h * 0.76), 1.2, fillPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HandMirrorVignettePainter oldDelegate) =>
      oldDelegate.color != color;
}
