import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Defines a single spotlight step in the Coachmark Tour.
class CoachmarkStep {
  final GlobalKey targetKey;
  final String title;
  final String description;
  final IconData icon;
  final String badgeText;
  final int? targetTabIndex;
  final bool isCircle;
  final Color? accentColor;
  final double? scrollAlignment;

  const CoachmarkStep({
    required this.targetKey,
    required this.title,
    required this.description,
    required this.icon,
    required this.badgeText,
    this.targetTabIndex,
    this.isCircle = false,
    this.accentColor,
    this.scrollAlignment,
  });
}

/// A whimsical and friendly Chalkboard / Whiteboard Sketch Coachmark Tour.
///
/// Features:
/// 1. Dark chalkboard scrim with clean spotlight cutout of the live app widget.
/// 2. White hand-drawn sketch border around the spotlighted widget.
/// 3. Playful animated yellow sketch robot guide mascot that hovers and gestures.
/// 4. Hand-drawn curved chalk arrows pointing from notes directly to UI elements.
/// 5. Sketched chalk oval "Tap to dismiss" button.
/// 6. Chalkboard footer: "QUICK TUTORIAL (X of Y) Tap to continue".
/// 7. Full-screen tap-to-advance gesture.
class AppCoachmarkTour extends StatefulWidget {
  final List<CoachmarkStep> steps;
  final int initialStepIndex;
  final ValueChanged<int>? onStepChanged;
  final VoidCallback onComplete;
  final VoidCallback? onSkip;

  const AppCoachmarkTour({
    super.key,
    required this.steps,
    this.initialStepIndex = 0,
    this.onStepChanged,
    required this.onComplete,
    this.onSkip,
  });

  static const String prefTourCompletedKey = 'has_completed_spotlight_tour_v1';

  static Future<void> markCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefTourCompletedKey, true);
    } catch (_) {}
  }

  static Future<bool> shouldShowTour() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return !(prefs.getBool(prefTourCompletedKey) ?? false);
    } catch (_) {
      return false;
    }
  }

  static Future<void> resetTour() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(prefTourCompletedKey);
    } catch (_) {}
  }

  @override
  State<AppCoachmarkTour> createState() => _AppCoachmarkTourState();
}

