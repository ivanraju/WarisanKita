import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/domain/models/user.dart';
import 'package:warisan_kita/domain/validators/profile_validator.dart';
import 'package:warisan_kita/ui/auth/email_verification_screen.dart';
import 'package:warisan_kita/ui/auth/widgets/password_strength_meter.dart';
import 'package:warisan_kita/ui/core/widgets/heritage_background.dart';
import 'package:warisan_kita/data/services/connectivity_service.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  ExistingAccountCheck? _existingAccountCheck;
  bool _isCheckingEmail = false;
  String? _emailAccountMessage;
  Timer? _emailDebounce;

  bool _isCheckingUsername = false;
  bool? _isUsernameAvailable;
  String? _usernameMessage;
  Timer? _usernameDebounce;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
    _usernameController.addListener(_onUsernameChanged);
    _passwordController.addListener(_onPasswordChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AuthViewModel>().clearError();
        ScaffoldMessenger.of(context).clearSnackBars();
      }
    });
  }

  void _onPasswordChanged() {
    setState(() {});
  }

  void _onUsernameChanged() {
    _usernameDebounce?.cancel();
    final raw = _usernameController.text.trim().replaceAll('@', '');
    if (raw.isEmpty) {
      setState(() {
        _isCheckingUsername = false;
        _isUsernameAvailable = null;
        _usernameMessage = null;
      });
      return;
    }

    final valErr = ProfileValidator.validateUsername(raw);
    if (valErr != null) {
      setState(() {
        _isCheckingUsername = false;
        _isUsernameAvailable = false;
        _usernameMessage = valErr;
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
    });

    _usernameDebounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final isAvailable =
            await context.read<AuthViewModel>().isUsernameAvailable(raw);
        if (!mounted ||
            _usernameController.text.trim().replaceAll('@', '') != raw) {
          return;
        }
        setState(() {
          _isCheckingUsername = false;
          _isUsernameAvailable = isAvailable;
          _usernameMessage =
              isAvailable ? '@$raw is available' : '@$raw is already taken';
        });
      } catch (_) {
        if (!mounted ||
            _usernameController.text.trim().replaceAll('@', '') != raw) {
          return;
        }
        setState(() {
          _isCheckingUsername = false;
          _isUsernameAvailable = null;
          _usernameMessage = 'Unable to check this username right now.';
        });
      }
    });
  }

  void _onEmailChanged() {
    _emailDebounce?.cancel();
    final email = _emailController.text.trim().toLowerCase();
    if (ProfileValidator.validateEmail(email) != null) {
      setState(() {
        _isCheckingEmail = false;
        _existingAccountCheck = null;
        _emailAccountMessage = null;
      });
      return;
    }

    setState(() {
      _isCheckingEmail = true;
      _existingAccountCheck = null;
      _emailAccountMessage = 'Checking whether this email is registered…';
    });

    _emailDebounce = Timer(const Duration(milliseconds: 450), () async {
      try {
        final check = await context.read<AuthViewModel>().checkExistingAccount(email);
        if (!mounted || _emailController.text.trim().toLowerCase() != email) return;
        setState(() {
          _isCheckingEmail = false;
          _existingAccountCheck = check.exists ? check : null;
          _emailAccountMessage = check.exists
              ? 'This email is already registered. Please sign in instead.'
              : 'This email is available for registration.';
        });
      } catch (_) {
        if (!mounted || _emailController.text.trim().toLowerCase() != email) return;
        setState(() {
          _isCheckingEmail = false;
          _existingAccountCheck = null;
          _emailAccountMessage = 'Unable to check this email right now.';
        });
      }
    });
  }

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _emailDebounce?.cancel();
    _emailController.removeListener(_onEmailChanged);
    _usernameController.removeListener(_onUsernameChanged);
    _passwordController.removeListener(_onPasswordChanged);
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _emailFocusNode.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final connectivity = context.read<ConnectivityService?>();
    if (connectivity != null && connectivity.isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text('Cannot register while offline. Please connect to the internet.'),
              ),
            ],
          ),
          backgroundColor: Color(0xFFC2410C),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    _emailDebounce?.cancel();
    _usernameDebounce?.cancel();
    final submittedEmail = _emailController.text.trim().toLowerCase();
    final submittedUsername =
        _usernameController.text.trim().replaceAll('@', '');
    setState(() {
      _isCheckingEmail = true;
      _isCheckingUsername = true;
    });
    try {
      final authVM = context.read<AuthViewModel>();
      final results = await Future.wait<Object>([
        authVM.checkExistingAccount(submittedEmail),
        authVM.isUsernameAvailable(submittedUsername),
      ]);
      final latestCheck = results[0] as ExistingAccountCheck;
      final usernameAvailable = results[1] as bool;
      if (!mounted) return;
      setState(() {
        _isCheckingEmail = false;
        _isCheckingUsername = false;
        _existingAccountCheck = latestCheck.exists ? latestCheck : null;
        _isUsernameAvailable = usernameAvailable;
        _usernameMessage = usernameAvailable
            ? '@$submittedUsername is available'
            : '@$submittedUsername is already taken';
        _emailAccountMessage = latestCheck.exists
            ? 'This email is already registered. Please sign in instead.'
            : 'This email is available for registration.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isCheckingEmail = false;
        _isCheckingUsername = false;
        _emailAccountMessage = 'Unable to check this email right now.';
        _usernameMessage = 'Unable to check this username right now.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to verify this email. Please try again.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_isUsernameAvailable == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_usernameMessage ?? 'USERNAME ALREADY TAKEN'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_existingAccountCheck != null && _existingAccountCheck!.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ACCOUNT ALREADY REGISTERED: Please sign in instead'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final authVM = context.read<AuthViewModel>();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final fullName = _fullNameController.text.trim();
    final username = _usernameController.text.trim().replaceAll('@', '');

    final result = await authVM.registerTourist(
      username: username.isNotEmpty ? username : email.split('@')[0],
      fullName: fullName.isNotEmpty ? fullName : null,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
    );

    if (!mounted) return;

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Registration failed'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (result.requiresEmailVerification) {
      ScaffoldMessenger.of(context).clearSnackBars();
      final changedEmail = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => EmailVerificationScreen(
            email: email,
            targetRoute: result.route ?? '/tourist',
            role: 'Tourist',
          ),
        ),
      );

      if (changedEmail == true && mounted) {
        _emailFocusNode.requestFocus();
        _emailController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _emailController.text.length,
        );
        final rawUser = _usernameController.text.trim();
        if (rawUser.isNotEmpty) {
          _onUsernameChanged();
        }
      }
      return;
    }

    ScaffoldMessenger.of(context).clearSnackBars();
    Navigator.of(context).pushNamedAndRemoveUntil('/tourist', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return HeritageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
            ),
            onPressed: () {
              context.read<AuthViewModel>().clearError();
              ScaffoldMessenger.of(context).clearSnackBars();
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Container(
              width: isDesktop ? 480 : double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0D2825) : Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: isDark ? Border.all(color: const Color(0xFF1E3A34)) : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cultural Explorer Welcome Icon
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFFFFD54F).withValues(alpha: 0.12)
                              : const Color(0xFF004D40).withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.explore_rounded,
                          color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Header Title
                    Text(
                      'Create Account',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 26,
                        color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                      ),
                    ),
                    const SizedBox(height: 6),

                    Text(
                      'Join the cultural preservation movement to discover traditional crafts & artisan studios across Malaysia.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        color: isDark ? Colors.white70 : Colors.grey[600],
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Full Name Field
                    TextFormField(
                      controller: _fullNameController,
                      textCapitalization: TextCapitalization.words,
                      style: GoogleFonts.plusJakartaSans(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 13.5,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        labelStyle: TextStyle(
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                        hintText: 'e.g. Siti Nurhaliza',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white38 : Colors.grey[400],
                        ),
                        prefixIcon: Icon(
                          Icons.person_outline_rounded,
                          color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF041412) : const Color(0xFFF8F9FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: isDark ? const BorderSide(color: Color(0xFF1E3A34)) : BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: isDark ? const BorderSide(color: Color(0xFF1E3A34)) : BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                            width: 1.5,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Please enter your full name';
                        }
                        return ProfileValidator.validateFullName(v);
                      },
                    ),

                    const SizedBox(height: 16),

                    // Unique Username / Handle Field
                    TextFormField(
                      controller: _usernameController,
                      style: GoogleFonts.plusJakartaSans(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 13.5,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Unique Username / Handle',
                        labelStyle: TextStyle(
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                        hintText: 'e.g. siticrafts',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white38 : Colors.grey[400],
                        ),
                        prefixIcon: Icon(
                          Icons.alternate_email_rounded,
                          color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                        ),
                        suffixIcon: _isCheckingUsername
                            ? Padding(
                                padding: const EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                                  ),
                                ),
                              )
                            : (_isUsernameAvailable != null
                                ? Icon(
                                    _isUsernameAvailable! ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                    color: _isUsernameAvailable! ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                  )
                                : null),
                        helperText: _usernameMessage,
                        helperStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _isUsernameAvailable == true
                              ? const Color(0xFF10B981)
                              : (_isUsernameAvailable == false
                                  ? const Color(0xFFEF4444)
                                  : (isDark ? Colors.white54 : Colors.grey[600])),
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF041412) : const Color(0xFFF8F9FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: isDark ? const BorderSide(color: Color(0xFF1E3A34)) : BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: isDark ? const BorderSide(color: Color(0xFF1E3A34)) : BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                            width: 1.5,
                          ),
                        ),
                      ),
                      validator: (v) {
                        final err = ProfileValidator.validateUsername(v);
                        if (err != null) return err;
                        if (_isUsernameAvailable == false) {
                          return 'This username is already taken';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Email Address Field
                    TextFormField(
                      controller: _emailController,
                      focusNode: _emailFocusNode,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.plusJakartaSans(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 13.5,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        labelStyle: TextStyle(
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                        hintText: 'e.g. siti@example.com',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white38 : Colors.grey[400],
                        ),
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                        ),
                        suffixIcon: _isCheckingEmail
                            ? Padding(
                                padding: const EdgeInsets.all(14),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                                  ),
                                ),
                              )
                            : (_emailAccountMessage == null
                                ? null
                                : Icon(
                                    _existingAccountCheck != null
                                        ? Icons.error_outline_rounded
                                        : Icons.check_circle_outline_rounded,
                                    color: _existingAccountCheck != null
                                        ? const Color(0xFFDC2626)
                                        : const Color(0xFF10B981),
                                  )),
                        helperText: _emailAccountMessage,
                        helperMaxLines: 2,
                        helperStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _isCheckingEmail
                              ? (isDark ? Colors.white54 : Colors.grey[600])
                              : (_existingAccountCheck != null
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF10B981)),
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF041412) : const Color(0xFFF8F9FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: isDark ? const BorderSide(color: Color(0xFF1E3A34)) : BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: isDark ? const BorderSide(color: Color(0xFF1E3A34)) : BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                            width: 1.5,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Please enter your email address';
                        }
                        final validation = ProfileValidator.validateEmail(v);
                        if (validation != null) return validation;
                        if (_existingAccountCheck?.exists == true) {
                          return 'This email is already registered';
                        }
                        return null;
                      },
                    ),

                    // Real-Time Existing Account Detection Banner
                    if (_existingAccountCheck != null && _existingAccountCheck!.exists) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF3B1212) : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? const Color(0xFF991B1B) : const Color(0xFFFCA5A5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Account Already Exists',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
                                    ),
                                  ),
                                  Text(
                                    'An account is already registered with this email. Would you like to sign in instead?',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: isDark ? const Color(0xFFFECACA) : const Color(0xFF7F1D1D),
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            FilledButton(
                              onPressed: () {
                                context.read<AuthViewModel>().clearError();
                                ScaffoldMessenger.of(context).clearSnackBars();
                                Navigator.of(context).pushReplacementNamed('/login');
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFDC2626),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Sign In',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: GoogleFonts.plusJakartaSans(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 13.5,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                        hintText: 'Must be at least 8 characters',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white38 : Colors.grey[400],
                        ),
                        prefixIcon: Icon(
                          Icons.key_rounded,
                          color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: isDark ? Colors.white60 : Colors.grey[600],
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF041412) : const Color(0xFFF8F9FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: isDark ? const BorderSide(color: Color(0xFF1E3A34)) : BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: isDark ? const BorderSide(color: Color(0xFF1E3A34)) : BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                            width: 1.5,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Please enter a password';
                        }
                        if (v.trim().length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        final cleanUsername = _usernameController.text.trim().replaceAll('@', '').toLowerCase();
                        if (cleanUsername.length >= 3 && v.trim().toLowerCase() == cleanUsername) {
                          return 'Password is too similar to your username';
                        }
                        return null;
                      },
                    ),

                    // Interactive Password Strength Meter & Live Checklist
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: PasswordStrengthMeter(password: _passwordController.text),
                    ),

                    const SizedBox(height: 16),

                    // Confirm Password Field
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      style: GoogleFonts.plusJakartaSans(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 13.5,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        labelStyle: TextStyle(
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                        hintText: 'Re-enter your password',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white38 : Colors.grey[400],
                        ),
                        prefixIcon: Icon(
                          Icons.lock_reset_rounded,
                          color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                            color: isDark ? Colors.white60 : Colors.grey[600],
                          ),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF041412) : const Color(0xFFF8F9FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: isDark ? const BorderSide(color: Color(0xFF1E3A34)) : BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: isDark ? const BorderSide(color: Color(0xFF1E3A34)) : BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                            width: 1.5,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (v.trim() != _passwordController.text.trim()) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Register Button
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: authVM.isLoading ? null : _handleRegister,
                        style: FilledButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFF1E3A34) : const Color(0xFF004D40),
                          foregroundColor: isDark ? const Color(0xFFFFD54F) : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: authVM.isLoading
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: isDark ? const Color(0xFFFFD54F) : Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                'Create Explorer Account',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? const Color(0xFFFFD54F) : Colors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // In-App Artisan Notice Hint
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF231F10) : const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.palette_outlined,
                            size: 18,
                            color: isDark ? const Color(0xFFFFD54F) : const Color(0xFFD97706),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Are you a Master Artisan? You can register your heritage workshop inside your Profile anytime after joining!',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: isDark ? const Color(0xFFFFE082) : const Color(0xFF92400E),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Sign In Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: isDark ? Colors.white70 : Colors.grey[700],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            context.read<AuthViewModel>().clearError();
                            ScaffoldMessenger.of(context).clearSnackBars();
                            Navigator.of(context).pushReplacementNamed('/login');
                          },
                          child: Text(
                            'Sign In',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
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
      ),
    );
  }
}
