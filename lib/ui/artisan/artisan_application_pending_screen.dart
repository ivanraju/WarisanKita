import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:warisan_kita/domain/models/user.dart';
import 'package:warisan_kita/ui/tourist/apply_artisan_screen.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';
import 'package:warisan_kita/ui/core/widgets/heritage_background.dart';

class ArtisanApplicationPendingScreen extends StatefulWidget {
  final String studioName;
  final String craftCategory;
  final String ssmNumber;
  final String premiseType;
  final String? ssmFileName;
  final String? ssmFileUrl;
  final String? certFileName;
  final String? certFileUrl;
  final List<String>? photos;

  const ArtisanApplicationPendingScreen({
    super.key,
    this.studioName = '',
    this.craftCategory = '',
    this.ssmNumber = '',
    this.premiseType = '',
    this.ssmFileName,
    this.ssmFileUrl,
    this.certFileName,
    this.certFileUrl,
    this.photos,
  });

  @override
  State<ArtisanApplicationPendingScreen> createState() =>
      _ArtisanApplicationPendingScreenState();
}

class _ArtisanApplicationPendingScreenState
    extends State<ArtisanApplicationPendingScreen> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AuthViewModel>().refreshCurrentUser();
      }
    });
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (mounted) {
        final auth = context.read<AuthViewModel>();
        if (auth.currentUser != null && !auth.currentUser!.isSuspended) {
          await auth.refreshCurrentUser();
          if (mounted) {
            if (auth.currentUser?.isApprovedArtisan == true) {
              _pollTimer?.cancel();
              Navigator.pushReplacementNamed(context, '/artisan');
            } else if (auth.currentUser?.isRejectedArtisan == true) {
              _pollTimer?.cancel();
            }
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authVM = context.watch<AuthViewModel>();
    final user = authVM.currentUser;
    final String effectiveStudio = (user?.studioName != null && user!.studioName!.isNotEmpty)
        ? user.studioName!
        : ((widget.studioName.isNotEmpty) ? widget.studioName : 'Traditional Craft Studio');
    final String effectiveCraft = (user?.craftCategory != null && user!.craftCategory!.isNotEmpty)
        ? user.craftCategory!
        : ((widget.craftCategory.isNotEmpty) ? widget.craftCategory : 'Heritage Craft');
    final String effectiveSsm = (user?.ssmNumber != null && user!.ssmNumber!.isNotEmpty)
        ? user.ssmNumber!
        : ((widget.ssmNumber.isNotEmpty) ? widget.ssmNumber : 'Under Verification');

    final bool isVillage = (user?.isVillageWorkshop == true) ||
        effectiveSsm == 'VILLAGE_EXEMPT' ||
        widget.ssmNumber == 'VILLAGE_EXEMPT' ||
        effectiveSsm.toLowerCase().contains('village') ||
        widget.premiseType.contains('Village') ||
        widget.premiseType.contains('Desa') ||
        widget.premiseType.contains('Home') ||
        widget.premiseType.contains('Kediaman');

    final bool isRejected = user?.isRejectedArtisan == true;

    // Document resolution
    final String? ssmDocName = (user?.ssmFileName != null && user!.ssmFileName!.isNotEmpty)
        ? user.ssmFileName
        : widget.ssmFileName;
    final String? ssmDocUrl = (user?.ssmFileUrl != null && user!.ssmFileUrl!.isNotEmpty)
        ? user.ssmFileUrl
        : widget.ssmFileUrl;

    final String? certDocName = (user?.certFileName != null && user!.certFileName!.isNotEmpty)
        ? user.certFileName
        : widget.certFileName;
    final String? certDocUrl = (user?.certFileUrl != null && user!.certFileUrl!.isNotEmpty)
        ? user.certFileUrl
        : widget.certFileUrl;

    final String? craftingPhotoName = (user?.craftingPhotoName != null && user!.craftingPhotoName!.isNotEmpty)
        ? user.craftingPhotoName
        : (isVillage ? (ssmDocName ?? user?.ssmFileName) : null);
    final String? craftingPhotoUrl = (user?.craftingPhotoUrl != null && user!.craftingPhotoUrl!.isNotEmpty)
        ? user.craftingPhotoUrl
        : (isVillage ? (ssmDocUrl ?? user?.ssmFileUrl) : null);

    final List<String> allPhotos = (user?.photos != null && user!.photos.isNotEmpty)
        ? user.photos
        : (widget.photos ?? const []);

    return HeritageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
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
                      ? (isVillage
                          ? 'Your artisan application was reviewed, but unfortunately could not be approved at this time. Please ensure your uploaded crafting photo clearly displays your craftwork or crafting process.'
                          : 'Your artisan application was reviewed, but unfortunately could not be approved at this time. Please ensure all uploaded documents (SSM, Kraftangan Cert) are clear, valid, and registered under your name.')
                      : (isVillage
                          ? 'Your craftwork verification photo has been received. Kraftangan Malaysia Moderation Officers are reviewing your application.'
                          : 'Your studio license documents (SSM License & Kraftangan Master Certificate) have been received. Kraftangan Malaysia Moderation Officers are reviewing your application.'),
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
                          subtitle: isVillage
                              ? 'Crafting photo attached'
                              : 'SSM & Kraftangan documents attached',
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
                          title: 'Heritage Directory Activation',
                          subtitle: 'Public cultural discovery & artisan profile active',
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
                      _buildSummaryRow(
                        isDark,
                        'Premise Type:',
                        isVillage
                            ? 'Home / Village Workshop (Bengkel Kediaman / Desa)'
                            : (user?.premiseTypeDisplay ?? 'Commercial Studio'),
                      ),
                      const SizedBox(height: 8),
                      _buildSummaryRow(isDark, 'Studio Name:', effectiveStudio),
                      const SizedBox(height: 8),
                      _buildSummaryRow(isDark, 'Craft Category:', effectiveCraft),
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        isDark,
                        isVillage ? 'SSM Reg. (Optional):' : 'SSM Reg. Number:',
                        (isVillage &&
                                (effectiveSsm == 'Under Verification' ||
                                    effectiveSsm == 'VILLAGE_EXEMPT' ||
                                    effectiveSsm.toLowerCase().contains('village')))
                            ? 'Exempted (Village Crafter)'
                            : effectiveSsm,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // 📜 Uploaded Verification Documents Section
                _buildUploadedDocumentsSection(
                  context: context,
                  isDark: isDark,
                  isVillage: isVillage,
                  ssmDocName: ssmDocName,
                  ssmDocUrl: ssmDocUrl,
                  certDocName: certDocName,
                  certDocUrl: certDocUrl,
                  craftingPhotoName: craftingPhotoName,
                  craftingPhotoUrl: craftingPhotoUrl,
                  photos: allPhotos,
                  effectiveSsm: effectiveSsm,
                  user: user,
                ),

                const SizedBox(height: 24),

                if (isRejected) ...[
                  // Rejection Official Feedback Notice
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A1215) : const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFEF4444),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.feedback_outlined, color: Color(0xFFEF4444), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'OFFICIAL REVIEW FEEDBACK',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFFEF4444),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          (user?.rejectionReason != null && user!.rejectionReason!.trim().isNotEmpty)
                              ? user.rejectionReason!.trim()
                              : 'Your uploaded credentials did not pass verification. Please ensure valid Kraftangan documents are attached.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF881337),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1012) : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF5C1D24) : const Color(0xFFFCA5A5),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: Color(0xFFEF4444), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Please update your details and resubmit below.',
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
                ]
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
                        final isNowRejected = refreshedUser?.isRejectedArtisan == true;
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
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ApplyArtisanScreen(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                          width: 1.5,
                        ),
                        foregroundColor: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.edit_document, size: 20),
                      label: Text(
                        'Update / Replace Attached Documents',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          flex: 2,
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
        const SizedBox(width: 12),
        Flexible(
          flex: 3,
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

  Widget _buildUploadedDocumentsSection({
    required BuildContext context,
    required bool isDark,
    required bool isVillage,
    required String? ssmDocName,
    required String? ssmDocUrl,
    required String? certDocName,
    required String? certDocUrl,
    required String? craftingPhotoName,
    required String? craftingPhotoUrl,
    required List<String> photos,
    required String effectiveSsm,
    required UserModel? user,
  }) {
    final hasExplicitSsmInDocs = user?.artisanDocuments.any(
          (d) =>
              d['doc_type'] == 'SSM_BUSINESS_CERT' ||
              d['doc_type'] == 'SSM_CERT' ||
              d['doc_type'] == 'SSM',
        ) ??
        false;
    final bool hasSsmDoc = !isVillage
        ? ((ssmDocName != null && ssmDocName.isNotEmpty) ||
            (ssmDocUrl != null && ssmDocUrl.isNotEmpty))
        : hasExplicitSsmInDocs ||
            (effectiveSsm != 'VILLAGE_EXEMPT' &&
                !effectiveSsm.toLowerCase().contains('village') &&
                effectiveSsm != 'Under Verification' &&
                effectiveSsm != 'Exempted (Village Crafter)' &&
                ssmDocName != null &&
                !ssmDocName.toLowerCase().contains('crafting') &&
                !ssmDocName.toLowerCase().contains('photo'));

    final hasCertDoc = (certDocName != null && certDocName.isNotEmpty) ||
        (certDocUrl != null && certDocUrl.isNotEmpty);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF041412) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF1E3A34) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E3A34)
                      : const Color(0xFF004D40).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isVillage ? Icons.cottage_outlined : Icons.business_outlined,
                  size: 18,
                  color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isVillage
                          ? 'Home Studio Uploaded Documents'
                          : 'Commercial Studio Uploaded Documents',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Tap any document to review attached files',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (isVillage) ...[
            // 1. Mandatory Crafting Photo Evidence
            _buildDocCard(
              context: context,
              isDark: isDark,
              icon: Icons.camera_alt_rounded,
              iconColor: const Color(0xFF10B981),
              badgeText: 'MANDATORY PROOF',
              badgeBg: isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5),
              badgeFg: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46),
              title: 'Crafting Photo Evidence (Proof)',
              fileName: craftingPhotoName ?? 'Crafting_Proof_Photo.jpg',
              fileUrl: craftingPhotoUrl,
              isImage: true,
              actionLabel: 'View Proof Photo',
            ),
            const SizedBox(height: 10),

            // 2. Optional Stuff - Kraftangan Cert (if uploaded)
            if (hasCertDoc) ...[
              _buildDocCard(
                context: context,
                isDark: isDark,
                icon: Icons.workspace_premium_rounded,
                iconColor: const Color(0xFFD97706),
                badgeText: 'OPTIONAL ACCREDITATION',
                badgeBg: isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7),
                badgeFg: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                title: 'Kraftangan Master Certificate',
                fileName: certDocName ?? 'Kraftangan_Certificate.pdf',
                fileUrl: certDocUrl,
                isImage: _isImageFile(certDocName ?? certDocUrl ?? ''),
                actionLabel: 'View Certificate',
              ),
            ] else ...[
              _buildExemptionNoticeCard(
                isDark: isDark,
                icon: Icons.workspace_premium_outlined,
                title: 'Kraftangan Certificate',
                notice: 'Not attached (Optional for Home / Village Workshops)',
              ),
            ],
            const SizedBox(height: 10),

            // 3. Optional Stuff - SSM Registration (if provided)
            if (hasSsmDoc) ...[
              _buildDocCard(
                context: context,
                isDark: isDark,
                icon: Icons.description_rounded,
                iconColor: const Color(0xFF3B82F6),
                badgeText: 'OPTIONAL SSM REGISTRATION',
                badgeBg: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE),
                badgeFg: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
                title: 'SSM Registration Certificate',
                fileName: ssmDocName ?? 'SSM_Registration.pdf',
                fileUrl: ssmDocUrl,
                isImage: _isImageFile(ssmDocName ?? ssmDocUrl ?? ''),
                actionLabel: 'View SSM Document',
              ),
            ] else ...[
              _buildExemptionNoticeCard(
                isDark: isDark,
                icon: Icons.verified_user_outlined,
                title: 'SSM Business Registration',
                notice: 'Exempted for Home / Village Crafters (Crafting photo is primary verification)',
              ),
            ],
            const SizedBox(height: 12),

            // 4. Optional Stuff - Studio / Workshop Photos
            if (photos.isNotEmpty) ...[
              _buildPhotosSection(
                context: context,
                isDark: isDark,
                photos: photos,
                title: 'Optional Studio / Workshop Photos (${photos.length})',
              ),
            ] else ...[
              _buildExemptionNoticeCard(
                isDark: isDark,
                icon: Icons.photo_library_outlined,
                title: 'Studio / Workshop Photos',
                notice: 'None attached (Optional)',
              ),
            ],
          ] else ...[
            // Commercial Studio:
            // 1. SSM Business Registration Document (Mandatory)
            _buildDocCard(
              context: context,
              isDark: isDark,
              icon: Icons.description_rounded,
              iconColor: const Color(0xFF3B82F6),
              badgeText: 'MANDATORY SSM',
              badgeBg: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE),
              badgeFg: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
              title: 'SSM Business Registration Document',
              fileName: ssmDocName ?? 'SSM_Business_Registration.pdf',
              fileUrl: ssmDocUrl,
              isImage: _isImageFile(ssmDocName ?? ssmDocUrl ?? ''),
              actionLabel: 'View SSM Document',
            ),
            const SizedBox(height: 10),

            // 2. Kraftangan Master Accreditation Certificate (Mandatory)
            _buildDocCard(
              context: context,
              isDark: isDark,
              icon: Icons.workspace_premium_rounded,
              iconColor: const Color(0xFFD97706),
              badgeText: 'MANDATORY ACCREDITATION',
              badgeBg: isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7),
              badgeFg: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
              title: 'Kraftangan Master Accreditation Certificate',
              fileName: certDocName ?? 'Kraftangan_Master_Certificate.pdf',
              fileUrl: certDocUrl,
              isImage: _isImageFile(certDocName ?? certDocUrl ?? ''),
              actionLabel: 'View Certificate',
            ),
            const SizedBox(height: 12),

            // 3. Optional Studio Photos (if attached)
            if (photos.isNotEmpty) ...[
              _buildPhotosSection(
                context: context,
                isDark: isDark,
                photos: photos,
                title: 'Studio / Workshop Photos (${photos.length})',
              ),
            ] else ...[
              _buildExemptionNoticeCard(
                isDark: isDark,
                icon: Icons.photo_library_outlined,
                title: 'Studio / Workshop Photos',
                notice: 'None attached (Optional)',
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildDocCard({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String badgeText,
    required Color badgeBg,
    required Color badgeFg,
    required String title,
    required String fileName,
    required String? fileUrl,
    required bool isImage,
    required String actionLabel,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D2825) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF1E3A34) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openDocumentPreview(
            context: context,
            title: title,
            fileName: fileName,
            fileUrl: fileUrl,
            isImage: isImage,
            isDark: isDark,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              badgeText,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: badgeFg,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E3A34) : const Color(0xFF004D40),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFFFFD54F) : Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isImage ? Icons.visibility_rounded : Icons.open_in_new_rounded,
                        size: 13,
                        color: isDark ? const Color(0xFFFFD54F) : Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotosSection({
    required BuildContext context,
    required bool isDark,
    required List<String> photos,
    required String title,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 76,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (ctx, idx) {
              final photo = photos[idx];
              final isUrl = photo.startsWith('http');
              return InkWell(
                onTap: () => _openDocumentPreview(
                  context: context,
                  title: 'Studio Photo #${idx + 1}',
                  fileName: isUrl ? photo.split('/').last : photo,
                  fileUrl: isUrl ? photo : null,
                  isImage: true,
                  isDark: isDark,
                ),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? const Color(0xFF1E3A34) : const Color(0xFFCBD5E1),
                    ),
                    color: isDark ? const Color(0xFF0D2825) : const Color(0xFFF1F5F9),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: isUrl
                      ? Image.network(
                          photo,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(
                              Icons.photo_rounded,
                              color: Color(0xFF94A3B8),
                              size: 24,
                            ),
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.image_outlined,
                                color: Color(0xFF004D40),
                                size: 20,
                              ),
                              const SizedBox(height: 2),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  photo,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 9),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExemptionNoticeCard({
    required bool isDark,
    required IconData icon,
    required String title,
    required String notice,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A221E) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF164E43) : const Color(0xFFBBF7D0),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF10B981)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$title: $notice',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF15803D),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openDocumentPreview({
    required BuildContext context,
    required String title,
    required String fileName,
    required String? fileUrl,
    required bool isImage,
    required bool isDark,
  }) {
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF0D2825) : Colors.white,
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    isImage
                        ? Icons.photo_library_outlined
                        : Icons.description_outlined,
                    color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 18,
                        color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(dialogCtx).pop(),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Attached File: $fileName',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              if (isImage && fileUrl != null && fileUrl.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 320),
                    color: isDark ? const Color(0xFF041412) : const Color(0xFFF1F5F9),
                    child: InteractiveViewer(
                      clipBehavior: Clip.antiAlias,
                      child: Image.network(
                        fileUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => Container(
                          padding: const EdgeInsets.all(32),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.image_not_supported_outlined,
                                size: 48,
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Image preview unavailable offline or invalid URL.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF041412) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0xFF1E3A34) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        isImage
                            ? Icons.image_rounded
                            : Icons.picture_as_pdf_rounded,
                        size: 48,
                        color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        fileName,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fileUrl != null && fileUrl.isNotEmpty
                            ? 'Uploaded to Kraftangan Document Storage'
                            : 'Local Document Attached with Application',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (fileUrl != null && fileUrl.isNotEmpty) ...[
                FilledButton.icon(
                  onPressed: () => _launchURL(fileUrl),
                  style: FilledButton.styleFrom(
                    backgroundColor: isDark
                        ? const Color(0xFFFFD54F)
                        : const Color(0xFF004D40),
                    foregroundColor: isDark ? const Color(0xFF041412) : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: Text(
                    'Open Full Document Link',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              OutlinedButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Close Preview'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('Error launching url: $e');
    }
  }

  bool _isImageFile(String path) {
    return RegExp(
      r'\.(jpg|jpeg|png|webp|gif|bmp)(\?.*)?$',
      caseSensitive: false,
    ).hasMatch(path);
  }
}