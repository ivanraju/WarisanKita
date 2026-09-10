import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/domain/models/user.dart';
import 'package:warisan_kita/domain/validators/profile_validator.dart';
import 'package:warisan_kita/ui/auth/email_verification_screen.dart';
import 'package:warisan_kita/ui/auth/widgets/password_strength_meter.dart';
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
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
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
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EmailVerificationScreen(
            email: email,
            targetRoute: result.route ?? '/tourist',
            role: 'Tourist',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).clearSnackBars();
    Navigator.of(context).pushNamedAndRemoveUntil('/tourist', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF004D40)),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
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
                        color: const Color(0xFF004D40).withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.explore_rounded,
                        color: Color(0xFF004D40),
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
                      color: const Color(0xFF004D40),
                    ),
                  ),
                  const SizedBox(height: 6),

                  Text(
                    'Join the cultural preservation movement to discover traditional crafts & artisan studios across Malaysia.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Full Name Field
                  TextFormField(
                    controller: _fullNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'e.g. Siti Nurhaliza',
                      prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF004D40)),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
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
                    decoration: InputDecoration(
                      labelText: 'Unique Username / Handle',
                      hintText: 'e.g. siticrafts',
                      prefixIcon: const Icon(Icons.alternate_email_rounded, color: Color(0xFF004D40)),
                      suffixIcon: _isCheckingUsername
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF004D40)),
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
                            : (_isUsernameAvailable == false ? const Color(0xFFEF4444) : Colors.grey[600]),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
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
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'e.g. siti@example.com',
                      prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF004D40)),
                      suffixIcon: _isCheckingEmail
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
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
                            ? Colors.grey[600]
                            : (_existingAccountCheck != null
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF10B981)),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
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
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Color(0xFFDC2626), size: 20),
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
                                    color: const Color(0xFF991B1B),
                                  ),
                                ),
                                Text(
                                  'An account is already registered with this email. Would you like to sign in instead?',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: const Color(0xFF7F1D1D),
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
                            child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white)),
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
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'At least 8 characters',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF004D40)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.grey[600],
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please enter a password';
                      }
                      if (v.trim().length < 8) {
                        return 'Password must be greater than 7 characters';
                      }
                      return null;
                    },
                  ),

                  // 📊 Interactive Password Strength Meter & Live Checklist
                  PasswordStrengthMeter(password: _passwordController.text),

                  const SizedBox(height: 16),

                  // Confirm Password Field
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      hintText: 'Re-enter your password',
                      prefixIcon: const Icon(Icons.lock_reset_rounded, color: Color(0xFF004D40)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.grey[600],
                        ),
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
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
                        backgroundColor: const Color(0xFF004D40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: authVM.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'Create Explorer Account',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // In-App Artisan Notice Hint
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.palette_outlined, size: 18, color: Color(0xFFD97706)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Are you a Master Artisan? You can register your heritage workshop inside your Profile anytime after joining!',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: const Color(0xFF92400E),
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
                          color: Colors.grey[700],
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
                            color: const Color(0xFF004D40),
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
    );
  }
}
