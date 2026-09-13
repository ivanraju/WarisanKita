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
import 'package:warisan_kita/data/services/connectivity_service.dart';
import 'package:warisan_kita/viewmodels/theme_viewmodel.dart';
import 'package:warisan_kita/ui/core/widgets/heritage_background.dart';
import 'package:warisan_kita/ui/widgets/heritage_logo.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0D2825) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: isDark ? const BorderSide(color: Color(0xFF1E3A34)) : BorderSide.none,
        ),
        title: Row(
          children: [
            Icon(
              Icons.switch_account_rounded,
              color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
              size: 26,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Select Active Role Context',
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 20,
                  color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                ),
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
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                height: 1.4,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 18),
            ...roles.map((role) {
              final isArtisan = role.contains('Artisan');
              final bool isArtisanSuspended = isArtisan && (authVM.currentUser?.isArtisanStudioSuspended == true);
              final bool isArtisanPending = isArtisan && !isArtisanSuspended && (authVM.currentUser?.isApprovedArtisan != true);

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: isDark
                      ? (isArtisan
                          ? (isArtisanSuspended ? const Color(0xFF381414) : const Color(0xFF261D0C))
                          : const Color(0xFF0A2233))
                      : (isArtisan
                          ? (isArtisanSuspended ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7))
                          : const Color(0xFFE0F2FE)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: isDark
                        ? BorderSide(
                            color: isArtisan
                                ? (isArtisanSuspended ? const Color(0xFF991B1B) : const Color(0xFFD97706))
                                : const Color(0xFF0284C7),
                            width: 1.2,
                          )
                        : BorderSide.none,
                  ),
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
                                          color: isDark
                                              ? (isArtisan
                                                  ? (isArtisanSuspended
                                                      ? const Color(0xFFFCA5A5)
                                                      : (isArtisanPending ? Colors.white70 : const Color(0xFFFFD54F)))
                                                  : const Color(0xFF7DD3FC))
                                              : (isArtisan
                                                  ? (isArtisanSuspended
                                                      ? const Color(0xFF991B1B)
                                                      : (isArtisanPending ? Colors.grey[700] : const Color(0xFFB45309)))
                                                  : const Color(0xFF0369A1)),
                                        ),
                                      ),
                                    ),
                                    if (isArtisanSuspended) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'STUDIO SUSPENDED',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : const Color(0xFF991B1B),
                                          ),
                                        ),
                                      ),
                                    ] else if (isArtisanPending) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'PENDING REVIEW',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? const Color(0xFFFEF3C7) : const Color(0xFF92400E),
                                          ),
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
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: isDark ? Colors.white60 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isArtisanPending ? Icons.lock_outline_rounded : Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: isDark
                                ? Colors.white38
                                : (isArtisanPending ? Colors.grey : Colors.black45),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    final connectivity = context.read<ConnectivityService?>();
    if (connectivity != null && connectivity.isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text('Cannot sign in while offline. Please connect to the internet.'),
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

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final authVM = context.read<AuthViewModel>();

    final result = await authVM.login(email, password);

    if (!mounted) return;

    if (!result.success) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      if (kIsWeb && (result.message?.contains('ACCESS DENIED') == true)) {
        showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            backgroundColor: isDark ? const Color(0xFF0D2825) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: isDark ? const BorderSide(color: Color(0xFF1E3A34)) : BorderSide.none,
            ),
            title: Row(
              children: [
                Icon(Icons.phonelink_lock_rounded, color: isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444), size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Access Denied: Mobile App Required',
                    style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B)),
                  ),
                ),
              ],
            ),
            content: Text(
              'This Web Portal is exclusively for Administrators.\n\nArtisan Studio & Cultural Explorer accounts cannot log in to the Web Portal. Please use the Warisan Kita Mobile App on your Android or iOS device.',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.5, color: isDark ? Colors.white70 : Colors.black87),
            ),
            actions: [
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                  foregroundColor: isDark ? const Color(0xFF004D40) : Colors.white,
                ),
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
            backgroundColor: isDark ? const Color(0xFF0D2825) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: isDark ? const BorderSide(color: Color(0xFF1E3A34)) : BorderSide.none,
            ),
            title: Row(
              children: [
                Icon(Icons.mark_email_unread_rounded, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7), size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Email Verification Required',
                    style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40)),
                  ),
                ),
              ],
            ),
            content: Text(
              'Your email address has not been verified yet. Please enter the 6-digit verification code sent to your inbox to activate your account.',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.5, color: isDark ? Colors.white70 : Colors.black87),
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(foregroundColor: isDark ? Colors.white70 : Colors.black54),
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                  foregroundColor: isDark ? const Color(0xFF004D40) : Colors.white,
                ),
                onPressed: () {
                  final targetEmail = result.unverifiedEmail ?? _emailController.text.trim();
                  Navigator.pop(dialogCtx);
                  context.read<AuthViewModel>().clearError();
                  ScaffoldMessenger.of(context).clearSnackBars();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EmailVerificationScreen(
                        email: targetEmail,
                        targetRoute: '/tourist',
                        resendOnOpen: true,
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
      final isDark = Theme.of(context).brightness == Brightness.dark;
      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0D2825) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: isDark ? const BorderSide(color: Color(0xFF1E3A34)) : BorderSide.none,
          ),
          title: Row(
            children: [
              Icon(Icons.laptop_chromebook_rounded, color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40), size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Admin Web Portal Only',
                  style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40)),
                ),
              ),
            ],
          ),
          content: Text(
            'Administrator accounts and moderation features are hosted exclusively on the Desktop Web Portal.\n\nPlease open the Admin Portal in a web browser at:\nhttps://warisan-kita.vercel.app',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.5, color: isDark ? Colors.white70 : Colors.black87),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: isDark ? Colors.white70 : Colors.black54),
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('DISMISS'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                foregroundColor: isDark ? const Color(0xFF004D40) : Colors.white,
              ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return HeritageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  width: isDesktop ? 480 : double.infinity,
                  padding: const EdgeInsets.all(32.0),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0D2825) : Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDark ? const Color(0xFF1E3A34) : const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
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
                        child: HeritageLogo(
                          size: 48,
                          showBadge: true,
                          glow: true,
                          badgeColor: isDark
                              ? const Color(0xFF133B36)
                              : Colors.white,
                          primaryColor: isDark
                              ? const Color(0xFF34D399)
                              : const Color(0xFF004D40),
                          accentColor: const Color(0xFFFFD54F),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        kIsWeb ? 'Warisan Kita • Admin Portal' : 'WarisanKita',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 26,
                          color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
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
                          color: isDark ? const Color(0xFF34D399) : const Color(0xFF004D40),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Error Banner
                  if (authVM.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF3B1212) : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF991B1B) : const Color(0xFFFCA5A5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              authVM.errorMessage!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFEF4444),
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
                          style: GoogleFonts.plusJakartaSans(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 13.5,
                          ),
                          decoration: InputDecoration(
                            labelText: kIsWeb ? 'Admin Username' : 'Username / Email Address',
                            labelStyle: TextStyle(
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                            ),
                            hintText: kIsWeb ? 'admin' : 'e.g. siticrafts or user@example.com',
                            hintStyle: TextStyle(
                              color: isDark ? Colors.white38 : Colors.grey[400],
                            ),
                            prefixIcon: Icon(
                              kIsWeb ? Icons.admin_panel_settings_rounded : Icons.person_outline_rounded,
                              size: 20,
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
                          style: GoogleFonts.plusJakartaSans(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 13.5,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: TextStyle(
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                            ),
                            hintText: 'Enter your password',
                            hintStyle: TextStyle(
                              color: isDark ? Colors.white38 : Colors.grey[400],
                            ),
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              size: 20,
                              color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                size: 20,
                                color: isDark ? Colors.white60 : Colors.grey[600],
                              ),
                              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
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
                            color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
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
                      backgroundColor: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                      foregroundColor: isDark ? const Color(0xFF00382E) : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: authVM.isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: isDark ? const Color(0xFF00382E) : Colors.white,
                            ),
                          )
                        : Text(
                            kIsWeb ? 'ADMIN SIGN IN' : 'SIGN IN',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: isDark ? const Color(0xFF00382E) : Colors.white,
                            ),
                          ),
                  ),

                  const SizedBox(height: 16),

                  // Bottom Footer: Web Mobile App Notice vs Mobile Registration Link
                  if (kIsWeb) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF063529) : const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? const Color(0xFF059669) : const Color(0xFFA7F3D0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.phone_android_rounded,
                            size: 20,
                            color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Cultural Tourists & Artisans: Please sign in via the Warisan Kita Mobile App.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46),
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
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
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
                              color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
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
        // Theme switcher button
        Positioned(
          top: 16,
          right: 16,
          child: SafeArea(
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0D2825).withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? const Color(0xFF1E3A34) : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                  size: 20,
                ),
                tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                onPressed: () {
                  context.read<ThemeViewModel>().toggleTheme(!isDark);
                },
              ),
            ),
          ),
        ),
      ],
    ),
  ),
);
  }

}

