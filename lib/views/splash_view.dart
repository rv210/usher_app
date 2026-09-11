import 'package:flutter/material.dart';

class BehanceSplashScreen extends StatefulWidget {
  const BehanceSplashScreen({super.key});

  @override
  State<BehanceSplashScreen> createState() => _BehanceSplashScreenState();
}

class _BehanceSplashScreenState extends State<BehanceSplashScreen> {
  bool _imageReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(
      const AssetImage('assets/images/splash_screen.png'),
      context,
    ).then((_) {
      if (mounted) setState(() => _imageReady = true);
    }).catchError((_) {
      if (mounted) setState(() => _imageReady = true);
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  Color(0xFF090D18),
                  Color(0xFF090A0D),
                  Color(0xFF0C0E14),
                ],
              ),
            ),
          ),

          // Cinematic artwork — fades in smoothly once precached
          AnimatedOpacity(
            opacity: _imageReady ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 350),
            child: Image.asset(
              'assets/images/splash_screen.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),

          // Subtle gold progress indicator at bottom
          Positioned(
            left: 48,
            right: 48,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    height: 3,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFD4AF37),
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

// Backward Compatibility Alias
typedef DribbbleSplashScreen = BehanceSplashScreen;
