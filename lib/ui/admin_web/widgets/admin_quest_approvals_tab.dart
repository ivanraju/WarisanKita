import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminQuestApprovalsTab extends StatefulWidget {
  const AdminQuestApprovalsTab({super.key});

  @override
  State<AdminQuestApprovalsTab> createState() => _AdminQuestApprovalsTabState();
}

class _AdminQuestApprovalsTabState extends State<AdminQuestApprovalsTab> {
  // Pending Quests Submitted by Artisans requiring Admin Approval
  final List<Map<String, dynamic>> _pendingQuests = [
    {
      'id': 'q101',
      'title': 'Draw Canting Wax on Silk Fabric',
      'artisan': 'Siti Batik Craft Studio',
      'state': 'Terengganu',
      'category': '🎨 Hands-on Crafting',
      'type': 'OPTIONAL',
      'points': 450,
      'description': 'Apply natural canting wax motifs onto unbleached silk fabric.',
      'dateSubmitted': 'Today at 02:15 PM',
    },
    {
      'id': 'q102',
      'title': 'Weave Traditional Songket Gold Thread',
      'artisan': 'Che Minah Heritage Songket',
      'state': 'Kelantan',
      'category': '🎨 Hands-on Crafting',
      'type': 'OPTIONAL',
      'points': 600,
      'description': 'Loom metallic gold thread into heritage songket border.',
      'dateSubmitted': 'Yesterday at 05:40 PM',
    },
    {
      'id': 'q103',
      'title': 'Listen to Workshop Heritage History Lore',
      'artisan': 'Master Wong Woodcraft',
      'state': 'Perak',
      'category': '👁️ Demonstration & Cultural Lore',
      'type': 'REQUIRED',
      'points': 200,
      'description': 'Listen to master artisan share historical craft origin.',
      'dateSubmitted': '05 Aug 2026',
    },
  ];

  void _approveQuest(Map<String, dynamic> quest) {
    setState(() {
      _pendingQuests.removeWhere((q) => q['id'] == quest['id']);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Quest "${quest['title']}" APPROVED! Now published live on tourist map (+${quest['points']} EXP).',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _rejectQuest(Map<String, dynamic> quest) {
    setState(() {
      _pendingQuests.removeWhere((q) => q['id'] == quest['id']);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Quest "${quest['title']}" rejected and sent back to artisan.'),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Pending Quest Approvals Queue',
                style: GoogleFonts.dmSerifDisplay(fontSize: 26, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(10)),
                child: Text(
                  '${_pendingQuests.length} Quests Pending Approval',
                  style: GoogleFonts.plusJakartaSans(color: const Color(0xFFB45309), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Review artisan-created quest tasks from the Categorized Library before publishing live to tourists.',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF64748B)),
          ),

          const SizedBox(height: 24),

          if (_pendingQuests.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars_rounded, size: 56, color: Color(0xFF10B981)),
                    const SizedBox(height: 12),
                    Text('All artisan quest applications have been reviewed!', style: GoogleFonts.dmSerifDisplay(fontSize: 20)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _pendingQuests.length,
                itemBuilder: (context, index) {
                  final quest = _pendingQuests[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black.withOpacity(0.06)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                quest['category'],
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                              child: Text(quest['type'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)),
                              child: Text(
                                '+${quest['points']} EXP REWARD',
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFB45309)),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        Text(
                          quest['title'],
                          style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: const Color(0xFF0F172A)),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          'Artisan Studio: ${quest['artisan']} (${quest['state']}) • Submitted: ${quest['dateSubmitted']}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B)),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          quest['description'],
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF334155)),
                        ),

                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 12),

                        // Action Buttons: Approve / Reject
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _rejectQuest(quest),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFEF4444),
                                side: const BorderSide(color: Color(0xFFEF4444)),
                              ),
                              icon: const Icon(Icons.close_rounded, size: 16),
                              label: const Text('Reject Quest'),
                            ),
                            const SizedBox(width: 12),
                            FilledButton.icon(
                              onPressed: () => _approveQuest(quest),
                              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                              icon: const Icon(Icons.check_rounded, size: 16),
                              label: const Text('APPROVE & PUBLISH LIVE'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
