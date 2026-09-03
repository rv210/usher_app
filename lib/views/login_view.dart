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

  final _smsCodeController = TextEditingController();

  bool _usePhoneLogin = false;
  bool _showPassword = false;
  String? _errorMessage;

  bool _unlockAttempting = false;

  @override
  void initState() {
    super.initState();
    _isRegister = widget.initialMode == 'register';
  }

  FirebaseService? _firebaseService;
  String _biometricLabel = "Biometric";
  IconData _biometricIcon = LucideIcons.fingerprint;
  bool _hasSavedBiometricCreds = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
              _errorMessage = "Phone not linked to an account yet. Please sign in with email/password below or register.";
            });
          } else {
            setState(() => _errorMessage = cleanErr);
          }
        }
        return;
      }

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

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = "Please enter both your email address and password.");
      return;
    }

    if (_isRegister) {
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();

      if (name.isEmpty) {
        setState(() => _errorMessage = "Please enter your full name.");
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

    // Standard Sign In
    try {
      final success = await firebaseService.signIn(email, password);
      if (!success) {
        // 2FA SMS challenge required, stay on view for SMS input
        return;
      }

      // Save credentials for instant biometric fingerprint unlock
      await firebaseService.saveBiometricCredentials(email, password);

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

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(_isRegister ? "Create Usher Account" : "Usher Sign In"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 8,
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

              if (!_isRegister && (firebaseService.biometricEnabled || _hasSavedBiometricCreds)) ...[
                const SizedBox(height: 12),
                DribbbleGlassContainer(
                  borderRadius: 16,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  onTap: _attemptBiometricUnlock,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_biometricIcon, size: 20, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        "Sign In with $_biometricLabel",
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
}


