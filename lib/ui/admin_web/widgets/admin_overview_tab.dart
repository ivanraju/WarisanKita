import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminOverviewTab extends StatelessWidget {
  final ValueChanged<String> onNavigateTab;

  const AdminOverviewTab({super.key, required this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Platform Overview & System Command Center',
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Real-time metrics, active moderation queues, and heritage ecosystem performance.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 28),

          // 4 Metric Cards Row
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Verified Artisans',
                  value: '15 Live',
                  subtitle: '3 Pending Verification',
                  icon: Icons.storefront_rounded,
                  color: const Color(0xFF10B981),
                  bgColor: const Color(0xFFECFDF5),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  title: 'Active Tourists',
                  value: '1,240',
                  subtitle: '+18% growth this month',
                  icon: Icons.people_alt_rounded,
                  color: const Color(0xFF3B82F6),
                  bgColor: const Color(0xFFEFF6FF),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  title: 'Quests Completed',
                  value: '342 AR Quests',
                  subtitle: '94% Completion Rate',
                  icon: Icons.stars_rounded,
                  color: const Color(0xFFD97706),
                  bgColor: const Color(0xFFFEF3C7),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  title: 'Forum Engagement',
                  value: '86 Threads',
                  subtitle: '100% Moderation Clean',
                  icon: Icons.forum_rounded,
                  color: const Color(0xFF8B5CF6),
                  bgColor: const Color(0xFFF3E8FF),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Quick Action Center Banner
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF004D40),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF004D40).withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFD54F),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bolt_rounded, color: Color(0xFF004D40), size: 32),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Moderation Action Required',
                        style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'You have 5 pending artisan profile submissions and 3 custom quests awaiting administrative verification.',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFFFFD54F)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Wrap(
                  spacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: () => onNavigateTab('Pending Approvals'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD54F),
                        foregroundColor: const Color(0xFF004D40),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.rate_review_rounded, size: 18),
                      label: Text('Review Artisans (5)', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => onNavigateTab('Quest Approvals'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 1.5),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.stars_rounded, size: 18),
                      label: Text('Approve Quests (3)', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Recent System Activity Audit Feed
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Audit Log & Activity',
                            style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: const Color(0xFF0F172A)),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text('View All Logs'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildAuditTile(
                        icon: Icons.verified_user_rounded,
                        color: const Color(0xFF10B981),
                        title: 'Master Artisan Pak Mat Profile Verified',
                        time: '10 mins ago',
                        subtitle: 'Plaque #MP-2026-088 issued to Kampung Morten Ceramic Studio',
                      ),
                      _buildAuditTile(
                        icon: Icons.stars_rounded,
                        color: const Color(0xFFD97706),
                        title: 'Quest Approved: Hand-Molding Labu Sayong',
                        time: '1 hour ago',
                        subtitle: 'Created by Pak Mat Pottery Studio • +500 EXP',
                      ),
                      _buildAuditTile(
                        icon: Icons.block_rounded,
                        color: const Color(0xFFEF4444),
                        title: 'Spam User Account Suspended',
                        time: '3 hours ago',
                        subtitle: 'User @spammer_user flagged for forum spam violating policies',
                      ),
                      _buildAuditTile(
                        icon: Icons.person_add_rounded,
                        color: const Color(0xFF3B82F6),
                        title: 'New Artisan Application Submitted',
                        time: '5 hours ago',
                        subtitle: 'Ahmad Razak Ceramic submitted SSM & Kraftangan certification',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 24),

              // Right Column: State Heritage Distribution Chart Card
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Artisan State Distribution',
                        style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: const Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Regional representation across Malaysia',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 20),
                      _buildStateRow('Kelantan (Songket & Batik)', 0.35, '6 Studios', const Color(0xFFD97706)),
                      _buildStateRow('Perak (Labu Sayong Pottery)', 0.28, '5 Studios', const Color(0xFF004D40)),
                      _buildStateRow('Melaka (Ceramics & Woodwork)', 0.22, '4 Studios', const Color(0xFF3B82F6)),
                      _buildStateRow('Terengganu (Batik Weaving)', 0.15, '3 Studios', const Color(0xFF8B5CF6)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.dmSerifDisplay(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(fontSize: 10, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditTile({
    required IconData icon,
    required Color color,
    required String title,
    required String time,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                    ),
                    Text(
                      time,
                      style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.grey[500]),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateRow(String label, double percentage, String countText, Color barColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
              Text(countText, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: barColor)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 8,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }
}
