import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/ui/core/widgets/heritage_background.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String? targetRoute;
  final String? role;
  final bool autoStartTimer;
  final bool resendOnOpen;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    this.targetRoute,
    this.role,
    this.autoStartTimer = true,
    this.resendOnOpen = false,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _resendCooldown = 0;
  Timer? _timer;
  bool _isVerifying = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AuthViewModel>().clearError();
        ScaffoldMessenger.of(context).clearSnackBars();
        if (widget.resendOnOpen) {
          _handleResend(force: true);
        }
      }
    });
    if (widget.autoStartTimer && !widget.resendOnOpen) {
      _startCooldownTimer();
    }
  }

  void _startCooldownTimer() {
    _timer?.cancel();
    if (!mounted) return;
    setState(() => _resendCooldown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        t.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
    if (value.length > 1) {
      final clean = value.replaceAll(RegExp(r'\D'), '');
      if (clean.isNotEmpty) {
        for (int i = 0; i < 6 && i < clean.length; i++) {
          _controllers[i].text = clean[i];
        }
        if (clean.length >= 6) {
          _focusNodes[5].unfocus();
          _handleVerify();
          return;
        } else {
          _focusNodes[clean.length.clamp(0, 5)].requestFocus();
        }
      }
      return;
    }

    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        if (_otpCode.length == 6) {
          _handleVerify();
        }
      }
    }
  }

  Future<void> _handleVerify() async {
    final code = _otpCode.trim();
    if (code.length != 6) {
      setState(() {
        _errorMessage = 'Please enter all 6 digits of the verification code.';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    final authVM = context.read<AuthViewModel>();
    final result = await authVM.verifyEmailOtp(
      email: widget.email,
      token: code,
      targetRoute: widget.targetRoute,
    );

    if (!mounted) return;

    setState(() => _isVerifying = false);

    if (!result.success) {
      final raw = (result.message ?? '').trim();
      final lower = raw.toLowerCase();
      final isTokenOrTechError = lower.contains('token') ||
          lower.contains('expired') ||
          lower.contains('invalid') ||
          lower.contains('authapiexception') ||
          lower.contains('authexception') ||
          lower.contains('exception') ||
          lower.contains('otp');

      final displayMsg = isTokenOrTechError
          ? 'Invalid or expired verification code. Please check your 6-digit code or request a new one.'
          : (raw.isNotEmpty ? raw : 'Invalid or expired verification code. Please try again.');

      setState(() {
        _errorMessage = displayMsg;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(displayMsg),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    context.read<AuthViewModel>().clearError();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 Email verified successfully! Welcome to Warisan Kita.'),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );

    final destination = result.route ?? widget.targetRoute ?? '/tourist';
    _timer?.cancel();
    Navigator.of(context).pushNamedAndRemoveUntil(destination, (route) => false);
  }

  Future<void> _handleResend({bool force = false}) async {
    if (_resendCooldown > 0 && !force) return;

    _startCooldownTimer();
    final authVM = context.read<AuthViewModel>();
    final sent = await authVM.resendVerificationOtp(widget.email);

    if (!mounted) return;

    if (sent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('A fresh 6-digit code has been sent to ${widget.email}'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final err = authVM.errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err != null && err.isNotEmpty
              ? err
              : 'Failed to resend code. Please try again later.'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleChangeEmail() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF063529) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              Icons.contact_mail_outlined,
              color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Change Email Address?',
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 20,
                  color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Going back will cancel your pending registration for ${widget.email} so you can update your email address or use your chosen username again.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            color: isDark ? Colors.white70 : const Color(0xFF475569),
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(
              'Keep Waiting',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white60 : Colors.grey[600],
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(
              'Change Email',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isVerifying = true);
    final authVM = context.read<AuthViewModel>();
    await authVM.cancelPendingRegistration(widget.email);
    if (!mounted) return;
    setState(() => _isVerifying = false);

    _timer?.cancel();
    authVM.clearError();
    ScaffoldMessenger.of(context).clearSnackBars();
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
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
              Navigator.of(context).pop(false);
            },
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                padding: EdgeInsets.all(isDesktop ? 36 : 24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0D2825) : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isDark ? const Color(0xFF1E3A34) : Colors.transparent,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.4)
                          : Colors.black.withValues(alpha: 0.05),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Heritage Verification Icon
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF063529)
                              : const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(
                          Icons.mark_email_read_rounded,
                          color: isDark
                              ? const Color(0xFF34D399)
                              : const Color(0xFF0284C7),
                          size: 38,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Header Title
                    Text(
                      'Verify Your Email',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 26,
                        color: isDark
                            ? const Color(0xFFFFD54F)
                            : const Color(0xFF004D40),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Email Caption
                    Text(
                      'We have sent a 6-digit verification code to:',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 6),

                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF041412)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF1E3A34)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(
                          widget.email,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? const Color(0xFFFFD54F)
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // 6 OTP Digit Input Boxes
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final boxWidth = ((constraints.maxWidth - 50) / 6).clamp(32.0, 52.0);
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(6, (index) {
                            return SizedBox(
                              width: boxWidth,
                              height: boxWidth * 1.18,
                              child: Focus(
                                onKeyEvent: (node, event) {
                                  if (event is KeyDownEvent &&
                                      event.logicalKey == LogicalKeyboardKey.backspace) {
                                    if (_controllers[index].text.isEmpty && index > 0) {
                                      _controllers[index - 1].clear();
                                      _focusNodes[index - 1].requestFocus();
                                      return KeyEventResult.handled;
                                    }
                                  }
                                  return KeyEventResult.ignored;
                                },
                                child: TextFormField(
                                  controller: _controllers[index],
                                  focusNode: _focusNodes[index],
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  maxLength: 1,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF004D40),
                                  ),
                                  decoration: InputDecoration(
                                    counterText: '',
                                    filled: true,
                                    fillColor: isDark
                                        ? const Color(0xFF041412)
                                        : const Color(0xFFF8F9FA),
                                    contentPadding: EdgeInsets.zero,
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: isDark
                                            ? const Color(0xFF1E3A34)
                                            : Colors.grey.shade300,
                                        width: 1.5,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: isDark
                                            ? const Color(0xFFFFD54F)
                                            : const Color(0xFF004D40),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  onChanged: (v) => _onDigitChanged(index, v),
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFFEF4444),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Verify Button
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: _isVerifying ? null : _handleVerify,
                        style: FilledButton.styleFrom(
                          backgroundColor: isDark
                              ? const Color(0xFF10B981)
                              : const Color(0xFF004D40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _isVerifying
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                'Verify & Proceed',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Resend Code Action with Countdown
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          "Didn't receive the code? ",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: isDark ? Colors.white70 : Colors.grey[700],
                          ),
                        ),
                        GestureDetector(
                          onTap: _resendCooldown == 0 ? _handleResend : null,
                          child: Text(
                            _resendCooldown > 0
                                ? 'Resend in ${_resendCooldown}s'
                                : 'Resend Code',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _resendCooldown > 0
                                  ? (isDark ? Colors.white30 : Colors.grey[400])
                                  : (isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40)),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Wrong Email / Back Link
                    Center(
                      child: TextButton.icon(
                        onPressed: _handleChangeEmail,
                        icon: Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                        label: Text(
                          'Change email address',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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
