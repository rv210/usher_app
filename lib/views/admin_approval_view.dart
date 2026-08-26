import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final firebaseService = Provider.of<FirebaseService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Portal"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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

              // Pending Approvals Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Pending Usher Approvals",
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  DribbblePillBadge(
                    label: "${firebaseService.pendingUsers.length} Pending",
                    color: AppColors.amber,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              firebaseService.pendingUsers.isEmpty
                  ? DribbbleGlassContainer(
                      borderRadius: 20,
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          "No pending user approvals at this time",
                          style: GoogleFonts.inter(color: context.textSecondaryColor),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: firebaseService.pendingUsers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final user = firebaseService.pendingUsers[index];
                        return DribbbleGlassContainer(
                          borderRadius: 20,
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: context.activeGradient,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    (user.name != null && user.name!.isNotEmpty) ? user.name![0] : 'U',
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.name ?? "Usher",
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: context.textPrimaryColor,
                                      ),
                                    ),
                                    Text(
                                      user.email ?? user.phone ?? "Pending Member",
                                      style: GoogleFonts.inter(fontSize: 12, color: context.textSecondaryColor),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(LucideIcons.checkCircle, color: AppColors.success, size: 24),
                                onPressed: () => firebaseService.approveUser(user.id),
                              ),
                              IconButton(
                                icon: const Icon(LucideIcons.xCircle, color: AppColors.danger, size: 24),
                                onPressed: () => firebaseService.denyUser(user.id),
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
}

