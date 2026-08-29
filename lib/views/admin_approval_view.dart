import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/team_member.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

class AdminApprovalView extends StatefulWidget {
  const AdminApprovalView({super.key});

  @override
  State<AdminApprovalView> createState() => _AdminApprovalViewState();
}

class _AdminApprovalViewState extends State<AdminApprovalView> {
  late TextEditingController _bulletinController;

  @override
  void initState() {
    super.initState();
    final service = Provider.of<FirebaseService>(context, listen: false);
    _bulletinController = TextEditingController(text: service.bulletinText);
  }

  @override
  void dispose() {
    _bulletinController.dispose();
    super.dispose();
  }

  int _selectedFilterIndex = 0; // 0 = Pending, 1 = All Ushers, 2 = Denied
  bool _isRefreshing = false;

  @override
  Widget build(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context);

    final List<TeamMember> displayedUsers;
    if (_selectedFilterIndex == 0) {
      displayedUsers = firebaseService.pendingUsers;
    } else if (_selectedFilterIndex == 1) {
      displayedUsers = firebaseService.liveRoster;
    } else {
      displayedUsers = firebaseService.deniedUsers;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Portal"),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(LucideIcons.refreshCw),
            tooltip: "Refresh Approvals",
            onPressed: _isRefreshing
                ? null
                : () async {
                    setState(() => _isRefreshing = true);
                    await firebaseService.refreshRoster();
                    if (mounted) {
                      setState(() => _isRefreshing = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Roster and approvals refreshed!"),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => firebaseService.refreshRoster(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bulletin Manager Section
                Text(
                  "Leadership Bulletin Broadcast",
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 10),

                DribbbleGlassContainer(
                  borderRadius: 24,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextField(
                        controller: _bulletinController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: "Enter global announcement text for all ushers...",
                        ),
                      ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerRight,
                        child: DribbbleGlowButton(
                          label: "Publish Bulletin",
                          icon: LucideIcons.send,
                          height: 46,
                          gradient: context.activeGradient,
                          onPressed: () {
                            firebaseService.updateBulletin(_bulletinController.text.trim());
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Leadership bulletin updated!")),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Approvals Header & Segmented Tabs
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Usher Approvals",
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    if (firebaseService.pendingUsers.isNotEmpty)
                      DribbblePillBadge(
                        label: "${firebaseService.pendingUsers.length} Pending",
                        color: AppColors.amber,
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Filter Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: "Pending (${firebaseService.pendingUsers.length})",
                        index: 0,
                        activeGradient: context.activeGradient,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: "All Members (${firebaseService.liveRoster.length})",
                        index: 1,
                        activeGradient: context.activeGradient,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: "Denied (${firebaseService.deniedUsers.length})",
                        index: 2,
                        activeGradient: context.activeGradient,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                displayedUsers.isEmpty
                    ? DribbbleGlassContainer(
                        borderRadius: 20,
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.userCheck,
                                size: 40,
                                color: context.textSecondaryColor.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _selectedFilterIndex == 0
                                    ? "No pending usher registrations"
                                    : _selectedFilterIndex == 2
                                        ? "No denied accounts"
                                        : "No team members found",
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: context.textSecondaryColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                icon: const Icon(LucideIcons.refreshCw, size: 16),
                                label: const Text("Refresh from Database"),
                                onPressed: () => firebaseService.refreshRoster(),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: displayedUsers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final user = displayedUsers[index];
                          final isPending = !user.approved && !user.denied;

                          return DribbbleGlassContainer(
                            borderRadius: 20,
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    gradient: user.isAdmin
                                        ? AppColors.primaryGradient
                                        : (user.approved
                                            ? const LinearGradient(colors: [Color(0xFF059669), Color(0xFF10B981)])
                                            : (user.denied
                                                ? const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFEF4444)])
                                                : context.activeGradient)),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      (user.name != null && user.name!.isNotEmpty) ? user.name![0].toUpperCase() : 'U',
                                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              user.name ?? "Usher",
                                              style: GoogleFonts.outfit(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: context.textPrimaryColor,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          if (isPending)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.amber.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: AppColors.amber.withValues(alpha: 0.5)),
                                              ),
                                              child: Text(
                                                "PENDING",
                                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.amber),
                                              ),
                                            )
                                          else if (user.approved)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.success.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                user.role?.toUpperCase() ?? "APPROVED",
                                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success),
                                              ),
                                            )
                                          else if (user.denied)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.danger.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                "DENIED",
                                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.danger),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      if (user.email != null && user.email!.isNotEmpty)
                                        Text(
                                          user.email!,
                                          style: GoogleFonts.inter(fontSize: 12, color: context.textSecondaryColor),
                                        ),
                                      if (user.phone != null && user.phone!.isNotEmpty)
                                        Text(
                                          user.phone!,
                                          style: GoogleFonts.inter(fontSize: 11, color: context.textSecondaryColor.withValues(alpha: 0.8)),
                                        ),
                                    ],
                                  ),
                                ),
                                if (!user.approved)
                                  IconButton(
                                    icon: const Icon(LucideIcons.checkCircle, color: AppColors.success, size: 26),
                                    tooltip: "Approve Usher",
                                    onPressed: () async {
                                      await firebaseService.approveUser(user.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text("${user.name ?? 'Usher'} approved!")),
                                        );
                                      }
                                    },
                                  ),
                                if (!user.denied && !user.isAdmin)
                                  IconButton(
                                    icon: const Icon(LucideIcons.xCircle, color: AppColors.danger, size: 26),
                                    tooltip: "Deny Access",
                                    onPressed: () async {
                                      await firebaseService.denyUser(user.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text("${user.name ?? 'Usher'} access denied.")),
                                        );
                                      }
                                    },
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
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int index,
    required Gradient activeGradient,
  }) {
    final isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilterIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? activeGradient : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : context.textSecondaryColor,
          ),
        ),
      ),
    );
  }
}

