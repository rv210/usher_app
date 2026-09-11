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
    _isRegister = widget.initialMode == 'register';
    _showLanding = widget.initialMode != 'register' && widget.initialMode != 'login_form';
  }

  FirebaseService? _firebaseService;
  String _biometricLabel = "Biometric";
  IconData _biometricIcon = LucideIcons.fingerprint;
  bool _hasSavedBiometricCreds = false;

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
        setState(() {
          _hasSavedBiometricCreds = true;
        });
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
      try {
        final profile = await firebaseService.findProfileByPhone(input);
        if (profile != null && profile.email != null && profile.email!.contains('@') && password.isNotEmpty) {
          final success = await firebaseService.signIn(profile.email!, password);
          if (!success) return; // 2FA SMS challenge required
          await firebaseService.saveBiometricCredentials(profile.email!, password);
          if (mounted) await _checkAndPromptFingerprint(firebaseService);
          return;
        } else {
          // Send SMS verification code to phone
          await firebaseService.sendPhoneSecurityCode(input);
          setState(() {
            _usePhoneLogin = true;
            _phoneController.text = input;
          });
          return;
        }
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

      // Save credentials for instant biometric fingerprint unlock
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
                    final password = _passwordController.text.trim();
                    if (email.isNotEmpty && password.isNotEmpty) {
                      await firebaseService.saveBiometricCredentials(email, password);
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
      return _buildLandingView(context);
    }

    if (_isRegister) {
      return _buildCreateAccountView(context, firebaseService);
    }

    return _buildSignInView(context, firebaseService);
  }

  Widget _buildSignInView(BuildContext context, FirebaseService firebaseService) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.white, size: 24),
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
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Welcome back! Please sign in to continue.",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF8E9BAE),
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
                    color: const Color(0xFF131926),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF243046), width: 1),
                  ),
                  child: TextField(
                    controller: _smsCodeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, letterSpacing: 6, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      counterText: "",
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      prefixIcon: const Icon(LucideIcons.messageSquare, color: Color(0xFF7E8B9F), size: 18),
                      hintText: "123456",
                      hintStyle: GoogleFonts.outfit(color: const Color(0xFF5E6B80), fontSize: 18, letterSpacing: 4),
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
                    color: const Color(0xFF131926),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF243046), width: 1),
                  ),
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      prefixIcon: const Icon(LucideIcons.mail, color: Color(0xFF7E8B9F), size: 18),
                      hintText: "Email or Phone Number",
                      hintStyle: GoogleFonts.inter(color: const Color(0xFF5E6B80), fontSize: 14),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Password
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF131926),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF243046), width: 1),
                  ),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      prefixIcon: const Icon(LucideIcons.lock, color: Color(0xFF7E8B9F), size: 18),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showPassword ? LucideIcons.eyeOff : LucideIcons.eye,
                          color: const Color(0xFF7E8B9F),
                          size: 18,
                        ),
                        onPressed: () => setState(() => _showPassword = !_showPassword),
                      ),
                      hintText: "Password",
                      hintStyle: GoogleFonts.inter(color: const Color(0xFF5E6B80), fontSize: 14),
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
                            side: const BorderSide(color: Color(0xFF3B4860), width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (val) => setState(() => _rememberMe = val ?? true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Remember me",
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFFCAD1DC),
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
                  const Expanded(child: Divider(color: Color(0xFF243046), thickness: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "or",
                      style: GoogleFonts.inter(color: const Color(0xFF7E8B9F), fontSize: 13),
                    ),
                  ),
                  const Expanded(child: Divider(color: Color(0xFF243046), thickness: 1)),
                ],
              ),

              const SizedBox(height: 20),

              // Biometric Sign In button (Replaces "Sign in with Google")
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(27),
                  onTap: _unlockAttempting ? null : _attemptBiometricUnlock,
                  child: Ink(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFF131926),
                      borderRadius: BorderRadius.circular(27),
                      border: Border.all(color: const Color(0xFF243046), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
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

              const SizedBox(height: 28),

              // Register footer link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF8E9BAE),
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

              // Church / Ministry
              _buildLightInputField(
                controller: _ministryController,
                icon: LucideIcons.church,
                hintText: "Church / Ministry",
                suffixIcon: LucideIcons.chevronDown,
                onTapSuffix: () => _selectMinistry(context),
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
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFC79540),
                            ),
                          ),
                          const TextSpan(text: " and "),
                          TextSpan(
                            text: "Privacy Policy",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFC79540),
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

  void _selectMinistry(BuildContext context) {
    final options = [
      "Guardians of the Gate",
      "Vestibule Ushers",
      "Main Sanctuary",
      "Hospitality Ministry",
      "Youth & Children",
      "Special Events",
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    "Select Ministry / Station",
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E2432)),
                  ),
                ),
                const SizedBox(height: 12),
                ...options.map((opt) => ListTile(
                      title: Text(opt, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: const Color(0xFF1E2432))),
                      trailing: _ministryController.text == opt
                          ? const Icon(LucideIcons.check, color: Color(0xFFC79540))
                          : null,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onTap: () {
                        setState(() => _ministryController.text = opt);
                        Navigator.pop(ctx);
                      },
                    )),
              ],
            ),
          ),
        );
      },
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
    final phone = firebaseService.pendingTwoFactorPhone ?? 'your registered phone';
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    final maskedPhone = cleanPhone.length >= 4
        ? '***-***-${cleanPhone.substring(cleanPhone.length - 4)}'
        : phone;

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
              if (_errorMessage != null || firebaseService.twoFactorError != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.alertTriangle, color: AppColors.danger, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage ?? firebaseService.twoFactorError!,
                          style: GoogleFonts.inter(
                            color: AppColors.danger,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
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
                        hintText: "123456",
                        counterText: "",
                        prefixIcon: Icon(LucideIcons.key, size: 18),
                      ),
                    ),
                    const SizedBox(height: 22),
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

  Widget _buildLandingView(BuildContext context) {
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


