import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

class LoginView extends StatefulWidget {
  final String initialMode; // 'login' or 'register'
  final VoidCallback onBackToLanding;

  const LoginView({
    super.key,
    this.initialMode = 'login',
    required this.onBackToLanding,
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

  bool _usePhoneLogin = false;
  bool _showAdminCode = false;
  bool _showPassword = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _isRegister = widget.initialMode == 'register';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _adminCodeController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (!mounted) return;
    setState(() => _errorMessage = null);
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);

    if (!_isRegister && _usePhoneLogin) {
      final phone = _phoneController.text.trim();
      final password = _passwordController.text.trim();

      if (phone.isEmpty || password.isEmpty) {
        if (!mounted) return;
        setState(() => _errorMessage = "Please enter your phone number and password.");
        return;
      }

      try {
        await firebaseService.signInWithPhone(phone, password);
      } catch (e) {
        if (!mounted) return;
        setState(() => _errorMessage = "Authentication failed: ${e.toString().replaceAll(RegExp(r'\[.*?\]'), '').replaceAll('Exception: ', '').trim()}");
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
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = "Authentication failed: ${e.toString().replaceAll(RegExp(r'\[.*?\]'), '').replaceAll('Exception: ', '').trim()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final firebaseService = Provider.of<FirebaseService>(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: widget.onBackToLanding,
        ),
        title: Text(_isRegister ? "Create Usher Account" : "Usher Sign In"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                        if (val) setState(() => _usePhoneLogin = false);
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
                          hintText: "e.g. Demitris Boyce",
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
                          hintText: "e.g. 7575508302",
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
                            hintText: "GUARDIAN-LEAD-2024",
                            prefixIcon: Icon(LucideIcons.key, size: 18),
                          ),
                        ),
                      ],
                    ] else if (_usePhoneLogin) ...[
                      Text("Registered Phone Number", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: "e.g. (757) 550-8302",
                          prefixIcon: Icon(LucideIcons.phone, size: 18),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text("Account Password", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
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
                    : (_usePhoneLogin ? "Sign In with Phone" : "Sign In"),
                icon: _isRegister
                    ? LucideIcons.userPlus
                    : (_usePhoneLogin ? LucideIcons.phoneCall : LucideIcons.logIn),
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
}