class _AppCoachmarkTourState extends State<AppCoachmarkTour>
    with TickerProviderStateMixin {
  late int _currentStep;
  late AnimationController _floatController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  Rect? _targetRect;
  bool _calculatingRect = true;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStepIndex.clamp(0, widget.steps.length - 1);

    // Floating bob animation for the guide robot mascot and chalk elements
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    // Fade animation between steps
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateTargetRect();
      _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _updateTargetRect() {
    if (!mounted || widget.steps.isEmpty) return;

    final step = widget.steps[_currentStep];
    final targetContext = step.targetKey.currentContext;

    if (targetContext != null) {
      bool needsScroll = false;
      try {
        final scrollable = Scrollable.maybeOf(targetContext);
        if (scrollable != null) {
          needsScroll = true;
          Scrollable.ensureVisible(
            targetContext,
            alignment: step.scrollAlignment ?? 0.25,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
          );
        }
      } catch (_) {}

      if (needsScroll) {
        // Wait for scroll animation (280ms) + a layout frame (50ms) to fully settle
        // before measuring the widget's global position.
        Future.delayed(const Duration(milliseconds: 360), () {
          if (!mounted) return;
          _measureAndSetRect(step);
        });
        return;
      }

      _measureAndSetRect(step);
    } else {
      // Fallback retry if widget context isn't available yet
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;
        final retryContext = step.targetKey.currentContext;
        if (retryContext != null && retryContext.mounted) {
          try {
            final scrollable = Scrollable.maybeOf(retryContext);
            if (scrollable != null && retryContext.mounted) {
              Scrollable.ensureVisible(
                retryContext,
                alignment: step.scrollAlignment ?? 0.25,
                duration: const Duration(milliseconds: 280),
              );
            }
          } catch (_) {}

          Future.delayed(const Duration(milliseconds: 360), () {
            if (!mounted) return;
            _measureAndSetRect(step);
          });
        }
      });
    }
  }

  /// Reads the current global position of the step's target widget and
  /// updates [_targetRect]. Must be called AFTER any scroll has settled.
  void _measureAndSetRect(CoachmarkStep step) {
    if (!mounted) return;
    final ctx = step.targetKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize && box.size.width > 0 && box.size.height > 0) {
      final pos = box.localToGlobal(Offset.zero);
      setState(() {
        _targetRect = pos & box.size;
        _calculatingRect = false;
      });
    }
  }



  void _goToStep(int index) {
    if (index < 0 || index >= widget.steps.length) return;
    HapticFeedback.lightImpact();

    _fadeController.reverse().then((_) {
      if (!mounted) return;
      setState(() {
        _currentStep = index;
        _calculatingRect = true;
      });
      widget.onStepChanged?.call(index);

      Future.delayed(const Duration(milliseconds: 80), () {
        if (!mounted) return;
        _updateTargetRect();
        _fadeController.forward(from: 0.0);
      });
    });
  }

  void _nextStep() {
    if (_currentStep < widget.steps.length - 1) {
      _goToStep(_currentStep + 1);
    } else {
      _finishTour();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    }
  }

  void _finishTour() {
    HapticFeedback.mediumImpact();
    AppCoachmarkTour.markCompleted();
    widget.onComplete();
  }

  void _skipTour() {
    HapticFeedback.selectionClick();
    AppCoachmarkTour.markCompleted();
    if (widget.onSkip != null) {
      widget.onSkip!();
    } else {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final mediaPadding = MediaQuery.of(context).padding;
    final step = widget.steps[_currentStep];

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // 1. Frosted Obsidian Scrim with Neon Laser Spotlight Cutout
          if (_targetRect != null)
            AnimatedBuilder(
              animation: _floatController,
              builder: (context, _) {
                return CustomPaint(
                  size: screenSize,
                  painter: _StudioSpotlightPainter(
                    targetRect: _targetRect!,
                    isCircle: step.isCircle,
                    pulseProgress: _floatController.value,
                    accentColor: step.accentColor ?? const Color(0xFF0057FF),
                  ),
                );
              },
            )
          else
            Container(color: const Color(0xDC060913)),

          // 2. Full-screen Tap-to-Advance Gesture
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _nextStep,
              child: const SizedBox.expand(),
            ),
          ),

          // 3. Spotlight Target Tap Hitbox
          if (_targetRect != null)
            Positioned(
              left: _targetRect!.left - 8,
              top: _targetRect!.top - 8,
              width: _targetRect!.width + 16,
              height: _targetRect!.height + 16,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _nextStep,
              ),
            ),

          // 4. Figma Studio Step Card & Target Beacon
          if (_targetRect != null && !_calculatingRect)
            FadeTransition(
              opacity: _fadeAnimation,
              child: _buildStudioCardWithPointer(context, screenSize, mediaPadding, step),
            ),

          // 5. Studio "Tap to dismiss" button
          _buildTapToDismissButton(context, mediaPadding),
        ],
      ),
    );
  }

  /// Builds the Figma Studio step card and precision laser pointer to target.
  Widget _buildStudioCardWithPointer(
    BuildContext context,
    Size screenSize,
    EdgeInsets mediaPadding,
    CoachmarkStep step,
  ) {
    final targetCenter = _targetRect!.center;
    final double navBarClearance = 115.0 + mediaPadding.bottom;

    final double safeTop = mediaPadding.top + 65.0;
    final double safeBottom = screenSize.height - navBarClearance;
    final double safeHeight = safeBottom - safeTop;

    final bool isTargetInNavBar = _targetRect!.bottom > screenSize.height - navBarClearance;
    final double safeMidY = safeTop + safeHeight / 2;
    final bool placeAbove = isTargetInNavBar || targetCenter.dy > safeMidY;

    final double cardWidth = math.min(screenSize.width - 32.0, 400.0);
    final double cardHeight = 230.0;
    final double cardLeft =
        ((screenSize.width - cardWidth) / 2).clamp(16.0, screenSize.width - cardWidth - 16.0);
    final double cardTop =
        (safeTop + (safeHeight - cardHeight) / 2).clamp(safeTop, safeBottom - cardHeight);

    final Offset pointerTarget = placeAbove
        ? Offset(targetCenter.dx.clamp(_targetRect!.left + 14.0, _targetRect!.right - 14.0), _targetRect!.top - 6.0)
        : Offset(targetCenter.dx.clamp(_targetRect!.left + 14.0, _targetRect!.right - 14.0), _targetRect!.bottom + 6.0);

    final Offset pointerSource = placeAbove
        ? Offset(
            (targetCenter.dx).clamp(cardLeft + 40.0, cardLeft + cardWidth - 40.0),
            cardTop + cardHeight,
          )
        : Offset(
            (targetCenter.dx).clamp(cardLeft + 40.0, cardLeft + cardWidth - 40.0),
            cardTop - 4.0,
          );

    return Stack(
      children: [
        // Precision laser pointer line connecting Card to Target
        CustomPaint(
          size: screenSize,
          painter: _StudioLaserPointerPainter(
            start: pointerSource,
            end: pointerTarget,
            accentColor: step.accentColor ?? const Color(0xFF0057FF),
            pulseProgress: _floatController.value,
          ),
        ),

        // Floating Studio Step Card
        Positioned(
          left: cardLeft,
          top: cardTop,
          width: cardWidth,
          child: AnimatedBuilder(
            animation: _floatController,
            builder: (context, child) {
              final bob = math.sin(_floatController.value * math.pi * 2) * 3.5;
              return Transform.translate(
                offset: Offset(0, bob),
                child: child,
              );
            },
            child: _buildStudioStepCard(step, placeAbove),
          ),
        ),
      ],
    );
  }

  /// Interactive Behance x Figma Studio Onboarding Card
  Widget _buildStudioStepCard(CoachmarkStep step, bool isPointingDown) {
    final accentColor = step.accentColor ?? const Color(0xFF0057FF);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xF20F172A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.45),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 32,
            spreadRadius: 4,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: accentColor.withValues(alpha: 0.22),
            blurRadius: 20,
            spreadRadius: -2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step pill badge & progress at top
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.40),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(step.icon, size: 13, color: accentColor),
                    const SizedBox(width: 6),
                    Text(
                      step.badgeText.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.9,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Interactive step dots
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_currentStep + 1}/${widget.steps.length}',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Avatar / Mascot & Typography
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stylized usher mascot in modern glass halo container
              Container(
                width: 58,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: const ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  child: CustomPaint(
                    painter: _UsherMascotPainter(),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title and Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      step.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      step.description,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.88),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Dynamic Stepper dots indicator row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.steps.length, (idx) {
              final isCurrent = idx == _currentStep;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                height: 5,
                width: isCurrent ? 18 : 5,
                decoration: BoxDecoration(
                  color: isCurrent ? accentColor : Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.5),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              );
            }),
          ),

          const SizedBox(height: 14),

          // Action buttons: Previous & Next / Finish
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_currentStep > 0)
                GestureDetector(
                  onTap: _prevStep,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.arrowLeft, size: 14, color: Colors.white70),
                        const SizedBox(width: 5),
                        Text(
                          'Previous',
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                GestureDetector(
                  onTap: _skipTour,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Text(
                      'Skip Tour',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),

              GestureDetector(
                onTap: _nextStep,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accentColor, const Color(0xFFA259FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.45),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _currentStep == widget.steps.length - 1 ? 'Finish Tour' : 'Next Step',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        _currentStep == widget.steps.length - 1 ? LucideIcons.checkCheck : LucideIcons.arrowRight,
                        size: 14,
                        color: Colors.white,
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
  }

  Widget _buildTapToDismissButton(BuildContext context, EdgeInsets mediaPadding) {
    return Positioned(
      bottom: mediaPadding.bottom + 16,
      left: 0,
      right: 0,
      child: Center(
        child: TextButton.icon(
          onPressed: _skipTour,
          icon: const Icon(LucideIcons.x, size: 14, color: Color(0x99FFFFFF)),
          label: Text(
            "Tap to exit tour",
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0x99FFFFFF),
              fontWeight: FontWeight.w500,
            ),
          ),
          style: TextButton.styleFrom(
            backgroundColor: const Color(0x33000000),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      ),
    );
  }
}

/// Painter for the dark frosted obsidian scrim with neon laser halo aperture cutout
/// framing the active spotlighted widget.
class _StudioSpotlightPainter extends CustomPainter {
  final Rect targetRect;
  final bool isCircle;
  final double pulseProgress;
  final Color accentColor;

  const _StudioSpotlightPainter({
    required this.targetRect,
    required this.isCircle,
    required this.pulseProgress,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;

    // 1. Dark obsidian studio scrim with BlendMode.clear cutout
    canvas.saveLayer(bounds, Paint());

    canvas.drawRect(
      bounds,
      Paint()..color = const Color(0xE0060913),
    );

    final clearPaint = Paint()..blendMode = BlendMode.clear;

    if (isCircle) {
      final radius = (math.max(targetRect.width, targetRect.height) / 2) + 6.0;
      canvas.drawCircle(targetRect.center, radius, clearPaint);
    } else {
      final rrect = RRect.fromRectAndRadius(
        targetRect.inflate(6.0),
        const Radius.circular(16.0),
      );
      canvas.drawRRect(rrect, clearPaint);
    }

    canvas.restore();

    // 2. High-Tech Neon Laser Ring with dynamic pulse
    final pulse = math.sin(pulseProgress * math.pi * 2);
    final glowColor = accentColor.withValues(alpha: 0.35 + 0.20 * pulse);
    final coreColor = Colors.white.withValues(alpha: 0.90);

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0 + pulse * 1.5
      ..color = glowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..color = coreColor;

    if (isCircle) {
      final baseRadius = (math.max(targetRect.width, targetRect.height) / 2) + 6.0;
      canvas.drawCircle(targetRect.center, baseRadius, glowPaint);
      canvas.drawCircle(targetRect.center, baseRadius, strokePaint);
    } else {
      final baseRRect = RRect.fromRectAndRadius(
        targetRect.inflate(6.0),
        const Radius.circular(16.0),
      );
      canvas.drawRRect(baseRRect, glowPaint);
      canvas.drawRRect(baseRRect, strokePaint);
    }

    // 3. Pulsing Beacon Anchor Dot on the target edge
    final beaconPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    final beaconHalo = Paint()
      ..color = accentColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    final beaconCenter = Offset(targetRect.center.dx, targetRect.top - 6.0);
    canvas.drawCircle(beaconCenter, 6.0 + pulse * 2.0, beaconHalo);
    canvas.drawCircle(beaconCenter, 3.5, beaconPaint);
  }

  @override
  bool shouldRepaint(covariant _StudioSpotlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.pulseProgress != pulseProgress ||
        oldDelegate.isCircle != isCircle ||
        oldDelegate.accentColor != accentColor;
  }
}

/// Painter for the minimalist precision laser connector line
class _StudioLaserPointerPainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final Color accentColor;
  final double pulseProgress;

  const _StudioLaserPointerPainter({
    required this.start,
    required this.end,
    required this.accentColor,
    required this.pulseProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final midY = (start.dy + end.dy) / 2;
    final controlPoint = Offset(start.dx, midY);

    final path = Path();
    path.moveTo(start.dx, start.dy);
    path.quadraticBezierTo(controlPoint.dx, controlPoint.dy, end.dx, end.dy);

    final glowPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);

    // Endpoint target dot
    canvas.drawCircle(end, 4.0, Paint()..color = accentColor);
    canvas.drawCircle(end, 2.0, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _StudioLaserPointerPainter oldDelegate) {
    return oldDelegate.start != start ||
        oldDelegate.end != end ||
        oldDelegate.pulseProgress != pulseProgress ||
        oldDelegate.accentColor != accentColor;
  }
}

/// Custom Vector Painter for the friendly Church Usher Guide Mascot.
///
/// Features:
/// - Neat stylish hair & warm welcoming smiling face with expressive eyes
/// - Crisp white collared shirt with burgundy/gold tie
/// - Smart navy usher suit jacket with gold "USHER" lapel badge
/// - Classic church white usher gloves
/// - Left hand holding church bulletin / program booklet
/// - Right hand politely gesturing "Right this way!" with white glove pointing toward the feature
/// - Tailored dress slacks and polished shoes
class _UsherMascotPainter extends CustomPainter {
  const _UsherMascotPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 82.0;
    canvas.save();
    canvas.scale(scale, scale);

    // Palette
    const skinColor = Color(0xFFFBBF24); // Warm golden skin
    const skinBlush = Color(0xFFF472B6);
    const hairColor = Color(0xFF292524); // Dark brown
    const hairHighlight = Color(0xFF44403C);
    const suitNavy = Color(0xFF1E293B); // Smart navy suit
    const suitLapel = Color(0xFF0F172A);
    const shirtWhite = Color(0xFFFFFFFF);
    const tieBurgundy = Color(0xFF991B1B);
    const badgeGold = Color(0xFFF59E0B);
    const badgeGoldLight = Color(0xFFFEF08A);
    const gloveWhite = Color(0xFFFFFFFF);
    const inkDark = Color(0xFF0F172A);

    final inkOutlinePaint = Paint()
      ..color = inkDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final thinInkPaint = Paint()
      ..color = inkDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;

    // 1. LEGS & DRESS SHOES (Behind body)
    // Left leg
    final leftLeg = Path()
      ..moveTo(30, 68)
      ..lineTo(28, 83)
      ..lineTo(35, 83)
      ..lineTo(36, 68)
      ..close();
    canvas.drawPath(leftLeg, Paint()..color = suitNavy);
    canvas.drawPath(leftLeg, inkOutlinePaint);

    // Left dress shoe
    final leftShoe = RRect.fromRectAndRadius(
      const Rect.fromLTWH(24, 82, 13, 7),
      const Radius.circular(3),
    );
    canvas.drawRRect(leftShoe, Paint()..color = inkDark);
    canvas.drawRRect(leftShoe, inkOutlinePaint);
    canvas.drawLine(const Offset(26, 84), const Offset(31, 84), Paint()..color = Colors.white54..strokeWidth = 1.0);

    // Right leg
    final rightLeg = Path()
      ..moveTo(45, 68)
      ..lineTo(46, 83)
      ..lineTo(53, 83)
      ..lineTo(51, 68)
      ..close();
    canvas.drawPath(rightLeg, Paint()..color = suitNavy);
    canvas.drawPath(rightLeg, inkOutlinePaint);

    // Right dress shoe
    final rightShoe = RRect.fromRectAndRadius(
      const Rect.fromLTWH(45, 82, 13, 7),
      const Radius.circular(3),
    );
    canvas.drawRRect(rightShoe, Paint()..color = inkDark);
    canvas.drawRRect(rightShoe, inkOutlinePaint);
    canvas.drawLine(const Offset(48, 84), const Offset(53, 84), Paint()..color = Colors.white54..strokeWidth = 1.0);

    // 2. SUIT JACKET TORSO
    final torsoRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(22, 34, 38, 36),
      const Radius.circular(9),
    );
    canvas.drawRRect(torsoRect, Paint()..color = suitNavy);
    canvas.drawRRect(torsoRect, inkOutlinePaint);

    // White Dress Shirt V-Neck insert
    final shirtV = Path()
      ..moveTo(33, 34)
      ..lineTo(49, 34)
      ..lineTo(44, 52)
      ..lineTo(38, 52)
      ..close();
    canvas.drawPath(shirtV, Paint()..color = shirtWhite);
    canvas.drawPath(shirtV, thinInkPaint);

    // Collar flaps
    final leftCollar = Path()
      ..moveTo(32, 34)
      ..lineTo(37, 43)
      ..lineTo(39, 34)
      ..close();
    canvas.drawPath(leftCollar, Paint()..color = shirtWhite);
    canvas.drawPath(leftCollar, thinInkPaint);

    final rightCollar = Path()
      ..moveTo(50, 34)
      ..lineTo(45, 43)
      ..lineTo(43, 34)
      ..close();
    canvas.drawPath(rightCollar, Paint()..color = shirtWhite);
    canvas.drawPath(rightCollar, thinInkPaint);

    // Burgundy / Gold Necktie
    final tie = Path()
      ..moveTo(39.5, 36)
      ..lineTo(42.5, 36)
      ..lineTo(43, 44)
      ..lineTo(41, 56)
      ..lineTo(39, 44)
      ..close();
    canvas.drawPath(tie, Paint()..color = tieBurgundy);
    canvas.drawPath(tie, thinInkPaint);
    canvas.drawRect(const Rect.fromLTWH(39.5, 35, 3, 3), Paint()..color = const Color(0xFF7F1D1D));

    // Suit Lapels
    final leftLapel = Path()
      ..moveTo(27, 34)
      ..lineTo(34, 46)
      ..lineTo(34, 55)
      ..lineTo(25, 42)
      ..close();
    canvas.drawPath(leftLapel, Paint()..color = suitLapel);
    canvas.drawPath(leftLapel, thinInkPaint);

    final rightLapel = Path()
      ..moveTo(55, 34)
      ..lineTo(48, 46)
      ..lineTo(48, 55)
      ..lineTo(57, 42)
      ..close();
    canvas.drawPath(rightLapel, Paint()..color = suitLapel);
    canvas.drawPath(rightLapel, thinInkPaint);

    // Gold "USHER" Badge on right chest lapel
    final badgeRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(26, 48, 9, 5.5),
      const Radius.circular(2),
    );
    canvas.drawRRect(badgeRect, Paint()..color = badgeGold);
    canvas.drawRRect(badgeRect, thinInkPaint);
    canvas.drawLine(const Offset(27.5, 50.5), const Offset(33.5, 50.5), Paint()..color = badgeGoldLight..strokeWidth = 1.2);

    // Gold jacket button
    canvas.drawCircle(const Offset(41, 59), 1.6, Paint()..color = badgeGold);
    canvas.drawCircle(const Offset(41, 59), 1.6, thinInkPaint);

    // 3. LEFT ARM & CHURCH BULLETIN
    // Left Arm holding bulletin
    final leftArm = Path()
      ..moveTo(23, 38)
      ..quadraticBezierTo(12, 45, 14, 55)
      ..quadraticBezierTo(18, 62, 25, 58);
    canvas.drawPath(
      leftArm,
      Paint()
        ..color = suitNavy
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(leftArm, inkOutlinePaint);

    // Church Bulletin / Program Booklet in Left Hand
    final bulletin = RRect.fromRectAndRadius(
      const Rect.fromLTWH(9, 49, 13, 18),
      const Radius.circular(2.5),
    );
    canvas.drawRRect(bulletin, Paint()..color = const Color(0xFFF8FAFC));
    canvas.drawRRect(bulletin, thinInkPaint);
    // Bulletin header / cross motif
    canvas.drawLine(const Offset(15.5, 52), const Offset(15.5, 58), Paint()..color = tieBurgundy..strokeWidth = 1.4);
    canvas.drawLine(const Offset(13, 54), const Offset(18, 54), Paint()..color = tieBurgundy..strokeWidth = 1.4);
    // Text lines on bulletin
    canvas.drawLine(const Offset(12, 60), const Offset(19, 60), thinInkPaint);
    canvas.drawLine(const Offset(12, 63), const Offset(18, 63), thinInkPaint);

    // Left White Usher Glove holding the booklet
    final leftGlove = Rect.fromCircle(center: const Offset(19, 58), radius: 3.5);
    canvas.drawOval(leftGlove, Paint()..color = gloveWhite);
    canvas.drawOval(leftGlove, thinInkPaint);

    // 4. RIGHT ARM & POINTING WHITE GLOVE
    // Right Arm (extending welcomingly to point towards the card)
    final rightArm = Path()
      ..moveTo(57, 38)
      ..quadraticBezierTo(71, 41, 75, 36);
    canvas.drawPath(
      rightArm,
      Paint()
        ..color = suitNavy
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(rightArm, inkOutlinePaint);

    // White cuff
    final cuff = RRect.fromRectAndRadius(
      const Rect.fromLTWH(71, 33, 4, 7),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(cuff, Paint()..color = shirtWhite);
    canvas.drawRRect(cuff, thinInkPaint);

    // White Glove Hand
    final rightGlove = Rect.fromCircle(center: const Offset(76, 36), radius: 3.8);
    canvas.drawOval(rightGlove, Paint()..color = gloveWhite);
    canvas.drawOval(rightGlove, inkOutlinePaint);

    // White Glove Extended Index Finger (Pointing directly at the text!)
    final fingerPath = Path()
      ..moveTo(77, 35)
      ..lineTo(82, 33);
    canvas.drawPath(
      fingerPath,
      Paint()
        ..color = gloveWhite
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      fingerPath,
      Paint()
        ..color = inkDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );

    // 5. NECK
    canvas.drawRect(const Rect.fromLTWH(37, 28, 8, 7), Paint()..color = skinColor);
    canvas.drawLine(const Offset(37, 28), const Offset(37, 34), thinInkPaint);
    canvas.drawLine(const Offset(45, 28), const Offset(45, 34), thinInkPaint);

    // 6. HEAD & FACE
    final head = RRect.fromRectAndRadius(
      const Rect.fromLTWH(24, 8, 34, 25),
      const Radius.circular(12),
    );
    canvas.drawRRect(head, Paint()..color = skinColor);
    canvas.drawRRect(head, inkOutlinePaint);

    // Ears
    final leftEar = RRect.fromRectAndRadius(const Rect.fromLTWH(21, 16, 4, 7), const Radius.circular(2));
    canvas.drawRRect(leftEar, Paint()..color = skinColor);
    canvas.drawRRect(leftEar, inkOutlinePaint);

    final rightEar = RRect.fromRectAndRadius(const Rect.fromLTWH(57, 16, 4, 7), const Radius.circular(2));
    canvas.drawRRect(rightEar, Paint()..color = skinColor);
    canvas.drawRRect(rightEar, inkOutlinePaint);

    // Cute Rosy Cheeks
    canvas.drawCircle(const Offset(30, 24), 2.5, Paint()..color = skinBlush.withValues(alpha: 0.5));
    canvas.drawCircle(const Offset(52, 24), 2.5, Paint()..color = skinBlush.withValues(alpha: 0.5));

    // Expressive Eyes
    final leftEye = Rect.fromCircle(center: const Offset(33, 19), radius: 3.5);
    final rightEye = Rect.fromCircle(center: const Offset(49, 19), radius: 3.5);
    canvas.drawOval(leftEye, Paint()..color = inkDark);
    canvas.drawOval(rightEye, Paint()..color = inkDark);

    // Eye Specular Highlights
    canvas.drawCircle(const Offset(32, 18), 1.2, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(48, 18), 1.2, Paint()..color = Colors.white);

    // Eyebrows
    final leftBrow = Path()..moveTo(30, 14)..quadraticBezierTo(33, 12, 36, 14);
    canvas.drawPath(leftBrow, thinInkPaint);
    final rightBrow = Path()..moveTo(46, 14)..quadraticBezierTo(49, 12, 52, 14);
    canvas.drawPath(rightBrow, thinInkPaint);

    // Welcoming Smile
    final mouth = Path()..moveTo(37, 24)..quadraticBezierTo(41, 28, 45, 24);
    canvas.drawPath(
      mouth,
      Paint()
        ..color = inkDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );

    // 7. NEAT USHER HAIR / COMB-OVER
    final hair = Path()
      ..moveTo(23, 15)
      ..quadraticBezierTo(23, 6, 41, 6)
      ..quadraticBezierTo(59, 6, 59, 15)
      ..quadraticBezierTo(54, 11, 48, 11)
      ..quadraticBezierTo(42, 13, 34, 11)
      ..quadraticBezierTo(28, 12, 23, 15)
      ..close();
    canvas.drawPath(hair, Paint()..color = hairColor);
    canvas.drawPath(hair, inkOutlinePaint);

    // Hair Swoop / Parting highlight
    final hairPart = Path()
      ..moveTo(30, 8)
      ..quadraticBezierTo(40, 8, 47, 10);
    canvas.drawPath(
      hairPart,
      Paint()
        ..color = hairHighlight
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
