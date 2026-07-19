import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/features/gamification/geofenced_tasks_screen.dart';
import 'package:warisan_kita/features/settings/settings_screen.dart';
import 'package:warisan_kita/state/gamification_state.dart';
import 'package:warisan_kita/models/gamification_models.dart';

class PassportDashboardScreen extends StatelessWidget {
  const PassportDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameStat = context.watch<GamificationState>();

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
                  _buildRankCard(gameStat),
                  const SizedBox(height: 40),
                  _buildSectionTitle('Heritage Vault'),
                  Text(
                    'Your collected digital heritage stamps',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.black38,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildStampGrid(gameStat.stamps),
                  const SizedBox(height: 40),
                  _buildStatsSection(),
                  const SizedBox(height: 40),
                  _buildQuestButton(context),
                  const SizedBox(height: 120),
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
      expandedHeight: 300,
      pinned: true,
      stretch: true,
      backgroundColor: const Color(0xFF004D40),
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.white),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
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
            // Tropical patterns
            Positioned(
              top: -20,
              right: -20,
              child: Icon(Icons.spa_rounded, size: 250, color: Colors.white.withOpacity(0.05)),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                _buildAnimatedAvatar(),
                const SizedBox(height: 16),
                Text(
                  'Aizat Rahim',
                  style: GoogleFonts.dmSerifDisplay(
                    color: Colors.white,
                    fontSize: 32,
                  ),
                ),
                Text(
                  'HERITAGE LEVEL 12',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFFFFD54F),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedAvatar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD54F), Color(0xFFFF7043)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF7043).withOpacity(0.3),
            blurRadius: 25,
            spreadRadius: 5,
          )
        ],
      ),
      child: const CircleAvatar(
        radius: 54,
        backgroundColor: Colors.white,
        child: CircleAvatar(
          radius: 50,
          backgroundImage: NetworkImage('https://i.pravatar.cc/300?u=aizat'),
        ),
      ),
    );
  }

  Widget _buildRankCard(GamificationState state) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 30,
            offset: const Offset(0, 15),
          )
        ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 84,
                height: 84,
                child: CircularProgressIndicator(
                  value: state.rankProgress,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey.shade100,
                  color: const Color(0xFFFF7043),
                  strokeCap: StrokeCap.round,
                ),
              ),
              const Icon(Icons.shield_moon_rounded, color: Color(0xFFFFD54F), size: 36),
            ],
          ),
          const SizedBox(width: 28),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Apprentice Guardian',
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 22,
                    color: const Color(0xFF004D40),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '450 / 600 XP to next tier',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.black38,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: state.rankProgress,
                  minHeight: 4,
                  backgroundColor: Colors.black12,
                  color: const Color(0xFF004D40),
                  borderRadius: BorderRadius.circular(10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.dmSerifDisplay(
        fontSize: 24,
        color: const Color(0xFF004D40),
      ),
    );
  }

  Widget _buildStampGrid(List<HeritageStamp> stamps) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: stamps.length,
      itemBuilder: (context, index) {
        final stamp = stamps[index];
        return _buildStampCollectible(stamp);
      },
    );
  }

  Widget _buildStampCollectible(HeritageStamp stamp) {
    return Container(
      decoration: BoxDecoration(
        color: stamp.isUnlocked ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(28),
        border: stamp.isUnlocked 
            ? Border.all(color: const Color(0xFFFFD54F), width: 2) 
            : null,
        boxShadow: stamp.isUnlocked ? [
          BoxShadow(
            color: const Color(0xFFFFD54F).withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ] : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: stamp.isUnlocked 
                  ? [const Color(0xFFFFD54F), const Color(0xFFFF7043)]
                  : [Colors.grey.shade400, Colors.grey.shade500],
            ).createShader(bounds),
            child: Icon(
              Icons.stars_rounded,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            stamp.isUnlocked ? 'EARNED' : 'LOCKED',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: stamp.isUnlocked ? const Color(0xFFFF7043) : Colors.black26,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stamp.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: stamp.isUnlocked ? Colors.black87 : Colors.black12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        _buildStatBox('VISITS', '14', Icons.location_on_rounded, const Color(0xFF00796B)),
        const SizedBox(width: 16),
        _buildStatBox('TASKS', '28', Icons.bolt_rounded, const Color(0xFFFF7043)),
        const SizedBox(width: 16),
        _buildStatBox('RANK', '#4', Icons.emoji_events_rounded, const Color(0xFFFFD54F)),
      ],
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.dmSerifDisplay(fontSize: 22, color: const Color(0xFF004D40)),
            ),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.black26,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestButton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF004D40), Color(0xFF00796B)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF004D40).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GeofencedTasksScreen()),
          );
        },
        icon: const Icon(Icons.map_rounded, color: Color(0xFFFFD54F)),
        label: const Text(
          'CONTINUE JOURNEY',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 68),
        ),
      ),
    );
  }
}
