import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/ui/tourist/apply_artisan_screen.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';

class ArtisanApplicationPendingScreen extends StatelessWidget {
  final String studioName;
  final String craftCategory;
  final String ssmNumber;

  const ArtisanApplicationPendingScreen({
    super.key,
    this.studioName = '',
    this.craftCategory = '',
    this.ssmNumber = '',
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authVM = context.watch<AuthViewModel>();
    final user = authVM.currentUser;
    final String effectiveStudio = (user?.studioName != null && user!.studioName!.isNotEmpty)
        ? user.studioName!
        : ((studioName.isNotEmpty) ? studioName : 'Traditional Craft Studio');
    final String effectiveCraft = (user?.craftCategory != null && user!.craftCategory!.isNotEmpty)
        ? user.craftCategory!
        : ((craftCategory.isNotEmpty) ? craftCategory : 'Heritage Craft');
    final String effectiveSsm = (user?.ssmNumber != null && user!.ssmNumber!.isNotEmpty)
        ? user.ssmNumber!
        : ((ssmNumber.isNotEmpty) ? ssmNumber : 'Under Verification');

    final bool isRejected = user?.status.toUpperCase() == 'REJECTED' ||
        user?.artisanStatus?.toUpperCase() == 'REJECTED';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF041412) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF041412) : Colors.white,
        elevation: 0,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                ),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Text(
          'Application Status',
          style: GoogleFonts.dmSerifDisplay(
            color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
            tooltip: 'Log Out',
            onPressed: () async {
              final authVM = context.read<AuthViewModel>();
              await authVM.logout();
              if (!context.mounted) return;
              Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/login', (route) => false);
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            width: isDesktop ? 550 : double.infinity,
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0D2825) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: isDark ? Border.all(color: const Color(0xFF1E3A34)) : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated Status Icon Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isRejected
                        ? (isDark ? const Color(0xFF2A1215) : const Color(0xFFFEF2F2))
                        : (isDark ? const Color(0xFF2E2305) : const Color(0xFFFEF3C7)),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isRejected
                          ? (isDark ? const Color(0xFF5C1D24) : const Color(0xFFFCA5A5))
                          : (isDark ? const Color(0xFF78590D) : const Color(0xFFFDE68A)),
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    isRejected ? Icons.cancel_outlined : Icons.hourglass_top_rounded,
                    size: 48,
                    color: isRejected ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                  ),
                ),

                const SizedBox(height: 20),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isRejected
                        ? (isDark ? const Color(0xFF2A1215) : const Color(0xFFFEF2F2))
                        : (isDark ? const Color(0xFF2E2305) : const Color(0xFFFEF3C7)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isRejected
                          ? const Color(0xFFEF4444)
                          : (isDark ? const Color(0xFFD97706) : const Color(0xFFF59E0B)),
                    ),
                  ),
                  child: Text(
                    isRejected ? '❌ APPLICATION NOT APPROVED' : '⏳ APPLICATION UNDER ADMIN REVIEW',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: isRejected
                          ? const Color(0xFFEF4444)
                          : (isDark ? const Color(0xFFFFD54F) : const Color(0xFF78350F)),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  isRejected ? 'Application Needs Update' : 'Application Submitted Successfully!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 24,
                    color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  isRejected
                      ? 'Your artisan application was reviewed, but unfortunately could not be approved at this time. Please ensure all uploaded documents (SSM, Kraftangan Cert) are clear, valid, and registered under your name.'
                      : 'Your studio license documents (SSM License & Kraftangan Master Certificate) have been received. Kraftangan Malaysia Moderation Officers are reviewing your application.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.grey[700],
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 28),

                if (!isRejected) ...[
                  // 3-Step Onboarding Progress Timeline
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF041412) : const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? const Color(0xFF1E3A34) : Colors.black.withValues(alpha: 0.04),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildTimelineItem(
                          isDark: isDark,
                          step: '1',
                          title: 'Application & Credentials Submitted',
                          subtitle: 'SSM & Kraftangan documents attached',
                          isCompleted: true,
                          isCurrent: false,
                        ),
                        Divider(height: 20, color: isDark ? const Color(0xFF1E3A34) : null),
                        _buildTimelineItem(
                          isDark: isDark,
                          step: '2',
                          title: 'Kraftangan Admin Review',
                          subtitle: 'In progress • Estimated 1 - 2 business days',
                          isCompleted: false,
                          isCurrent: true,
                        ),
                        Divider(height: 20, color: isDark ? const Color(0xFF1E3A34) : null),
                        _buildTimelineItem(
                          isDark: isDark,
                          step: '3',
                          title: 'Marketplace Directory Activation',
                          subtitle: 'Public tourist search & quest completion active',
                          isCompleted: false,
                          isCurrent: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Submitted Details Summary Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF041412) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF1E3A34) : const Color(0xFFBFDBFE),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow(isDark, 'Studio Name:', effectiveStudio),
                      const SizedBox(height: 8),
                      _buildSummaryRow(isDark, 'Craft Category:', effectiveCraft),
                      const SizedBox(height: 8),
                      _buildSummaryRow(isDark, 'SSM Reg. Number:', effectiveSsm),
                      const SizedBox(height: 8),
                      _buildSummaryRow(isDark, 'Uploaded Proof:', 'SSM_Cert.pdf, Kraftangan_Cert.pdf'),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                if (isRejected)
                  // Rejection Notice
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A1215) : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? const Color(0xFF5C1D24) : const Color(0xFFFCA5A5),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Please double-check your credentials and submit a new application when ready.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  // Locked Status Notice
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A1215) : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? const Color(0xFF5C1D24) : const Color(0xFFFCA5A5),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_outlined, color: Color(0xFFEF4444), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '🔒 Studio Profile Customization is locked until Kraftangan Admin Officers verify & approve your license.',
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

                const SizedBox(height: 20),

                // Action Buttons
                if (isRejected) ...[
                  // Primary Action for Rejected: Update Documents & Re-Apply
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const ApplyArtisanScreen(),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF004D40),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.edit_document, size: 20),
                      label: Text(
                        'Update Documents & Re-Apply',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // Primary Action for Pending: Check Verification Status
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: () async {
                        final authVM = context.read<AuthViewModel>();
                        await authVM.restoreSession();
                        if (!context.mounted) return;
                        
                        final refreshedUser = authVM.currentUser;
                        final isNowRejected = refreshedUser?.status.toUpperCase() == 'REJECTED' ||
                            refreshedUser?.artisanStatus?.toUpperCase() == 'REJECTED';
                        final isNowApproved = refreshedUser?.isApprovedArtisan == true;

                        if (isNowApproved) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
                                  SizedBox(width: 10),
                                  Text('🎉 Congratulations! Your artisan application has been approved.'),
                                ],
                              ),
                              backgroundColor: Color(0xFF10B981),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          Navigator.pushReplacementNamed(context, '/artisan');
                        } else if (isNowRejected) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.cancel_outlined, color: Colors.white, size: 18),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text('Your application was not approved. Please review details below and re-apply.'),
                                  ),
                                ],
                              ),
                              backgroundColor: Color(0xFFEF4444),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.sync_rounded, color: Colors.white, size: 18),
                                  SizedBox(width: 10),
                                  Text('Application status: STILL UNDER REVIEW'),
                                ],
                              ),
                              backgroundColor: Color(0xFFD97706),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                        foregroundColor: isDark ? const Color(0xFF041412) : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      label: Text(
                        'Check Verification Status',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Contact Support Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('📞 Kraftangan Help Desk Hotline: +60 3-2161 3700'),
                          backgroundColor: isDark ? const Color(0xFF0D2825) : const Color(0xFF004D40),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: Icon(
                      Icons.headset_mic_rounded,
                      size: 18,
                      color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                    ),
                    label: Text(
                      'Contact Verification Support',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Return to Tourist Mode
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/tourist');
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                    ),
                    icon: const Icon(Icons.explore_outlined, size: 18),
                    label: Text(
                      'Continue as Cultural Tourist',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required bool isDark,
    required String step,
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isCurrent,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: isCompleted
              ? const Color(0xFF10B981)
              : (isCurrent
                  ? const Color(0xFFD97706)
                  : (isDark ? const Color(0xFF1E3A34) : Colors.grey[300])),
          child: isCompleted
              ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
              : Text(
                  step,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isCurrent
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.grey[600]),
                  ),
                ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isCurrent
                      ? (isDark ? const Color(0xFFFFD54F) : const Color(0xFF78350F))
                      : (isDark ? Colors.white : const Color(0xFF0F172A)),
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: isCurrent
                      ? (isDark ? const Color(0xFFFFCA28) : const Color(0xFFB45309))
                      : (isDark ? Colors.white60 : Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(bool isDark, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            softWrap: true,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E3A8A),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            softWrap: true,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: isDark ? Colors.white70 : const Color(0xFF1D4ED8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}