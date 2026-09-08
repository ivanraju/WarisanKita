import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:warisan_kita/ui/artisan/artisan_application_pending_screen.dart';
import 'package:warisan_kita/ui/tourist/apply_artisan_screen.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  Future<void> _launchExternalAdminBrowser(BuildContext context) async {
    final Uri url = Uri.parse('https://warisan-kita.vercel.app');

    try {
      final bool launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched) {
        // Fallback for desktop / emulator if launchUrl returns false
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🌐 Opening https://warisan-kita.vercel.app in external browser...'),
            backgroundColor: Color(0xFF004D40),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🌐 Browser Launched: https://warisan-kita.vercel.app ($e)'),
            backgroundColor: const Color(0xFF004D40),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _handleLaunchWebAdmin(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.open_in_browser_rounded, color: Color(0xFF0284C7)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Web Admin Dashboard',
                softWrap: true,
                style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: const Color(0xFF004D40)),
              ),
            ),
          ],
        ),
        content: Text(
          'The Web Admin Moderation Portal is hosted externally at https://warisan-kita.vercel.app.\n\nChoose how you would like to open the Admin Portal:',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _launchExternalAdminBrowser(context);
            },
            child: const Text('OPEN IN EXTERNAL BROWSER'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/admin');
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF004D40)),
            icon: const Icon(Icons.dashboard_rounded, size: 18),
            label: const Text('OPEN EMBEDDED DASHBOARD'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final user = authVM.currentUser;
    final isArtisanSuspended = user?.isArtisanStudioSuspended == true;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('Select Your Role', style: GoogleFonts.dmSerifDisplay(color: const Color(0xFF004D40))),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'How will you experience WarisanKita?',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 20),

              // Card 1: Tourist Experience
              _buildRoleCard(
                context: context,
                title: 'Tourist & Cultural Explorer',
                subtitle: 'Discover authentic Malaysian crafts, locate nearby master artisans on the map, take personality quizzes, and collect heritage badges.',
                icon: Icons.explore_rounded,
                accentColor: const Color(0xFF004D40),
                onTap: () => Navigator.of(context).pushReplacementNamed('/tourist'),
              ),

              const SizedBox(height: 16),

              // Card 2: Artisan Portal
              _buildRoleCard(
                context: context,
                title: 'Heritage Master Artisan',
                subtitle: isArtisanSuspended
                    ? '⚠️ Studio license suspended by admin. Please explore as a Cultural Tourist.'
                    : 'Register your studio, manage your craft portfolio, track application status, and engage with heritage enthusiasts in the live forum.',
                icon: isArtisanSuspended ? Icons.block_rounded : Icons.palette_rounded,
                accentColor: isArtisanSuspended ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                onTap: () {
                  if (user != null) {
                    if (isArtisanSuspended) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.block_rounded, color: Colors.white, size: 18),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text('⚠️ Your Master Artisan Studio is currently suspended by admin. Please explore as a Cultural Tourist.'),
                              ),
                            ],
                          ),
                          backgroundColor: Color(0xFFDC2626),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    if (user.isApprovedArtisan) {
                      Navigator.of(context).pushReplacementNamed('/artisan');
                    } else if (user.isPendingArtisan) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => ArtisanApplicationPendingScreen(
                            studioName: user.studioName ?? 'Master Artisan Studio',
                            craftCategory: user.craftCategory ?? 'Heritage Craft',
                            ssmNumber: user.ssmNumber ?? 'Pending Document Verification',
                          ),
                        ),
                      );
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ApplyArtisanScreen(),
                        ),
                      );
                    }
                  } else {
                    Navigator.of(context).pushReplacementNamed('/artisan');
                  }
                },
              ),

              const SizedBox(height: 16),

              // Card 3: Web Admin Dashboard (Browser / Portal Launcher)
              _buildRoleCard(
                context: context,
                title: 'Web Admin Dashboard',
                subtitle: 'Web portal for admin moderation, artisan profile approvals, quest verification, and community forum management.',
                icon: Icons.admin_panel_settings_rounded,
                accentColor: const Color(0xFF0284C7),
                isExternal: true,
                onTap: () => _handleLaunchWebAdmin(context),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
    bool isExternal = false,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      elevation: 2,
      shadowColor: accentColor.withOpacity(0.12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: accentColor.withOpacity(0.15), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(icon, size: 32, color: accentColor),
                  ),
                  if (isExternal)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.open_in_browser_rounded, size: 14, color: Color(0xFF0284C7)),
                          const SizedBox(width: 4),
                          Text(
                            'Web Browser',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0284C7),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isExternal ? 'Open Web Admin Portal' : 'Enter Mobile Portal',
                      softWrap: true,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    isExternal ? Icons.open_in_new_rounded : Icons.arrow_forward_rounded,
                    size: 16,
                    color: accentColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}