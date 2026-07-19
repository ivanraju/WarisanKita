import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/state/auth_state.dart';
import 'package:warisan_kita/features/auth/login_screen.dart';

class ArtisanDashboardScreen extends StatelessWidget {
  const ArtisanDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsGrid(),
                  const SizedBox(height: 40),
                  _buildSectionHeader('Digital Tokens'),
                  const SizedBox(height: 16),
                  _buildQRActionCard(context),
                  const SizedBox(height: 40),
                  _buildSectionHeader('Recent Visitor Interactions'),
                  const SizedBox(height: 16),
                  _buildActivityList(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      stretch: true,
      backgroundColor: const Color(0xFF004D40),
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Colors.white),
          onPressed: () {
            context.read<AuthState>().logout();
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
          },
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF004D40), Color(0xFF00251A)],
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const CircleAvatar(
                      radius: 44,
                      backgroundImage: NetworkImage('https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ahmad Fauzi',
                    style: GoogleFonts.dmSerifDisplay(color: Colors.white, fontSize: 26),
                  ),
                  Text(
                    'MASTER BATIK ARTIST',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFFFFD54F),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.dmSerifDisplay(fontSize: 22, color: const Color(0xFF004D40)),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        _buildStatCard('VISITORS', '1.2k', Icons.group_rounded, const Color(0xFF00796B)),
        const SizedBox(width: 16),
        _buildStatCard('SAVED', '452', Icons.bookmark_rounded, const Color(0xFFFF7043)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 20),
            Text(value, style: GoogleFonts.dmSerifDisplay(fontSize: 28, color: const Color(0xFF004D40))),
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black26, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildQRActionCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF004D40),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF004D40).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.qr_code_scanner_rounded, size: 72, color: Color(0xFFFFD54F)),
          const SizedBox(height: 20),
          Text(
            'Check-in Token',
            style: GoogleFonts.dmSerifDisplay(color: Colors.white, fontSize: 24),
          ),
          const SizedBox(height: 12),
          const Text(
            'Present this code at your workshop for visitors to claim their digital stamp.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () => _showQR(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD54F),
              foregroundColor: const Color(0xFF004D40),
              minimumSize: const Size(double.infinity, 60),
            ),
            child: const Text('REVEAL TOKEN', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList() {
    return Column(
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFF8F9FA),
              child: Text('${index + 1}', style: const TextStyle(color: Color(0xFF004D40), fontWeight: FontWeight.bold)),
            ),
            title: Text('Visitor #771$index', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Claimed Batik Master Stamp'),
            trailing: const Text('2h ago', style: TextStyle(fontSize: 11, color: Colors.black26, fontWeight: FontWeight.bold)),
          ),
        );
      }),
    );
  }

  void _showQR(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 40),
            const Icon(Icons.qr_code_2_rounded, size: 200, color: Color(0xFF004D40)),
            const SizedBox(height: 24),
            Text(
              'Ahmad Fauzi • Batik',
              style: GoogleFonts.dmSerifDisplay(fontSize: 24, color: const Color(0xFF004D40)),
            ),
            const SizedBox(height: 8),
            const Text('TOKEN ID: AF-BTK-2024', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black26)),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
