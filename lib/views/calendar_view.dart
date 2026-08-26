import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/team_member.dart';
import '../models/deployment.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  String _selectedServiceFilter = 'All';
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedSunday;
  bool _sundaysOnlyFilter = false;

  final List<String> _serviceFilters = ['All', 'Sundays Only', 'Sunday Morning Service', 'Communion Service', 'Mid-week Rallies'];

  List<DateTime> _getSundaysForMonth(DateTime monthDate) {
    final sundays = <DateTime>[];
    final firstDay = DateTime(monthDate.year, monthDate.month, 1);
    final lastDay = DateTime(monthDate.year, monthDate.month + 1, 0);

    for (var day = firstDay; day.isBefore(lastDay.add(const Duration(days: 1))); day = day.add(const Duration(days: 1))) {
      if (day.weekday == DateTime.sunday) {
        sundays.add(day);
      }
    }
    return sundays;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final firebaseService = Provider.of<FirebaseService>(context);

    final sundays = _getSundaysForMonth(_focusedMonth);

    final filteredDeployments = firebaseService.deployments.where((d) {
      // Sunday Filter
      if (_selectedSunday != null) {
        final sundayStr = DateFormat('yyyy-MM-dd').format(_selectedSunday!);
        final sundayShortStr = DateFormat('MMM d, yyyy').format(_selectedSunday!);
        if (d.date != sundayStr && !d.date.contains(sundayShortStr) && !d.date.contains(DateFormat('MM/dd/yyyy').format(_selectedSunday!))) {
          // If date doesn't match selected sunday
          return false;
        }
      }

      if (_sundaysOnlyFilter || _selectedServiceFilter == 'Sundays Only') {
        if (!d.serviceType.toLowerCase().contains('sunday') && d.serviceType != 'Sunday Morning Service') {
          return false;
        }
      } else if (_selectedServiceFilter != 'All') {
        if (d.serviceType != _selectedServiceFilter) return false;
      }
      return true;
    }).toList();


    return Scaffold(
      appBar: AppBar(
        title: const Text("Duty Roster & Deployments"),
        actions: [
          if (firebaseService.deployments.isNotEmpty)
            IconButton(
              icon: const Icon(LucideIcons.trash2, color: AppColors.danger),
              tooltip: "Clear All Schedules",
              onPressed: () {
                _confirmClearAll(context, firebaseService);
              },
            ),
          IconButton(
            icon: const Icon(LucideIcons.plus),
            tooltip: "Assign Duty Station",
            onPressed: () {
              _showAddDeploymentDialog(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),

            // Sunday Roster Calendar Strip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: DribbbleGlassContainer(
                borderRadius: 22,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Calendar Month Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(LucideIcons.calendarDays, color: AppColors.accent, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              DateFormat('MMMM yyyy').format(_focusedMonth),
                              style: GoogleFonts.outfit(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            if (_selectedSunday != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: InkWell(
                                  onTap: () => setState(() => _selectedSunday = null),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          "All Sundays",
                                          style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(LucideIcons.x, size: 12, color: AppColors.primary),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(4),
                              icon: const Icon(LucideIcons.chevronLeft, size: 20),
                              onPressed: () {
                                setState(() {
                                  _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                                  _selectedSunday = null;
                                });
                              },
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(4),
                              icon: const Icon(LucideIcons.chevronRight, size: 20),
                              onPressed: () {
                                setState(() {
                                  _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                                  _selectedSunday = null;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Sundays Scrollable Horizontal Row
                    SizedBox(
                      height: 82,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: sundays.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final sundayDate = sundays[index];
                          final isSelected = _selectedSunday != null &&
                              _selectedSunday!.year == sundayDate.year &&
                              _selectedSunday!.month == sundayDate.month &&
                              _selectedSunday!.day == sundayDate.day;

                          final sundayFormattedStr = DateFormat('yyyy-MM-dd').format(sundayDate);
                          final sundayShortStr = DateFormat('MMM d, yyyy').format(sundayDate);
                          final sundayDeployments = firebaseService.deployments.where((d) {
                            return d.date == sundayFormattedStr || d.date.contains(sundayShortStr);
                          }).toList();

                          final hasLead = sundayDeployments.any((d) => d.role.toLowerCase().contains('lead') || d.role.toLowerCase().contains('head'));

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedSunday = null;
                                } else {
                                  _selectedSunday = sundayDate;
                                }
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 72,
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                              decoration: BoxDecoration(
                                gradient: isSelected ? AppColors.accentGradient : null,
                                color: isSelected
                                    ? null
                                    : (isDark ? AppColors.surfaceDark : Colors.white),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : (hasLead ? AppColors.accent.withValues(alpha: 0.5) : (isDark ? AppColors.borderDark : AppColors.borderLight)),
                                  width: hasLead && !isSelected ? 1.5 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.accent.withValues(alpha: 0.4),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    DateFormat('MMM').format(sundayDate).toUpperCase(),
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white.withValues(alpha: 0.9)
                                          : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                    ),
                                  ),
                                  Text(
                                    "${sundayDate.day}",
                                    style: GoogleFonts.outfit(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (hasLead) ...[
                                        Icon(LucideIcons.crown, size: 10, color: isSelected ? Colors.white : AppColors.sunset),
                                        const SizedBox(width: 3),
                                      ],
                                      Text(
                                        "${sundayDeployments.length} Ushers",
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? Colors.white : (sundayDeployments.isNotEmpty ? AppColors.primary : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Service Type Filter Pills
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _serviceFilters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = _serviceFilters[index];
                  final isSelected = filter == _selectedServiceFilter;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedServiceFilter = filter),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: isSelected ? context.activeGradient : null,
                        color: isSelected ? null : (isDark ? AppColors.surfaceDark : Colors.white),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected ? Colors.transparent : context.borderThemeColor,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Theme.of(context).primaryColor.withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        filter,
                        style: GoogleFonts.outfit(
                          color: isSelected ? Colors.white : context.textPrimaryColor,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 14),

            // Deployments List
            Expanded(
              child: filteredDeployments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.calendarX, size: 48, color: context.textSecondaryColor),
                          const SizedBox(height: 12),
                          Text("No deployments found", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      itemCount: filteredDeployments.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final dep = filteredDeployments[index];
                        final roleLower = dep.role.toLowerCase();
                        final isLead = roleLower.contains('lead usher') || (roleLower.contains('lead') && !roleLower.contains('head'));

                        return DribbbleGlassContainer(
                          borderRadius: 22,
                          padding: const EdgeInsets.all(20),
                          borderColor: isLead ? Theme.of(context).primaryColor : null,
                          backgroundColor: isLead
                              ? Theme.of(context).primaryColor.withValues(alpha: isDark ? 0.15 : 0.08)
                              : null,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isLead) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    gradient: context.activeGradient,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context).primaryColor.withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(LucideIcons.crown, size: 13, color: Colors.white),
                                      const SizedBox(width: 6),
                                      Text(
                                        "STATION LEAD IN CHARGE",
                                        style: GoogleFonts.outfit(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],

                              Row(
                                children: [
                                  DribbblePillBadge(
                                    label: dep.serviceType,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      Icon(LucideIcons.calendar, size: 14, color: Theme.of(context).primaryColor),
                                      const SizedBox(width: 5),
                                      Text(
                                        dep.date,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: context.textPrimaryColor,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        constraints: const BoxConstraints(),
                                        padding: EdgeInsets.zero,
                                        icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.danger),
                                        tooltip: "Remove Duty",
                                        onPressed: () => firebaseService.deleteDeployment(dep.id),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 14),

                              Row(
                                children: [
                                  Stack(
                                    children: [
                                      Container(
                                        width: isLead ? 50 : 44,
                                        height: isLead ? 50 : 44,
                                        decoration: BoxDecoration(
                                          gradient: context.activeGradient,
                                          shape: BoxShape.circle,
                                          border: isLead ? Border.all(color: Colors.white, width: 2) : null,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Theme.of(context).primaryColor.withValues(alpha: 0.45),
                                              blurRadius: isLead ? 12 : 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            dep.usherName.isNotEmpty ? dep.usherName[0] : 'U',
                                            style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.bold,
                                              fontSize: isLead ? 20 : 18,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (isLead)
                                        Positioned(
                                          right: 0,
                                          bottom: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(3),
                                            decoration: const BoxDecoration(
                                              color: AppColors.sunset,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(LucideIcons.crown, size: 10, color: Colors.white),
                                          ),
                                        ),
                                    ],
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
                                                  fontSize: isLead ? 18 : 17,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                                ),
                                              ),
                                            ),
                                            if (isLead)
                                              DribbblePillBadge(
                                                label: "LEAD",
                                                icon: LucideIcons.crown,
                                                color: AppColors.sunset,
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "${dep.usherName} • ${dep.role}",
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: isLead ? FontWeight.bold : FontWeight.normal,
                                            color: isLead
                                                ? (isDark ? AppColors.accentLight : AppColors.secondary)
                                                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 14),
                              Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                              const SizedBox(height: 12),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        dep.verified ? LucideIcons.checkCircle : LucideIcons.clock,
                                        size: 16,
                                        color: dep.verified ? AppColors.success : AppColors.amber,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        dep.verified ? "Confirmed Duty" : "Cover Requested",
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: dep.verified ? AppColors.success : AppColors.amber,
                                        ),
                                      ),
                                    ],
                                  ),
                                  InkWell(
                                    onTap: () => _showSubInDialog(context, firebaseService, dep),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(LucideIcons.userCheck, size: 13, color: AppColors.primary),
                                          const SizedBox(width: 4),
                                          Text(
                                            "Sub-In",
                                            style: GoogleFonts.outfit(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
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
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubInDialog(BuildContext context, FirebaseService firebaseService, Deployment dep) {
    final roster = firebaseService.liveRoster.isNotEmpty
        ? firebaseService.liveRoster
        : firebaseService.approvedUsers;

    TeamMember? selectedMember = roster.isNotEmpty ? roster.first : null;
    final customNameController = TextEditingController();
    String selectedRole = dep.role;

    final roleOptions = [
      'Lead Usher (Sunday Lead)',
      'Assigned Usher',
      'Head Usher',
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text("Sub-In Usher for Station", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Station: ${dep.station}", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 2),
                          Text("Currently Assigned: ${dep.usherName}", style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondaryLight)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text("Select Replacement (Sub-In):", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<TeamMember?>(
                      value: selectedMember,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(LucideIcons.userCheck, size: 18),
                      ),
                      items: [
                        ...roster.map(
                          (m) => DropdownMenuItem<TeamMember?>(
                            value: m,
                            child: Text("${m.name ?? 'Usher'} (${m.displayRole})"),
                          ),
                        ),
                        const DropdownMenuItem<TeamMember?>(
                          value: null,
                          child: Text("Custom Sub-In Name..."),
                        ),
                      ],
                      onChanged: (val) {
                        setModalState(() => selectedMember = val);
                      },
                    ),
                    if (selectedMember == null) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: customNameController,
                        decoration: const InputDecoration(
                          labelText: "Custom Sub-In Name",
                          prefixIcon: Icon(LucideIcons.userPlus, size: 18),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text("Duty Role:", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(LucideIcons.shield, size: 18),
                      ),
                      items: roleOptions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedRole = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel"),
                ),
                ElevatedButton.icon(
                  icon: const Icon(LucideIcons.userCheck, size: 16),
                  label: const Text("Confirm Sub-In"),
                  onPressed: () {
                    final subName = selectedMember != null
                        ? (selectedMember!.name ?? 'Usher')
                        : customNameController.text.trim();

                    if (subName.isEmpty) return;

                    firebaseService.subInDeployment(
                      dep.id,
                      newUsherName: subName,
                      newUsherId: selectedMember?.id,
                      newRole: selectedRole,
                    );

                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("$subName is subbed in for ${dep.usherName} at ${dep.station}!"),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getNextSundayDateString() {
    final now = DateTime.now();
    final daysUntilSunday = (DateTime.sunday - now.weekday + 7) % 7;
    final sunday = daysUntilSunday == 0 ? now : now.add(Duration(days: daysUntilSunday));
    return "${sunday.year}-${sunday.month.toString().padLeft(2, '0')}-${sunday.day.toString().padLeft(2, '0')}";
  }

  void _showAddDeploymentDialog(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);
    final roster = firebaseService.liveRoster.isNotEmpty
        ? firebaseService.liveRoster
        : firebaseService.approvedUsers;

    TeamMember? selectedMember = roster.isNotEmpty ? roster.first : null;
    final customNameController = TextEditingController();
    final customStationController = TextEditingController();
    final dateController = TextEditingController(text: _getNextSundayDateString());

    String selectedRole = (selectedMember != null && selectedMember.isLead)
        ? 'Lead Usher (Sunday Lead)'
        : 'Assigned Usher';

    final roleOptions = [
      'Lead Usher (Sunday Lead)',
      'Assigned Usher',
      'Head Usher',
    ];

    String selectedStation = 'Sanctuary (Lead Station)';
    final stations = [
      'Sanctuary (Lead Station)',
      'Vestibule/Door Greeter',
      'Sanctuary',
      'Sign/Bathrooms/Petitions',
      'WT Breakdown',
      'Custom...',
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text("Assign Duty Station", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Select Usher from User Database
                    if (roster.isNotEmpty) ...[
                      DropdownButtonFormField<TeamMember>(
                        initialValue: selectedMember,
                        decoration: const InputDecoration(
                          labelText: "Select Usher",
                          prefixIcon: Icon(LucideIcons.user, size: 18),
                        ),
                        items: roster.map((m) {
                          return DropdownMenuItem<TeamMember>(
                            value: m,
                            child: Text(
                              "${m.name ?? 'Usher'} (${m.displayRole})",
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              selectedMember = val;
                              if (val.isLead) {
                                selectedRole = 'Lead Usher (Sunday Lead)';
                                selectedStation = 'Sanctuary (Lead Station)';
                              }
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      TextField(
                        controller: customNameController,
                        decoration: const InputDecoration(
                          labelText: "Usher Name",
                          prefixIcon: Icon(LucideIcons.user, size: 18),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Manual Role / Lead Designation Selector
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(
                        labelText: "Duty Role / Lead Designation",
                        prefixIcon: Icon(LucideIcons.shieldCheck, size: 18),
                      ),
                      items: roleOptions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selectedRole = val;
                            if (val == 'Lead Usher (Sunday Lead)') {
                              selectedStation = 'Sanctuary (Lead Station)';
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Select Station
                    DropdownButtonFormField<String>(
                      initialValue: selectedStation,
                      decoration: const InputDecoration(
                        labelText: "Station Location",
                        prefixIcon: Icon(LucideIcons.mapPin, size: 18),
                      ),
                      items: stations.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedStation = val);
                      },
                    ),
                    if (selectedStation == 'Custom...') ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: customStationController,
                        decoration: const InputDecoration(
                          labelText: "Custom Station Name",
                          prefixIcon: Icon(LucideIcons.edit, size: 18),
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: dateController,
                            decoration: const InputDecoration(
                              labelText: "Duty Date (YYYY-MM-DD)",
                              prefixIcon: Icon(LucideIcons.calendar, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(LucideIcons.calendarDays, color: AppColors.primary),
                          tooltip: "Select Date",
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.tryParse(dateController.text) ?? DateTime.now(),
                              firstDate: DateTime(2025),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setModalState(() {
                                dateController.text = DateFormat('yyyy-MM-dd').format(picked);
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Upcoming Sundays Quick Chips
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Quick Pick Sunday:", style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 32,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: 4,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (context, index) {
                          final now = DateTime.now();
                          final daysUntilNextSunday = (DateTime.sunday - now.weekday + 7) % 7;
                          final nextSunday = now.add(Duration(days: daysUntilNextSunday + (index * 7)));
                          final formatted = DateFormat('yyyy-MM-dd').format(nextSunday);
                          final label = DateFormat('MMM d').format(nextSunday);

                          return InkWell(
                            onTap: () {
                              setModalState(() {
                                dateController.text = formatted;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: dateController.text == formatted ? AppColors.accent : AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "Sun $label",
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: dateController.text == formatted ? Colors.white : AppColors.primary,
                                ),
                              ),
                            ),
                          );
                        },
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
                    final usherName = selectedMember != null
                        ? (selectedMember!.name ?? 'Usher')
                        : customNameController.text.trim();
                    final usherId = selectedMember?.id;

                    final finalStation = selectedStation == 'Custom...'
                        ? customStationController.text.trim()
                        : selectedStation;

                    if (usherName.isNotEmpty && finalStation.isNotEmpty) {
                      firebaseService.addDeployment(
                        station: finalStation,
                        usherName: usherName,
                        usherId: usherId,
                        role: selectedRole,
                        date: dateController.text.trim(),
                        serviceType: _selectedServiceFilter == 'All' ? 'Sunday Morning Service' : _selectedServiceFilter,
                      );
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text("Assign Duty"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmClearAll(BuildContext context, FirebaseService firebaseService) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Clear All Schedules?", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: const Text("This will permanently delete all active schedule deployments from Firebase."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              firebaseService.clearAllDeployments();
              Navigator.pop(ctx);
            },
            child: const Text("Clear All", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

