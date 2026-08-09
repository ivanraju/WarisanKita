import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/ui/gamification/qr_scanner_view.dart';
import 'package:warisan_kita/viewmodels/gamification_viewmodel.dart';
import 'package:warisan_kita/domain/models/badge.dart';

class GeofencedTasksScreen extends StatelessWidget {
  const GeofencedTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameStat = context.watch<GamificationViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context),
          SliverPadding(
            padding: const EdgeInsets.all(24.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildActiveQuestCard(context, gameStat.activeTasks),
                const SizedBox(height: 40),
                _buildSectionHeader('Legendary Landmarks'),
                const SizedBox(height: 16),
                _buildQuestTile(
                  context,
                  title: 'Melaka Pottery Hub',
                  distance: '1.2km away',
                  image: 'https://images.unsplash.com/photo-1565193998771-e64b81bd957d?w=400',
                  difficulty: 'Medium',
                  xp: '150 XP',
                  isLocked: true,
                ),
                const SizedBox(height: 16),
                _buildQuestTile(
                  context,
                  title: 'Heritage Blacksmith',
                  distance: '4.5km away',
                  image: 'https://images.unsplash.com/photo-1533090161767-e6ffed986c88?w=400',
                  difficulty: 'Hard',
                  xp: '300 XP',
                  isLocked: true,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF004D40),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        title: Text(
          'Heritage Quests',
          style: GoogleFonts.dmSerifDisplay(
            color: const Color(0xFF004D40),
            fontSize: 26,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.dmSerifDisplay(
        fontSize: 20,
        color: const Color(0xFF004D40),
      ),
    );
  }

  Widget _buildActiveQuestCard(BuildContext context, List<HeritageTask> tasks) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                child: Image.network(
                  'https://images.unsplash.com/photo-1605721911519-3dfeb3be25e7?w=600',
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD54F),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                  ),
                  child: Text(
                    'ACTIVE NOW',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF004D40),
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Zaid Woodworks Studio',
                  style: GoogleFonts.dmSerifDisplay(fontSize: 24, color: const Color(0xFF004D40)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Color(0xFFFF7043)),
                    const SizedBox(width: 4),
                    Text(
                      'Terengganu • Site Verified',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFFFF7043),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                ...tasks.map((task) => _buildTaskItem(context, task)).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(BuildContext context, HeritageTask task) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 28,
            width: 28,
            decoration: BoxDecoration(
              color: task.isCompleted ? const Color(0xFF2E7D32) : Colors.transparent,
              border: Border.all(
                color: task.isCompleted ? const Color(0xFF2E7D32) : Colors.black12,
                width: 2,
              ),
              shape: BoxShape.circle,
            ),
            child: task.isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: GoogleFonts.plusJakartaSans(
                    color: task.isCompleted ? Colors.black26 : Colors.black87,
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (!task.isCompleted)
                  Text(
                    'REWARD: ${task.xpReward}',
                    style: const TextStyle(fontSize: 10, color: Color(0xFFFFD54F), fontWeight: FontWeight.w900),
                  ),
              ],
            ),
          ),
          if (!task.isCompleted && task.title.contains('QR'))
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QRScannerScreen())),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF004D40),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF004D40).withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'SCAN',
                      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuestTile(
    BuildContext context, {
    required String title,
    required String distance,
    required String image,
    required String difficulty,
    required String xp,
    bool isLocked = false,
  }) {
    return Opacity(
      opacity: isLocked ? 0.6 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(image, width: 80, height: 80, fit: BoxFit.cover),
          ),
          title: Text(title, style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: const Color(0xFF004D40))),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Text(distance, style: TextStyle(fontSize: 12, color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildQuestBadge(difficulty, const Color(0xFF004D40)),
                  const SizedBox(width: 8),
                  _buildQuestBadge(xp, const Color(0xFFFFD54F), textColor: const Color(0xFF004D40)),
                ],
              ),
            ],
          ),
          trailing: Icon(isLocked ? Icons.lock_outline_rounded : Icons.chevron_right_rounded, color: Colors.black12),
        ),
      ),
    );
  }

  Widget _buildQuestBadge(String label, Color color, {Color textColor = Colors.white}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5),
      ),
    );
  }
}
