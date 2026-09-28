import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/team_member.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

class DatabaseView extends StatefulWidget {
  final GlobalKey? addMemberKey;
  final GlobalKey? contactActionsKey;

  const DatabaseView({
    super.key,
    this.addMemberKey,
    this.contactActionsKey,
  });

  @override
  State<DatabaseView> createState() => _DatabaseViewState();
}

class _DatabaseViewState extends State<DatabaseView> {
  String _searchQuery = '';
  String _roleFilter = 'All';
  final List<String> _roleFilters = ['All', 'Admin/Lead', 'Usher'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<FirebaseService>(context, listen: false).refreshRoster();
      }
    });
  }

  void _makePhoneCall(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse("tel:$cleanPhone");
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  void _sendSms(String phoneNumber, {String? body}) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final separator = (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) ? '&' : '?';
    final uri = (body != null && body.isNotEmpty)
        ? Uri.parse("sms:$cleanPhone${separator}body=${Uri.encodeComponent(body)}")
        : Uri.parse("sms:$cleanPhone");
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final firebaseService = Provider.of<FirebaseService>(context);

    final rawMembers = firebaseService.liveRoster.isNotEmpty
        ? firebaseService.liveRoster
        : firebaseService.approvedUsers;

    // Filter out any ghost accounts and deduplicate
    final cleanMembers = rawMembers.where((u) => !FirebaseService.isGhostMember(u)).toList();
    final allMembers = FirebaseService.deduplicateMemberList(
      cleanMembers,
      currentUid: firebaseService.currentUser?.uid,
    );

    // Calculate dynamic role counts for filter pills
    final adminCount = allMembers.where((u) {
      final displayRole = u.displayRole.toLowerCase();
      final memberRole = (u.role ?? '').toLowerCase();
      return u.isAdmin ||
          u.isLead ||
          displayRole.contains('admin') ||
          displayRole.contains('lead') ||
          memberRole.contains('admin') ||
          memberRole.contains('lead');
    }).length;
    final usherCount = allMembers.length - adminCount;

    final roster = allMembers.where((u) {
      final matchesSearch = (u.name ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (u.phone ?? '').contains(_searchQuery) ||
          (u.email ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
      if (_roleFilter == 'All') return matchesSearch;
      final displayRole = u.displayRole.toLowerCase();
      final memberRole = (u.role ?? '').toLowerCase();

      final bool isAdminOrLead = u.isAdmin ||
          u.isLead ||
          displayRole.contains('admin') ||
          displayRole.contains('lead') ||
          memberRole.contains('admin') ||
          memberRole.contains('lead');

      if (_roleFilter == 'Admin/Lead' || _roleFilter == 'Admin / Lead') {
        return matchesSearch && isAdminOrLead;
      } else if (_roleFilter == 'Usher') {
        return matchesSearch && (!isAdminOrLead || displayRole.contains('usher') || memberRole.contains('usher'));
      }

      final targetRole = _roleFilter.toLowerCase();
      final matchesRole = (displayRole == targetRole) || (memberRole == targetRole);
      return matchesSearch && matchesRole;
    }).toList();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("Usher Team Directory"),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.sparkles),
            tooltip: "Purge Ghost & Duplicate Users",
            onPressed: () async {
              final count = await firebaseService.purgeGhostMembers();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      count > 0
                          ? "Successfully cleaned $count ghost/duplicate user document(s) from Firestore 'team' collection!"
                          : "No ghost or duplicate users found in 'team' collection!",
                    ),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.rotateCcw),
            tooltip: "Refresh Team Directory",
            onPressed: () => firebaseService.refreshRoster(),
          ),
          IconButton(
            key: widget.addMemberKey,
            icon: const Icon(LucideIcons.userPlus),
            tooltip: "Add Team Member",
            onPressed: () => _showAddMemberDialog(context, firebaseService),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: "Search usher by name, phone, or email...",
                  prefixIcon: const Icon(LucideIcons.search, size: 18),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(LucideIcons.x, size: 18),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                ),
              ),
            ),

            // Role Filter Chips with dynamic counts and haptics
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _roleFilters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = _roleFilters[index];
                  final isSelected = filter == _roleFilter;
                  final count = filter == 'All'
                      ? allMembers.length
                      : (filter.contains('Admin') ? adminCount : usherCount);
                  final badgeLabel = "$filter ($count)";

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _roleFilter = filter);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: isSelected ? context.activeGradient : null,
                        color: isSelected ? null : (isDark ? AppColors.surfaceDark : Colors.white),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? Colors.transparent : context.borderThemeColor,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Theme.of(context).primaryColor.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        badgeLabel,
                        style: GoogleFonts.outfit(
                          color: isSelected ? Colors.white : context.textPrimaryColor,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Member Roster List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => firebaseService.refreshRoster(),
                child: roster.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * (allMembers.isEmpty ? 0.08 : 0.15)),
                          Center(
                            child: allMembers.isNotEmpty
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(LucideIcons.users, size: 48, color: context.textSecondaryColor),
                                      const SizedBox(height: 12),
                                      Text(
                                        "No team members found with role '$_roleFilter'",
                                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 12),
                                      ElevatedButton.icon(
                                        icon: const Icon(LucideIcons.rotateCcw, size: 18),
                                        label: Text("Show All (${allMembers.length}) Members"),
                                        onPressed: () {
                                          setState(() {
                                            _roleFilter = 'All';
                                            _searchQuery = '';
                                          });
                                        },
                                      ),
                                    ],
                                  )
                                : Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    child: DribbbleGlassContainer(
                                      borderRadius: 24,
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 64,
                                            height: 64,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: context.activeGradient,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Theme.of(context).primaryColor.withValues(alpha: 0.35),
                                                  blurRadius: 16,
                                                  offset: const Offset(0, 6),
                                                ),
                                              ],
                                            ),
                                            child: const Center(
                                              child: Icon(LucideIcons.users, size: 32, color: Colors.white),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            "No Team Members Found",
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            "There are currently no team members in this directory view. Tap refresh or add a new team member below.",
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              height: 1.45,
                                              color: context.textSecondaryColor,
                                            ),
                                          ),
                                          const SizedBox(height: 22),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              OutlinedButton.icon(
                                                icon: const Icon(LucideIcons.rotateCcw, size: 16),
                                                label: const Text("Refresh"),
                                                style: OutlinedButton.styleFrom(
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                ),
                                                onPressed: () => firebaseService.refreshRoster(),
                                              ),
                                              const SizedBox(width: 12),
                                              ElevatedButton.icon(
                                                icon: const Icon(LucideIcons.userPlus, size: 16),
                                                label: const Text("Add Team Member"),
                                                style: ElevatedButton.styleFrom(
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                                ),
                                                onPressed: () => _showAddMemberDialog(context, firebaseService),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      )
                    : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).size.width >= 800 ? 30 : 85),
                      itemCount: roster.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final member = roster[index];
                        final name = (member.name != null && member.name!.trim().isNotEmpty) ? member.name!.trim() : 'Usher';

                        return DribbbleGlassContainer(
                          borderRadius: 22,
                          padding: const EdgeInsets.all(16),
                          onTap: () => _showQuickContactSheet(context, firebaseService, member),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
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
                                          fontWeight: FontWeight.bold,
                                          fontSize: 19,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.outfit(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: context.textPrimaryColor,
                                            height: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Builder(
                                          builder: (context) {
                                            final isLeader = member.isAdmin ||
                                                member.isLead ||
                                                (member.role?.toLowerCase().contains('admin') == true) ||
                                                (member.role?.toLowerCase().contains('lead') == true);
                                            final isScheduled = firebaseService.isMemberOnSchedule(member);
                                            return Wrap(
                                              spacing: 6,
                                              runSpacing: 4,
                                              crossAxisAlignment: WrapCrossAlignment.center,
                                              children: [
                                                DribbblePillBadge(
                                                  label: isScheduled ? "On Duty" : "Off Duty",
                                                  color: isScheduled ? AppColors.success : const Color(0xFF64748B),
                                                  icon: isScheduled ? LucideIcons.circleCheck : LucideIcons.circleSlash,
                                                ),
                                                DribbblePillBadge(
                                                  label: isLeader ? "Admin/Lead" : (member.role ?? "Usher"),
                                                  color: isLeader ? Theme.of(context).primaryColor : AppColors.success,
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          (member.phone != null && member.phone!.isNotEmpty)
                                              ? "${member.phone}${(member.email != null && member.email!.isNotEmpty) ? ' • ${member.email}' : ''}"
                                              : (member.email ?? "No contact info"),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: context.textSecondaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
                              const SizedBox(height: 8),
                              Row(
                                key: index == 0 ? widget.contactActionsKey : null,
                                children: [
                                  Expanded(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      physics: const BouncingScrollPhysics(),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (member.phone != null && member.phone!.isNotEmpty) ...[
                                            InkWell(
                                              onTap: () {
                                                HapticFeedback.lightImpact();
                                                _makePhoneCall(member.phone!);
                                              },
                                              borderRadius: BorderRadius.circular(10),
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                child: Row(
                                                  children: [
                                                    const Icon(LucideIcons.phone, color: AppColors.success, size: 15),
                                                    const SizedBox(width: 4),
                                                    Text("Call", style: GoogleFonts.inter(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.bold)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            InkWell(
                                              onTap: () {
                                                HapticFeedback.lightImpact();
                                                _sendSms(member.phone!);
                                              },
                                              borderRadius: BorderRadius.circular(10),
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                child: Row(
                                                  children: [
                                                    Icon(LucideIcons.messageSquare, color: Theme.of(context).colorScheme.secondary, size: 15),
                                                    const SizedBox(width: 4),
                                                    Text("SMS", style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                          ],
                                          InkWell(
                                            onTap: () => _showQuickContactSheet(context, firebaseService, member),
                                            borderRadius: BorderRadius.circular(10),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              child: Row(
                                                children: [
                                                  Icon(LucideIcons.sparkles, color: Theme.of(context).primaryColor, size: 14),
                                                  const SizedBox(width: 4),
                                                  Text("Actions", style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(6),
                                        icon: Icon(LucideIcons.edit2, color: Theme.of(context).primaryColor, size: 17),
                                        tooltip: "Edit Member",
                                        onPressed: () => _showEditMemberDialog(context, firebaseService, member),
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(6),
                                        icon: const Icon(LucideIcons.trash2, color: AppColors.danger, size: 17),
                                        tooltip: "Remove Member",
                                        onPressed: () => _confirmDeleteMember(context, firebaseService, member.id, name),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickContactSheet(BuildContext context, FirebaseService firebaseService, TeamMember member) {
    HapticFeedback.lightImpact();
    final name = (member.name != null && member.name!.trim().isNotEmpty) ? member.name!.trim() : 'Usher';
    final isLeader = member.isAdmin ||
        member.isLead ||
        (member.role?.toLowerCase().contains('admin') == true) ||
        (member.role?.toLowerCase().contains('lead') == true);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: Theme.of(ctx).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 28,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: 28,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Pull Handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: Theme.of(ctx).dividerColor.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Header with Avatar & Details
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: context.activeGradient,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'U',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: context.textPrimaryColor,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Builder(
                              builder: (context) {
                                final isScheduled = firebaseService.isMemberOnSchedule(member);
                                return Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    DribbblePillBadge(
                                      label: isScheduled ? "On Duty" : "Off Duty",
                                      color: isScheduled ? AppColors.success : const Color(0xFF64748B),
                                      icon: isScheduled ? LucideIcons.circleCheck : LucideIcons.circleSlash,
                                    ),
                                    DribbblePillBadge(
                                      label: isLeader ? "Admin/Lead" : (member.role ?? "Usher"),
                                      color: isLeader ? Theme.of(context).primaryColor : AppColors.success,
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 4),
                            Builder(
                              builder: (context) {
                                final memberDep = firebaseService.getMemberDeployment(member);
                                if (memberDep != null) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Text(
                                      "Assigned Post: ${memberDep.station} • ${memberDep.role}",
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                            Text(
                              member.phone ?? member.email ?? "No contact info",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Direct Call Action
                  if (member.phone != null && member.phone!.isNotEmpty) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(LucideIcons.phoneCall, color: AppColors.success, size: 20),
                      ),
                      title: Text("Call ${member.phone}", style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15)),
                      subtitle: Text("Direct cellular voice call", style: GoogleFonts.inter(fontSize: 12)),
                      trailing: const Icon(LucideIcons.chevronRight, size: 16),
                      onTap: () {
                        Navigator.pop(ctx);
                        _makePhoneCall(member.phone!);
                      },
                    ),
                    const Divider(height: 1),

                    // SMS Quick Templates
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(LucideIcons.messageSquare, color: Theme.of(context).primaryColor, size: 20),
                      ),
                      title: Text("Send Ministry SMS", style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15)),
                      subtitle: Text("Instant church service templates", style: GoogleFonts.inter(fontSize: 12)),
                      children: [
                        _buildSmsTemplateTile(
                          ctx,
                          member.phone!,
                          "Reminder: Usher Duty this Sunday",
                          "Hi $name, reminding you of your upcoming Usher duty this Sunday at 9:30 AM. See you at briefing!",
                        ),
                        _buildSmsTemplateTile(
                          ctx,
                          member.phone!,
                          "Shift Coverage Request",
                          "Hi $name, are you available to cover an usher station shift for this upcoming service?",
                        ),
                        _buildSmsTemplateTile(
                          ctx,
                          member.phone!,
                          "General Team Message",
                          "Hi $name, just following up regarding the Usher Ministry team schedule.",
                        ),
                      ],
                    ),
                    const Divider(height: 1),
                  ],

                  // Copy Contact Info
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(LucideIcons.copy, color: Color(0xFFF59E0B), size: 20),
                    ),
                    title: Text("Copy Contact Details", style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15)),
                    subtitle: Text("Name, phone, and email to clipboard", style: GoogleFonts.inter(fontSize: 12)),
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      final contactStr = "$name\nPhone: ${member.phone ?? 'N/A'}\nEmail: ${member.email ?? 'N/A'}\nRole: ${member.displayRole}";
                      Clipboard.setData(ClipboardData(text: contactStr));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Copied contact details for $name!"),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),

                  // Edit Member
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(LucideIcons.edit3, color: Theme.of(context).primaryColor, size: 20),
                    ),
                    title: Text("Edit Profile & Station Role", style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15)),
                    subtitle: Text("Update role, name, phone, or email", style: GoogleFonts.inter(fontSize: 12)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showEditMemberDialog(context, firebaseService, member);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSmsTemplateTile(BuildContext ctx, String phone, String title, String body) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.only(left: 48, right: 8, bottom: 4),
      title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13.5)),
      subtitle: Text(body, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 11.5)),
      trailing: const Icon(LucideIcons.send, size: 14),
      onTap: () {
        Navigator.pop(ctx);
        _sendSms(phone, body: body);
      },
    );
  }

  void _showAddMemberDialog(BuildContext context, FirebaseService firebaseService) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedRole = 'Usher';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
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
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 28,
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
                    Center(
                    child: Container(
                      width: 44,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
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
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(LucideIcons.userPlus, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Add Usher to Directory",
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            Text(
                              "Enroll team member with roster role & phone",
                              style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
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
                      labelText: "Full Name",
                      prefixIcon: Icon(LucideIcons.user, size: 18),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: "Email Address",
                      prefixIcon: Icon(LucideIcons.mail, size: 18),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: "Phone Number",
                      prefixIcon: Icon(LucideIcons.phone, size: 18),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: selectedRole,
                    decoration: const InputDecoration(labelText: "Role"),
                    items: const [
                      DropdownMenuItem(value: 'Usher', child: Text('Usher')),
                      DropdownMenuItem(value: 'Admin/Lead', child: Text('Admin/Lead')),
                      DropdownMenuItem(value: 'Lead', child: Text('Team Lead')),
                      DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedRole = val);
                    },
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
                            if (nameController.text.trim().isNotEmpty) {
                              firebaseService.addTeamMember(
                                name: nameController.text.trim(),
                                email: emailController.text.trim(),
                                phone: phoneController.text.trim(),
                                role: selectedRole,
                              );
                              Navigator.pop(ctx);
                            }
                          },
                          child: const Text("Add Member"),
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

  void _showEditMemberDialog(BuildContext context, FirebaseService firebaseService, TeamMember member) {
    final nameController = TextEditingController(text: member.name);
    final emailController = TextEditingController(text: member.email);
    final phoneController = TextEditingController(text: member.phone);
    final validRoles = ['Usher', 'Admin/Lead', 'Lead', 'Admin'];
    String selectedRole = validRoles.contains(member.role)
        ? member.role!
        : (member.isAdmin || member.isLead ? 'Admin/Lead' : 'Usher');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
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
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 28,
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
                    Center(
                    child: Container(
                      width: 44,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
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
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(LucideIcons.edit3, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Edit Member Details",
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            Text(
                              "Update role assignment or contact information",
                              style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
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
                      labelText: "Full Name",
                      prefixIcon: Icon(LucideIcons.user, size: 18),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: "Email Address",
                      prefixIcon: Icon(LucideIcons.mail, size: 18),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: "Phone Number",
                      prefixIcon: Icon(LucideIcons.phone, size: 18),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: selectedRole,
                    decoration: const InputDecoration(labelText: "Role"),
                    items: const [
                      DropdownMenuItem(value: 'Usher', child: Text('Usher')),
                      DropdownMenuItem(value: 'Admin/Lead', child: Text('Admin/Lead')),
                      DropdownMenuItem(value: 'Lead', child: Text('Team Lead')),
                      DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedRole = val);
                    },
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
                            if (nameController.text.trim().isNotEmpty) {
                              firebaseService.updateTeamMember(
                                TeamMember(
                                  id: member.id,
                                  name: nameController.text.trim(),
                                  email: emailController.text.trim(),
                                  phone: phoneController.text.trim(),
                                  role: selectedRole,
                                  approved: member.approved,
                                  denied: member.denied,
                                ),
                              );
                              Navigator.pop(ctx);
                            }
                          },
                          child: const Text("Save"),
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

  void _confirmDeleteMember(BuildContext context, FirebaseService firebaseService, String userId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Remove $name?", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to remove $name from the Firestore Team Directory?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              firebaseService.deleteTeamMember(userId);
              Navigator.pop(ctx);
            },
            child: const Text("Remove", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
