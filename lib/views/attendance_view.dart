import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/attendance_log.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

class AttendanceView extends StatefulWidget {
  const AttendanceView({super.key});

  @override
  State<AttendanceView> createState() => _AttendanceViewState();
}

class _AttendanceViewState extends State<AttendanceView> {
  final _notesController = TextEditingController();
  final _dateController = TextEditingController(
    text: "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}",
  );

  @override
  void dispose() {
    _notesController.dispose();
    _dateController.dispose();
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final firebaseService = Provider.of<FirebaseService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Digital Headcount Tally"),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.rotateCcw),
            tooltip: "Reset Counter",
            onPressed: () {
              firebaseService.resetTallyCount();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tally Counter Hero Display Card (Dribbble Glass Ring)
              DribbbleGlassContainer(
                borderRadius: 28,
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                child: Column(
                  children: [
                    DribbblePillBadge(
                      label: "LIVE HEADCOUNT TRACKER",
                      icon: LucideIcons.binary,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: context.activeGradient,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.4),
                            blurRadius: 24,
                            spreadRadius: 2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          "${firebaseService.currentTallyCount}",
                          style: GoogleFonts.outfit(
                            fontSize: 54,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Increment / Decrement Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Decrement Button
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            firebaseService.updateTallyCount(-1);
                          },
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.danger.withValues(alpha: 0.3), width: 1.5),
                            ),
                            child: const Icon(LucideIcons.minus, color: AppColors.danger, size: 28),
                          ),
                        ),

                        const SizedBox(width: 28),

                        // Increment Button
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            firebaseService.updateTallyCount(1);
                          },
                          child: Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              gradient: context.activeGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).primaryColor.withValues(alpha: 0.45),
                                  blurRadius: 18,
                                  spreadRadius: -2,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(LucideIcons.plus, color: Colors.white, size: 36),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Quick Add Presets
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildPresetChip(context, "+5", () => firebaseService.updateTallyCount(5)),
                        const SizedBox(width: 8),
                        _buildPresetChip(context, "+10", () => firebaseService.updateTallyCount(10)),
                        const SizedBox(width: 8),
                        _buildPresetChip(context, "+25", () => firebaseService.updateTallyCount(25)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Service & Notes Inputs
              Text(
                "Service Details",
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 10),

              // Service Type Dropdown & Date Picker Row
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      value: firebaseService.activeServiceType,
                      decoration: const InputDecoration(
                        labelText: "Service Type",
                        prefixIcon: Icon(LucideIcons.church, size: 18),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Sunday Morning Service', child: Text('Sunday Morning')),
                        DropdownMenuItem(value: 'Communion Service', child: Text('Communion')),
                        DropdownMenuItem(value: 'Mid-week Rallies', child: Text('Mid-week Rallies')),
                        DropdownMenuItem(value: 'Special Event / Concert', child: Text('Special Event')),
                      ],
                      onChanged: (val) {
                        if (val != null) firebaseService.setActiveServiceType(val);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: TextField(
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
                  ),
                ],
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

              DribbbleGlowButton(
                label: "Save & Submit Headcount",
                icon: LucideIcons.check,
                onPressed: () => _submitCount(firebaseService),
                gradient: context.activeGradient,
              ),

              const SizedBox(height: 28),

              // Attendance History Header
              Text(
                "Recent Attendance Logs",
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 12),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: firebaseService.attendanceLogs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final log = firebaseService.attendanceLogs[index];
                  return DribbbleGlassContainer(
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
                                    color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                                    blurRadius: 6,
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

                        // Optional Log Notes
                        if (log.notes != null && log.notes!.trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            log.notes!.trim(),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              height: 1.45,
                              color: context.textSecondaryColor,
                            ),
                          ),
                        ],

                        const SizedBox(height: 10),
                        Text(
                          "Logged by ${log.submittedBy}",
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
      ),
    );
  }

  void _showEditAttendanceDialog(BuildContext context, FirebaseService firebaseService, AttendanceLogEntry log) {
    final countController = TextEditingController(text: log.headcount.toString());
    final dateController = TextEditingController(text: log.serviceDate);
    final notesController = TextEditingController(text: log.notes ?? '');
    String serviceType = log.serviceType;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text("Edit Attendance Log", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: countController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Headcount",
                        prefixIcon: Icon(LucideIcons.users, size: 18),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: serviceType,
                      decoration: const InputDecoration(
                        labelText: "Service Type",
                        prefixIcon: Icon(LucideIcons.church, size: 18),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Sunday Morning Service', child: Text('Sunday Morning Service')),
                        DropdownMenuItem(value: 'Communion Service', child: Text('Communion Service')),
                        DropdownMenuItem(value: 'Mid-week Rallies', child: Text('Mid-week Rallies')),
                        DropdownMenuItem(value: 'Special Event / Concert', child: Text('Special Event / Concert')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => serviceType = val);
                      },
                    ),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: "Notes",
                        prefixIcon: Icon(LucideIcons.fileText, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
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
              ],
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
    return DribbbleGlassContainer(
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      onTap: onTap,
      child: Text(
        label,
        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
      ),
    );
  }
}

