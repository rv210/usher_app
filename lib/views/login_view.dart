import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

class LoginView extends StatefulWidget {
  final String initialMode; // 'login' or 'register'

  const LoginView({
    super.key,
    this.initialMode = 'login',
  });

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late bool _isRegister;
  late bool _showLanding;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _ministryController = TextEditingController(text: 'Guardians of the Gate');

  final _smsCodeController = TextEditingController();

  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  bool _usePhoneLogin = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _rememberMe = true;
  bool _agreeToTerms = true;
  String? _errorMessage;

  bool _unlockAttempting = false;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()..onTap = () => _showTermsOfService(context);
    _privacyRecognizer = TapGestureRecognizer()..onTap = () => _showPrivacyPolicy(context);
    _isRegister = widget.initialMode == 'register';
    _showLanding = widget.initialMode != 'register' && widget.initialMode != 'login_form';
  }

  FirebaseService? _firebaseService;
  String _biometricLabel = "Biometric";
  IconData _biometricIcon = LucideIcons.fingerprint;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/images/login_bg.png'), context).catchError((_) {});
    _firebaseService = Provider.of<FirebaseService>(context, listen: false);

    _firebaseService!.getBiometricTypeLabel().then((label) {
      if (mounted) {
        setState(() {
          _biometricLabel = label;
          _biometricIcon = label == "Face ID" ? LucideIcons.scanFace : LucideIcons.fingerprint;
        });
      }
    });

    _firebaseService!.getBiometricCredentials().then((creds) {
      if (mounted && creds != null && creds['email'] != null) {
        if (_emailController.text.isEmpty) {
          _emailController.text = creds['email']!;
        }
      }
    });
  }

  Future<void> _attemptBiometricUnlock() async {
    if (!mounted || _unlockAttempting) return;
    setState(() {
      _unlockAttempting = true;
      _errorMessage = null;
    });

    final success = await _firebaseService!.loginWithBiometrics();

    if (!mounted) return;
    setState(() {
      _unlockAttempting = false;
      if (!success) {
        _errorMessage = "$_biometricLabel verification unsuccessful. If you haven't signed in yet, please sign in with your email and password once to link $_biometricLabel.";
      } else {
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
      }
    });
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    _firebaseService?.cancelPhoneVerification();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _confirmPasswordController.dispose();
    _ministryController.dispose();
    _smsCodeController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (!mounted) return;
    setState(() => _errorMessage = null);
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);

    if (!_isRegister && _usePhoneLogin && firebaseService.phoneCodeSent) {
      // Verify SMS code
      final smsCode = _smsCodeController.text.trim();
      if (smsCode.isEmpty) {
        if (!mounted) return;
        setState(() => _errorMessage = "Please enter the 6-digit security code received via SMS.");
        return;
      }

      try {
        await firebaseService.verifyPhoneSecurityCode(smsCode);
        if (mounted) {
          await _checkAndPromptFingerprint(firebaseService);
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _errorMessage = e.toString().replaceAll(RegExp(r'\[.*?\]'), '').replaceAll('Exception: ', '').trim());
      }
      return;
    }

    if (_isRegister) {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final phone = _phoneController.text.trim();
      final password = _passwordController.text.trim();
      final confirmPassword = _confirmPasswordController.text.trim();

      if (name.isEmpty) {
        setState(() => _errorMessage = "Please enter your full name.");
        return;
      }
      if (email.isEmpty || !email.contains('@')) {
        setState(() => _errorMessage = "Please enter a valid email address.");
        return;
      }
      if (phone.isEmpty) {
        setState(() => _errorMessage = "Please enter your phone number.");
        return;
      }
      if (password.length < 6) {
        setState(() => _errorMessage = "Password must be at least 6 characters.");
        return;
      }
      if (password != confirmPassword) {
        setState(() => _errorMessage = "Passwords do not match. Please re-enter.");
        return;
      }
      if (!_agreeToTerms) {
        setState(() => _errorMessage = "Please accept the Terms of Service and Privacy Policy.");
        return;
      }

      try {
        await firebaseService.signUp(
          email,
          password,
          name,
          phone,
        );
        await firebaseService.saveBiometricCredentials(email, password);
        if (mounted) {
          await _checkAndPromptFingerprint(firebaseService);
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _errorMessage = "Registration failed: ${e.toString().replaceAll(RegExp(r'\[.*?\]'), '').replaceAll('Exception: ', '').trim()}");
      }
      return;
    }

    // Standard Sign In (Email or Phone Number)
    final input = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (input.isEmpty) {
      setState(() => _errorMessage = "Please enter your email or phone number.");
      return;
    }

    // Check if input is a phone number without '@'
    final digitsOnly = input.replaceAll(RegExp(r'[^\d]'), '');
    final isPhoneOnly = !input.contains('@') && digitsOnly.length >= 7;

    if (isPhoneOnly) {
      if (password.isEmpty) {
        // Allow passwordless phone SMS authentication for users and testers
        try {
          setState(() {
            _usePhoneLogin = true;
            _errorMessage = null;
          });
          await firebaseService.sendPhoneSecurityCode(input);
        } catch (e) {
          if (!mounted) return;
          setState(() => _errorMessage = e.toString().replaceAll('Exception: ', '').trim());
        }
        return;
      }
      // Look up the account email linked to this phone number, then sign in
      // using standard email+password. This ensures 2FA (if enabled) is properly
      // triggered — the raw phone auth SMS path bypassed the 2FA challenge entirely.
      try {
        final profile = await firebaseService.findProfileByPhone(input);
        if (profile != null && (profile.email?.contains('@') ?? false)) {
          final success = await firebaseService.signIn(profile.email!, password);
          if (!success) return; // 2FA SMS challenge displayed — wait for code
          await firebaseService.saveBiometricCredentials(profile.email!, password);
          if (mounted) await _checkAndPromptFingerprint(firebaseService);
        } else {
          // If no linked email found, initiate direct phone SMS sign-in
          try {
            setState(() {
              _usePhoneLogin = true;
              _errorMessage = null;
            });
            await firebaseService.sendPhoneSecurityCode(input);
          } catch (e) {
            setState(() => _errorMessage = e.toString().replaceAll('Exception: ', '').trim());
          }
        }
        return;
      } catch (e) {
        if (!mounted) return;
        setState(() => _errorMessage = e.toString().replaceAll(RegExp(r'\[.*?\]'), '').replaceAll('Exception: ', '').trim());
        return;
      }
    }

    if (password.isEmpty) {
      setState(() => _errorMessage = "Please enter your password.");
      return;
    }

    try {
      final success = await firebaseService.signIn(input, password);
      if (!success) {
        // 2FA SMS challenge required, stay on view for SMS input
        return;
      }

      // Save credentials securely in Keystore for fast biometric unlock
      await firebaseService.saveBiometricCredentials(input, password);

      if (mounted) {
        await _checkAndPromptFingerprint(firebaseService);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = "Authentication failed: ${e.toString().replaceAll(RegExp(r'\[.*?\]'), '').replaceAll('Exception: ', '').trim()}");
    }
  }

  Future<void> _checkAndPromptFingerprint(FirebaseService firebaseService) async {
    final available = await firebaseService.isBiometricAvailable();
    if (!mounted) return;

    if (!available || firebaseService.biometricEnabled) {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      return;
    }

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: BoxDecoration(
          color: Theme.of(ctx).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: context.activeGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(ctx).primaryColor.withValues(alpha: 0.4),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    _biometricIcon,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Activate $_biometricLabel Sign In?",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: ctx.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Enable $_biometricLabel for fast, secure 1-tap unlock next time you open the app.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.45,
                  color: ctx.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(ctx).primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
                icon: Icon(_biometricIcon, size: 20),
                label: Text(
                  "Activate $_biometricLabel",
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  final success = await firebaseService.authenticateBiometrics(
                    reason: "Authenticate with $_biometricLabel to activate quick sign-in",
                  );
                  if (success) {
                    await firebaseService.setBiometricEnabled(true);
                    final email = _emailController.text.trim();
                    final pass = _passwordController.text.trim();
                    if (email.isNotEmpty) {
                      await firebaseService.saveBiometricCredentials(email, pass.isNotEmpty ? pass : null);
                    }
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("✅ $_biometricLabel unlock activated successfully!"),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  }
                  if (mounted && Navigator.canPop(context)) {
                    Navigator.of(context).pop();
                  }
                },
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (mounted && Navigator.canPop(context)) {
                    Navigator.of(context).pop();
                  }
                },
                child: Text(
                  "No Thanks, Maybe Later",
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: ctx.textSecondaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (mounted && Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context);

    // Two-Step SMS Verification Challenge
    if (firebaseService.pendingTwoFactor) {
      return _buildTwoFactorScreen(context, firebaseService);
    }

    if (_showLanding) {
      return _buildLandingView(context, firebaseService);
    }

    if (_isRegister) {
      return _buildCreateAccountView(context, firebaseService);
    }

    return _buildSignInView(context, firebaseService);
  }

  Widget _buildSignInView(BuildContext context, FirebaseService firebaseService) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF090D16) : const Color(0xFFF5F7FA);
    final fieldBg = isDark ? const Color(0xFF131926) : Colors.white;
    final fieldBorder = isDark ? const Color(0xFF243046) : const Color(0xFFDDE2EA);
    final iconColor = isDark ? const Color(0xFF7E8B9F) : const Color(0xFF8899AA);
    final hintColor = isDark ? const Color(0xFF5E6B80) : const Color(0xFFADB5BD);
    final labelColor = isDark ? Colors.white : const Color(0xFF1A2233);
    final subtitleColor = isDark ? const Color(0xFF8E9BAE) : const Color(0xFF5A6475);
    final checkboxBorder = isDark ? const Color(0xFF3B4860) : const Color(0xFFBBCAD8);
    final dividerColor = isDark ? const Color(0xFF243046) : const Color(0xFFDDE2EA);
    final biometricBg = isDark ? const Color(0xFF131926) : Colors.white;
    final biometricBorder = isDark ? const Color(0xFF243046) : const Color(0xFFDDE2EA);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: isDark ? Colors.white : const Color(0xFF1A2233), size: 24),
          tooltip: "Back to Welcome",
          onPressed: () {
            HapticFeedback.lightImpact();
            setState(() {
              _showLanding = true;
              _errorMessage = null;
            });
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cathedral / App Logo
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE5BC6A).withValues(alpha: 0.28),
                            blurRadius: 18,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: const Color(0xFFE5BC6A).withValues(alpha: 0.5), width: 1.5),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/app_icon.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "GUARDIANS OF THE GATE",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.2,
                        color: const Color(0xFFE5BC6A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "USHER APP",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3.5,
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              Text(
                "Sign In",
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: labelColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Welcome back! Please sign in to continue.",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: subtitleColor,
                ),
              ),

              const SizedBox(height: 20),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.alertTriangle, color: AppColors.danger, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.inter(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (_usePhoneLogin && firebaseService.phoneCodeSent) ...[
                Container(
                  decoration: BoxDecoration(
                    color: fieldBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: fieldBorder, width: 1),
                    boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: TextField(
                    controller: _smsCodeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    style: GoogleFonts.outfit(color: labelColor, fontSize: 20, letterSpacing: 6, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      counterText: "",
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      prefixIcon: Icon(LucideIcons.messageSquare, color: iconColor, size: 18),
                      hintText: "000000",
                      hintStyle: GoogleFonts.outfit(color: hintColor, fontSize: 18, letterSpacing: 4),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      firebaseService.cancelPhoneVerification();
                      _smsCodeController.clear();
                      setState(() {
                        _usePhoneLogin = false;
                        _errorMessage = null;
                      });
                    },
                    child: Text(
                      "Wrong number? Start over",
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFE5BC6A),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                // Email or Phone Number
                Container(
                  decoration: BoxDecoration(
                    color: fieldBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: fieldBorder, width: 1),
                    boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.inter(color: labelColor, fontSize: 14),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      prefixIcon: Icon(LucideIcons.mail, color: iconColor, size: 18),
                      hintText: "Email or Phone Number",
                      hintStyle: GoogleFonts.inter(color: hintColor, fontSize: 14),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Password
                Container(
                  decoration: BoxDecoration(
                    color: fieldBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: fieldBorder, width: 1),
                    boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    style: GoogleFonts.inter(color: labelColor, fontSize: 14),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      prefixIcon: Icon(LucideIcons.lock, color: iconColor, size: 18),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showPassword ? LucideIcons.eyeOff : LucideIcons.eye,
                          color: iconColor,
                          size: 18,
                        ),
                        onPressed: () => setState(() => _showPassword = !_showPassword),
                      ),
                      hintText: "Password",
                      hintStyle: GoogleFonts.inter(color: hintColor, fontSize: 14),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Remember me & Forgot password
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: Checkbox(
                            value: _rememberMe,
                            activeColor: const Color(0xFFE5BC6A),
                            checkColor: const Color(0xFF161208),
                            side: BorderSide(color: checkboxBorder, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (val) => setState(() => _rememberMe = val ?? true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Remember me",
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _showForgotPasswordDialog(context, firebaseService),
                      child: Text(
                        "Forgot password?",
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFE5BC6A),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 22),

              // Sign In Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(27),
                  onTap: firebaseService.authLoading ? null : _handleSubmit,
                  child: Ink(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE5BC6A), Color(0xFFC79540)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(27),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFC79540).withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: firebaseService.authLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF161208)),
                            )
                          : Text(
                              _usePhoneLogin && firebaseService.phoneCodeSent ? "Verify & Sign In" : "Sign In",
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF161208),
                                letterSpacing: 0.3,
                              ),
                            ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Divider: "────── or ──────"
              Row(
                children: [
                  Expanded(child: Divider(color: dividerColor, thickness: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "or",
                      style: GoogleFonts.inter(color: iconColor, fontSize: 13),
                    ),
                  ),
                  Expanded(child: Divider(color: dividerColor, thickness: 1)),
                ],
              ),

              const SizedBox(height: 20),

              // Biometric Sign In button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(27),
                  onTap: _unlockAttempting ? null : _attemptBiometricUnlock,
                  child: Ink(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      color: biometricBg,
                      borderRadius: BorderRadius.circular(27),
                      border: Border.all(color: biometricBorder, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _unlockAttempting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE5BC6A)),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _biometricIcon,
                                  size: 22,
                                  color: const Color(0xFFE5BC6A),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  "Sign in with $_biometricLabel",
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: labelColor,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Register footer link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: subtitleColor,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _isRegister = true;
                        _errorMessage = null;
                      });
                    },
                    child: Text(
                      "Register",
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFE5BC6A),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateAccountView(BuildContext context, FirebaseService firebaseService) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Color(0xFF1E2432), size: 24),
          tooltip: "Back to Sign In",
          onPressed: () {
            HapticFeedback.lightImpact();
            setState(() {
              _isRegister = false;
              _errorMessage = null;
            });
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Create Account",
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E2432),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Join the team and help us make everyone feel at home.",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF6B7280),
                ),
              ),

              const SizedBox(height: 24),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.alertTriangle, color: AppColors.danger, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.inter(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Full Name
              _buildLightInputField(
                controller: _nameController,
                icon: LucideIcons.user,
                hintText: "Full Name",
                keyboardType: TextInputType.name,
              ),

              const SizedBox(height: 14),

              // Email Address
              _buildLightInputField(
                controller: _emailController,
                icon: LucideIcons.mail,
                hintText: "Email Address",
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 14),

              // Phone Number
              _buildLightInputField(
                controller: _phoneController,
                icon: LucideIcons.phone,
                hintText: "Phone Number",
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 14),

              // Password
              _buildLightInputField(
                controller: _passwordController,
                icon: LucideIcons.lock,
                hintText: "Password",
                isPassword: true,
                showPassword: _showPassword,
                onTogglePassword: () => setState(() => _showPassword = !_showPassword),
              ),

              const SizedBox(height: 14),

              // Confirm Password
              _buildLightInputField(
                controller: _confirmPasswordController,
                icon: LucideIcons.lock,
                hintText: "Confirm Password",
                isPassword: true,
                showPassword: _showConfirmPassword,
                onTogglePassword: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
              ),

              const SizedBox(height: 18),

              // Terms Agreement Checkbox
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: Checkbox(
                      value: _agreeToTerms,
                      activeColor: const Color(0xFFC79540),
                      side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      onChanged: (val) => setState(() => _agreeToTerms = val ?? true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        text: "I agree to the ",
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF4B5563)),
                        children: [
                          TextSpan(
                            text: "Terms of Service",
                            recognizer: _termsRecognizer,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFC79540),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          const TextSpan(text: " and "),
                          TextSpan(
                            text: "Privacy Policy",
                            recognizer: _privacyRecognizer,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFC79540),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Create Account Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(27),
                  onTap: firebaseService.authLoading ? null : _handleSubmit,
                  child: Ink(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE5BC6A), Color(0xFFC79540)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(27),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFC79540).withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: firebaseService.authLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF161208)),
                            )
                          : Text(
                              "Create Account",
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF161208),
                                letterSpacing: 0.3,
                              ),
                            ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Sign In Footer link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account? ",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _isRegister = false;
                        _errorMessage = null;
                      });
                    },
                    child: Text(
                      "Sign In",
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFC79540),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLightInputField({
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool showPassword = false,
    VoidCallback? onTogglePassword,
    IconData? suffixIcon,
    VoidCallback? onTapSuffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !showPassword,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(color: const Color(0xFF1E2432), fontSize: 14),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          prefixIcon: Icon(icon, color: const Color(0xFF4B5563), size: 18),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    showPassword ? LucideIcons.eyeOff : LucideIcons.eye,
                    color: const Color(0xFF6B7280),
                    size: 18,
                  ),
                  onPressed: onTogglePassword,
                )
              : (suffixIcon != null
                  ? IconButton(
                      icon: Icon(suffixIcon, color: const Color(0xFF6B7280), size: 18),
                      onPressed: onTapSuffix,
                    )
                  : null),
          hintText: hintText,
          hintStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 14),
        ),
      ),
    );
  }

  void _showTermsOfService(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC79540).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.fileText, color: Color(0xFFC79540), size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Terms of Service",
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E2432),
                                ),
                              ),
                              Text(
                                "Last Updated: September 2026",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.x, size: 20, color: Color(0xFF64748B)),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFF1F5F9), height: 1),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildLegalClause(
                            number: "1",
                            title: "Acceptance of Terms",
                            content:
                                "By registering for or utilizing the Church Usher Application (\"Usher App\"), you agree to be bound by these Terms of Service and all related church ministry protocols and codes of conduct.",
                          ),
                          _buildLegalClause(
                            number: "2",
                            title: "Intended Ministry Purpose",
                            content:
                                "This platform is provided exclusively for church ushers, ministry coordinators, and pastoral staff to facilitate station assignments (Main Sanctuary, Vestibule, Signs/Bathroom, Petitions), interactive supply checklists, and congregation attendance headcounts.",
                          ),
                          _buildLegalClause(
                            number: "3",
                            title: "Account Integrity & Security",
                            content:
                                "You are responsible for safeguarding your login credentials. Accurate personal information (full name, email, and phone number) must be provided for team authentication and operational security notifications.",
                          ),
                          _buildLegalClause(
                            number: "4",
                            title: "Ministry Communications",
                            content:
                                "Active account holders consent to receive vital service rosters, station sub-in alerts, emergency broadcast notices, and verification codes via push notification and operational messaging.",
                          ),
                          _buildLegalClause(
                            number: "5",
                            title: "Administrative Oversight",
                            content:
                                "Ministry roles (Usher, Lead, Admin) are maintained by church leadership. Church administrators retain the prerogative to approve, modify, or revoke system permissions in accordance with ministry guidelines.",
                          ),
                          _buildLegalClause(
                            number: "6",
                            title: "Limitation of Liability",
                            content:
                                "The application is provided \"as is\" without warranty of any kind. The ministry is not liable for carrier SMS delivery delays, local device outages, or schedule miscommunications.",
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC79540),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: Text("I Understand & Agree", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.shieldCheck, color: Color(0xFF2563EB), size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Privacy Policy",
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E2432),
                                ),
                              ),
                              Text(
                                "Last Updated: September 2026",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.x, size: 20, color: Color(0xFF64748B)),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFF1F5F9), height: 1),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildLegalClause(
                            number: "1",
                            title: "Information Collected",
                            content:
                                "We collect user registration details (full name, email address, phone number), duty deployment assignments, and service attendance tallies necessary to fulfill church operations.",
                          ),
                          _buildLegalClause(
                            number: "2",
                            title: "How We Use Information",
                            content:
                                "Data is used strictly to coordinate usher schedules, authenticate user sign-ins (including two-step SMS verification), maintain historical headcount logs, and dispatch critical station announcements.",
                          ),
                          _buildLegalClause(
                            number: "3",
                            title: "Zero Selling of Personal Data",
                            content:
                                "Your personal data is strictly protected. We do not sell, rent, monetize, or disclose your contact information to third-party marketing companies, advertisers, or data brokers.",
                          ),
                          _buildLegalClause(
                            number: "4",
                            title: "Data Encryption & Security",
                            content:
                                "All communications with backend servers are encrypted in transit via SSL/TLS and stored securely within Google Firebase cloud infrastructure with strict role-based access rules.",
                          ),
                          _buildLegalClause(
                            number: "5",
                            title: "Member Data Privacy",
                            content:
                                "Congregation and team member contact details in the directory are restricted to verified ministry staff and ushers for church service operations, coordination, and emergency response.",
                          ),
                          _buildLegalClause(
                            number: "6",
                            title: "Your Rights & Account Deletion",
                            content:
                                "You possess the right to inspect, correct, or request the permanent deletion of your account and personal records at any time through the in-app Settings portal or by contacting church administration.",
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: Text("Understood", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLegalClause({required String number, required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF475569)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1E2432)),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: GoogleFonts.inter(fontSize: 13, height: 1.45, color: const Color(0xFF475569)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showForgotPasswordDialog(BuildContext context, FirebaseService firebaseService) {
    final resetController = TextEditingController(
      text: _usePhoneLogin ? _phoneController.text.trim() : _emailController.text.trim(),
    );

    showDialog(
      context: context,
      builder: (ctx) {
        bool isSubmitting = false;
        String? modalError;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text("Reset Password", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Enter your registered email address or phone number. We will send you a password reset link.",
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondaryLight),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: resetController,
                      decoration: const InputDecoration(
                        labelText: "Email or Phone Number",
                        prefixIcon: Icon(LucideIcons.mail, size: 18),
                      ),
                    ),
                    if (modalError != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        modalError!,
                        style: GoogleFonts.inter(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setModalState(() {
                            isSubmitting = true;
                            modalError = null;
                          });
                          try {
                            await firebaseService.sendPasswordResetEmail(resetController.text.trim());
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Password reset email sent to ${resetController.text.trim()}!"),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            setModalState(() {
                              isSubmitting = false;
                              modalError = e.toString().replaceAll('Exception: ', '').trim();
                            });
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text("Send Reset Link"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTwoFactorScreen(BuildContext context, FirebaseService firebaseService) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final phone = firebaseService.pendingTwoFactorPhone ?? 'your registered phone';
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    final maskedPhone = cleanPhone.length >= 4
        ? '***-***-${cleanPhone.substring(cleanPhone.length - 4)}'
        : phone;
    final rawErr = _errorMessage ?? firebaseService.twoFactorError;
    final isRateLimit = rawErr != null &&
        (rawErr.toLowerCase().contains('blocked') ||
            rawErr.toLowerCase().contains('unusual activity') ||
            rawErr.toLowerCase().contains('too-many-requests') ||
            rawErr.toLowerCase().contains('rate limit'));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => firebaseService.cancelTwoFactorVerification(),
        ),
        title: const Text("Two-Step Verification"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: context.activeGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.4),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(LucideIcons.shieldCheck, color: Colors.white, size: 38),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "SMS Security Verification",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "An extra layer of security is active on your account. Enter the 6-digit code sent to $maskedPhone.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.4,
                  color: context.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 28),
              if (rawErr != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: (isRateLimit ? Colors.amber : AppColors.danger).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: (isRateLimit ? Colors.amber : AppColors.danger).withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isRateLimit ? LucideIcons.shieldAlert : LucideIcons.alertTriangle,
                        color: isRateLimit ? (isDark ? Colors.amber[300] : Colors.amber[800]) : AppColors.danger,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isRateLimit
                                  ? "Carrier SMS Rate Limit Reached"
                                  : rawErr,
                              style: GoogleFonts.inter(
                                color: isRateLimit
                                    ? (isDark ? Colors.amber[300] : Colors.amber[900])
                                    : AppColors.danger,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (isRateLimit) ...[
                              const SizedBox(height: 4),
                              Text(
                                "Carrier SMS quota has been reached. Please wait a few moments before requesting another code.",
                                style: GoogleFonts.inter(
                                  color: isDark ? Colors.amber[200] : Colors.amber[900],
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              DribbbleGlassContainer(
                borderRadius: 24,
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "6-Digit Security Code",
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _smsCodeController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      autofocus: true,
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                      ),
                      maxLength: 6,
                      decoration: const InputDecoration(
                        hintText: "000000",
                        counterText: "",
                        prefixIcon: Icon(LucideIcons.key, size: 18),
                      ),
                    ),
                    const SizedBox(height: 18),
                    DribbbleGlowButton(
                      label: "Verify & Sign In",
                      icon: LucideIcons.shieldCheck,
                      isLoading: firebaseService.authLoading,
                      onPressed: () async {
                        final code = _smsCodeController.text.trim();
                        if (code.isEmpty) {
                          setState(() => _errorMessage = "Please enter the 6-digit code.");
                          return;
                        }
                        setState(() => _errorMessage = null);
                        try {
                          await firebaseService.verifyTwoFactorSmsCode(code);
                          if (mounted) {
                            await _checkAndPromptFingerprint(firebaseService);
                          }
                        } catch (e) {
                          if (mounted) {
                            setState(() => _errorMessage = e.toString().replaceAll('Exception: ', '').trim());
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Didn't receive the code? ", style: GoogleFonts.inter(fontSize: 13, color: context.textSecondaryColor)),
                  GestureDetector(
                    onTap: () async {
                      if (firebaseService.pendingTwoFactorPhone != null) {
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          await firebaseService.sendTwoFactorSmsCode(firebaseService.pendingTwoFactorPhone!);
                          if (mounted) {
                            messenger.showSnackBar(
                              const SnackBar(content: Text("A new 2FA security code was sent!")),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            setState(() => _errorMessage = e.toString().replaceAll('Exception: ', '').trim());
                          }
                        }
                      }
                    },
                    child: Text(
                      "Resend SMS",
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => firebaseService.cancelTwoFactorVerification(),
                child: Text(
                  "Cancel and return to sign in",
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: context.textSecondaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLandingView(BuildContext context, FirebaseService firebaseService) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A0D),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Cathedral Artwork
          Image.asset(
            'assets/images/login_bg.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFF090A0D),
            ),
          ),

          // Gradient overlay for smooth contrast at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 220,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF090A0D).withValues(alpha: 0.5),
                    const Color(0xFF090A0D).withValues(alpha: 0.92),
                  ],
                ),
              ),
            ),
          ),

          // Interactive Action Buttons
          Positioned(
            left: 24,
            right: 24,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // "Get Started" Gold Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(28),
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          setState(() {
                            _showLanding = false;
                            _isRegister = true;
                          });
                        },
                        child: Ink(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE5BC6A), Color(0xFFC79540)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFC79540).withValues(alpha: 0.38),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              "Get Started",
                              style: GoogleFonts.outfit(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF161208),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // "Sign In" Outlined Glass Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(28),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _showLanding = false;
                            _isRegister = false;
                          });
                        },
                        child: Ink(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0C0E14).withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: const Color(0xFFE5BC6A).withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              "Sign In",
                              style: GoogleFonts.outfit(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    if (firebaseService.biometricEnabled) ...[
                      const SizedBox(height: 14),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(28),
                          onTap: _unlockAttempting ? null : _attemptBiometricUnlock,
                          child: Ink(
                            width: double.infinity,
                            height: 54,
                            decoration: BoxDecoration(
                              color: const Color(0xFF131926).withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: const Color(0xFF243046),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: _unlockAttempting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFFE5BC6A),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _biometricIcon,
                                          size: 20,
                                          color: const Color(0xFFE5BC6A),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          "Sign In with $_biometricLabel",
                                          style: GoogleFonts.outfit(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


