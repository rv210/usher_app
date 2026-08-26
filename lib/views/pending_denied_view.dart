import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

class PendingDeniedView extends StatelessWidget {
  final bool isDenied;

  const PendingDeniedView({
    super.key,
    this.isDenied = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isDenied ? AppColors.danger.withValues(alpha: 0.15) : AppColors.warning.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDenied ? LucideIcons.userX : LucideIcons.clock,
                  color: isDenied ? AppColors.danger : AppColors.warning,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isDenied ? "Access Denied" : "Approval Pending",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isDenied
                    ? "Your account registration has been declined by an administrator. Please contact your team lead for assistance."
                    : "Your account has been submitted successfully and is currently under review by a Team Lead or Admin. Access to duty rosters and headcount logs will open as soon as approved.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.5,
                  color: context.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => firebaseService.signOut(),
                icon: const Icon(LucideIcons.logOut, size: 18),
                label: const Text("Sign Out"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
