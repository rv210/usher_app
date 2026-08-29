import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/training_module.dart';
import '../theme/app_theme.dart';

class UsheringTrainingView extends StatefulWidget {
  const UsheringTrainingView({super.key});

  @override
  State<UsheringTrainingView> createState() => _UsheringTrainingViewState();
}

class _UsheringTrainingViewState extends State<UsheringTrainingView> {
  final Set<int> _expandedIndices = {};

  void _toggleExpanded(int index) {
    setState(() {
      if (_expandedIndices.contains(index)) {
        _expandedIndices.remove(index);
      } else {
        _expandedIndices.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ushering 101")),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: context.activeGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: -2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(LucideIcons.graduationCap, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Ushering 101",
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "by $usheringTrainingAuthor",
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              "Training Modules",
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),

            // Module List
            ...List.generate(usheringTrainingModules.length, (index) {
              final module = usheringTrainingModules[index];
              final isExpanded = _expandedIndices.contains(index);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DribbbleGlassContainer(
                  borderRadius: 20,
                  padding: const EdgeInsets.all(18),
                  onTap: () => _toggleExpanded(index),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: context.activeGradient,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              "${index + 1}",
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  module.title,
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: context.textPrimaryColor),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  module.summary,
                                  style: GoogleFonts.inter(fontSize: 12.5, color: context.textSecondaryColor),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                            color: context.textSecondaryColor,
                            size: 20,
                          ),
                        ],
                      ),
                      if (isExpanded) ...[
                        const SizedBox(height: 14),
                        Container(height: 1, color: context.borderThemeColor),
                        const SizedBox(height: 14),
                        Text(
                          module.content,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            height: 1.5,
                            fontStyle: FontStyle.italic,
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
