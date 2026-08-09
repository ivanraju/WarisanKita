import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:warisan_kita/ui/artisan/artisan_main_scaffold.dart';

class ArtisanApplicationPendingScreen extends StatelessWidget {
  final String studioName;
  final String craftCategory;
  final String ssmNumber;

  const ArtisanApplicationPendingScreen({
    super.key,
    this.studioName = 'Pak Mat Pottery Studio',
    this.craftCategory = 'Pottery & Ceramics',
    this.ssmNumber = '202601004821 (SSM Verified)',
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Application Status',
          style: GoogleFonts.dmSerifDisplay(color: const Color(0xFF004D40), fontSize: 22),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
            tooltip: 'Log Out',
            onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
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
                    color: const Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFDE68A), width: 3),
                  ),
                  child: const Icon(
                    Icons.hourglass_top_rounded,
                    size: 48,
                    color: Color(0xFFD97706),
                  ),
                ),

                const SizedBox(height: 20),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF59E0B)),
                  ),
                  child: Text(
                    '⏳ APPLICATION UNDER ADMIN REVIEW',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF78350F),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  'Application Submitted Successfully!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 24,
                    color: const Color(0xFF004D40),
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'Your studio license documents (SSM License & Kraftangan Master Certificate) have been received. Kraftangan Malaysia Moderation Officers are reviewing your application.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 28),

                // 3-Step Onboarding Progress Timeline
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black.withOpacity(0.04)),
                  ),
                  child: Column(
                    children: [
                      _buildTimelineItem(
                        step: '1',
                        title: 'Application & Credentials Submitted',
                        subtitle: 'SSM & Kraftangan documents attached',
                        isCompleted: true,
                        isCurrent: false,
                      ),
                      const Divider(height: 20),
                      _buildTimelineItem(
                        step: '2',
                        title: 'Kraftangan Admin Review',
                        subtitle: 'In progress • Estimated 1 - 2 business days',
                        isCompleted: false,
                        isCurrent: true,
                      ),
                      const Divider(height: 20),
                      _buildTimelineItem(
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

                // Submitted Details Summary Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow('Studio Name:', studioName),
                      const SizedBox(height: 8),
                      _buildSummaryRow('Craft Category:', craftCategory),
                      const SizedBox(height: 8),
                      _buildSummaryRow('SSM Reg. Number:', ssmNumber),
                      const SizedBox(height: 8),
                      _buildSummaryRow('Uploaded Proof:', 'SSM_Cert.pdf, Kraftangan_Cert.pdf'),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Locked Status Notice
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outlined, color: Color(0xFFEF4444), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '🔒 Studio Profile Customization is locked until Kraftangan Admin Officers verify & approve your license.',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFB91C1C)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.sync_rounded, color: Colors.white, size: 18),
                              SizedBox(width: 10),
                              Text('Application status: STILL UNDER REVIEW by Kraftangan Officers'),
                            ],
                          ),
                          backgroundColor: Color(0xFFD97706),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF004D40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFFFFD54F)),
                    label: Text(
                      'Check Verification Status',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('📞 Kraftangan Help Desk Hotline: +60 3-2161 3700'),
                          backgroundColor: Color(0xFF004D40),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF004D40)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.headset_mic_rounded, size: 18, color: Color(0xFF004D40)),
                    label: Text(
                      'Contact Verification Support',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF004D40)),
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
              : (isCurrent ? const Color(0xFFD97706) : Colors.grey[300]),
          child: isCompleted
              ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
              : Text(
                  step,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isCurrent ? Colors.white : Colors.grey[600],
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
                  color: isCurrent ? const Color(0xFF78350F) : const Color(0xFF0F172A),
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: isCurrent ? const Color(0xFFB45309) : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF1E3A8A), fontWeight: FontWeight.bold),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF1D4ED8), fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
