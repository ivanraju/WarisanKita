import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/ui/artisan/artisan_task_management_screen.dart';
import 'package:warisan_kita/ui/artisan/profile_builder_tab.dart';
import 'package:warisan_kita/ui/core/live_forum_tab.dart';
import 'package:warisan_kita/ui/artisan/artisan_settings_screen.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';

class ArtisanDashboardTab extends StatefulWidget {
  const ArtisanDashboardTab({super.key});

  @override
  State<ArtisanDashboardTab> createState() => _ArtisanDashboardTabState();
}

class _ArtisanDashboardTabState extends State<ArtisanDashboardTab> {
  bool _isStudioOpen = true;

  final List<Map<String, dynamic>> _weeklyPreservationData = const [
    {'day': 'Mon', 'visitors': '14 Visitors', 'heightRatio': 0.40},
    {'day': 'Tue', 'visitors': '22 Visitors', 'heightRatio': 0.55},
    {'day': 'Wed', 'visitors': '18 Visitors', 'heightRatio': 0.45},
    {'day': 'Thu', 'visitors': '30 Visitors', 'heightRatio': 0.70},
    {'day': 'Fri', 'visitors': '38 Visitors', 'heightRatio': 0.85},
    {'day': 'Sat', 'visitors': '48 Visitors', 'heightRatio': 1.00}, // PEAK
    {'day': 'Sun', 'visitors': '28 Visitors', 'heightRatio': 0.65},
  ];

