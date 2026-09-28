import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/attendance_log.dart';
import '../models/guest_check_in.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

class AttendanceView extends StatefulWidget {
  final GlobalKey? counterKey;
  final GlobalKey? submitKey;
  final GlobalKey? historyKey;
  final GlobalKey? editDeleteKey;

  static final ValueNotifier<int> activeSubTab = ValueNotifier<int>(0);

  const AttendanceView({
    super.key,
    this.counterKey,
    this.submitKey,
    this.historyKey,
    this.editDeleteKey,
  });

  @override
  State<AttendanceView> createState() => _AttendanceViewState();
}

class _AttendanceViewState extends State<AttendanceView> {
  final _notesController = TextEditingController();
  final _dateController = TextEditingController(
    text: "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}",
  );
  final _searchController = TextEditingController();
  int _selectedSegment = 0;
  Timer? _tallyUndoTimer;

  @override
  void initState() {
    super.initState();
    _selectedSegment = AttendanceView.activeSubTab.value;
    AttendanceView.activeSubTab.addListener(_handleSubTabChanged);
  }

  void _handleSubTabChanged() {
    if (mounted && _selectedSegment != AttendanceView.activeSubTab.value) {
      setState(() {
        _selectedSegment = AttendanceView.activeSubTab.value;
      });
    }
  }

  String _normalizeServiceType(String val) {
    if (val == 'Sunday Morning Service' || val == 'Sunday Morning') return 'Sunday Service';
    if (val == 'Special Event / Concert' || val == 'Mid-week Rallies') return 'Special Events';
    if (val == 'Communion') return 'Communion Service';
    return val;
  }

  @override
  void dispose() {
    _tallyUndoTimer?.cancel();
    AttendanceView.activeSubTab.removeListener(_handleSubTabChanged);
    _notesController.dispose();
    _dateController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _submitCount(FirebaseService firebaseService) async {
    final count = firebaseService.currentTallyCount;
    if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tally count is zero. Increment counter before submitting.")),
      );
      return;
    }

    await firebaseService.submitAttendanceLog(
      headcount: count,
      serviceType: firebaseService.activeServiceType,
      serviceDate: _dateController.text.trim(),
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    _notesController.clear();
    firebaseService.resetTallyCount();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Logged $count attendees for ${firebaseService.activeServiceType} (${_dateController.text.trim()})!"),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(_selectedSegment == 0 ? "Digital Headcount Tally" : "Guest Check-In"),
        actions: [
          if (_selectedSegment == 0)
            IconButton(
              icon: const Icon(LucideIcons.rotateCcw),
              tooltip: "Reset Counter",
              onPressed: () {
                firebaseService.resetTallyCount();
              },
            )
          else
            IconButton(
              icon: const Icon(LucideIcons.userPlus),
              tooltip: "Register Guest",
              onPressed: () {
                _showRegisterGuestModal(context, firebaseService);
              },
            ),
        ],
      ),
      body: BehanceAmbientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Segmented Switcher (Headcount Tally vs Guest Check-In)
                _buildSegmentControl(context, firebaseService),

