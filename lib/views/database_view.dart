import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/team_member.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

class DatabaseView extends StatefulWidget {
  const DatabaseView({super.key});

  @override
  State<DatabaseView> createState() => _DatabaseViewState();
}

class _DatabaseViewState extends State<DatabaseView> {
  String _searchQuery = '';
  String _roleFilter = 'All';

  final List<String> _roleFilters = ['All', 'Lead', 'Admin', 'Usher'];

  void _makePhoneCall(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse("tel:$cleanPhone");
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  void _sendSms(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse("sms:$cleanPhone");
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

    final allMembers = firebaseService.liveRoster.isNotEmpty
        ? firebaseService.liveRoster
        : firebaseService.approvedUsers;

    final roster = allMembers.where((u) {
      final matchesSearch = (u.name ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (u.phone ?? '').contains(_searchQuery) ||
          (u.email ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
      if (_roleFilter == 'All') return matchesSearch;
      final displayRole = u.displayRole.toLowerCase();
      final memberRole = (u.role ?? '').toLowerCase();
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
            tooltip: "Purge Ghost Users",
            onPressed: () async {
              final count = await firebaseService.purgeGhostMembers();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      count > 0
                          ? "Successfully removed $count ghost user document(s) from Firestore!"
                          : "No empty ghost users found in database!",
                    ),
                  ),
                );
              }
            },
          ),
          IconButton(
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

            // Role Filter Chips
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _roleFilters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = _roleFilters[index];
                  final isSelected = filter == _roleFilter;
                  return GestureDetector(
                    onTap: () => setState(() => _roleFilter = filter),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
                        filter,
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
              child: roster.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.users, size: 48, color: context.textSecondaryColor),
                          const SizedBox(height: 12),
                          Text(
                            allMembers.isNotEmpty
                                ? "No team members found with role '$_roleFilter'"
                                : "No team members in directory",
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          if (allMembers.isNotEmpty)
                            ElevatedButton.icon(
                              icon: const Icon(LucideIcons.rotateCcw, size: 18),
                              label: Text("Show All (${allMembers.length}) Members"),
                              onPressed: () {
                                setState(() {
                                  _roleFilter = 'All';
                                  _searchQuery = '';
                                });
                              },
                            )
                          else
                            ElevatedButton.icon(
                              icon: const Icon(LucideIcons.userPlus, size: 18),
                              label: const Text("Add First Member"),
                              onPressed: () => _showAddMemberDialog(context, firebaseService),
                            ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).size.width >= 800 ? 30 : 85),
                      itemCount: roster.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final member = roster[index];
                        final name = (member.name != null && member.name!.trim().isNotEmpty) ? member.name!.trim() : 'Usher';

                        return DribbbleGlassContainer(
                          borderRadius: 22,
                          padding: const EdgeInsets.all(16),
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
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.outfit(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: context.textPrimaryColor,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            DribbblePillBadge(
                                              label: member.role ?? "Usher",
                                              color: member.isAdmin ? Theme.of(context).primaryColor : AppColors.success,
                                            ),
                                          ],
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
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (member.phone != null && member.phone!.isNotEmpty) ...[
                                    InkWell(
                                      onTap: () => _makePhoneCall(member.phone!),
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
                                    const SizedBox(width: 10),
                                    InkWell(
                                      onTap: () => _sendSms(member.phone!),
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
                                    const Spacer(),
                                  ] else
                                    const Spacer(),
                                  IconButton(
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(6),
                                    icon: Icon(LucideIcons.edit2, color: Theme.of(context).primaryColor, size: 17),
                                    tooltip: "Edit Member",
                                    onPressed: () => _showEditMemberDialog(context, firebaseService, member),
                                  ),
                                  const SizedBox(width: 8),
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
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context, FirebaseService firebaseService) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedRole = 'Usher';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text("Add Usher to Directory", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                    decoration: const InputDecoration(
                      labelText: "Email Address",
                      prefixIcon: Icon(LucideIcons.mail, size: 18),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: "Phone Number",
                      prefixIcon: Icon(LucideIcons.phone, size: 18),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(labelText: "Role"),
                    items: const [
                      DropdownMenuItem(value: 'Usher', child: Text('Usher')),
                      DropdownMenuItem(value: 'Lead', child: Text('Lead Usher')),
                      DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                    ],
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
              ElevatedButton(
                onPressed: () {
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
            ],
          );
        },
      ),
    );
  }

  void _showEditMemberDialog(BuildContext context, FirebaseService firebaseService, TeamMember member) {
    final nameController = TextEditingController(text: member.name);
    final emailController = TextEditingController(text: member.email);
    final phoneController = TextEditingController(text: member.phone);
    String selectedRole = member.role ?? 'Usher';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text("Edit Member Details", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                    decoration: const InputDecoration(
                      labelText: "Email Address",
                      prefixIcon: Icon(LucideIcons.mail, size: 18),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: "Phone Number",
                      prefixIcon: Icon(LucideIcons.phone, size: 18),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(labelText: "Role"),
                    items: const [
                      DropdownMenuItem(value: 'Usher', child: Text('Usher')),
                      DropdownMenuItem(value: 'Lead', child: Text('Lead Usher')),
                      DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                    ],
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
              ElevatedButton(
                onPressed: () {
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
            ],
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
