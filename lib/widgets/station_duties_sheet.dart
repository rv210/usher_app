import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/station_duty.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

/// Modal bottom sheet or dialog displaying detailed duties and interactive checklist for Usher Stations.
class StationDutiesSheet extends StatefulWidget {
  final String? initialStationName;
  final String? serviceDate;
  final VoidCallback? onDutyStateChanged;

  const StationDutiesSheet({
    super.key,
    this.initialStationName,
    this.serviceDate,
    this.onDutyStateChanged,
  });

  /// Static helper to present the sheet anywhere in the app
  static Future<void> show(
    BuildContext context, {
    String? initialStationName,
    String? serviceDate,
    VoidCallback? onDutyStateChanged,
  }) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StationDutiesSheet(
        initialStationName: initialStationName,
        serviceDate: serviceDate,
        onDutyStateChanged: onDutyStateChanged,
      ),
    );
  }

  @override
  State<StationDutiesSheet> createState() => _StationDutiesSheetState();
}

class _StationDutiesSheetState extends State<StationDutiesSheet> {
  late UsherStation _selectedStation;
  final Map<String, bool> _checkedStatus = {};
  final Set<String> _expandedDuties = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedStation = UsherStationRegistry.getStationByName(widget.initialStationName);
    // Expand all duties by default so instructions are readily visible
    for (final d in _selectedStation.duties) {
      _expandedDuties.add(d.id);
    }
    _loadChecklistState();
  }

  Future<void> _loadChecklistState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final station in UsherStationRegistry.allStations) {
        for (final duty in station.duties) {
          final key = UsherStationRegistry.getChecklistPrefKey(
            stationId: station.id,
            dutyId: duty.id,
            serviceDate: widget.serviceDate,
          );
          _checkedStatus[duty.id] = prefs.getBool(key) ?? false;
        }
      }
    } catch (e) {
      debugPrint("Error loading station duties checklist: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleDutyCheck(StationDutyItem duty) async {
    HapticFeedback.lightImpact();
    final newStatus = !(_checkedStatus[duty.id] ?? false);
    setState(() {
      _checkedStatus[duty.id] = newStatus;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = UsherStationRegistry.getChecklistPrefKey(
        stationId: duty.stationId,
        dutyId: duty.id,
        serviceDate: widget.serviceDate,
      );
      await prefs.setBool(key, newStatus);
      widget.onDutyStateChanged?.call();
    } catch (e) {
      debugPrint("Error saving duty status: $e");
    }
  }

  Future<void> _resetStationChecklist() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Reset ${_selectedStation.name} Duties?",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "This will uncheck all duty items for ${_selectedStation.name} on this service date.",
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Reset All"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      HapticFeedback.mediumImpact();
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        for (final d in _selectedStation.duties) {
          _checkedStatus[d.id] = false;
          final key = UsherStationRegistry.getChecklistPrefKey(
            stationId: _selectedStation.id,
            dutyId: d.id,
            serviceDate: widget.serviceDate,
          );
          prefs.setBool(key, false);
        }
      });
      widget.onDutyStateChanged?.call();
    }
  }

  Future<void> _markAllStationDone() async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (final d in _selectedStation.duties) {
        _checkedStatus[d.id] = true;
        final key = UsherStationRegistry.getChecklistPrefKey(
          stationId: _selectedStation.id,
          dutyId: d.id,
          serviceDate: widget.serviceDate,
        );
        prefs.setBool(key, true);
      }
    });
    widget.onDutyStateChanged?.call();
  }

  void _copyStationBriefing() {
    HapticFeedback.selectionClick();
    final buffer = StringBuffer();
    buffer.writeln("📋 ${_selectedStation.name.toUpperCase()} - STATION DUTIES BRIEFING");
    buffer.writeln("Tagline: ${_selectedStation.tagline}");
    buffer.writeln("---------------------------------------");

    for (var i = 0; i < _selectedStation.duties.length; i++) {
      final d = _selectedStation.duties[i];
      final isDone = _checkedStatus[d.id] ?? false;
      buffer.writeln("${isDone ? '[X]' : '[ ]'} ${i + 1}. ${d.title} (${d.timing})");
      buffer.writeln("   Summary: ${d.summary}");
      buffer.writeln("   Supplies: ${d.supplies.join(', ')}");
      buffer.writeln("   Key Steps:");
      for (final step in d.detailedSteps) {
        buffer.writeln("     • $step");
      }
      buffer.writeln();
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _selectedStation.accentColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(LucideIcons.checkCheck, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              "Copied ${_selectedStation.name} duties to clipboard",
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  void _requestSuppliesHelp(BuildContext context, StationDutyItem duty) {
    HapticFeedback.mediumImpact();
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);
    final user = firebaseService.currentUser;
    final userName = user?.displayName ?? user?.email?.split('@').first ?? 'Usher';

    final textController = TextEditingController(
      text: "Need supplies/assistance for [${duty.title}] at ${_selectedStation.name}. Please bring: ${duty.supplies.take(2).join(', ')}.",
    );

    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _selectedStation.accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(LucideIcons.send, color: _selectedStation.accentColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Dispatch Supply Request",
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Send rapid notification to team comms channel for ${_selectedStation.name}:",
              style: GoogleFonts.inter(fontSize: 13, color: context.textSecondaryColor),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              maxLines: 3,
              style: GoogleFonts.inter(fontSize: 13),
              decoration: InputDecoration(
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.05)
                    : const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.borderThemeColor),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dlgCtx).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedStation.accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(LucideIcons.radio, size: 16),
            label: const Text("Broadcast Alert"),
            onPressed: () async {
              Navigator.of(dlgCtx).pop();
              final note = textController.text.trim();
              if (note.isNotEmpty) {
                final message = "📦 [STATION SUPPLIES • ${_selectedStation.name}]: $note (Sent by $userName)";
                await firebaseService.postCommsMessage(message);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: _selectedStation.accentColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      content: Row(
                        children: [
                          const Icon(LucideIcons.radio, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Supplies request sent to Comms!",
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final duties = _selectedStation.duties;
    final totalCount = duties.length;
    final doneCount = duties.where((d) => _checkedStatus[d.id] == true).length;
    final progress = totalCount > 0 ? (doneCount / totalCount) : 0.0;
    final allComplete = totalCount > 0 && doneCount == totalCount;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.12) : AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Header Title & Actions Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _selectedStation.accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedStation.accentColor.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    _selectedStation.icon,
                    size: 22,
                    color: _selectedStation.accentColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              "Detailed Station Duties",
                              style: GoogleFonts.outfit(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: context.textPrimaryColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: _selectedStation.accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "OFFICIAL",
                              style: GoogleFonts.outfit(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: _selectedStation.accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _selectedStation.tagline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: "Copy Station Briefing",
                  icon: const Icon(LucideIcons.copy, size: 18),
                  onPressed: _copyStationBriefing,
                ),
                IconButton(
                  tooltip: "Close",
                  icon: const Icon(LucideIcons.x, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Station Horizontal Tab Bar
          Container(
            height: 46,
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: UsherStationRegistry.allStations.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final station = UsherStationRegistry.allStations[index];
                final isSelected = station.id == _selectedStation.id;
                final stationDone = station.duties.where((d) => _checkedStatus[d.id] == true).length;
                final stationTotal = station.duties.length;

                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedStation = station;
                      for (final d in station.duties) {
                        _expandedDuties.add(d.id);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                station.accentColor,
                                station.accentColor.withValues(alpha: 0.82),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected
                          ? null
                          : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? Colors.transparent : context.borderThemeColor,
                        width: 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: station.accentColor.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          station.icon,
                          size: 15,
                          color: isSelected ? Colors.white : context.textPrimaryColor,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          station.name,
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? Colors.white : context.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.25)
                                : station.accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "$stationDone/$stationTotal",
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : station.accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Station Progress & Checklist Overview Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: allComplete
                    ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5))
                    : (isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC)),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: allComplete
                      ? const Color(0xFF059669)
                      : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: (allComplete ? const Color(0xFF059669) : _selectedStation.accentColor)
                              .withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          allComplete ? LucideIcons.badgeCheck : LucideIcons.listChecks,
                          size: 16,
                          color: allComplete ? const Color(0xFF059669) : _selectedStation.accentColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              allComplete
                                  ? "${_selectedStation.name} Duties Ready! 🎉"
                                  : "${_selectedStation.name} Checklist: $doneCount of $totalCount Done",
                              style: GoogleFonts.outfit(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: allComplete ? const Color(0xFF059669) : context.textPrimaryColor,
                              ),
                            ),
                            Text(
                              allComplete
                                  ? "All station preparations and inspection items verified for service."
                                  : "Check off each protocol as completed prior to doors opening.",
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: context.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "${(progress * 100).toInt()}%",
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: allComplete ? const Color(0xFF059669) : _selectedStation.accentColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 7,
                      backgroundColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        allComplete ? const Color(0xFF059669) : _selectedStation.accentColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Quick Actions Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(LucideIcons.checkCheck, size: 14),
                        label: Text("Mark All Done", style: GoogleFonts.inter(fontSize: 11.5)),
                        onPressed: _markAllStationDone,
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          visualDensity: VisualDensity.compact,
                          foregroundColor: AppColors.danger,
                        ),
                        icon: const Icon(LucideIcons.rotateCcw, size: 14),
                        label: Text("Reset", style: GoogleFonts.inter(fontSize: 11.5)),
                        onPressed: _resetStationChecklist,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Scrollable Duties List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
                    itemCount: duties.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final duty = duties[index];
                      final isChecked = _checkedStatus[duty.id] ?? false;
                      final isExpanded = _expandedDuties.contains(duty.id);

                      return Container(
                        decoration: BoxDecoration(
                          color: isChecked
                              ? (isDark
                                  ? const Color(0xFF064E3B).withValues(alpha: 0.25)
                                  : const Color(0xFFF0FDF4))
                              : (isDark ? AppColors.cardDark : Colors.white),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isChecked
                                ? const Color(0xFF059669).withValues(alpha: 0.5)
                                : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                            width: isChecked ? 1.5 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Main Duty Row
                            InkWell(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                              onTap: () => _toggleDutyCheck(duty),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Interactive Checkbox
                                    GestureDetector(
                                      onTap: () => _toggleDutyCheck(duty),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        width: 26,
                                        height: 26,
                                        decoration: BoxDecoration(
                                          color: isChecked ? const Color(0xFF059669) : Colors.transparent,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isChecked
                                                ? const Color(0xFF059669)
                                                : (isDark ? Colors.white38 : Colors.black26),
                                            width: 2,
                                          ),
                                        ),
                                        child: isChecked
                                            ? const Icon(LucideIcons.check, size: 16, color: Colors.white)
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Duty Title & Category
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  duty.title,
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    decoration: isChecked
                                                        ? TextDecoration.lineThrough
                                                        : TextDecoration.none,
                                                    color: isChecked
                                                        ? (isDark ? Colors.white60 : Colors.black54)
                                                        : context.textPrimaryColor,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              // Timing Tag
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                decoration: BoxDecoration(
                                                  color: _selectedStation.accentColor.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  duty.timing,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.w600,
                                                    color: _selectedStation.accentColor,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            duty.summary,
                                            style: GoogleFonts.inter(
                                              fontSize: 11.5,
                                              color: context.textSecondaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Expand/Collapse Chevron
                                    IconButton(
                                      icon: Icon(
                                        isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                                        size: 18,
                                        color: context.textSecondaryColor,
                                      ),
                                      onPressed: () {
                                        HapticFeedback.selectionClick();
                                        setState(() {
                                          if (isExpanded) {
                                            _expandedDuties.remove(duty.id);
                                          } else {
                                            _expandedDuties.add(duty.id);
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Expandable Details (Steps & Supplies)
                            if (isExpanded) ...[
                              const Divider(height: 1),
                              Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Required Supplies Section
                                    Row(
                                      children: [
                                        Icon(LucideIcons.package, size: 14, color: _selectedStation.accentColor),
                                        const SizedBox(width: 6),
                                        Text(
                                          "SUPPLIES & EQUIPMENT",
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.6,
                                            color: _selectedStation.accentColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: duty.supplies.map((sup) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                                            ),
                                          ),
                                          child: Text(
                                            sup,
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: context.textPrimaryColor,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 12),

                                    // Detailed Action Steps
                                    Row(
                                      children: [
                                        Icon(LucideIcons.clipboardList, size: 14, color: context.textSecondaryColor),
                                        const SizedBox(width: 6),
                                        Text(
                                          "OPERATIONAL STEPS & PROTOCOL",
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.6,
                                            color: context.textSecondaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Column(
                                      children: duty.detailedSteps.map((step) {
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 6),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                margin: const EdgeInsets.only(top: 5),
                                                width: 5,
                                                height: 5,
                                                decoration: BoxDecoration(
                                                  color: _selectedStation.accentColor,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  step,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    height: 1.35,
                                                    color: context.textPrimaryColor,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 10),

                                    // Quick Supply Request Button
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          visualDensity: VisualDensity.compact,
                                          side: BorderSide(
                                            color: _selectedStation.accentColor.withValues(alpha: 0.4),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        icon: Icon(LucideIcons.radio, size: 13, color: _selectedStation.accentColor),
                                        label: Text(
                                          "Need Supplies / Assistance?",
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: _selectedStation.accentColor,
                                          ),
                                        ),
                                        onPressed: () => _requestSuppliesHelp(context, duty),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
