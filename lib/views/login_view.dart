import 'package:flutter/material.dart';
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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _adminCodeController = TextEditingController();

  final _smsCodeController = TextEditingController();

  bool _usePhoneLogin = false;
  bool _showAdminCode = false;
  bool _showPassword = false;
  String? _errorMessage;

  bool _unlockAttempting = false;
  bool _hasTriggeredAutoUnlock = false;
  bool _showBiometricScreen = true;
  bool _biometricAvailable = true;

  @override
  void initState() {
    super.initState();
    _isRegister = widget.initialMode == 'register';
    _showBiometricScreen = !_isRegister;
  }

  FirebaseService? _firebaseService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _firebaseService = Provider.of<FirebaseService>(context, listen: false);

    _firebaseService!.isBiometricAvailable().then((available) {
      if (mounted) setState(() => _biometricAvailable = available);
    });

    if (!_hasTriggeredAutoUnlock && _firebaseService!.isLocked) {
      _hasTriggeredAutoUnlock = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _attemptBiometricUnlock());
    }
  }

  Future<void> _attemptBiometricUnlock() async {
    if (!mounted || _unlockAttempting) return;
    setState(() {
      _unlockAttempting = true;
      _errorMessage = null;
    });

    final success = await _firebaseService!.unlockWithBiometrics();

    if (!mounted) return;
    setState(() {
      _unlockAttempting = false;
      if (!success) {
        _errorMessage = "Couldn't verify your identity. Please try again.";
      } else if (_firebaseService!.currentUser == null) {
        _showBiometricScreen = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Biometrics verified! Sign in with your credentials once to link quick unlock."),
            backgroundColor: AppColors.success,
          ),
        );
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
    _adminCodeController.dispose();
    _smsCodeController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (!mounted) return;
    setState(() => _errorMessage = null);
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);

    if (!_isRegister && _usePhoneLogin) {
      if (!firebaseService.phoneCodeSent) {
        final phone = _phoneController.text.trim();
        if (phone.isEmpty) {
          if (!mounted) return;
          setState(() => _errorMessage = "Please enter your registered phone number.");
          return;
        }

        try {
          await firebaseService.sendPhoneSecurityCode(phone);
        } catch (e) {
          if (!mounted) return;
          final cleanErr = e.toString().replaceAll(RegExp(r'\[.*?\]'), '').replaceAll('Exception: ', '').trim();
          if (cleanErr.toLowerCase().contains('no usher profile') || cleanErr.toLowerCase().contains('not registered')) {
            // Redirect directly to Email Login
            setState(() {
              _usePhoneLogin = false;
              _errorMessage = "$cleanErr\nRedirected to Email Sign In.";
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(cleanErr),
                backgroundColor: AppColors.danger,
                duration: const Duration(seconds: 4),
              ),
            );
          } else {
            setState(() => _errorMessage = "Couldn't send code: $cleanErr");
          }
        }
        return;
      }

      final code = _smsCodeController.text.trim();
      if (code.isEmpty) {
        if (!mounted) return;
        setState(() => _errorMessage = "Please enter the 6-digit code sent to your phone.");
        return;
      }

      try {
        await firebaseService.verifyPhoneSecurityCode(code);
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        if (!mounted) return;
        setState(() => _errorMessage = e.toString().replaceAll(RegExp(r'\[.*?\]'), '').replaceAll('Exception: ', '').trim());
      }
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      if (!mounted) return;
      setState(() => _errorMessage = "Please fill in all required fields.");
      return;
    }

    try {
      if (_isRegister) {
        final name = _nameController.text.trim();
        final phone = _phoneController.text.trim();
        final adminCode = _adminCodeController.text.trim();

        await firebaseService.signUp(
          email,
          password,
          name,
          phone,
          adminCode: adminCode.isNotEmpty ? adminCode : null,
        );
      } else {
        await firebaseService.signIn(email, password);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = "Authentication failed: ${e.toString().replaceAll(RegExp(r'\[.*?\]'), '').replaceAll('Exception: ', '').trim()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context);

    // Two-Step SMS Verification Challenge
    if (firebaseService.pendingTwoFactor) {
      return _buildTwoFactorScreen(context, firebaseService);
    }

    // Biometric Screen (when locked, or when biometric mode is active on Sign In)
    if (firebaseService.isLocked || (_showBiometricScreen && !_isRegister && _biometricAvailable)) {
      return _buildBiometricLoginScreen(context, firebaseService);
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () {
            if (_biometricAvailable && !_isRegister) {
              setState(() => _showBiometricScreen = true);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(_isRegister ? "Create Usher Account" : "Usher Sign In"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_biometricAvailable && !_isRegister) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: InkWell(
                    onTap: () => setState(() => _showBiometricScreen = true),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.scanFace, size: 18, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 6),
                          Icon(LucideIcons.fingerprint, size: 18, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            "Fast Biometric Sign In (Face ID / Fingerprint)",
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              // Segmented Tab Switcher
              DribbbleGlassContainer(
                borderRadius: 20,
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isRegister = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            gradient: !_isRegister ? context.activeGradient : null,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: !_isRegister
                                ? [
                                    BoxShadow(
                                      color: Theme.of(context).primaryColor.withValues(alpha: 0.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              "Sign In",
                              style: GoogleFonts.outfit(
                                fontWeight: !_isRegister ? FontWeight.bold : FontWeight.w500,
                                color: !_isRegister ? Colors.white : context.textSecondaryColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isRegister = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            gradient: _isRegister ? context.activeGradient : null,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: _isRegister
                                ? [
                                    BoxShadow(
                                      color: Theme.of(context).primaryColor.withValues(alpha: 0.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              "Register",
                              style: GoogleFonts.outfit(
                                fontWeight: _isRegister ? FontWeight.bold : FontWeight.w500,
                                color: _isRegister ? Colors.white : context.textSecondaryColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Sign In Mode Switcher (Email vs Phone)
              if (!_isRegister) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilterChip(
                      showCheckmark: false,
                      avatar: Icon(
                        LucideIcons.mail,
                        size: 14,
                        color: !_usePhoneLogin ? Colors.white : context.textPrimaryColor,
                      ),
                      label: Text("Sign In with Email", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
                      selected: !_usePhoneLogin,
                      selectedColor: Theme.of(context).primaryColor,
                      labelStyle: TextStyle(
                        color: !_usePhoneLogin ? Colors.white : context.textPrimaryColor,
                      ),
                      onSelected: (val) {
                        if (val) {
                          firebaseService.cancelPhoneVerification();
                          setState(() => _usePhoneLogin = false);
                        }
                      },
                    ),
                    const SizedBox(width: 10),
                    FilterChip(
                      showCheckmark: false,
                      avatar: Icon(
                        LucideIcons.phone,
                        size: 14,
                        color: _usePhoneLogin ? Colors.white : context.textPrimaryColor,
                      ),
                      label: Text("Sign In with Phone", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
                      selected: _usePhoneLogin,
                      selectedColor: Theme.of(context).primaryColor,
                      labelStyle: TextStyle(
                        color: _usePhoneLogin ? Colors.white : context.textPrimaryColor,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _usePhoneLogin = true);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              if (_errorMessage != null) ...[
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
                          _errorMessage!,
                          style: GoogleFonts.inter(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              DribbbleGlassContainer(
                borderRadius: 24,
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_isRegister) ...[
                      Text("Full Name", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: "First and last name",
                          prefixIcon: Icon(LucideIcons.user, size: 18),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text("Phone Number", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: "(555) 000-0000",
                          prefixIcon: Icon(LucideIcons.phone, size: 18),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text("Email Address", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: "email@example.com",
                          prefixIcon: Icon(LucideIcons.mail, size: 18),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text("Password", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _passwordController,
                        obscureText: !_showPassword,
                        decoration: InputDecoration(
                          hintText: "••••••••",
                          prefixIcon: const Icon(LucideIcons.lock, size: 18),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPassword ? LucideIcons.eyeOff : LucideIcons.eye,
                              size: 18,
                              color: context.textSecondaryColor,
                            ),
                            onPressed: () => setState(() => _showPassword = !_showPassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => setState(() => _showAdminCode = !_showAdminCode),
                        child: Row(
                          children: [
                            Icon(_showAdminCode ? LucideIcons.chevronDown : LucideIcons.chevronRight, size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text("Have an Admin or Lead Security Passcode?", style: GoogleFonts.inter(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      if (_showAdminCode) ...[
                        const SizedBox(height: 10),
                        TextField(
                          controller: _adminCodeController,
                          decoration: const InputDecoration(
                            hintText: "Enter security passcode",
                            prefixIcon: Icon(LucideIcons.key, size: 18),
                          ),
                        ),
                      ],
                    ] else if (_usePhoneLogin) ...[
                      if (!firebaseService.phoneCodeSent) ...[
                        Text("Registered Phone Number", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            hintText: "(555) 000-0000",
                            prefixIcon: Icon(LucideIcons.phone, size: 18),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "We'll text a 6-digit verification code to this number.",
                          style: GoogleFonts.inter(fontSize: 12, color: context.textSecondaryColor),
                        ),
                      ] else ...[
                        Text("Verification Code", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _smsCodeController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: const InputDecoration(
                            hintText: "123456",
                            counterText: "",
                            prefixIcon: Icon(LucideIcons.messageSquare, size: 18),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Enter the code we texted to ${firebaseService.pendingPhone ?? 'your phone'}.",
                          style: GoogleFonts.inter(fontSize: 12, color: context.textSecondaryColor),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              firebaseService.cancelPhoneVerification();
                              _smsCodeController.clear();
                              setState(() => _errorMessage = null);
                            },
                            child: Text(
                              "Wrong number? Start over",
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ] else ...[
                      Text("Email Address", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: "name@church.org",
                          prefixIcon: Icon(LucideIcons.mail, size: 18),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text("Password", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _passwordController,
                        obscureText: !_showPassword,
                        decoration: InputDecoration(
                          hintText: "••••••••",
                          prefixIcon: const Icon(LucideIcons.lock, size: 18),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPassword ? LucideIcons.eyeOff : LucideIcons.eye,
                              size: 18,
                              color: context.textSecondaryColor,
                            ),
                            onPressed: () => setState(() => _showPassword = !_showPassword),
                          ),
                        ),
                      ),
                      if (!_isRegister) ...[
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => _showForgotPasswordDialog(context, firebaseService),
                            child: Text(
                              "Forgot Password?",
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              DribbbleGlowButton(
                label: _isRegister
                    ? "Register & Enter Hub"
                    : (_usePhoneLogin
                        ? (firebaseService.phoneCodeSent ? "Verify & Sign In" : "Send Verification Code")
                        : "Sign In"),
                icon: _isRegister
                    ? LucideIcons.userPlus
                    : (_usePhoneLogin
                        ? (firebaseService.phoneCodeSent ? LucideIcons.shieldCheck : LucideIcons.phoneCall)
                        : LucideIcons.logIn),
                onPressed: _handleSubmit,
                isLoading: firebaseService.authLoading,
              ),
            ],
          ),
        ),
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

  Widget _buildBiometricLoginScreen(BuildContext context, FirebaseService firebaseService) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final iconColor = isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Background ambient soft light orbs
          Positioned(
            bottom: -100,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withValues(alpha: isDark ? 0.12 : 0.06),
              ),
            ),
          ),
          Positioned(
            top: 200,
            right: -100,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.secondary.withValues(alpha: isDark ? 0.1 : 0.05),
              ),
            ),
          ),

          Column(
            children: [
              // Top Curved Header Banner (Matching Mockup)
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  24,
                  MediaQuery.of(context).padding.top + 28,
                  24,
                  38,
                ),
                decoration: BoxDecoration(
                  gradient: context.activeGradient,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(42),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.35),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      "Welcome Back!",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Fast and Secure Login",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),

              // Middle Interactive Biometric Area
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 36),

                        // Face ID Interactive Target
                        InkWell(
                          onTap: _attemptBiometricUnlock,
                          borderRadius: BorderRadius.circular(28),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 110,
                            height: 110,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.cardDark.withValues(alpha: 0.8)
                                  : Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: _unlockAttempting
                                    ? primaryColor
                                    : (isDark ? AppColors.borderDark : AppColors.borderLight),
                                width: _unlockAttempting ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: _FaceIdGlyph(
                              size: 64,
                              color: _unlockAttempting ? primaryColor : iconColor,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // "OR" Divider
                        Text(
                          "OR",
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: context.textSecondaryColor,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Fingerprint Interactive Target
                        InkWell(
                          onTap: _attemptBiometricUnlock,
                          borderRadius: BorderRadius.circular(28),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 110,
                            height: 110,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.cardDark.withValues(alpha: 0.8)
                                  : Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: _unlockAttempting
                                    ? primaryColor
                                    : (isDark ? AppColors.borderDark : AppColors.borderLight),
                                width: _unlockAttempting ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Icon(
                              LucideIcons.fingerprint,
                              size: 64,
                              color: _unlockAttempting ? primaryColor : iconColor,
                            ),
                          ),
                        ),

                        if (_unlockAttempting) ...[
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Authenticating...",
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],

                        if (_errorMessage != null) ...[
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.danger,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 42),

                        // Switch to Username & Password Link
                        GestureDetector(
                          onTap: () {
                            if (firebaseService.isLocked) {
                              _showLockedPasswordFallbackDialog(context, firebaseService);
                            } else {
                              setState(() {
                                _showBiometricScreen = false;
                                _errorMessage = null;
                              });
                            }
                          },
                          child: Text(
                            "LOGIN WITH USERNAME & PASSWORD",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              decoration: TextDecoration.underline,
                              color: context.textPrimaryColor,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom Corner Action Icons (Matching Mockup)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  8,
                  24,
                  MediaQuery.of(context).padding.bottom + 14,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Bottom Left Logo/Back Action
                    InkWell(
                      onTap: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          setState(() => _showBiometricScreen = false);
                        }
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? AppColors.surfaceDark : Colors.white,
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            LucideIcons.arrowUpRight,
                            size: 20,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),

                    // Bottom Right Support Contact Action
                    InkWell(
                      onTap: () => _showSupportContactDialog(context),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? AppColors.surfaceDark : Colors.white,
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            LucideIcons.phoneCall,
                            size: 20,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLockedPasswordFallbackDialog(BuildContext context, FirebaseService firebaseService) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Sign In with Password", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: const Text(
          "To sign in with your email or phone password instead of biometrics, you can sign out and re-enter your credentials.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              firebaseService.signOut();
            },
            child: const Text("Sign Out & Enter Password"),
          ),
        ],
      ),
    );
  }

  void _showSupportContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(LucideIcons.phoneCall, color: Theme.of(context).primaryColor, size: 20),
            ),
            const SizedBox(width: 10),
            Text("Ministry Support", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Need assistance with your account or duty deployments?",
              style: GoogleFonts.inter(fontSize: 13, color: context.textSecondaryColor),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Head Usher / Admin Office", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text("Email: ushers@ministryhub.org", style: GoogleFonts.inter(fontSize: 12, color: context.textSecondaryColor)),
                  Text("Phone: (555) 123-4567", style: GoogleFonts.inter(fontSize: 12, color: context.textSecondaryColor)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close"),
          ),
        ],
      ),
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
                          if (mounted) Navigator.of(context).pop();
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
                        try {
                          await firebaseService.sendTwoFactorSmsCode(firebaseService.pendingTwoFactorPhone!);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
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
}

class _FaceIdGlyph extends StatelessWidget {
  final double size;
  final Color color;

  const _FaceIdGlyph({
    this.size = 64,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _FaceIdPainter(color: color),
    );
  }
}

class _FaceIdPainter extends CustomPainter {
  final Color color;

  _FaceIdPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.055
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final bracketLen = w * 0.22;
    final radius = w * 0.12;

    // Top-Left bracket
    final tlPath = Path()
      ..moveTo(0, bracketLen)
      ..lineTo(0, radius)
      ..arcToPoint(Offset(radius, 0), radius: Radius.circular(radius))
      ..lineTo(bracketLen, 0);
    canvas.drawPath(tlPath, paint);

    // Top-Right bracket
    final trPath = Path()
      ..moveTo(w - bracketLen, 0)
      ..lineTo(w - radius, 0)
      ..arcToPoint(Offset(w, radius), radius: Radius.circular(radius))
      ..lineTo(w, bracketLen);
    canvas.drawPath(trPath, paint);

    // Bottom-Left bracket
    final blPath = Path()
      ..moveTo(0, h - bracketLen)
      ..lineTo(0, h - radius)
      ..arcToPoint(Offset(radius, h), radius: Radius.circular(radius))
      ..lineTo(bracketLen, h);
    canvas.drawPath(blPath, paint);

    // Bottom-Right bracket
    final brPath = Path()
      ..moveTo(w - bracketLen, h)
      ..lineTo(w - radius, h)
      ..arcToPoint(Offset(w, h - radius), radius: Radius.circular(radius))
      ..lineTo(w, h - bracketLen);
    canvas.drawPath(brPath, paint);

    // Eyes
    final eyeY = h * 0.42;
    final eyeRadius = w * 0.045;
    canvas.drawCircle(Offset(w * 0.36, eyeY), eyeRadius, fillPaint);
    canvas.drawCircle(Offset(w * 0.64, eyeY), eyeRadius, fillPaint);

    // Nose
    final nosePath = Path()
      ..moveTo(w * 0.5, h * 0.45)
      ..lineTo(w * 0.5, h * 0.54)
      ..lineTo(w * 0.46, h * 0.54);
    canvas.drawPath(nosePath, paint);

    // Smile
    final smileRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.58),
      width: w * 0.32,
      height: h * 0.22,
    );
    canvas.drawArc(smileRect, 0.2, 2.74, false, paint);
  }

  @override
  bool shouldRepaint(covariant _FaceIdPainter oldDelegate) => oldDelegate.color != color;
}