                if (_selectedSegment == 0) ...[
                  // Tally Counter Hero Display Card (Figma Bento + Behance Concentric Ring)
                  FigmaBentoCard(
                  key: widget.counterKey,
                  borderRadius: 26,
                  padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
                  child: Column(
                    children: [
                      // Top Telemetry Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          BehancePillBadge(
                            label: "SANCTUARY TALLY",
                            icon: LucideIcons.radio,
                            color: Theme.of(context).primaryColor,
                          ),
                          BehancePillBadge(
                            label: firebaseService.currentTallyCount >= 320
                                ? "PEAK LOAD"
                                : (firebaseService.currentTallyCount >= 200 ? "MODERATE" : "OPTIMAL"),
                            icon: LucideIcons.activity,
                            color: firebaseService.currentTallyCount >= 320
                                ? AppColors.danger
                                : (firebaseService.currentTallyCount >= 200 ? AppColors.warning : AppColors.success),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      // Concentric Behance Ring Gauge (Full-Dial Eyes-Free Touch Area)
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          firebaseService.updateTallyCount(1);
                        },
                        onLongPress: () {
                          HapticFeedback.heavyImpact();
                          if (firebaseService.currentTallyCount > 0) {
                            firebaseService.updateTallyCount(-1);
                          }
                        },
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.28),
                              width: 2.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).primaryColor.withValues(alpha: 0.22),
                                blurRadius: 30,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 154,
                              height: 154,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: context.activeGradient,
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).primaryColor.withValues(alpha: 0.45),
                                    blurRadius: 22,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 220),
                                    transitionBuilder: (child, animation) {
                                      return ScaleTransition(
                                        scale: Tween<double>(begin: 0.88, end: 1.0).animate(
                                          CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                                        ),
                                        child: FadeTransition(opacity: animation, child: child),
                                      );
                                    },
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        "${firebaseService.currentTallyCount}",
                                        key: ValueKey<int>(firebaseService.currentTallyCount),
                                        style: GoogleFonts.outfit(
                                          fontSize: 56,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          height: 1.0,
                                          letterSpacing: -1.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    "HEADCOUNT",
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.6,
                                      color: Colors.white.withValues(alpha: 0.85),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    "Tap to +1 • Hold -1",
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withValues(alpha: 0.65),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Increment / Decrement Steppers
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Decrement Stepper
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              firebaseService.updateTallyCount(-1);
                            },
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppColors.danger.withValues(alpha: 0.14),
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.danger.withValues(alpha: 0.35), width: 1.5),
                              ),
                              child: const Icon(LucideIcons.minus, color: AppColors.danger, size: 28),
                            ),
                          ),

                          const SizedBox(width: 32),

                          // Increment Stepper (Flagship Button)
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              firebaseService.updateTallyCount(1);
                            },
                            child: Container(
                              width: 86,
                              height: 86,
                              decoration: BoxDecoration(
                                gradient: context.activeGradient,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
                                    blurRadius: 24,
                                    spreadRadius: -1,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(LucideIcons.plus, color: Colors.white, size: 38),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // Quick Add Presets Bar with Undo Capability
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildPresetChip(context, "+1", () => _updateTallyWithUndo(firebaseService, 1, "+1 added")),
                          _buildPresetChip(context, "+5", () => _updateTallyWithUndo(firebaseService, 5, "+5 added")),
                          _buildPresetChip(context, "+10", () => _updateTallyWithUndo(firebaseService, 10, "+10 added")),
                          _buildPresetChip(context, "+25", () => _updateTallyWithUndo(firebaseService, 25, "+25 added")),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Service & Notes Inputs (Figma Bento Entry Card)
                FigmaBentoCard(
                  key: widget.submitKey,
                  borderRadius: 22,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      BehanceSectionHeader(
                        title: "Dispatch Entry",
                        subtitle: "Record service metadata & section counts",
                        icon: LucideIcons.clipboardList,
                      ),
                      const SizedBox(height: 16),

                      // Service Type Dropdown & Date Picker
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _normalizeServiceType(firebaseService.activeServiceType),
                        decoration: const InputDecoration(
                          labelText: "Service Type",
                          prefixIcon: Icon(LucideIcons.church, size: 18),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Sunday Service',
                            child: Text('Sunday Service', overflow: TextOverflow.ellipsis),
                          ),
                          DropdownMenuItem(
                            value: 'Special Events',
                            child: Text('Special Events', overflow: TextOverflow.ellipsis),
                          ),
                          DropdownMenuItem(
                            value: 'Communion Service',
                            child: Text('Communion Service', overflow: TextOverflow.ellipsis),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) firebaseService.setActiveServiceType(val);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _dateController,
                        readOnly: true,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setState(() {
                              _dateController.text =
                                  "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                            });
                          }
                        },
                        decoration: const InputDecoration(
                          labelText: "Service Date",
                          prefixIcon: Icon(LucideIcons.calendar, size: 18),
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          hintText: "Section notes (e.g. Sanctuary 110, Balcony 20)",
                          prefixIcon: Icon(LucideIcons.fileText, size: 18),
                        ),
                      ),

                      const SizedBox(height: 20),

                      BehanceActionButton(
                        label: "TRANSMIT HEADCOUNT TO DISPATCH",
                        icon: LucideIcons.send,
                        onPressed: () => _submitCount(firebaseService),
                        gradient: context.activeGradient,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Attendance History Header & Logs
                Container(
                  key: widget.historyKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      BehanceSectionHeader(
                        title: "Log Archive",
                        subtitle: "Recent attendance transmissions",
                        icon: LucideIcons.history,
                      ),
                      const SizedBox(height: 14),

                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: firebaseService.attendanceLogs.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final log = firebaseService.attendanceLogs[index];
                          return FigmaBentoCard(
                            borderRadius: 18,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Card Header Row
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Headcount Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        gradient: context.activeGradient,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Theme.of(context).primaryColor.withValues(alpha: 0.35),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        "${log.headcount}",
                                        style: GoogleFonts.outfit(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            log.serviceType,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.outfit(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: context.textPrimaryColor,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Icon(LucideIcons.calendar, size: 11, color: Theme.of(context).primaryColor),
                                              const SizedBox(width: 4),
                                              Text(
                                                log.serviceDate,
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: Theme.of(context).primaryColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      key: index == 0 ? widget.editDeleteKey : null,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            constraints: const BoxConstraints(),
                                            padding: const EdgeInsets.all(6),
                                            icon: Icon(LucideIcons.edit2, size: 16, color: Theme.of(context).primaryColor),
                                            tooltip: "Edit Log",
                                            onPressed: () => _showEditAttendanceDialog(context, firebaseService, log),
                                          ),
                                          const SizedBox(width: 4),
                                          IconButton(
                                            constraints: const BoxConstraints(),
                                            padding: const EdgeInsets.all(6),
                                            icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.danger),
                                            tooltip: "Delete Log",
                                            onPressed: () => _confirmDeleteAttendance(context, firebaseService, log.id),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                // Optional Log Notes
                                if (log.notes != null && log.notes!.trim().isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
                                        border: Border(
                                          left: BorderSide(color: Theme.of(context).primaryColor, width: 2.5),
                                        ),
                                      ),
                                      child: Text(
                                        log.notes!.trim(),
                                        style: GoogleFonts.inter(
                                          fontSize: 12.5,
                                          height: 1.4,
                                          color: context.textSecondaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 10),
                                Text(
                                  "Transmitted by ${log.submittedBy}",
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                ] else ...[
                  _buildGuestCheckInView(context, firebaseService),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _updateTallyWithUndo(FirebaseService firebaseService, int delta, String message) {
    HapticFeedback.mediumImpact();
    firebaseService.updateTallyCount(delta);

    _tallyUndoTimer?.cancel();
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 2500),
        dismissDirection: DismissDirection.horizontal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xF01E293B),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        content: Row(
          children: [
            Expanded(
              child: Text(
                "$message • Tally: ${firebaseService.currentTallyCount}",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _tallyUndoTimer?.cancel();
                HapticFeedback.heavyImpact();
                firebaseService.updateTallyCount(-delta);
                messenger.hideCurrentSnackBar();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  "UNDO",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF60A5FA),
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _tallyUndoTimer?.cancel();
                messenger.hideCurrentSnackBar();
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: Colors.white54,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // Guaranteed fallback auto-dismissal timer in case accessibility navigation delays SnackBar
    _tallyUndoTimer = Timer(const Duration(milliseconds: 2600), () {
      if (mounted) {
        messenger.hideCurrentSnackBar();
      }
    });
  }

  void _showEditAttendanceDialog(BuildContext context, FirebaseService firebaseService, AttendanceLogEntry log) {
    final countController = TextEditingController(text: log.headcount.toString());
    final dateController = TextEditingController(text: log.serviceDate);
    final notesController = TextEditingController(text: log.notes ?? '');
    String serviceType = log.serviceType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.90,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 16,
                    bottom: bottomInset > 0 ? bottomInset + 20 : 28,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    // Pull Handle
                    Center(
                      child: Container(
                        width: 42,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: context.textSecondaryColor.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: context.activeGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(LucideIcons.edit2, size: 20, color: Colors.white),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Edit Attendance Log",
                                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "Modify submitted headcount & details",
                                style: GoogleFonts.inter(fontSize: 12, color: context.textSecondaryColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: countController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Headcount",
                        prefixIcon: Icon(LucideIcons.users, size: 18),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _normalizeServiceType(serviceType),
                      decoration: const InputDecoration(
                        labelText: "Service Type",
                        prefixIcon: Icon(LucideIcons.church, size: 18),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Sunday Service',
                          child: Text('Sunday Service', overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: 'Special Events',
                          child: Text('Special Events', overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: 'Communion Service',
                          child: Text('Communion Service', overflow: TextOverflow.ellipsis),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => serviceType = val);
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: dateController,
                      readOnly: true,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.tryParse(dateController.text) ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setModalState(() {
                            dateController.text =
                                "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                          });
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: "Date of Service",
                        prefixIcon: Icon(LucideIcons.calendar, size: 18),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: "Notes (Optional)",
                        prefixIcon: Icon(LucideIcons.fileText, size: 18),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text("Cancel"),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              final newCount = int.tryParse(countController.text.trim()) ?? log.headcount;
                              firebaseService.editAttendanceLog(
                                log.id,
                                headcount: newCount,
                                serviceType: serviceType,
                                serviceDate: dateController.text.trim(),
                                notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                              );
                              Navigator.pop(ctx);
                            },
                            child: const Text("Save Changes"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        );
      },
    );
  }

  void _confirmDeleteAttendance(BuildContext context, FirebaseService firebaseService, String logId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Delete Headcount Log?", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to delete this attendance log?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              firebaseService.deleteAttendanceLog(logId);
              Navigator.pop(ctx);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(BuildContext context, String label, VoidCallback onTap) {
    return BehanceGlassCard(
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      onTap: onTap,
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildSegmentControl(BuildContext context, FirebaseService firebaseService) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeGradient = context.activeGradient;
    final isGold = activeGradient.colors.contains(const Color(0xFFC79540)) ||
        activeGradient.colors.contains(const Color(0xFFE5BC6A));
    final activeTextColor = isGold ? const Color(0xFF161208) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16253B).withValues(alpha: 0.8) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedSegment = 0);
                AttendanceView.activeSubTab.value = 0;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: _selectedSegment == 0 ? activeGradient : null,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _selectedSegment == 0
                      ? [
                          BoxShadow(
                            color: activeGradient.colors.last.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.binary,
                      size: 16,
                      color: _selectedSegment == 0 ? activeTextColor : context.textSecondaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Headcount Tally",
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: _selectedSegment == 0 ? activeTextColor : context.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedSegment = 1);
                AttendanceView.activeSubTab.value = 1;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: _selectedSegment == 1 ? activeGradient : null,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _selectedSegment == 1
                      ? [
                          BoxShadow(
                            color: activeGradient.colors.last.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.userCheck,
                      size: 16,
                      color: _selectedSegment == 1 ? activeTextColor : context.textSecondaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Guest Check-In",
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: _selectedSegment == 1 ? activeTextColor : context.textSecondaryColor,
                      ),
                    ),
                    if (firebaseService.todayGuestCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: _selectedSegment == 1
                              ? (isGold ? const Color(0xFF161208).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.25))
                              : Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "${firebaseService.todayGuestCount}",
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: _selectedSegment == 1 ? activeTextColor : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestCheckInView(BuildContext context, FirebaseService firebaseService) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayList = firebaseService.guestCheckIns;
    final query = _searchController.text.trim().toLowerCase();

    final filteredList = query.isEmpty
        ? displayList
        : displayList.where((g) {
            return g.guestName.toLowerCase().contains(query) ||
                (g.notes?.toLowerCase().contains(query) ?? false) ||
                g.entrance.toLowerCase().contains(query);
          }).toList();

    final totalGuestsToday = firebaseService.todayGuestCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Telemetry Bento Grid
        Row(
          children: [
            // Card 1: Total Checked In
            Expanded(
              child: FigmaBentoCard(
                borderRadius: 20,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(LucideIcons.users, size: 16, color: Theme.of(context).primaryColor),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "TODAY",
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "$totalGuestsToday",
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Total Checked In",
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    Text(
                      "Sanctuary Visitors",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Card 2: Door / Entrance Station (Enforced Vestibule Station)
            Expanded(
              child: FigmaBentoCard(
                borderRadius: 20,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(LucideIcons.doorOpen, size: 16, color: Color(0xFF38BDF8)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "ACTIVE",
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF38BDF8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Vestibule",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Assigned Station",
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    Text(
                      "Vestibule Door Post",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Action Button: + Register Guest / Family (Direct manual check-in, NO QR SCAN)
        BehanceActionButton(
          label: "+ REGISTER GUEST / FAMILY",
          icon: LucideIcons.userPlus,
          height: 52,
          onPressed: () => _showRegisterGuestModal(context, firebaseService),
        ),

        const SizedBox(height: 22),

        // Search Bar & Filter Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(LucideIcons.history, size: 18, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  "Recent Check-Ins",
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimaryColor,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "${filteredList.length} Entries",
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Search Box
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF16253B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: "Search guests, notes...",
              hintStyle: GoogleFonts.inter(fontSize: 13, color: context.textSecondaryColor),
              prefixIcon: Icon(LucideIcons.search, size: 18, color: context.textSecondaryColor),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(LucideIcons.x, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Check-Ins List
        if (filteredList.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            child: Column(
              children: [
                Icon(LucideIcons.userX, size: 36, color: context.textSecondaryColor.withValues(alpha: 0.5)),
                const SizedBox(height: 10),
                Text(
                  "No guest check-ins found",
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Tap '+ Register Guest / Family' to check in guests at the Vestibule Station.",
                  style: GoogleFonts.inter(fontSize: 12, color: context.textSecondaryColor),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final guest = filteredList[index];
              return _buildGuestCheckInCard(context, firebaseService, guest, isDark);
            },
          ),
      ],
    );
  }

  Widget _buildGuestCheckInCard(
    BuildContext context,
    FirebaseService firebaseService,
    GuestCheckInEntry guest,
    bool isDark,
  ) {
    final activeGradient = context.activeGradient;
    final isGold = activeGradient.colors.contains(const Color(0xFFC79540)) ||
        activeGradient.colors.contains(const Color(0xFFE5BC6A));
    final partyTextColor = isGold ? const Color(0xFF161208) : Colors.white;
    final primary = Theme.of(context).primaryColor;

    return FigmaBentoCard(
      borderRadius: 18,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Party Size Badge Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: activeGradient,
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: activeGradient.colors.last.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                "${guest.partySize}",
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: partyTextColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        guest.guestName,
                        style: GoogleFonts.outfit(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimaryColor,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: primary.withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Checked In",
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(LucideIcons.clock, size: 12, color: context.textSecondaryColor),
                    const SizedBox(width: 4),
                    Text(
                      guest.checkInTime,
                      style: GoogleFonts.inter(fontSize: 11.5, color: context.textSecondaryColor),
                    ),
                    const SizedBox(width: 10),
                    Icon(LucideIcons.mapPin, size: 12, color: primary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        "Vestibule Station",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: primary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (guest.notes != null && guest.notes!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
                        border: Border(
                          left: BorderSide(color: primary, width: 2.5),
                        ),
                      ),
                      child: Text(
                        guest.notes!.trim(),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Edit & Delete Action Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
                icon: Icon(LucideIcons.edit2, size: 16, color: Theme.of(context).primaryColor),
                tooltip: "Edit Check-In",
                onPressed: () => _showEditGuestModal(context, firebaseService, guest),
              ),
              const SizedBox(width: 2),
              IconButton(
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
                icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.danger),
                tooltip: "Delete Check-In",
                onPressed: () => _confirmDeleteGuest(context, firebaseService, guest),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRegisterGuestModal(BuildContext context, FirebaseService service) {
    final nameController = TextEditingController();
    final notesController = TextEditingController();
    int partySize = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.90,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 22,
                  right: 22,
                  top: 16,
                  bottom: bottomInset > 0 ? bottomInset + 20 : 28,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: context.textSecondaryColor.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(LucideIcons.userPlus, color: Theme.of(context).primaryColor, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Register Guest / Family",
                                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "Vestibule Station Check-In",
                                style: GoogleFonts.inter(fontSize: 12, color: context.textSecondaryColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: "Guest or Family Name",
                        hintText: "e.g. The Anderson Family or Sarah Jenkins",
                        prefixIcon: Icon(LucideIcons.user, size: 18),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Party Size",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: context.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.black : Colors.grey[100])?.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(LucideIcons.minus, size: 16),
                                onPressed: partySize > 1 ? () => setModalState(() => partySize--) : null,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                child: Text(
                                  "$partySize",
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: context.textPrimaryColor,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(LucideIcons.plus, size: 16),
                                onPressed: () => setModalState(() => partySize++),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          partySize == 1 ? "1 person" : "$partySize people",
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Entrance / Station: Fixed to Vestibule Station
                    Text(
                      "Entrance Station",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: context.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(LucideIcons.mapPin, size: 18, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Vestibule Station",
                              style: GoogleFonts.outfit(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: context.textPrimaryColor,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "FIXED POST",
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: "Notes (Optional)",
                        hintText: "e.g. Needs wheelchair seating, first visit",
                        prefixIcon: Icon(LucideIcons.fileText, size: 18),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text("Cancel"),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: const Color(0xFF161208),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () {
                              final name = nameController.text.trim().isNotEmpty
                                  ? nameController.text.trim()
                                  : "Guest Family";
                              final notes = notesController.text.trim().isNotEmpty
                                  ? notesController.text.trim()
                                  : null;

                              HapticFeedback.mediumImpact();
                              service.addGuestCheckIn(
                                guestName: name,
                                partySize: partySize,
                                entrance: 'Vestibule Station',
                                notes: notes,
                              );

                              Navigator.pop(ctx);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(LucideIcons.checkCheck, color: Color(0xFF161208), size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          "Checked in $name ($partySize) at Vestibule Station!",
                                          style: const TextStyle(color: Color(0xFF161208), fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Theme.of(context).primaryColor,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            },
                            child: const Text("Confirm Check-In", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showEditGuestModal(BuildContext context, FirebaseService service, GuestCheckInEntry guest) {
    final nameController = TextEditingController(text: guest.guestName);
    final notesController = TextEditingController(text: guest.notes ?? '');
    int partySize = guest.partySize;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.90,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 22,
                  right: 22,
                  top: 16,
                  bottom: bottomInset > 0 ? bottomInset + 20 : 28,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: context.textSecondaryColor.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: context.activeGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(LucideIcons.edit2, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Edit Guest Check-In",
                                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "Update guest details or party size",
                                style: GoogleFonts.inter(fontSize: 12, color: context.textSecondaryColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Guest or Family Name",
                        prefixIcon: Icon(LucideIcons.user, size: 18),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Party Size",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: context.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.black : Colors.grey[100])?.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(LucideIcons.minus, size: 16),
                                onPressed: partySize > 1 ? () => setModalState(() => partySize--) : null,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                child: Text(
                                  "$partySize",
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: context.textPrimaryColor,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(LucideIcons.plus, size: 16),
                                onPressed: () => setModalState(() => partySize++),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          partySize == 1 ? "1 person" : "$partySize people",
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Entrance Station",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: context.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(LucideIcons.mapPin, size: 18, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Vestibule Station",
                              style: GoogleFonts.outfit(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: context.textPrimaryColor,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "FIXED POST",
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: "Notes (Optional)",
                        prefixIcon: Icon(LucideIcons.fileText, size: 18),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text("Cancel"),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: const Color(0xFF161208),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () {
                              final name = nameController.text.trim().isNotEmpty
                                  ? nameController.text.trim()
                                  : guest.guestName;
                              final notes = notesController.text.trim().isNotEmpty
                                  ? notesController.text.trim()
                                  : null;

                              HapticFeedback.selectionClick();
                              service.updateGuestCheckIn(
                                id: guest.id,
                                guestName: name,
                                partySize: partySize,
                                entrance: 'Vestibule Station',
                                notes: notes,
                              );

                              Navigator.pop(ctx);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Updated check-in for $name"),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            },
                            child: const Text("Save Changes"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDeleteGuest(BuildContext context, FirebaseService service, GuestCheckInEntry guest) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Delete Guest Check-In?", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(
          "Are you sure you want to remove the check-in for '${guest.guestName}' (${guest.partySize} ${guest.partySize == 1 ? 'guest' : 'guests'}) at Vestibule Station?",
          style: GoogleFonts.inter(fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              HapticFeedback.mediumImpact();
              service.removeGuestCheckIn(guest.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Removed check-in for ${guest.guestName}"),
                  backgroundColor: AppColors.danger,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

