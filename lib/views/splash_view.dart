import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

class DribbbleSplashScreen extends StatefulWidget {
  const DribbbleSplashScreen({super.key});

  @override
  State<DribbbleSplashScreen> createState() => _DribbbleSplashScreenState();
}

class _DribbbleSplashScreenState extends State<DribbbleSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _imageOpacity;

  bool _imageReady = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.3, end: 0.9).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _imageOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precache the image so it renders immediately on first frame
    precacheImage(
      const AssetImage('assets/images/splash_screen.png'),
      context,
    ).then((_) {
      if (mounted) setState(() => _imageReady = true);
    }).catchError((_) {
      // If image fails, still mark as ready — fallback gradient shows
      if (mounted) setState(() => _imageReady = true);
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context);
    final styleTheme = firebaseService.activeStyleTheme;
    final themeConfig =
        AppThemePresets.configs[styleTheme] ?? AppThemePresets.configs[AppStyleTheme.burgundy]!;
    final primaryColor = themeConfig.primary;

    return Scaffold(
      backgroundColor: const Color(0xFF090A0D),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fallback gradient — shows instantly while image decodes
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0D0A06),
                  Color(0xFF090A0D),
                  Color(0xFF0A0806),
                ],
              ),
            ),
          ),

          // Cinematic artwork — fades in once precached
          if (_imageReady)
            AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 300),
              child: Image.asset(
                'assets/images/splash_screen.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),

          // Pulsing radiant amber halo glow over the emblem
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Center(
                child: Container(
                  width: 230,
                  height: 230,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFB300)
                            .withValues(alpha: _pulseAnimation.value * 0.35),
                        blurRadius: 80,
                        spreadRadius: 20,
                      ),
                      BoxShadow(
                        color: primaryColor
                            .withValues(alpha: _pulseAnimation.value * 0.25),
                        blurRadius: 120,
                        spreadRadius: 30,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Shimmering golden progress bar at bottom
          Positioned(
            left: 40,
            right: 40,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 28),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    height: 3,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFFFD54F),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
