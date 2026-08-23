import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/viewmodels/forum_viewmodel.dart';

class AdminForumModerationTab extends StatefulWidget {
  const AdminForumModerationTab({super.key});

  @override
  State<AdminForumModerationTab> createState() => _AdminForumModerationTabState();
}

class _AdminForumModerationTabState extends State<AdminForumModerationTab> {
  // FR400_6: Flagged threads and reported reply moderation queue
  final List<Map<String, dynamic>> _staticReportedPosts = [];

  void _dismissFlag(Map<String, dynamic> post) {
    if (post['isDynamic'] == true) {
      context.read<ForumViewModel>().dismissReport(post['id'].toString());
    } else {
      setState(() {
        _staticReportedPosts.removeWhere((p) => p['id'] == post['id']);
      });
    }
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
      builder: (dialogContext) {
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
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final reason = reasonController.text.trim();
                // C2: Reason Required = deletion_reason.length >= 10 AND deletion_reason.length <= 255
                if (reason.length < 10 || reason.length > 255) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Deletion reason must be between 10 and 255 characters.'),
                      backgroundColor: Color(0xFFEF4444),
                    ),
                  );
                  return;
                }

                Navigator.of(dialogContext).pop();

                if (post['isDynamic'] == true) {
                  context.read<ForumViewModel>().deleteThread(post['id'].toString());
                } else {
                  setState(() {
                    _staticReportedPosts.removeWhere((p) => p['id'] == post['id']);
                  });
                }

                // M1: Action Logged
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Forum content successfully moderated ($reason) and author notified.',
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
    final forumVM = context.watch<ForumViewModel>();

    final dynamicReported = forumVM.threads.where((t) => t.isReported).map((t) {
      return {
        'id': t.id,
        'author': t.authorName,
        'role': t.isArtisan ? 'Master Artisan' : 'Tourist',
        'content': t.title,
        'reason': t.reportReason ?? 'User Reported Flag',
        'reportsCount': 1,
        'timestamp': t.timestamp,
        'isDynamic': true,
      };
    }).toList();

    final allReported = [...dynamicReported, ..._staticReportedPosts];
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Reported Content Queue',
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: isMobile ? 22 : 26,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${allReported.length} Pending Flags',
                  style: GoogleFonts.plusJakartaSans(color: const Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          if (allReported.isEmpty)
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
                itemCount: allReported.length,
                itemBuilder: (context, index) {
                  final post = allReported[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: EdgeInsets.all(isMobile ? 16 : 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black.withOpacity(0.06)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(0xFFEF4444).withOpacity(0.12),
                              child: const Icon(Icons.flag_rounded, size: 16, color: Color(0xFFEF4444)),
                            ),
                            Text(
                              post['author'].toString(),
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                              child: Text(post['role'].toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            Text(post['timestamp'].toString(), style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Text(
                          '"${post['content']}"',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontStyle: FontStyle.italic, color: const Color(0xFF334155)),
                        ),

                        const SizedBox(height: 8),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Text(
                            'Reason: ${post['reason']}',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFB45309)),
                          ),
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