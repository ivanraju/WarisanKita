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
  bool _showHistory = false;
  final List<Map<String, dynamic>> _staticReportedPosts = [];
  // IDs deleted by admin this session - prevents them reappearing in the queue
  // even if Supabase hasn't propagated the deletion yet
  final Set<String> _deletedIds = {};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final forumVM = context.read<ForumViewModel>();

      await forumVM.fetchThreads();
      await forumVM.fetchForumReportQueue();
      await forumVM.fetchForumModerationHistory();
    });
  }

  void _dismissFlag(Map<String, dynamic> post) async {
    final type = post['type']?.toString();
    final id = post['id']?.toString() ?? '';
    final threadId = (post['threadId'] ?? id).toString();

    if (type == 'reply') {
      await context.read<ForumViewModel>().dismissReplyReport(
        threadId,
        id,
      );
    } else {
      await context.read<ForumViewModel>().dismissReport(
        id,
      );
    }

    setState(() {
      _staticReportedPosts.removeWhere(
        (p) => p['id'] == id,
      );
    });

    if (!mounted) return;

    final typeLabel =
    type == 'reply' ? 'reply' : 'post';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Flag dismissed for $typeLabel by ${post['author'] ?? 'author'}.',
        ),
        backgroundColor: const Color(0xFF004D40),
        behavior: SnackBarBehavior.floating,
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
          actionsOverflowAlignment: OverflowBarAlignment.end,
          actionsOverflowDirection: VerticalDirection.down,
          actionsOverflowButtonSpacing: 8,
          title: Text(
            post['type'] == 'reply'
                ? 'Delete Forum Reply'
                : 'Delete Forum Post',
            style: GoogleFonts.dmSerifDisplay(
              color: const Color(0xFFEF4444),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
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
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final reason = reasonController.text.trim();

                // C2: Reason Required
                if (reason.length < 10 || reason.length > 255) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Deletion reason must be between 10 and 255 characters.',
                      ),
                      backgroundColor: Color(0xFFEF4444),
                    ),
                  );
                  return;
                }

                final forumVM = context.read<ForumViewModel>();

                try {
                  final type = post['type']?.toString();
                  final id = post['id']?.toString() ?? '';
                  final threadId = (post['threadId'] ?? id).toString();

                  // Admin delete reported REPLY
                  if (type == 'reply') {
                    await forumVM.adminDeleteForumReply(
                      threadId,
                      id,
                      reason,
                    );
                  }
                  // Admin delete reported POST
                  else {
                    await forumVM.adminDeleteForumPost(
                      id,
                      reason,
                    );
                  }

                  if (mounted) {
                    setState(() {
                      _deletedIds.add(id); // prevent re-appearing in queue
                      _staticReportedPosts.removeWhere((p) => p['id'] == id);
                    });
                  }

                  if (!dialogContext.mounted) return;
                  Navigator.of(dialogContext).pop();

                  if (!mounted) return;

                  final String typeLabel =
                  post['type'] == 'reply'
                      ? 'reply'
                      : 'post';

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Forum $typeLabel deleted. Check debug console for confirmation.',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: const Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (e) {
                  if (!dialogContext.mounted) return;

                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to delete forum content: $e',
                      ),
                      backgroundColor: const Color(0xFFEF4444),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
              child: const Text('CONFIRM DELETION'),
            ),
          ],
        );
      },
    );
  }

  void _showReportsDialog(Map<String, dynamic> item) {
    final List<Map<String, dynamic>> reports =
    List<Map<String, dynamic>>.from(
      item['reports'] ?? [],
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            '${reports.length} Reports',
            style: GoogleFonts.dmSerifDisplay(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: 520,
            child: reports.isEmpty
                ? const Text('No report details available.')
                : ListView.separated(
              shrinkWrap: true,
              itemCount: reports.length,
              separatorBuilder: (_, __) =>
              const Divider(height: 24),
              itemBuilder: (context, index) {
                final report = reports[index];

                final reporterId =
                    report['reporter_id']?.toString() ??
                        'Unknown';

                final reason =
                    report['reason']?.toString() ??
                        'No reason provided';

                final notes =
                report['notes']?.toString();

                final createdAt =
                    report['created_at']?.toString() ?? '';

                return Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Report ${index + 1}',
                      style:
                      GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      'Reporter ID: $reporterId',
                      style:
                      GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Reason: $reason',
                      style:
                      GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    if (notes != null &&
                        notes.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Notes: $notes',
                        style:
                        GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                        ),
                      ),
                    ],

                    const SizedBox(height: 4),

                    Text(
                      'Reported at: $createdAt',
                      style:
                      GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final forumVM = context.watch<ForumViewModel>();
    debugPrint(
      'ADMIN REPORT QUEUE = ${forumVM.reportQueue}',
    );

    final List<Map<String, dynamic>> dynamicReported = [];

    for (final item in forumVM.reportQueue) {
      final String type = item['type']?.toString() ?? '';

      final List<Map<String, dynamic>> reports =
      List<Map<String, dynamic>>.from(
        item['reports'] ?? [],
      );

      final int reportsCount =
          (item['reportsCount'] as int?) ?? reports.length;

      // =========================
      // REPORTED POST
      // =========================
      if (type == 'post') {
        final String postId =
            item['postId']?.toString() ?? '';

        // Skip items that were deleted this session
        if (_deletedIds.contains(postId)) continue;

        dynamic foundThread;

        for (final thread in forumVM.threads) {
          if (thread.id == postId) {
            foundThread = thread;
            break;
          }
        }

        if (foundThread == null) {
          continue;
        }

        final latestReport =
        reports.isNotEmpty ? reports.first : null;

        dynamicReported.add({
          'id': postId,
          'type': 'post',

          'author': foundThread.authorName,

          'role': foundThread.isArtisan
              ? 'Master Artisan'
              : 'Tourist',

          'content': foundThread.title,

          'reason':
          latestReport?['reason'] ??
              'User Reported Content',

          'reportsCount': reportsCount,

          // ✅ All individual reports
          'reports': reports,

          'timestamp': foundThread.timestamp,

          'isDynamic': true,
        });
      }

      // =========================
      // REPORTED REPLY
      // =========================
      else if (type == 'reply') {
        final String replyId =
            item['replyId']?.toString() ?? '';

        // Skip items that were deleted this session
        if (_deletedIds.contains(replyId)) continue;

        dynamic foundThread;
        dynamic foundReply;

        for (final thread in forumVM.threads) {
          for (final reply in thread.replies) {
            if (reply.id == replyId) {
              foundThread = thread;
              foundReply = reply;
              break;
            }
          }
          if (foundReply != null) break;
        }

        final latestReport = reports.isNotEmpty ? reports.first : null;
        final String reportNotes = latestReport?['notes']?.toString() ?? item['notes']?.toString() ?? '';
        final String reportReason = latestReport?['reason']?.toString() ?? item['reason']?.toString() ?? 'User Reported Reply';

        String authorName = foundReply?.sender ?? 'Community Member';
        if (authorName == 'Community Member' && reportNotes.contains('posted by ')) {
          authorName = reportNotes.split('posted by ').last.split(':').first.trim();
        }

        String replyContent = foundReply?.text ?? '';
        if (replyContent.isEmpty) {
          if (reportNotes.contains('"')) {
            final match = RegExp(r'"([^"]*)"').firstMatch(reportNotes);
            if (match != null && match.group(1) != null) {
              replyContent = match.group(1)!;
            }
          }
          if (replyContent.isEmpty) {
            replyContent = reportNotes.isNotEmpty ? reportNotes : 'Reported Reply Content';
          }
        }

        dynamicReported.add({
          'id': replyId,
          'type': 'reply',

          // Needed later for delete/dismiss reply
          'threadId': foundThread?.id ?? item['postId']?.toString() ?? '',
          'replyId': replyId,

          'author': authorName,

          'role': (foundReply?.isArtisan == true)
              ? 'Master Artisan'
              : 'Tourist',

          'content': replyContent,

          'reason': reportReason,

          'reportsCount': reportsCount,

          // ✅ All individual reports
          'reports': reports,

          'timestamp': foundReply?.timestamp ?? latestReport?['created_at']?.toString() ?? 'Recent',

          'isDynamic': true,
        });
      }
    }

    // Also include any reported threads/replies directly from forumVM.threads
    for (final thread in forumVM.threads) {
      if (thread.isReported && !_deletedIds.contains(thread.id)) {
        final bool alreadyInQueue = dynamicReported.any((item) => item['type'] == 'post' && item['id'] == thread.id);
        if (!alreadyInQueue) {
          dynamicReported.add({
            'id': thread.id,
            'type': 'post',
            'author': thread.authorName,
            'role': thread.isArtisan ? 'Master Artisan' : 'Tourist',
            'content': thread.title,
            'reason': thread.reportReason ?? 'User Reported Content',
            'reportsCount': 1,
            'reports': [
              {
                'reason': thread.reportReason ?? 'User Reported Content',
                'notes': thread.reportNotes ?? '',
                'created_at': thread.timestamp,
              }
            ],
            'timestamp': thread.timestamp,
            'isDynamic': true,
          });
        }
      }
      for (final reply in thread.replies) {
        if (reply.isReported && !_deletedIds.contains(reply.id)) {
          final bool alreadyInQueue = dynamicReported.any((item) => item['type'] == 'reply' && item['id'] == reply.id);
          if (!alreadyInQueue) {
            dynamicReported.add({
              'id': reply.id,
              'type': 'reply',
              'threadId': thread.id,
              'replyId': reply.id,
              'author': reply.sender,
              'role': reply.isArtisan ? 'Master Artisan' : 'Tourist',
              'content': reply.text,
              'reason': reply.reportReason ?? 'User Reported Reply',
              'reportsCount': 1,
              'reports': [
                {
                  'reason': reply.reportReason ?? 'User Reported Reply',
                  'notes': reply.reportNotes ?? '',
                  'created_at': reply.timestamp,
                }
              ],
              'timestamp': reply.timestamp,
              'isDynamic': true,
            });
          }
        }
      }
    }

    final allReported = [
      ...dynamicReported,
      ..._staticReportedPosts,
    ];

    final isMobile = MediaQuery.of(context).size.width < 768;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _showHistory
                ? 'Moderation History'
                : 'Reported Content Queue',
            style: GoogleFonts.dmSerifDisplay(
              fontSize: isMobile ? 22 : 26,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),

          const SizedBox(height: 16),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: () {
                  setState(() {
                    _showHistory = false;
                  });
                },
                style: FilledButton.styleFrom(
                  backgroundColor: !_showHistory
                      ? const Color(0xFF004D40)
                      : Colors.grey[300],
                  foregroundColor: !_showHistory
                      ? Colors.white
                      : Colors.black87,
                ),
                icon: const Icon(
                  Icons.flag_outlined,
                  size: 18,
                ),
                label: Text(
                  'Pending Reports (${allReported.length})',
                ),
              ),

              FilledButton.icon(
                onPressed: () async {
                  await context
                      .read<ForumViewModel>()
                      .fetchForumModerationHistory();

                  if (!mounted) return;

                  setState(() {
                    _showHistory = true;
                  });
                },
                style: FilledButton.styleFrom(
                  backgroundColor: _showHistory
                      ? const Color(0xFF004D40)
                      : Colors.grey[300],
                  foregroundColor: _showHistory
                      ? Colors.white
                      : Colors.black87,
                ),
                icon: const Icon(
                  Icons.history_rounded,
                  size: 18,
                ),
                label: Text(
                  'Moderation History '
                      '(${forumVM.moderationHistory.length})',
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

        if (_showHistory)
    Expanded(
        child: forumVM.moderationHistory.isEmpty
            ? Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history_rounded,
                size: 56,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 12),
              Text(
                'No moderation history yet.',
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 20,
                ),
              ),
            ],
          ),
        )
            : ListView.builder(
          itemCount: forumVM.moderationHistory.length,
          itemBuilder: (context, index) {
            final record =
            forumVM.moderationHistory[index];

            final status =
                record['status']?.toString() ??
                    'unknown';

            final bool isActioned =
                status == 'actioned';

            final bool isPost =
                record['post_id'] != null;

            final String type =
            isPost ? 'Post' : 'Reply';

            final String targetId =
            isPost
                ? record['post_id']?.toString() ?? ''
                : record['reply_id']?.toString() ?? '';

            final String reportReason =
                record['reason']?.toString() ??
                    'No reason provided';

            final String? reportNotes =
            record['notes']?.toString();

            final String? deletionReason =
            record['deletion_reason']?.toString();

            final String notes = (record['notes'] ?? '').toString();

            String authorName =
                record['target_author_name']?.toString() ??
                    record['author_name']?.toString() ??
                    '';

            if (authorName.isEmpty || authorName == 'null' || authorName == 'Unknown User') {
              if (notes.contains('created by ')) {
                final part = notes.split('created by ').last;
                authorName = part.split(':').first.trim();
              } else if (notes.contains('posted by ')) {
                final part = notes.split('posted by ').last;
                authorName = part.split(':').first.trim();
              } else if (notes.contains('by ') && notes.contains('(')) {
                final part = notes.split('by ').last;
                authorName = part.split('(').first.trim();
              } else if (isPost && targetId.isNotEmpty) {
                final threadMatch = forumVM.threads.where((t) => t.id == targetId).firstOrNull;
                if (threadMatch != null) {
                  authorName = threadMatch.authorName;
                }
              }
            }

            if (authorName.isEmpty || authorName == 'null') {
              authorName = 'Community Member';
            }

            String resolvedContent =
                record['content_snapshot']?.toString() ??
                    record['post_title']?.toString() ??
                    record['reply_text']?.toString() ??
                    '';

            if (resolvedContent.isEmpty || resolvedContent == 'null') {
              if (notes.contains('"')) {
                final match = RegExp(r'"([^"]*)"').firstMatch(notes);
                if (match != null && match.group(1) != null) {
                  resolvedContent = match.group(1)!;
                }
              }
            }

            final String? contentSnapshot =
                resolvedContent.isNotEmpty ? resolvedContent : null;

            final String reporterId =
                record['reporter_id']?.toString() ??
                    'Unknown';

            final String resolvedAt =
                record['resolved_at']?.toString() ??
                    '';

            final Color statusColor =
            isActioned
                ? const Color(0xFFEF4444)
                : const Color(0xFF10B981);

            return Container(
              margin:
              const EdgeInsets.only(bottom: 16),
              padding:
              EdgeInsets.all(isMobile ? 16 : 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(20),
                border: Border.all(
                  color:
                  Colors.black.withValues(alpha:0.06),
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                    Colors.black.withValues(alpha:0.03),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    crossAxisAlignment:
                    WrapCrossAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 17,
                        backgroundColor:
                        statusColor.withValues(alpha:0.12),
                        child: Icon(
                          isActioned
                              ? Icons.delete_outline_rounded
                              : Icons.check_circle_outline_rounded,
                          size: 18,
                          color: statusColor,
                        ),
                      ),

                      Text(
                        '$type Moderation Record',
                        style:
                        GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color:
                          const Color(0xFF0F172A),
                        ),
                      ),

                      Container(
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                          statusColor.withValues(alpha:0.10),
                          borderRadius:
                          BorderRadius.circular(20),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style:
                          GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Author',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    authorName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (contentSnapshot != null &&
                      contentSnapshot.trim().isNotEmpty) ...[
                    Text(
                      'Content',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),

                    const SizedBox(height: 4),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        contentSnapshot,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                  ],

                  Text(
                    'Original Report Reason',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    reportReason,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  if (reportNotes != null &&
                      reportNotes.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Reporter Notes',
                      style:
                      GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reportNotes,
                      style:
                      GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                      ),
                    ),
                  ],

                  if (isActioned &&
                      deletionReason != null &&
                      deletionReason
                          .trim()
                          .isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Admin Deletion Reason',
                      style:
                      GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color:
                        const Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      deletionReason,
                      style:
                      GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color:
                        const Color(0xFF991B1B),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 18,
                    runSpacing: 8,
                    children: [
                      Text(
                        'Reporter: $reporterId',
                        style:
                        GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'Target ID: $targetId',
                        style:
                        GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'Resolved: $resolvedAt',
                        style:
                        GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        )
    )
        else if (allReported.isEmpty)
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
                      border: Border.all(color: Colors.black.withValues(alpha:0.06)),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.03), blurRadius: 10)],
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
                              backgroundColor: const Color(0xFFEF4444).withValues(alpha:0.12),
                              child: const Icon(
                                Icons.flag_rounded,
                                size: 16,
                                color: Color(0xFFEF4444),
                              ),
                            ),

                            // NEW: Show whether it is a reported post or reply
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: post['type'] == 'reply'
                                    ? const Color(0xFFE0F2FE)
                                    : const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                post['type'] == 'reply'
                                    ? 'REPORTED REPLY'
                                    : 'REPORTED POST',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            Text(
                              post['author'].toString(),
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                post['role'].toString(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            Text(
                              post['timestamp'].toString(),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        if (post['type'] == 'reply') ...[
                          Text(
                            'Reply from thread: ${post['parentThread']}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
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

                        const SizedBox(height: 12),

                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${post['reportsCount'] ?? 0} Reports',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF4338CA),
                                ),
                              ),
                            ),

                            OutlinedButton.icon(
                              onPressed: () => _showReportsDialog(post),
                              icon: const Icon(
                                Icons.visibility_outlined,
                                size: 16,
                              ),
                              label: const Text('View Reports'),
                            ),
                          ],
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
                              label: Text(
                                post['type'] == 'reply'
                                    ? 'Delete Reply'
                                    : 'Delete Post',
                              ),
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