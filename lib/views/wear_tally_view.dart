import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

/// Dedicated Wear OS UI optimized specifically for Samsung Galaxy Watch and circular screens.
/// Features a pure OLED black background, rotary bezel support, haptic feedback,
/// a dedicated Submit action (Design A), and live synchronization with Firebase Firestore.
class WearTallyCounterView extends StatefulWidget {
  const WearTallyCounterView({super.key});

  @override
  State<WearTallyCounterView> createState() => _WearTallyCounterViewState();
}

class _WearTallyCounterViewState extends State<WearTallyCounterView> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  double _accumulatedScroll = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOutCubic),
    );

    // Auto-authenticate Galaxy Watch in background on launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final service = Provider.of<FirebaseService>(context, listen: false);
      service.ensureWatchAuthenticated();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _increment(FirebaseService service, int delta) {
    if (delta > 0) {
      HapticFeedback.heavyImpact();
      _pulseController.forward().then((_) => _pulseController.reverse());
    } else {
      HapticFeedback.mediumImpact();
    }
    service.updateTallyCount(delta);
  }

  void _handleRotaryScroll(PointerScrollEvent event, FirebaseService service) {
    _accumulatedScroll += event.scrollDelta.dy;
    // Each 20 units of rotary bezel turn counts as one tick
    if (_accumulatedScroll >= 20) {
      _increment(service, 1);
      _accumulatedScroll = 0;
    } else if (_accumulatedScroll <= -20) {
      _increment(service, -1);
      _accumulatedScroll = 0;
    }
  }

  Future<void> _submitCount(BuildContext context, FirebaseService service, int count) async {
    if (count <= 0 || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    HapticFeedback.heavyImpact();

    final now = DateTime.now();
    final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final profileName = service.userProfile?.name;
    final usherName = (profileName != null && profileName.isNotEmpty)
        ? '$profileName (Galaxy Watch)'
        : 'Galaxy Watch7';

    try {
      await service.ensureWatchAuthenticated();
      await service.submitAttendanceLog(
        headcount: count,
        serviceType: service.activeServiceType,
        serviceDate: dateStr,
        notes: 'Submitted directly from Samsung Galaxy Watch7',
        submittedBy: usherName,
      );

      service.resetTallyCount();

      if (!mounted) return;

      // Show success animation overlay
      _showSuccessDialog(context, count);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSuccessDialog(BuildContext context, int count) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (ctx.mounted) {
            Navigator.of(ctx).pop();
          }
        });

        return Scaffold(
          backgroundColor: Colors.black.withValues(alpha: 0.95),
          body: SafeArea(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                          border: Border.all(color: const Color(0xFF10B981), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withValues(alpha: 0.45),
                              blurRadius: 14,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            LucideIcons.check,
                            color: Color(0xFF10B981),
                            size: 26,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "SUBMITTED!",
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "Logged $count attendees\nSynced to Mobile App",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSubmitConfirmation(BuildContext context, FirebaseService service, int count) {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (modalCtx) {
        return WearSubmitConfirmationSheet(
          count: count,
          serviceType: service.activeServiceType,
          onCancel: () {
            HapticFeedback.lightImpact();
            Navigator.of(modalCtx).pop();
          },
          onConfirm: () {
            Navigator.of(modalCtx).pop();
            _submitCount(context, service, count);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context);
    final count = firebaseService.currentTallyCount;
    final primary = Theme.of(context).primaryColor;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black, // Pure OLED black for Galaxy Watch battery life
      body: Listener(
        onPointerSignal: (pointerSignal) {
          if (pointerSignal is PointerScrollEvent) {
            _handleRotaryScroll(pointerSignal, firebaseService);
          }
        },
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Title / Service Type (curved around top bezel)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "USHER TALLY",
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.0,
                            color: AppColors.accent,
                          ),
                        ),
                        Text(
                          firebaseService.activeServiceType.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: Colors.white60,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Center Big Tally Readout
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: GestureDetector(
                      onTap: () => _increment(firebaseService, 1),
                      child: Container(
                        width: size.width * 0.40,
                        height: size.width * 0.40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF161214),
                          border: Border.all(
                            color: primary.withValues(alpha: 0.8),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withValues(alpha: 0.35),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Text(
                                "$count",
                                style: GoogleFonts.outfit(
                                  fontSize: 46,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Controls Area: Increment/Decrement Row + Submit Pill Button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Row of Minus, Reset, Plus
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Minus Button
                            GestureDetector(
                              onTap: () => _increment(firebaseService, -1),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.danger.withValues(alpha: 0.2),
                                  border: Border.all(
                                    color: AppColors.danger.withValues(alpha: 0.5),
                                    width: 1.5,
                                  ),
                                ),
                                child: const Icon(
                                  LucideIcons.minus,
                                  color: AppColors.danger,
                                  size: 18,
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Quick Reset
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.vibrate();
                                firebaseService.resetTallyCount();
                              },
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white12,
                                ),
                                child: const Icon(
                                  LucideIcons.rotateCcw,
                                  color: Colors.white70,
                                  size: 13,
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Plus Button
                            GestureDetector(
                              onTap: () => _increment(firebaseService, 1),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: context.activeGradient,
                                  boxShadow: [
                                    BoxShadow(
                                      color: primary.withValues(alpha: 0.4),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  LucideIcons.plus,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // Design A: Dedicated "SUBMIT" Pill Button
                        GestureDetector(
                          onTap: count > 0
                              ? () => _showSubmitConfirmation(context, firebaseService, count)
                              : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: count > 0
                                  ? const LinearGradient(
                                      colors: [Color(0xFF059669), Color(0xFF10B981)],
                                    )
                                  : const LinearGradient(
                                      colors: [Color(0xFF232225), Color(0xFF18171A)],
                                    ),
                              boxShadow: count > 0
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                              border: Border.all(
                                color: count > 0
                                    ? const Color(0xFF34D399).withValues(alpha: 0.6)
                                    : Colors.white12,
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.send,
                                  size: 10,
                                  color: count > 0 ? Colors.white : Colors.white30,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  count > 0 ? "SUBMIT ($count)" : "SUBMIT",
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: count > 0 ? Colors.white : Colors.white30,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  ),
),
    );
  }
}

/// Dedicated Wear OS confirmation dialog sheet optimized for circular Galaxy Watch displays.
/// Implements responsive scaling and safety margins to guarantee zero pixel overflow on any watch diameter.
class WearSubmitConfirmationSheet extends StatelessWidget {
  final int count;
  final String serviceType;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const WearSubmitConfirmationSheet({
    super.key,
    required this.count,
    required this.serviceType,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Curved Header with Service Type
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "SUBMIT ATTENDANCE",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(height: 2),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 140),
                        child: Text(
                          serviceType.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white60,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Headcount Hero Box
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF181518),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.25),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "$count",
                          style: GoogleFonts.outfit(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "ATTENDEES",
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Confirmation Buttons Row: Cancel (X) & Confirm (Check)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Cancel Button
                      GestureDetector(
                        onTap: onCancel,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.danger.withValues(alpha: 0.2),
                            border: Border.all(
                              color: AppColors.danger.withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              LucideIcons.x,
                              color: AppColors.danger,
                              size: 18,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Confirm & Submit Button
                      GestureDetector(
                        onTap: onConfirm,
                        child: Container(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF059669), Color(0xFF10B981)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.5),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.check,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                "CONFIRM",
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: Colors.white,
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
            ),
          ),
        ),
      ),
    );
  }
}