  void _toggleStudioStatus(bool isOpen) {
    setState(() => _isStudioOpen = isOpen);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isOpen
              ? '🟢 Studio Live Status: OPEN FOR EDUCATIONAL WALK-INS & DEMOS'
              : '🔴 Studio Live Status: IN KILN SESSION (DEMOS PAUSED)',
        ),
        backgroundColor: isOpen ? const Color(0xFF004D40) : const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authVM = context.watch<AuthViewModel>();
    final user = authVM.currentUser;
    final studioName = user?.studioName ?? user?.displayName ?? 'Pak Mat Pottery Studio';
    final handle = user?.handle ?? 'pakmat';
    final craft = user?.craftCategory ?? 'Pottery & Ceramics';
    final initials = user?.initials ?? 'PM';

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Top App Bar
        SliverAppBar(
          backgroundColor: isDark ? const Color(0xFF041412) : const Color(0xFFF8F9FA),
          elevation: 0,
          title: Text(
            'Master Artisan Command Center',
            style: GoogleFonts.dmSerifDisplay(
              color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
              fontSize: 24,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.settings_outlined, color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40)),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ArtisanSettingsScreen()),
                );
              },
            ),
          ],
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🏛️ MASTER HERITAGE GUILD & ACCREDITATION HEADER CARD
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [const Color(0xFF0D2825), const Color(0xFF061A18)]
                          : [const Color(0xFF0A192F), const Color(0xFF004D40)],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: isDark ? Border.all(color: const Color(0xFF1E3A34)) : null,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF004D40).withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFFFFD54F), width: 2),
                                      ),
                                    ),
                                    CircleAvatar(
                                      radius: 27,
                                      backgroundColor: const Color(0xFFFFD54F),
                                      child: Text(
                                        initials,
                                        style: GoogleFonts.dmSerifDisplay(
                                          color: const Color(0xFF004D40),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        studioName,
                                        softWrap: true,
                                        style: GoogleFonts.dmSerifDisplay(
                                          color: Colors.white,
                                          fontSize: 22,
                                        ),
                                      ),
                                      Text(
                                        '@$handle • $craft',
                                        softWrap: true,
                                        style: GoogleFonts.plusJakartaSans(
                                          color: const Color(0xFFFFD54F),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Accreditation Badges Strip
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _buildHeaderBadge('🏆 Kraftangan Certified Master', const Color(0xFFFFD54F), const Color(0xFF004D40)),
                          _buildHeaderBadge('📜 License #KFG-2024-889', Colors.white24, Colors.white),
                          _buildHeaderBadge('🏛️ UNESCO Living Heritage Nominee', Colors.white24, Colors.white),
                        ],
                      ),

                      const SizedBox(height: 18),
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 12),

                      // Studio Live Availability Toggle Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Studio Live Cultural Status:',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.white70),
                                ),
                                Text(
                                  _isStudioOpen ? '🟢 OPEN FOR EDUCATIONAL DEMOS' : '🔴 IN KILN SESSION (DEMOS PAUSED)',
                                  softWrap: true,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _isStudioOpen ? const Color(0xFF34D399) : const Color(0xFFFCA5A5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: _isStudioOpen,
                            onChanged: _toggleStudioStatus,
                            activeThumbColor: const Color(0xFFFFD54F),
                            activeTrackColor: const Color(0xFF10B981),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ⚡ MASTER STUDIO MANAGEMENT ACTIONS
                Text(
                  'Studio Management Portal',
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 20,
                    color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionButton(
                        context,
                        icon: Icons.stars_rounded,
                        label: 'Manage Quests',
                        color: const Color(0xFFD97706),
                        isDark: isDark,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ArtisanTaskManagementScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildQuickActionButton(
                        context,
                        icon: Icons.history_edu_rounded,
                        label: 'Craft Portfolio',
                        color: isDark ? const Color(0xFF34D399) : const Color(0xFF004D40),
                        isDark: isDark,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ProfileBuilderTab()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildQuickActionButton(
                        context,
                        icon: Icons.forum_rounded,
                        label: 'Live Forum',
                        color: const Color(0xFF0284C7),
                        isDark: isDark,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const LiveForumTab()),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // 📊 INFORMATIONAL CULTURAL PRESERVATION METRICS & KNOWLEDGE TRANSFER HUB
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Heritage Preservation Metrics',
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 22,
                            color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                          ),
                        ),
                        Text(
                          'Knowledge transfer, apprentice outreach & lore archival',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E3A34) : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                        border: isDark ? Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.3)) : null,
                      ),
                      child: Text(
                        'August 2026',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFFFFD54F) : const Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 📊 WEEKLY TOURIST & STUDENT KNOWLEDGE TRANSMISSION CHART
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isDark
                          ? [const Color(0xFF0D2825), const Color(0xFF061A18)]
                          : [const Color(0xFF0A192F), const Color(0xFF0F172A)],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: isDark ? Border.all(color: const Color(0xFF1E3A34)) : null,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF004D40).withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Cultural Lore Preserved',
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.white70),
                              ),
                              Text(
                                '1,450 Craft Hours',
                                style: GoogleFonts.dmSerifDisplay(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF10B981)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.school_rounded, color: Color(0xFF34D399), size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '340 Students Taught',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF34D399)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Goal Progress Indicator
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: const LinearProgressIndicator(
                                value: 0.92,
                                backgroundColor: Colors.white24,
                                color: Color(0xFFFFD54F),
                                minHeight: 8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '92% Archival Goal',
                            style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFFFD54F)),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Weekly Cultural Visitor Visualizer Chart
                      SizedBox(
                        height: 120,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: _weeklyPreservationData.map((data) {
                              final double heightRatio = data['heightRatio'];
                              final bool isPeak = heightRatio == 1.0;

                            return Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  data['visitors'],
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: isPeak ? const Color(0xFFFFD54F) : Colors.white60,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: 18,
                                  height: 80 * heightRatio,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: isPeak
                                          ? [const Color(0xFFF59E0B), const Color(0xFFFFD54F)]
                                          : [const Color(0xFF004D40), const Color(0xFF10B981)],
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  data['day'],
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: isPeak ? FontWeight.bold : FontWeight.normal,
                                    color: isPeak ? const Color(0xFFFFD54F) : Colors.white70,
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 📜 INFORMATIONAL HERITAGE PRESERVATION CARD
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0D2825) : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? const Color(0xFF1E3A34) : const Color(0xFF86EFAC)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.verified_user_rounded, color: isDark ? const Color(0xFF34D399) : const Color(0xFF166534), size: 26),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'National Heritage Accreditation Verified:',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: isDark ? const Color(0xFF34D399) : const Color(0xFF14532D),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Your studio is recognized as an official Cultural Preservation Site by Kraftangan Malaysia. All completed quests contribute directly to national craft heritage documentation.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: isDark ? Colors.white70 : const Color(0xFF166534),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),

        // 4 Informational Cultural Metric Cards Grid
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.05,
            ),
            delegate: SliverChildListDelegate([
              _buildRichAnalyticsCard(
                title: 'Students & Tourists',
                value: '340 Taught',
                subtitle: '↗ +18% outreach',
                icon: Icons.groups_rounded,
                color: const Color(0xFF0284C7),
                isDark: isDark,
              ),
              _buildRichAnalyticsCard(
                title: 'Published Quests',
                value: '14 Active',
                subtitle: 'All admin verified',
                icon: Icons.stars_rounded,
                color: const Color(0xFF10B981),
                isDark: isDark,
              ),
              _buildRichAnalyticsCard(
                title: 'Digital Plaques',
                value: '28 Issued',
                subtitle: 'Handshake verified',
                icon: Icons.verified_rounded,
                color: const Color(0xFFF59E0B),
                isDark: isDark,
              ),
              _buildRichAnalyticsCard(
                title: 'Craft Lore Hours',
                value: '1,450 Hrs',
                subtitle: 'Preserved in 2026',
                icon: Icons.history_edu_rounded,
                color: const Color(0xFF8B5CF6),
                isDark: isDark,
              ),
            ]),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  Widget _buildHeaderBadge(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(color: textCol, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0D2825) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? const Color(0xFF1E3A34) : color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRichAnalyticsCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D2825) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF1E3A34) : Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            softWrap: true,
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            softWrap: true,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : Colors.grey[600],
            ),
          ),
          Text(
            subtitle,
            softWrap: true,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
