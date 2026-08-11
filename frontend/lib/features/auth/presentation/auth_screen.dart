import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swaransh_academy/Core/service/api_exceptions.dart';
import 'package:swaransh_academy/features/auth/data/provider.dart';
import 'package:swaransh_academy/features/auth/data/users_api_service.dart';
import 'package:swaransh_academy/features/role_select/presentation/selectedRoleprovider.dart';

import '../../../Core/auth/auth_notifier.dart';
import '../../../Core/auth/user_role.dart';
import '../../../Core/theme/app_colors.dart';
import '../../../Core/theme/app_spacing.dart';
import '../../../Core/theme/app_typography.dart';
import 'widgets/google_logo.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, this.onSuccess});

  /// Called after auth + role verification completes successfully.
  /// Defaults to context.go('/home') if null.
  final VoidCallback? onSuccess;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _busy = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _formKey.currentState?.reset();
    });
  }

  Future<void> _submitEmail() async {
    debugPrint(
      "Name ${_nameCtrl.text} , email ${_emailCtrl.text} , pass ${_passwordCtrl.text}",
    );
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);

    final selectedRole = ref.read(selectedRoleProvider);

    // Admin code check happens BEFORE any Supabase call
    if (selectedRole == UserRole.admin) {
      final isVerified = await _handlePostAuth();
      if (!isVerified) {
        if (mounted) {
          setState(() => _busy = false);
          _showError('Incorrect admin code');
        }
        return;
      }
    }
    ref.read(authProvider.notifier).authFlowInProgress = true;
    try {
      if (_isSignUp) {
        //* First sign Up , then create user (inside signUp function), then Resolve user ...

        ref.read(authProvider.notifier).handlingSignUp = true;

        //* Manual Admin Switch
        if (selectedRole == UserRole.admin) {
          debugPrint("Manually Changing Role to ADMIN in AUTH Screen");
          ref.read(isAdminRoleProvider.notifier).state = UserRole.admin;
        }

        // 1. Supabase auth only
        final role = selectedRole?.name ?? UserRole.guest.name;
        debugPrint("Signing UP ...");
        await ref
            .read(authProvider.notifier)
            .signUpWithEmail(
              //? Create USER API inside ...
              _emailCtrl.text.trim(),
              _passwordCtrl.text,
              _nameCtrl.text.trim(),
              role,
            );
        if (!mounted) return;

        debugPrint("Handling SignUp flow false");
        await ref.read(authProvider.notifier).refreshRole();
        // 3. Now resolve real role from DB
        ref.read(authProvider.notifier).handlingSignUp = false;
        if (!mounted) return;
      } else {
        // Sign-in
        await ref
            .read(authProvider.notifier)
            .signInWithEmail(_emailCtrl.text.trim(), _passwordCtrl.text);
        if (!mounted) return;
      }

      // This always runs for both sign-in and sign-up
      ref.read(selectedRoleProvider.notifier).state = null;
      _onSuccess(); // ← now guaranteed to be called
    } catch (e) {
      debugPrint("ERROR: $e");

      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitGoogle() async {
    setState(() => _busy = true);
    final selectedRole = ref.read(selectedRoleProvider);
    debugPrint("Selected ROLE: $selectedRole");

    if (selectedRole == UserRole.admin) {
      final isVerified = await _handlePostAuth();
      debugPrint(
        "Verification result = ${isVerified ? "Successful" : "Failed"}",
      );

      if (!isVerified) {
        if (mounted) {
          setState(() => _busy = false);
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text(
                  "Incorrect Password",
                  textAlign: TextAlign.center,
                ),
                backgroundColor: Color(0xFFC1473B),
              ),
            );
        }
        return;
      }
    }

    try {
      await ref.read(authProvider.notifier).signInWithGoogle();
      if (!mounted) return;
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// After Supabase auth succeeds, check if admin code is needed.
  Future<bool> _handlePostAuth() async {
    // Show admin code dialog before proceeding.
    ref.read(authProvider.notifier).handlingAdminVerification = true;
    debugPrint(
      "Handling Admin Auth Subscription: ${ref.read(authProvider.notifier).handlingAdminVerification}",
    );
    debugPrint("SHOWING Password Screen ...");
    final verified = await _showAdminCodeDialog();
    ref.read(authProvider.notifier).handlingAdminVerification = false;
    debugPrint("Entered Password: $verified");

    if (verified) {
      // Only clear the selected role intent once admin auth actually succeeds.
      ref.read(selectedRoleProvider.notifier).state = null;
    }

    return verified;
    // Admin verified — role will be set by backend on POST /user call.
  }

  Future<bool> _showAdminCodeDialog() async {
    debugPrint("Password Screen Function  Called");
    final codeCtrl = TextEditingController();
    debugPrint("mounted before dialog = $mounted");
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Admin Verification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the admin access code to continue.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: codeCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Admin Code',
                prefixIcon: Icon(Icons.key_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx, true);
              FocusScope.of(context).unfocus();
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
    debugPrint("dialog returned");

    if (result != true) return false;
    debugPrint("result: $result");
    // Sending Verification API
    try {
      final isVerified = await ref
          .read(usersApiServiceProvider)
          .verifyAdmin(codeCtrl.text.trim());
      debugPrint("Verification: $isVerified");

      ref.read(adminVerificationProvider.notifier).state = isVerified;
      if (!isVerified) {
        if (mounted) setState(() => _busy = false);
        debugPrint("Admin Verification Failed");
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text("Incorrect Password", textAlign: TextAlign.center),
              backgroundColor: Color(0xFFC1473B),
            ),
          );
      }
      return isVerified;

      // use isVerified
    } on ApiException catch (e) {
      setState(() {
        _busy = false;
      });
      _showError(e.message);
      return false;
    }
  }

  void _onSuccess() {
    debugPrint("onSuccess is null? ${widget.onSuccess == null}");
    if (widget.onSuccess != null) {
      widget.onSuccess!();
    } else {
      context.go('/home');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedRole = ref.watch(selectedRoleProvider);
    final isAdminFlow = selectedRole == UserRole.admin;

    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/app_logo.png',
                      width: 72,
                      height: 72,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.music_note,
                        size: 56,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Swaransh Academy',
                      style: AppTypography.headlineLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAdminFlow
                          ? 'Admin sign-in'
                          : _isSignUp
                          ? 'Create your account'
                          : 'Welcome back',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (isAdminFlow) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.navy.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.admin_panel_settings_outlined,
                              size: 14,
                              color: AppColors.navy,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Admin flow — code required after sign-in',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.navy,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (_isSignUp) ...[
                      _Field(
                        controller: _nameCtrl,
                        label: 'Full Name',
                        icon: Icons.person_outline,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter your name'
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    _Field(
                      controller: _emailCtrl,
                      label: 'Email address',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Please enter your email';
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v))
                          return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _Field(
                      controller: _passwordCtrl,
                      label: 'Password',
                      icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      suffix: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'Please enter a password';
                        if (_isSignUp && v.length < 6)
                          return 'Password must be at least 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _busy ? null : _submitEmail,
                        child: _busy
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.xs,
                                ),
                                child: Text(
                                  _isSignUp ? 'Create Account' : 'Sign In',
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Text(
                      'or',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _busy ? null : _submitGoogle,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.divider),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const GoogleLogo(size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Continue with Google',
                        style: AppTypography.button.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isSignUp
                          ? 'Already have an account? '
                          : "Don't have an account? ",
                      style: AppTypography.bodySmall,
                    ),
                    GestureDetector(
                      onTap: _toggleMode,
                      child: Text(
                        _isSignUp ? 'Sign In' : 'Sign Up',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: TextButton(
                  onPressed: () {
                    ref.read(selectedRoleProvider.notifier).state = null;
                    context.canPop() ? context.pop() : context.go('/home');
                  },
                  child: Text(
                    'Continue as Guest',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
        suffixIcon: suffix,
      ),
    );
  }
}
