import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:warisan_kita/domain/models/user.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';
import 'package:warisan_kita/ui/artisan/artisan_application_pending_screen.dart';
import 'package:warisan_kita/ui/auth/email_verification_screen.dart';
import 'package:warisan_kita/ui/auth/forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _emailController.addListener(_clearErrorOnTyping);
    _passwordController.addListener(_clearErrorOnTyping);

    final authVM = context.read<AuthViewModel>();
    if (authVM.errorMessage != null || authVM.statusMessage != null) {
      authVM.clearError();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        context.read<AuthViewModel>().clearError();
        ScaffoldMessenger.of(context).clearSnackBars();
      }
      if (kIsWeb) {
        final authVM = context.read<AuthViewModel>();
        final UserModel? user = authVM.currentUser ?? await authVM.restoreSession();
        if (mounted && user != null && user.isAdmin) {
          Navigator.of(context).pushReplacementNamed('/admin');
        }
      }
    });
  }

  void _clearErrorOnTyping() {
    final authVM = context.read<AuthViewModel>();
    if (authVM.errorMessage != null) {
      authVM.clearError();
    }
  }

  @override
  void dispose() {
    _emailController.removeListener(_clearErrorOnTyping);
    _passwordController.removeListener(_clearErrorOnTyping);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // UC001 - A5: Multi-Role Selection Modal Dialog [M7] [FR001_4]
  void _showMultiRoleDialog(BuildContext context, AuthViewModel authVM, List<String> roles) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.switch_account_rounded, color: Color(0xFF004D40), size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Select Active Role Context',
                style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: const Color(0xFF004D40)),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Multiple roles are associated with this email. Please select your active session role:',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.4, color: Colors.black87),
            ),
            const SizedBox(height: 18),
            ...roles.map((role) {
              final isArtisan = role.contains('Artisan');
              final bool isArtisanSuspended = isArtisan && (authVM.currentUser?.isArtisanStudioSuspended == true);
              final bool isArtisanPending = isArtisan && !isArtisanSuspended && (authVM.currentUser?.isApprovedArtisan != true);

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: isArtisan
                      ? (isArtisanSuspended ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7))
                      : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      if (isArtisan && isArtisanSuspended) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('⚠️ Your Master Artisan Studio is currently suspended by admin. Please explore as a Cultural Tourist.'),
                            backgroundColor: Color(0xFFEF4444),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }

                      Navigator.of(ctx).pop();
                      authVM.selectActiveRole(role);
                      if (isArtisan) {
                        if (isArtisanPending) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('⏳ Opening Master Artisan Application Status...'),
                              backgroundColor: Color(0xFFD97706),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => ArtisanApplicationPendingScreen(
                                studioName: authVM.currentUser?.studioName ?? 'Master Artisan Studio',
                                craftCategory: authVM.currentUser?.craftCategory ?? 'Heritage Craft',
                                ssmNumber: authVM.currentUser?.ssmNumber ?? 'Pending Document Verification',
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Active Session Role Set: $role'),
                              backgroundColor: const Color(0xFF10B981),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          Navigator.of(context).pushReplacementNamed('/artisan');
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Active Session Role Set: $role'),
                            backgroundColor: const Color(0xFF10B981),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        Navigator.of(context).pushReplacementNamed('/tourist');
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Icon(
                            isArtisan
                                ? (isArtisanSuspended
                                    ? Icons.block_rounded
                                    : (isArtisanPending ? Icons.lock_clock_rounded : Icons.palette_rounded))
                                : Icons.explore_rounded,
                            color: isArtisan
                                ? (isArtisanSuspended
                                    ? const Color(0xFFEF4444)
                                    : (isArtisanPending ? Colors.grey : const Color(0xFFD97706)))
                                : const Color(0xFF0284C7),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        role,
                                        softWrap: true,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: isArtisan
                                              ? (isArtisanSuspended
                                                  ? const Color(0xFF991B1B)
                                                  : (isArtisanPending ? Colors.grey[700] : const Color(0xFFB45309)))
                                              : const Color(0xFF0369A1),
                                        ),
                                      ),
                                    ),
                                    if (isArtisanSuspended) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFCA5A5),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'STUDIO SUSPENDED',
                                          style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF991B1B)),
                                        ),
                                      ),
                                    ] else if (isArtisanPending) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF3C7),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'PENDING REVIEW',
                                          style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF92400E)),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  isArtisan
                                      ? (isArtisanSuspended
                                          ? 'Studio license suspended by admin. Please contact support.'
                                          : (isArtisanPending ? 'Studio application currently under admin verification' : 'Access studio management & masterwork'))
                                      : 'Explore crafts, map & quests',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isArtisanPending ? Icons.lock_outline_rounded : Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: isArtisanPending ? Colors.grey : Colors.black45,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final authVM = context.read<AuthViewModel>();

    final result = await authVM.login(email, password);

    if (!mounted) return;

    if (!result.success) {
      if (kIsWeb && (result.message?.contains('ACCESS DENIED') == true)) {
        showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.phonelink_lock_rounded, color: Color(0xFFEF4444), size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Access Denied: Mobile App Required',
                    style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: const Color(0xFF991B1B)),
                  ),
                ),
              ],
            ),
            content: Text(
              'This Web Portal is exclusively for Administrators.\n\nArtisan Studio & Cultural Explorer accounts cannot log in to the Web Portal. Please use the Warisan Kita Mobile App on your Android or iOS device.',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.5, color: Colors.black87),
            ),
            actions: [
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF004D40)),
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      if (result.requiresEmailVerification) {
        showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                const Icon(Icons.mark_email_unread_rounded, color: Color(0xFF0284C7), size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Email Verification Required',
                    style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: const Color(0xFF004D40)),
                  ),
                ),
              ],
            ),
            content: Text(
              'Your email address has not been verified yet. Please enter the 6-digit verification code sent to your inbox to activate your account.',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.5, color: Colors.black87),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF004D40)),
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  context.read<AuthViewModel>().clearError();
                  ScaffoldMessenger.of(context).clearSnackBars();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EmailVerificationScreen(
                        email: result.unverifiedEmail ?? _emailController.text.trim(),
                        targetRoute: '/tourist',
                      ),
                    ),
                  );
                },
                child: const Text('Verify Email Now'),
              ),
            ],
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Authentication failed'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Handle Multi-Role Selection Prompt [M7] [A5]
    if (result.requiresRoleSelection) {
      _showMultiRoleDialog(context, authVM, result.availableRoles);
      return;
    }

    // Handle Pending Artisan [A4]
    if (result.route == 'pending_artisan' || result.route == '/pending-artisan') {
      final isRejected = result.user?.status.toUpperCase() == 'REJECTED' ||
          result.user?.artisanStatus?.toUpperCase() == 'REJECTED';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isRejected
                ? 'ARTISAN APPLICATION: Needs Review & Document Updates'
                : 'ARTISAN APPLICATION SUBMITTED: Pending Admin Review',
          ),
          backgroundColor: isRejected ? const Color(0xFFEF4444) : const Color(0xFFD97706),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ArtisanApplicationPendingScreen(
            studioName: result.user?.studioName ?? '',
            craftCategory: result.user?.craftCategory ?? '',
            ssmNumber: result.user?.ssmNumber ?? '',
          ),
        ),
      );
      return;
    }

    // 📱 Mobile Guard: If logging in as Administrator on mobile app
    if (!kIsWeb && result.user?.role == 'Admin') {
      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.laptop_chromebook_rounded, color: Color(0xFF004D40), size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Admin Web Portal Only',
                  style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: const Color(0xFF004D40)),
                ),
              ),
            ],
          ),
          content: Text(
            'Administrator accounts and moderation features are hosted exclusively on the Desktop Web Portal.\n\nPlease open the Admin Portal in a web browser at:\nhttps://warisan-kita.vercel.app',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.5, color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('DISMISS'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF004D40)),
              icon: const Icon(Icons.open_in_browser_rounded, size: 18),
              label: const Text('OPEN WEB PORTAL'),
              onPressed: () async {
                Navigator.pop(dialogCtx);
                final uri = Uri.parse('https://warisan-kita.vercel.app');
                try {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } catch (e) {
                  await launchUrl(uri, mode: LaunchMode.platformDefault);
                }
              },
            ),
          ],
        ),
      );
      return;
    }

    // Handle Regular RBAC Routes [M2]
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('LOGIN SUCCESSFUL: Authenticated as ${result.user?.role ?? "User"}'),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (result.route != null) {
      Navigator.of(context).pushReplacementNamed(result.route!);
    } else {
      Navigator.of(context).pushReplacementNamed('/tourist');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            width: isDesktop ? 480 : double.infinity,
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF004D40).withOpacity(0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Logo Badge
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF004D40).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      kIsWeb ? Icons.security_rounded : Icons.auto_awesome_mosaic_rounded,
                      size: 36,
                      color: const Color(0xFF004D40),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  kIsWeb ? 'Warisan Kita • Admin Portal' : 'WarisanKita',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 26,
                    color: const Color(0xFF004D40),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),

                Text(
                  kIsWeb ? 'MALAYSIAN HERITAGE MODERATION CONSOLE' : 'PLEASE ENTER LOGIN CREDENTIALS',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: const Color(0xFF004D40),
                  ),
                ),

                const SizedBox(height: 20),

                // Error Banner
                if (authVM.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authVM.errorMessage!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Form Container with Validation
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Email / Username Input
                      TextFormField(
                        controller: _emailController,
                        keyboardType: kIsWeb ? TextInputType.text : TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: kIsWeb ? 'Admin Username' : 'Username / Email Address',
                          hintText: kIsWeb ? 'admin' : 'e.g. siticrafts or user@example.com',
                          prefixIcon: Icon(
                            kIsWeb ? Icons.admin_panel_settings_rounded : Icons.person_outline_rounded,
                            size: 20,
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return kIsWeb ? 'Please enter your admin username' : 'Please enter your username or email address';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Password Input
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter your password',
                          prefixIcon: const Icon(Icons.lock_outline, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                // Forgot Password Button (Hidden on Web Admin Portal)
                if (!kIsWeb) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        context.read<AuthViewModel>().clearError();
                        ScaffoldMessenger.of(context).clearSnackBars();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Forgot Password?',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF004D40),
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Main Login Button
                FilledButton(
                  onPressed: authVM.isLoading ? null : _handleLogin,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF004D40),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: authVM.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text(
                          kIsWeb ? 'ADMIN SIGN IN' : 'SIGN IN',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),

                const SizedBox(height: 16),

                // Bottom Footer: Web Mobile App Notice vs Mobile Registration Link
                if (kIsWeb) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.phone_android_rounded, size: 20, color: Color(0xFF047857)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Cultural Tourists & Artisans: Please sign in via the Warisan Kita Mobile App.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF065F46),
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.black54),
                      ),
                      GestureDetector(
                        onTap: () {
                          context.read<AuthViewModel>().clearError();
                          ScaffoldMessenger.of(context).clearSnackBars();
                          Navigator.of(context).pushNamed('/register');
                        },
                        child: Text(
                          'Register / Join Us',
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
              ],
            ),
          ),
        ),
      ),
    );
  }

}

