import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';
import 'package:warisan_kita/viewmodels/forum_viewmodel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminForumModerationTab extends StatefulWidget {
  const AdminForumModerationTab({super.key});

  @override
  State<AdminForumModerationTab> createState() => _AdminForumModerationTabState();
}

class _AdminForumModerationTabState extends State<AdminForumModerationTab> {
  bool _showHistory = false;
  final List<Map<String, dynamic>> _staticReportedPosts = [];
  final Set<String> _deletedIds = {};

  String _formatDateTime(dynamic value) {
    if (value == null) return '';

    final raw = value.toString();

    if (raw.isEmpty || raw == 'null' || raw == 'Recent') {
      return raw;
    }

    try {
      final dateTime = DateTime.parse(raw).toLocal();

      final day = dateTime.day.toString().padLeft(2, '0');
      final month = dateTime.month.toString().padLeft(2, '0');
      final year = dateTime.year;

      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');

      return '$day/$month/$year $hour:$minute';
    } catch (_) {
      return raw;
    }
  }

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

  Future<String> _getUsernameByEmail(String email) async {
    if (email.trim().isEmpty) {
      return 'Unknown User';
    }

    try {
      final row = await Supabase.instance.client
          .from('users')
          .select('username')
          .ilike('email', email.trim())
          .maybeSingle();

      final String username =
      (row?['username'] ?? '').toString().trim();

      if (username.isNotEmpty) {
        return username;
      }
    } catch (e) {
      debugPrint('Pending report username lookup error: $e');
    }

    return 'Unknown User';
  }

