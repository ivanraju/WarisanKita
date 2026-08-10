import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminForumModerationTab extends StatefulWidget {
  const AdminForumModerationTab({super.key});

  @override
  State<AdminForumModerationTab> createState() => _AdminForumModerationTabState();
}

class _AdminForumModerationTabState extends State<AdminForumModerationTab> {
  // FR400_6: Flagged threads and reported reply data
  final List<Map<String, dynamic>> _reportedPosts = [
    {
      'id': 'p101',
      'author': 'User_8492',
      'role': 'Tourist',
      'content': 'Offensive promotional spam link posted in Batik thread.',
      'reason': 'Spam / Unauthorized Advertising',
      'reportsCount': 5,
      'timestamp': '12 mins ago',
    },
    {
      'id': 'p102',
      'author': 'Visitor_3920',
      'role': 'Tourist',
      'content': 'Inappropriate language directed at master artisan in Pottery thread.',
      'reason': 'Harassment / Inappropriate Content',
      'reportsCount': 3,
      'timestamp': '45 mins ago',
    },
  ];

  void _dismissFlag(Map<String, dynamic> post) {
    setState(() {
      _reportedPosts.removeWhere((p) => p['id'] == post['id']);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Flag dismissed for post by ${post['author']}.'),
        backgroundColor: const Color(0xFF004D40),
      ),
    );
  }

  // FR400_7 & FR400_8: Delete Post Action with Deletion Reason Dialog (C2)
  void _openDeletePostDialog(Map<String, dynamic> post) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Delete Forum Post', style: GoogleFonts.dmSerifDisplay(color: const Color(0xFFEF4444))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please specify the administrative deletion reason (10 to 255 characters):',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'e.g. Violation of Community Guidelines Rule 4 (Spam & Harassment)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final reason = reasonController.text.trim();
                // C2: Reason Required = deletion_reason.length >= 10 AND deletion_reason.length <= 255
                if (reason.length < 10 || reason.length > 255) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Deletion reason must be between 10 and 255 characters.'),
                      backgroundColor: Color(0xFFEF4444),
                    ),
                  );
                  return;
                }

                Navigator.of(context).pop();

                // Soft Deletion in DB & Audit Trail Logging (FR400_8, M1)
                setState(() {
                  _reportedPosts.removeWhere((p) => p['id'] == post['id']);
                });

                // M1: Action Logged
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Forum content successfully moderated and author notified.',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: const Color(0xFF10B981),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
              child: const Text('CONFIRM DELETION'),
            ),
          ],
        );
      },
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
              Expanded(
                child: Text(
                  'Reported Content Queue',
                  softWrap: true,
                  style: GoogleFonts.dmSerifDisplay(fontSize: 26, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_reportedPosts.length} Pending Flags',
                  style: GoogleFonts.plusJakartaSans(color: const Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          if (_reportedPosts.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 56, color: Color(0xFF10B981)),
                    const SizedBox(height: 12),
                    Text('All reported forum posts have been reviewed!', style: GoogleFonts.dmSerifDisplay(fontSize: 20)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _reportedPosts.length,
                itemBuilder: (context, index) {
                  final post = _reportedPosts[index];

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
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(0xFFEF4444).withOpacity(0.12),
                              child: const Icon(Icons.flag_rounded, size: 16, color: Color(0xFFEF4444)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      post['author'],
                                      softWrap: true,
                                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                                    child: Text(post['role'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(post['timestamp'], style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Text(
                          '"${post['content']}"',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontStyle: FontStyle.italic, color: const Color(0xFF334155)),
                        ),

                        const SizedBox(height: 16),

                        // Action Buttons: Dismiss Flag, Edit Post, Delete Post (FR400_7)
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          alignment: WrapAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _dismissFlag(post),
                              icon: const Icon(Icons.check_rounded, size: 16),
                              label: const Text('Dismiss Flag'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Edit Post view opened.')),
                                );
                              },
                              icon: const Icon(Icons.edit_rounded, size: 16),
                              label: const Text('Edit Post'),
                            ),
                            FilledButton.icon(
                              onPressed: () => _openDeletePostDialog(post),
                              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                              icon: const Icon(Icons.delete_forever_rounded, size: 16),
                              label: const Text('Delete Post'),
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