  void _dismissFlag(Map<String, dynamic> post) async {
    final type = post['type']?.toString();
    final id = post['id']?.toString() ?? '';
    final threadId = (post['threadId'] ?? id).toString();
    final authVM = context.read<AuthViewModel>();
    final adminName = authVM.currentUser?.effectiveUsername ?? authVM.currentUser?.email ?? 'Admin';

    try {
      if (type == 'reply') {
        await context.read<ForumViewModel>().dismissReplyReport(
          threadId,
          id,
          adminName,
        );
      } else {
        await context.read<ForumViewModel>().dismissReport(
          id,
          adminName,
        );
      }

    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to dismiss forum reports: $error'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }
    if (!mounted) return;
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
                final authVM = context.read<AuthViewModel>();
                final adminName = authVM.currentUser?.effectiveUsername ?? authVM.currentUser?.email ?? 'Admin';

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
                      adminName,
                    );
                  }
                  // Admin delete reported POST
                  else {
                    await forumVM.adminDeleteForumPost(
                      id,
                      reason,
                      adminName,
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

  Future<void> _showReportsDialog(Map<String, dynamic> item) async {
    final List<Map<String, dynamic>> reports =
        List<Map<String, dynamic>>.from(item['reports'] ?? [])
          ..sort((a, b) {
            final aDate = DateTime.tryParse(a['created_at']?.toString() ?? '');
            final bDate = DateTime.tryParse(b['created_at']?.toString() ?? '');
            if (aDate == null && bDate == null) return 0;
            if (aDate == null) return 1;
            if (bDate == null) return -1;
            return aDate.compareTo(bDate);
          });

    // Reuse the same username resolution used by the Pending Reports card.
    final resolvedContentAuthorUsername = await _getUsernameByEmail(
      (item['authorEmail'] ?? '').toString(),
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
                _formatDateTime(report['created_at']);

                final isAutomated = reporterId.isEmpty || reporterId == 'null';
                final reporterName = isAutomated
                    ? 'Automated Safety System'
                    : (report['reporterUsername']?.toString() ?? 'Unknown User');
                final fullReporterId = isAutomated
                    ? 'System'
                    : (report['reporterDisplayId']?.toString() ?? reporterId);
                final author = resolvedContentAuthorUsername;
                final authorId = item['contentAuthorId']?.toString() ?? 'Unknown';
                final contentType = item['type']?.toString() == 'reply' ? 'Reply' : 'Post';
                final visibility = item['contentIsReported'] == true ? 'Quarantined' : 'Visible';
                final pendingManual = item['distinctPendingManualReporters'] ?? 0;
                final preview = item['contentPreview']?.toString() ?? 'Unavailable';
                return Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    if (index == 0) ...[
                      Text('Reported Content', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                      Text('Content type: $contentType'),
                      Text('Content preview: $preview'),
                      Text('Content author username: $author'),
                      Text('Content author ID: $authorId'),
                      Text('Current visibility: $visibility'),
                      Text('$pendingManual / 3 reporters'),
                      const Divider(),
                    ],
                    Text('This Report', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
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
                      'Report reason: $reason',
                      style:
                      GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Report notes: ${notes ?? 'None'}',
                      style:
                      GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Reported date/time: $createdAt',
                      style:
                      GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text('Current report status: ${report['status']?.toString() ?? 'pending'}'),
                    const Divider(),
                    Text('Reporter Information', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                    Text('Reporter username: $reporterName'),
                    Text('User ID: $fullReporterId'),
                    Text('Total forum reports: ${report['reporterTotalCount'] ?? 'Unknown'}'),
                    Text('Pending reports: ${report['reporterPendingCount'] ?? 'Unknown'}'),
                    Text('Dismissed reports: ${report['reporterDismissedCount'] ?? 'Unknown'}'),
                    Text('Actioned reports: ${report['reporterActionedCount'] ?? 'Unknown'}'),
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
          'authorEmail': foundThread.authorEmail,

          'role': foundThread.isArtisan
              ? 'Master Artisan'
              : 'Tourist',

          'content': foundThread.title,
          'contentPreview': foundThread.title,
          'contentAuthorUsername': item['contentAuthorUsername'] ?? 'Unknown User',
          'contentAuthorId': item['contentAuthorId'] ?? foundThread.userId ?? 'Unknown',
          'contentIsReported': foundThread.isReported,
          'distinctPendingManualReporters': item['distinctPendingManualReporters'] ?? 0,

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
        final String reportNotes = latestReport?['notes']?.toString() ??
            item['notes']?.toString() ?? '';
        final String reportReason = latestReport?['reason']?.toString() ??
            item['reason']?.toString() ?? 'User Reported Reply';

        String authorName = foundReply?.sender ?? 'Community Member';
        if (authorName == 'Community Member' &&
            reportNotes.contains('posted by ')) {
          authorName = reportNotes
              .split('posted by ')
              .last
              .split(':')
              .first
              .trim();
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
            replyContent =
            reportNotes.isNotEmpty ? reportNotes : 'Reported Reply Content';
          }
        }

        dynamicReported.add({
          'id': replyId,
          'type': 'reply',

          'threadId': foundThread?.id ?? item['postId']?.toString() ?? '',
          'replyId': replyId,

          'parentThread': foundThread?.title ?? 'Unknown Thread',

          'author': authorName,
          'authorEmail': foundReply?.authorEmail ?? '',
          'role': (foundReply?.isArtisan == true)
              ? 'Master Artisan'
              : 'Tourist',

          'content': replyContent,
          'contentPreview': replyContent,
          'contentAuthorUsername': item['contentAuthorUsername'] ?? 'Unknown User',
          'contentAuthorId': item['contentAuthorId'] ?? foundReply?.userId ?? 'Unknown',
          'contentIsReported': foundReply?.isReported ?? false,
          'distinctPendingManualReporters': item['distinctPendingManualReporters'] ?? 0,
          'reason': reportReason,
          'reportsCount': reportsCount,
          'reports': reports,

          'timestamp':
          foundReply?.timestamp ??
              latestReport?['created_at']?.toString() ??
              'Recent',

          'isDynamic': true,
        });
      }
    }
        final allReported = [
          ...dynamicReported,
          ..._staticReportedPosts,
        ];

        final isMobile = MediaQuery
            .of(context)
            .size
            .width < 768;

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

                        final bool isDeleted = isActioned &&
                            record['action_type'] == 'deleted';
                        final bool isModeration = isDeleted || status == 'dismissed';

                        final String notes = (record['notes'] ?? '').toString();
                        final String postId = (record['post_id'] ?? '')
                            .toString();
                        final String replyId = (record['reply_id'] ?? '')
                            .toString();

                        final bool hasPostId = postId.isNotEmpty &&
                            postId != 'null';
                        final bool hasReplyId = replyId.isNotEmpty &&
                            replyId != 'null';

                        final bool isPost = record['target_type'] != null
                            ? record['target_type'] == 'post'
                            : hasPostId ||
                            (!hasReplyId && (notes.toLowerCase().contains(
                                'post') ||
                                notes.toLowerCase().contains(
                                    'flagged content') ||
                                record['post_title'] != null));

                        final String type = isPost ? 'Post' : 'Reply';

                        String targetId = '';
                        if (isPost && hasPostId) {
                          targetId = postId;
                        } else if (!isPost && hasReplyId) {
                          targetId = replyId;
                        } else if (hasPostId) {
                          targetId = postId;
                        } else if (hasReplyId) {
                          targetId = replyId;
                        } else {
                          final rawId = (record['target_id'] ?? record['id'] ??
                              '').toString();
                          if (rawId.isNotEmpty && rawId != 'null') {
                            targetId = rawId;
                          }
                        }

                        final String reportReason =
                            record['reason']?.toString() ??
                                'No reason provided';

                        final String? reportNotes =
                        record['notes']?.toString();

                        final String? deletionReason =
                        record['deletion_reason']?.toString();

                        String authorName =
                            record['target_author_name']?.toString() ??
                                record['author_name']?.toString() ??
                                '';

                        if (authorName.isEmpty || authorName == 'null' ||
                            authorName == 'Unknown User') {
                          if (notes.contains('created by ')) {
                            final part = notes
                                .split('created by ')
                                .last;
                            authorName = part
                                .split(':')
                                .first
                                .trim();
                          } else if (notes.contains('posted by ')) {
                            final part = notes
                                .split('posted by ')
                                .last;
                            authorName = part
                                .split(':')
                                .first
                                .trim();
                          } else
                          if (notes.contains('by ') && notes.contains('(')) {
                            final part = notes
                                .split('by ')
                                .last;
                            authorName = part
                                .split('(')
                                .first
                                .trim();
                          } else if (isPost && targetId.isNotEmpty) {
                            final threadMatch = forumVM.threads
                                .where((t) => t.id == targetId)
                                .firstOrNull;
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

                        if (resolvedContent.isEmpty ||
                            resolvedContent == 'null') {
                          if (notes.contains('"')) {
                            final match = RegExp(r'"([^"]*)"').firstMatch(
                                notes);
                            if (match != null && match.group(1) != null) {
                              resolvedContent = match.group(1)!;
                            }
                          }
                        }

                        final String? contentSnapshot =
                        resolvedContent.isNotEmpty ? resolvedContent : null;

                        final String reporterId =
                            record['reporter_id']?.toString() ??
                                '';
                        final auditReports = List<Map<String, dynamic>>.from(
                          record['report_rows'] ?? const [],
                        );

                        // Only grouped canonical actions establish a complete
                        // count. Legacy rows retain their own reporter audit.
                        final hasCanonicalReports =
                            record['is_moderation_action'] == true &&
                            record['reports_involved'] is num &&
                            record['target_id'] != null &&
                            record['target_type'] != null;
                        final displayedReports = isModeration && hasCanonicalReports
                            ? auditReports.where((report) {
                                final id = report['reporter_id']?.toString();
                                return record['target_id'] != null &&
                                    record['target_type'] != null &&
                                    report['target_id'] == record['target_id'] &&
                                    report['target_type'] == record['target_type'] &&
                                    id != null &&
                                    id.isNotEmpty &&
                                    id != 'null';
                              }).toList()
                            : auditReports;
                        // Number reporters by original submission time, not
                        // the shared resolution time or database return order.
                        displayedReports.sort((a, b) {
                          final aTime = DateTime.tryParse('${a['created_at'] ?? ''}');
                          final bTime = DateTime.tryParse('${b['created_at'] ?? ''}');
                          if (aTime == null && bTime != null) return 1;
                          if (aTime != null && bTime == null) return -1;
                          if (aTime != null && bTime != null) {
                            final order = aTime.compareTo(bTime);
                            if (order != 0) return order;
                          }
                          return '${a['id'] ?? ''}'.compareTo('${b['id'] ?? ''}');
                        });
                        final int? reportsInvolved = isModeration
                            ? hasCanonicalReports ? displayedReports
                                .map((report) => report['reporter_id'].toString())
                                .toSet().length : null
                            : (record['reports_involved'] as num?)?.toInt() ?? 1;
                        final resolvedAt =
                            _formatDateTime(record['resolved_at']);

                        String moderatorName =
                            record['moderator_name']?.toString() ??
                                record['admin_username']?.toString() ??
                                '';

                        if (moderatorName.isEmpty || moderatorName == 'null') {
                          if (notes.contains('by Admin ')) {
                            final part = notes
                                .split('by Admin ')
                                .last;
                            moderatorName = part
                                .split(':')
                                .first
                                .trim();
                          } else if (notes.contains('Dismissed by Admin ')) {
                            moderatorName = notes
                                .split('Dismissed by Admin ')
                                .last
                                .trim();
                          } else {
                            moderatorName = 'Admin';
                          }
                        }

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
                              Colors.black.withValues(alpha: 0.06),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                Colors.black.withValues(alpha: 0.03),
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
                                    statusColor.withValues(alpha: 0.12),
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
                                      statusColor.withValues(alpha: 0.10),
                                      borderRadius:
                                      BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      isDeleted ? 'DELETED' : status.toUpperCase(),
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
                                  contentSnapshot
                                      .trim()
                                      .isNotEmpty) ...[
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

                              if (isModeration || (reportsInvolved ?? 0) > 1) ...[
                                Text(
                                  reportsInvolved == null
                                      ? 'Reports involved: Unknown (举报人数无法确认)'
                                      : 'Reports involved: $reportsInvolved',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],

                              if (!isModeration) ...[
                                Text('Original Reports', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                                const SizedBox(height: 8),
                              ],
                              if (!isModeration && displayedReports.isEmpty)
                                Text(reportReason, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
                              ...displayedReports.asMap().entries.map((entry) {
                                final report = entry.value;
                                final date = _formatDateTime(report['created_at']);
                                return Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text('${isModeration ? 'Reporter' : 'Report'} ${entry.key + 1}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                                    Text('${isModeration ? 'Username' : 'Reporter username'}: ${report['reporter_username'] ?? 'Unknown User'}'),
                                    Text('${isModeration ? 'ID' : 'Reporter ID'}: ${report['reporter_id']}'),
                                    Text('${isModeration ? 'Original Report Reason' : 'Reason'}: ${report['reason'] ?? 'No reason provided'}'),
                                    Text('${isModeration ? 'Original Report Notes' : 'Notes'}: ${report['notes'] ?? 'None'}'),
                                    Text('Reported at: $date'),
                                  ]),
                                );
                              }),

                              if (isActioned &&
                                  deletionReason != null &&
                                  deletionReason
                                      .trim()
                                      .isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'Admin Deletion Reason:',
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
                              ], const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 10),

                              Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF004D40).withValues(
                                          alpha: 0.08),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.admin_panel_settings_rounded,
                                          size: 13,
                                          color: Color(0xFF004D40),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Moderated By: $moderatorName',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF004D40),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!isModeration &&
                                      targetId.isNotEmpty && targetId != 'null')
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '$type ID: #${targetId.length > 8
                                            ? targetId.substring(0, 8)
                                            : targetId}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF334155),
                                        ),
                                      ),
                                    ),
                                  if (!isModeration && reporterId.isNotEmpty &&
                                      reporterId != 'null' &&
                                      reporterId != 'Unknown')
                                    Text(
                                      'Reporter: #${reporterId.length > 8
                                          ? reporterId.substring(0, 8)
                                          : reporterId}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  if (resolvedAt.isNotEmpty)
                                    Text(
                                      'Resolved: $resolvedAt',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
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
              else
                if (allReported.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                              Icons.check_circle_outline_rounded, size: 56,
                              color: Color(0xFF10B981)),
                          const SizedBox(height: 12),
                          Text('All reported forum posts have been reviewed!',
                              style: GoogleFonts.dmSerifDisplay(fontSize: 20)),
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
                            border: Border.all(
                                color: Colors.black.withValues(alpha: 0.06)),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10)
                            ],
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
                                    backgroundColor: const Color(0xFFEF4444)
                                        .withValues(alpha: 0.12),
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

                                  FutureBuilder<String>(
                                    future: _getUsernameByEmail(
                                      (post['authorEmail'] ?? '').toString(),
                                    ),
                                    builder: (context, snapshot) {
                                      final String username =
                                          snapshot.data ??
                                              post['author']?.toString() ??
                                              'Unknown User';

                                      return Text(
                                        username,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      );
                                    },
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
                                    _formatDateTime(post['timestamp']),
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
                                  'Reply from thread: ${post['parentThread'] ??
                                      'Unknown Thread'}',
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
                                style: GoogleFonts.plusJakartaSans(fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    color: const Color(0xFF334155)),
                              ),

                              const SizedBox(height: 8),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFBEB),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: const Color(0xFFFDE68A)),
                                ),
                                child: Text(
                                  'Reason: ${post['reason']}',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFB45309)),
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
                                    icon: const Icon(
                                        Icons.check_rounded, size: 16),
                                    label: const Text('Dismiss Flag'),
                                  ),
                                  FilledButton.icon(
                                    onPressed: () =>
                                        _openDeletePostDialog(post),
                                    style: FilledButton.styleFrom(
                                        backgroundColor: const Color(
                                            0xFFEF4444)),
                                    icon: const Icon(
                                        Icons.delete_forever_rounded, size: 16),
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
