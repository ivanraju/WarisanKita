import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';
import 'package:warisan_kita/viewmodels/forum_viewmodel.dart';
import 'package:warisan_kita/viewmodels/language_viewmodel.dart';

class LiveForumTab extends StatefulWidget {
  const LiveForumTab({super.key});

  @override
  State<LiveForumTab> createState() => _LiveForumTabState();
}

class _LiveForumTabState extends State<LiveForumTab> {
  Map<String, dynamic>? _activeThread;
  String _selectedCommunity = 'All';
  String _selectedSort = 'Hot';
  String? _replyingToReplyId;
  String? _replyingToName;
  String? _replyingToText;
  final Set<String> _dismissedNoticeIds = {};

  final Map<String, GlobalKey> _replyKeys = {};
  final ScrollController _answersScrollController = ScrollController();
  Future<void> _scrollToReply(String replyId) async {
    if (_activeThread == null) return;

    final List<Map<String, dynamic>> messages = List<Map<String, dynamic>>.from(
      _activeThread!['messages'] ?? [],
    );

    final int targetIndex = messages.indexWhere(
      (msg) => msg['id']?.toString() == replyId,
    );

    if (targetIndex == -1) {
      debugPrint('Reply ID not found: $replyId');
      return;
    }

    debugPrint('Target reply index: $targetIndex / ${messages.length}');

    // ==================================
    // Step 1: Check whether already built
    // ==================================
    var targetContext = _replyKeys[replyId]?.currentContext;

    if (targetContext != null) {
      await Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
        alignment: 0.08,
      );

      debugPrint('Direct scroll success');
      return;
    }

    // ==================================
    // Step 2: Scroll approximately there
    // so Flutter builds that reply
    // ==================================
    if (!_answersScrollController.hasClients) {
      debugPrint('Answers ScrollController not attached');
      return;
    }

    final position = _answersScrollController.position;

    final double maxScroll = position.maxScrollExtent;

    double approximateOffset = 0;

    if (messages.length > 1) {
      approximateOffset = maxScroll * (targetIndex / (messages.length - 1));
    }

    approximateOffset = approximateOffset.clamp(0.0, maxScroll);

    await _answersScrollController.animateTo(
      approximateOffset,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );

    // Give Flutter time to build the target card
    await Future.delayed(const Duration(milliseconds: 150));

    if (!mounted) return;

    // ==================================
    // Step 3: Precise scroll
    // ==================================
    final replyContext = _replyKeys[replyId]?.currentContext;

    if (replyContext != null && replyContext.mounted) {
      await Scrollable.ensureVisible(
        replyContext,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
        alignment: 0.08,
      );

      debugPrint('Scrolled precisely to reply: $replyId');
    } else {
      debugPrint('Target still not built: $replyId');
    }
  }

  final List<String> _communities = [
    'All',
    'c/BatikCraft',
    'c/PotterySayong',
    'c/SongketWeaving',
    'c/WoodCarving',
    'c/TravelQnA',
  ];

  final List<String> _sortOptions = ['Hot', 'New', 'Top', 'Verified Q&A'];
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final forumVM = context.read<ForumViewModel>();
      forumVM.fetchThreads();
      forumVM.fetchForumModerationHistory();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _answersScrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(BuildContext context) async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _activeThread == null) return;

    final authVM = context.read<AuthViewModel>();
    final forumVM = context.read<ForumViewModel>();
    final user = authVM.currentUser;
    final bool isUserArtisan =
        user?.isArtisan == true || user?.role == 'Artisan';
    final String effectiveAuthor =
        (user?.effectiveUsername != null && user!.effectiveUsername.isNotEmpty)
        ? user.effectiveUsername
        : ((user?.displayName != null && user!.displayName!.isNotEmpty)
              ? user.displayName!
              : (user?.email.isNotEmpty == true
                    ? user!.email.split('@').first
                    : 'Community Member'));

    final result = await forumVM.postReply(
      threadId: _activeThread!['id'].toString(),
      text: text,
      authorName: effectiveAuthor,
      authorEmail: user?.email ?? '',
      isArtisan: isUserArtisan,
      parentReplyId: _replyingToReplyId,
    );

    if (result.isBlocked) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.block_rounded, color: Color(0xFFEF4444)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Content Blocked',
                  softWrap: true,
                  style: GoogleFonts.dmSerifDisplay(
                    color: const Color(0xFF991B1B),
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            result.blockReason ?? 'Your reply contains prohibited words.',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.5),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF004D40),
              ),
              child: const Text('UNDERSTOOD'),
            ),
          ],
        ),
      );
      return;
    }

    _messageController.clear();

    setState(() {
      _replyingToReplyId = null;
      _replyingToName = null;
      _replyingToText = null;
    });

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isAutoFlagged
              ? '⚠️ Answer posted and flagged for moderator review (${result.flagReason})'
              : '💬 Answer posted to discussion!',
        ),
        backgroundColor: result.isAutoFlagged
            ? const Color(0xFFD97706)
            : const Color(0xFF004D40),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _voteThread(Map<String, dynamic> thread, int voteDirection) {
    final authVM = context.read<AuthViewModel>();
    final currentUser = authVM.currentUser;
    final String authorEmail =
        (thread['authorEmail'] ?? thread['author_email'] ?? '').toString();
    final String userId = (thread['userId'] ?? thread['user_id'] ?? '')
        .toString();

    final bool isMyThread =
        (currentUser != null &&
        ((currentUser.email.isNotEmpty &&
                authorEmail.isNotEmpty &&
                authorEmail.toLowerCase() == currentUser.email.toLowerCase()) ||
            (currentUser.id.isNotEmpty &&
                userId.isNotEmpty &&
                userId == currentUser.id)));

    if (isMyThread) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot vote on your own post.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    context.read<ForumViewModel>().voteThread(
      thread['id'].toString(),
      voteDirection,
    );
  }

  void _voteMessage(Map<String, dynamic> msg, int voteDirection) {
    if (_activeThread == null) return;
    final bool isMyReply = (msg['isMe'] as bool?) ?? false;

    if (isMyReply) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot vote on your own reply.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    context.read<ForumViewModel>().voteReply(
      _activeThread!['id'].toString(),
      msg['id'].toString(),
      voteDirection,
    );
  }

  void _showFlagReportModal(
    BuildContext context,
    String threadId,
    String title,
  ) {
    String selectedReason = 'Inappropriate Content';
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              const Icon(Icons.flag_rounded, color: Color(0xFFEF4444)),
              const SizedBox(width: 10),
              Text(
                'Report / Flag Content',
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 20,
                  color: const Color(0xFF004D40),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Report item: "$title"',
                maxLines: 2,
                softWrap: true,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Select Moderation Reason:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedReason,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Inappropriate Content',
                    child: Text('Inappropriate / Offensive Content'),
                  ),
                  DropdownMenuItem(
                    value: 'Misinformation',
                    child: Text('Misinformation / Fake Heritage Claim'),
                  ),
                  DropdownMenuItem(
                    value: 'Spam/Off-topic',
                    child: Text('Spam or Off-topic Advertisement'),
                  ),
                  DropdownMenuItem(
                    value: 'Harassment',
                    child: Text('Harassment or Abusive Language'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedReason = val);
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Additional Notes for Admin (Optional)',
                  hintText: 'Provide details for the admin moderation team...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCEL'),
            ),
            FilledButton.icon(
              onPressed: () async {
                final notes = notesController.text.trim();

                final result = await context
                    .read<ForumViewModel>()
                    .reportThread(threadId, selectedReason, notes);

                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);

                if (!context.mounted) return;

                // User already has a pending report
                if (result['already_reported'] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        '⚠️ You have already reported this post. '
                        'Your report is still pending Admin review.',
                      ),
                      backgroundColor: Color(0xFFD97706),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 4),
                    ),
                  );

                  return;
                }

                // New report successfully submitted
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '🚩 Report submitted successfully ($selectedReason)',
                    ),
                    backgroundColor: const Color(0xFFEF4444),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
              ),
              icon: const Icon(Icons.flag_rounded, size: 16),
              label: const Text('SUBMIT REPORT'),
            ),
          ],
        ),
      ),
    );
  }

  void _showReplyReportModal(
    BuildContext context,
    String threadId,
    String replyId,
    String replyText,
  ) {
    String selectedReason = 'Inappropriate Content';
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              const Icon(Icons.flag_rounded, color: Color(0xFFEF4444)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Report Reply',
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 20,
                    color: const Color(0xFF004D40),
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Report reply: "$replyText"',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),

              const SizedBox(height: 14),

              Text(
                'Select Moderation Reason:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                initialValue: selectedReason,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Inappropriate Content',
                    child: Text('Inappropriate / Offensive Content'),
                  ),
                  DropdownMenuItem(
                    value: 'Misinformation',
                    child: Text('Misinformation / Fake Heritage Claim'),
                  ),
                  DropdownMenuItem(
                    value: 'Spam/Off-topic',
                    child: Text('Spam or Off-topic Advertisement'),
                  ),
                  DropdownMenuItem(
                    value: 'Harassment',
                    child: Text('Harassment or Abusive Language'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() {
                      selectedReason = val;
                    });
                  }
                },
              ),

              const SizedBox(height: 14),

              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Additional Notes for Admin (Optional)',
                  hintText: 'Explain why this reply should be reviewed...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCEL'),
            ),

            FilledButton.icon(
              onPressed: () async {
                final notes = notesController.text.trim();

                final result = await context.read<ForumViewModel>().reportReply(
                  threadId,
                  replyId,
                  selectedReason,
                  notes,
                );

                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);

                if (!context.mounted) return;

                // Already has pending report
                if (result['already_reported'] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        '⚠️ You have already reported this reply. '
                        'Your report is still pending Admin review.',
                      ),
                      backgroundColor: Color(0xFFD97706),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 4),
                    ),
                  );

                  return;
                }

                // New report success
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '🚩 Reply report submitted successfully ($selectedReason)',
                    ),
                    backgroundColor: const Color(0xFFEF4444),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
              ),
              icon: const Icon(Icons.flag_rounded, size: 16),
              label: const Text('SUBMIT REPORT'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteMessage(String replyId) {
    if (_activeThread == null) return;
    final threadId = _activeThread!['id'].toString();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Delete Answer / Reply',
                softWrap: true,
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 18,
                  color: const Color(0xFF004D40),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this response? This action cannot be undone.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              setState(() {
                if (_activeThread != null && _activeThread!['messages'] is List) {
                  final List msgs = List.from(_activeThread!['messages']);
                  msgs.removeWhere((m) =>
                      m is Map &&
                      (m['id']?.toString() == replyId ||
                          m['parentReplyId']?.toString() == replyId));
                  _activeThread!['messages'] = msgs;
                  _activeThread!['replies'] = msgs.length;
                  _activeThread!['replyCount'] = msgs.length;
                }
              });
              await context.read<ForumViewModel>().deleteReply(threadId, replyId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🗑️ Response deleted successfully.'),
                    backgroundColor: Color(0xFFEF4444),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('DELETE ANSWER'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteThread(Map<String, dynamic> thread) {
    final threadId = thread['id'].toString();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Delete Question / Post',
                softWrap: true,
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 18,
                  color: const Color(0xFF004D40),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete your post "${thread['title']}"? All community answers will be permanently removed.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<ForumViewModel>().deleteThread(threadId);
              if (_activeThread?['id'] == threadId) {
                setState(() => _activeThread = null);
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🗑️ Post deleted successfully.'),
                  backgroundColor: Color(0xFFEF4444),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('DELETE POST'),
          ),
        ],
      ),
    );
  }

  void _showEditMessageDialog(String replyId, String currentText) {
    if (_activeThread == null) return;
    final threadId = _activeThread!['id'].toString();
    final editController = TextEditingController(text: currentText);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.edit_rounded, color: Color(0xFF004D40)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Edit Response',
                softWrap: true,
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 20,
                  color: const Color(0xFF004D40),
                ),
              ),
            ),
          ],
        ),
        content: TextField(
          controller: editController,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'Your Answer / Response',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL'),
          ),
          FilledButton.icon(
            onPressed: () async {
              final newText = editController.text.trim();
              if (newText.isEmpty) return;

              final forumVM = context.read<ForumViewModel>();

              final result = await forumVM.editReply(
                threadId,
                replyId,
                newText,
              );

              if (!mounted) return;

              if (result.isBlocked) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🚫 Edit Blocked: ${result.blockReason}'),
                    backgroundColor: const Color(0xFFEF4444),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              if (!dialogContext.mounted) return;

              Navigator.pop(dialogContext);

              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    result.isAutoFlagged
                        ? '⚠️ Answer updated and flagged for moderator review (${result.flagReason}).'
                        : '✏️ Answer updated successfully.',
                  ),
                  backgroundColor: result.isAutoFlagged
                      ? const Color(0xFFD97706)
                      : const Color(0xFF004D40),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF004D40),
            ),
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text('SAVE CHANGES'),
          ),
        ],
      ),
    );
  }

  void _showEditThreadDialog(Map<String, dynamic> thread) {
    final threadId = thread['id'].toString();
    final editTitleController = TextEditingController(
      text: thread['title'].toString(),
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.edit_rounded, color: Color(0xFF004D40)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Edit Question / Post Title',
                softWrap: true,
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 18,
                  color: const Color(0xFF004D40),
                ),
              ),
            ),
          ],
        ),
        content: TextField(
          controller: editTitleController,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Question Title',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL'),
          ),
          FilledButton.icon(
            onPressed: () async {
              final newTitle = editTitleController.text.trim();
              if (newTitle.isEmpty) return;

              final forumVM = context.read<ForumViewModel>();

              final result = await forumVM.editThread(threadId, newTitle);

              if (!mounted) return;

              if (result.isBlocked) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🚫 Edit Blocked: ${result.blockReason}'),
                    backgroundColor: const Color(0xFFEF4444),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              if (!dialogContext.mounted) return;

              Navigator.pop(dialogContext);

              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    result.isAutoFlagged
                        ? '⚠️ Title updated and flagged for moderator review (${result.flagReason}).'
                        : '✏️ Post title updated.',
                  ),
                  backgroundColor: result.isAutoFlagged
                      ? const Color(0xFFD97706)
                      : const Color(0xFF004D40),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF004D40),
            ),
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text('SAVE CHANGES'),
          ),
        ],
      ),
    );
  }

  void _showCreateThreadModal(LanguageViewModel langVM) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    String selectedCommunity = 'c/BatikCraft';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF0D2825) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Ask Question / Create Post',
                            style: GoogleFonts.dmSerifDisplay(
                              fontSize: 22,
                              color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: isDark ? Colors.white70 : Colors.black87),
                          onPressed: () => Navigator.pop(modalContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Select Community Hub:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCommunity,
                      dropdownColor: isDark ? const Color(0xFF0D2825) : Colors.white,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: isDark ? const BorderSide(color: Color(0xFF1E3A34)) : BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: isDark ? const BorderSide(color: Color(0xFF1E3A34)) : BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF041412) : const Color(0xFFF8F9FA),
                      ),
                      items: _communities.where((c) => c != 'All').map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text(
                            c,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null)
                          setModalState(() => selectedCommunity = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Question / Title:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleController,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'e.g. How to care for handwoven Songket silk?',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: isDark ? Colors.white38 : Colors.grey[400],
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF041412) : const Color(0xFFF8F9FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: isDark ? const BorderSide(color: Color(0xFF1E3A34)) : BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: isDark ? const BorderSide(color: Color(0xFF1E3A34)) : BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Details / Context:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: bodyController,
                      maxLines: 3,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'Provide details or background for master artisans...',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : Colors.grey[400],
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF041412) : const Color(0xFFF8F9FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: isDark ? const BorderSide(color: Color(0xFF1E3A34)) : BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: isDark ? const BorderSide(color: Color(0xFF1E3A34)) : BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: () async {
                          final title = titleController.text.trim();
                          final body = bodyController.text.trim();

                          if (title.isEmpty) return;

                          final authVM = context.read<AuthViewModel>();
                          final user = authVM.currentUser;
                          final bool isUserArtisan =
                              user?.isArtisan == true ||
                              user?.role == 'Artisan';
                          final String effectiveAuthor =
                              (user?.effectiveUsername != null &&
                                  user!.effectiveUsername.isNotEmpty)
                              ? user.effectiveUsername
                              : ((user?.displayName != null &&
                                        user!.displayName!.isNotEmpty)
                                    ? user.displayName!
                                    : (user?.email.isNotEmpty == true
                                          ? user!.email.split('@').first
                                          : 'Community Member'));

                          final result = await context
                              .read<ForumViewModel>()
                              .createThread(
                                community: selectedCommunity,
                                title: title,
                                authorName: effectiveAuthor,
                                authorEmail: user?.email ?? '',
                                isArtisan: isUserArtisan,
                                initialMessage: body.isNotEmpty ? body : null,
                              );

                          if (result.isBlocked) {
                            if (!modalContext.mounted) return;
                            showDialog(
                              context: modalContext,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                title: Row(
                                  children: [
                                    const Icon(
                                      Icons.block_rounded,
                                      color: Color(0xFFEF4444),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Post Blocked',
                                        softWrap: true,
                                        style: GoogleFonts.dmSerifDisplay(
                                          color: const Color(0xFF991B1B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                content: Text(
                                  result.blockReason ??
                                      'Your question contains prohibited or offensive keywords.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                                actions: [
                                  FilledButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF004D40),
                                    ),
                                    child: const Text('UNDERSTOOD'),
                                  ),
                                ],
                              ),
                            );
                            return;
                          }

                          if (!modalContext.mounted) return;
                          Navigator.of(modalContext).pop();

                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                result.isAutoFlagged
                                    ? '⏳ Post held in moderation queue for admin review (${result.flagReason}). It will appear publicly once approved.'
                                    : '🎉 Post published to community hub!',
                              ),
                              backgroundColor: result.isAutoFlagged
                                  ? const Color(0xFFD97706)
                                  : const Color(0xFF004D40),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF004D40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: Text(
                          'Post Question to Community',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final langVM = context.watch<LanguageViewModel>();
    final forumVM = context.watch<ForumViewModel>();
    final authVM = context.watch<AuthViewModel>();
    final currentUser = authVM.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Map<String, dynamic>> threadsMap = forumVM.threads.map((t) {
      final map = t.toMap();
      final bool isMyThread =
          currentUser != null &&
          ((currentUser.id.isNotEmpty &&
                  t.userId != null &&
                  t.userId!.isNotEmpty &&
                  t.userId == currentUser.id) ||
              (currentUser.email.isNotEmpty &&
                  t.authorEmail.isNotEmpty &&
                  t.authorEmail.toLowerCase() ==
                      currentUser.email.toLowerCase()));

      map['isMe'] = isMyThread;
      if (isMyThread) {
        map['displayName'] = '${t.authorName} (You)';
      } else {
        map['displayName'] = t.authorName;
      }

      final List<Map<String, dynamic>> msgMaps = t.replies.map((r) {
        final rMap = r.toMap();
        final bool isMyMsg =
            currentUser != null &&
            (currentUser.email.isNotEmpty &&
                r.authorEmail.isNotEmpty &&
                r.authorEmail.toLowerCase() == currentUser.email.toLowerCase());
        rMap['isMe'] = isMyMsg;
        if (isMyMsg) {
          rMap['displayName'] = '${r.sender} (You)';
        } else {
          rMap['displayName'] = r.sender;
        }
        return rMap;
      }).toList();
      map['messages'] = msgMaps;
      return map;
    }).toList();

    if (_activeThread != null) {
      final updated = threadsMap.firstWhere(
        (t) => t['id'] == _activeThread!['id'],
        orElse: () => _activeThread!,
      );
      _activeThread = updated;
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF041412) : const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.forum_rounded,
                color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                _activeThread == null
                    ? 'Warisan Community Hub'
                    : 'Question & Answers',
                style: GoogleFonts.dmSerifDisplay(
                  color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF041412) : Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: _activeThread != null
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                ),
                onPressed: () => setState(() => _activeThread = null),
              )
            : null,
        actions: [
          if (_activeThread == null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton.icon(
                onPressed: () => _showCreateThreadModal(langVM),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF004D40),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(
                  Icons.add_comment_rounded,
                  size: 16,
                  color: Color(0xFFFFD54F),
                ),
                label: Text(
                  'Ask Question',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (_activeThread != null)
            IconButton(
              icon: const Icon(Icons.flag_outlined, color: Color(0xFFEF4444)),
              tooltip: 'Report / Flag Post',
              onPressed: () => _showFlagReportModal(
                context,
                _activeThread!['id'].toString(),
                _activeThread!['title'].toString(),
              ),
            ),
        ],
      ),
      body: _activeThread == null
          ? _buildRedditQuoraFeed(langVM, threadsMap, isDark)
          : _buildQuoraThreadDetailView(langVM, isDark),
      floatingActionButton: _activeThread == null
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateThreadModal(langVM),
              backgroundColor: const Color(0xFF004D40),
              icon: const Icon(
                Icons.edit_note_rounded,
                color: Color(0xFFFFD54F),
                size: 26,
              ),
              label: Text(
                'Ask / Post',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            )
          : null,
    );
  }

  // REDDIT & QUORA HYBRID HOME FEED
  Widget _buildRedditQuoraFeed(
    LanguageViewModel langVM,
    List<Map<String, dynamic>> threads,
    bool isDark,
  ) {
    final forumVMWatch = context.watch<ForumViewModel>();

    // Collect IDs of posts that have been ACTIONED/DELETED by admin
    final Set<String> deletedPostIds = Set.from(_dismissedNoticeIds);

    for (final n in forumVMWatch.moderationHistory) {
      final String actionType = (n['action_type'] ?? '').toString().toLowerCase();
      final String status = (n['status'] ?? '').toString().toLowerCase();

      // Only treat posts as deleted if status is actioned/deleted (NEVER if dismissed!)
      if (status != 'dismissed' && (actionType == 'deleted' || status == 'actioned')) {
        final String id = (n['post_id'] ?? n['id'])?.toString() ?? '';
        if (id.isNotEmpty) deletedPostIds.add(id);
      }
    }

    // Only show approved, non-flagged threads in public feed (EXCEPT for author, unless deleted by admin)
    List<Map<String, dynamic>> filteredThreads = threads.where((t) {
      final String threadId = t['id']?.toString() ?? '';

      if (deletedPostIds.contains(threadId)) {
        return false; // Actioned/deleted by admin, hide completely from feed
      }
      if (t['isReported'] == true) {
        return t['isMe'] == true;
      }
      return true;
    }).toList();

    // Check if the current user has any post ACTUALLY pending in moderation review (excluding deleted)
    final pendingMyPosts = threads.where((t) {
      final String threadId = t['id']?.toString() ?? '';

      if (deletedPostIds.contains(threadId)) {
        return false; // Actioned/deleted by admin, no longer pending review!
      }
      return t['isReported'] == true && t['isMe'] == true;
    }).toList();

    if (_selectedCommunity != 'All') {
      filteredThreads = filteredThreads
          .where((t) => t['community'] == _selectedCommunity)
          .toList();
    }

    if (_selectedSort == 'Hot') {
      filteredThreads = List<Map<String, dynamic>>.from(filteredThreads)
        ..sort((a, b) {
          double hotScore(Map<String, dynamic> thread) {
            final int upvotes = (thread['upvotes'] as int?) ?? 0;
            final int replies = (thread['repliesCount'] as int?) ?? 0;

            final DateTime createdAt =
                DateTime.tryParse(thread['timestamp']?.toString() ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0);

            final double ageHours =
                DateTime.now().difference(createdAt).inMinutes / 60.0;

            final double agePenalty = ageHours / 24.0;

            return (upvotes * 2) + replies - agePenalty;
          }

          return hotScore(b).compareTo(hotScore(a));
        });
    } else if (_selectedSort == 'New') {
      filteredThreads = List<Map<String, dynamic>>.from(filteredThreads)
        ..sort((a, b) {
          final aTime =
              DateTime.tryParse(a['timestamp']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);

          final bTime =
              DateTime.tryParse(b['timestamp']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);

          return bTime.compareTo(aTime); // newest first
        });
    } else if (_selectedSort == 'Top') {
      filteredThreads = List.from(filteredThreads)
        ..sort(
          (a, b) => ((b['upvotes'] as int?) ?? 0).compareTo(
            (a['upvotes'] as int?) ?? 0,
          ),
        );
    } else if (_selectedSort == 'Verified Q&A') {
      filteredThreads = filteredThreads
          .where((t) => t['isSolved'] == true)
          .toList();
    }

    final forumVM = context.watch<ForumViewModel>();
    final authVM = context.watch<AuthViewModel>();
    final currentUser = authVM.currentUser;
    final String currentEmail = currentUser?.email.toLowerCase().trim() ?? '';
    final String currentName =
        (currentUser?.effectiveUsername ??
                currentUser?.displayName ??
                currentUser?.username ??
                '')
            .toLowerCase()
            .trim();

    final myDeletedNotices = forumVM.moderationHistory.where((item) {
      final String actionType = (item['action_type'] ?? '')
          .toString()
          .toLowerCase();
      final String status = (item['status'] ?? '').toString().toLowerCase();
      if (actionType != 'deleted' && status != 'actioned') return false;

      final String rawReason = (item['reason'] ?? '').toString().trim();
      final String resNotes = (item['resolution_notes'] ?? '')
          .toString()
          .trim();
      // Filter out stuck automated reports from previous testing that lack resolution notes
      if (rawReason.toLowerCase().startsWith('automated') &&
          resNotes.isEmpty &&
          (actionType == 'deleted' || status == 'actioned')) {
        return false;
      }

      // Filter to ensure notice belongs to current user
      if (currentUser == null) return false;
      bool belongsToMe = false;

      // Check author_id from joined tables
      String authorId = '';
      if (item['forum_posts'] != null) {
        authorId = (item['forum_posts']['author_id'] ?? '').toString();
      } else if (item['forum_replies'] != null) {
        authorId = (item['forum_replies']['author_id'] ?? '').toString();
      }
      if (authorId.isNotEmpty && authorId == currentUser.id) {
        belongsToMe = true;
      }

      // Fallback: check if notes contain user's email or name (important for orphaned reports from CASCADE deletions)
      final String notes = (item['notes'] ?? '').toString().toLowerCase();
      if (currentEmail.isNotEmpty && notes.contains(currentEmail)) {
        belongsToMe = true;
      } else if (currentName.isNotEmpty && notes.contains(currentName)) {
        belongsToMe = true;
      }

      // Fallback: check local injected author_email
      final String itemEmail = (item['author_email'] ?? '')
          .toString()
          .toLowerCase();
      if (itemEmail.isNotEmpty && itemEmail == currentEmail) {
        belongsToMe = true;
      }

      return belongsToMe;
    }).toList();

    return Column(
      children: [
        if (myDeletedNotices.isNotEmpty)
          ...myDeletedNotices
              .where((notice) {
                final noticeId =
                    notice['id']?.toString() ??
                    notice['resolved_at']?.toString() ??
                    '';
                return !_dismissedNoticeIds.contains(noticeId);
              })
              .map((notice) {
                final noticeId =
                    notice['id']?.toString() ??
                    notice['resolved_at']?.toString() ??
                    '';
                final String notes = (notice['notes'] ?? '').toString();
                final String delReason = (notice['deletion_reason'] ?? '').toString().trim();
                final String resolutionNotes =
                    (notice['resolution_notes'] ?? '').toString().trim();
                final String rawReason = (notice['reason'] ?? '')
                    .toString()
                    .trim();
                final String adminReason = (notice['admin_reason'] ?? '')
                    .toString()
                    .trim();

                String reasonText = '';
                if (delReason.isNotEmpty && delReason != 'null') {
                  reasonText = delReason;
                } else if (adminReason.isNotEmpty && adminReason != 'null') {
                  reasonText = adminReason;
                } else if (resolutionNotes.isNotEmpty &&
                    resolutionNotes != 'null' &&
                    resolutionNotes != 'Admin Moderation Deletion') {
                  reasonText = resolutionNotes;
                } else if (notes.contains('deleted: ')) {
                  reasonText = notes.split('deleted: ').last.trim();
                } else if (rawReason.isNotEmpty &&
                    rawReason != 'null' &&
                    !rawReason.toLowerCase().startsWith('automated') &&
                    rawReason != 'Admin Moderation Deletion' &&
                    rawReason != 'User Reported Content') {
                  reasonText = rawReason;
                } else {
                  reasonText = rawReason.isNotEmpty
                      ? rawReason
                      : 'Violation of Community Guidelines';
                }

                String postTitle = (notice['post_title'] ?? '')
                    .toString()
                    .trim();
                if (postTitle.isEmpty && notes.contains('"')) {
                  final match = RegExp(r'"([^"]*)"').firstMatch(notes);
                  if (match != null && match.group(1) != null) {
                    postTitle = match.group(1)!;
                  }
                }

                final String descriptionText = postTitle.isNotEmpty
                    ? 'Your post "$postTitle" was removed by an administrator.'
                    : 'Your content was removed by moderation.';

                return Container(
                  margin: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF3B1212) : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFFDC2626),
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Post Removed by Administrator',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () async {
                                    setState(() {
                                      _dismissedNoticeIds.add(noticeId);
                                    });
                                    final String targetId =
                                        notice['id']?.toString() ?? noticeId;
                                    if (targetId.isNotEmpty) {
                                      await context
                                          .read<ForumViewModel>()
                                          .dismissModerationNotice(targetId);
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(2.0),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                      color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              descriptionText,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : const Color(0xFF7F1D1D),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF041412) : Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFFFCA5A5),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.gavel_rounded,
                                    size: 14,
                                    color: Color(0xFFB91C1C),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Admin Reason: $reasonText',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFB91C1C),
                                      ),
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
                );
              }),
        if (pendingMyPosts.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(14, 10, 14, 2),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E3A34) : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF34D399).withValues(alpha: 0.3) : const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.pending_actions_rounded,
                  color: Color(0xFFB45309),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'You have ${pendingMyPosts.length} question(s) currently held in moderation review.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF78350F),
                    ),
                  ),
                ),
              ],
            ),
          ),
        // Subreddit / Community Filter Chips Header
        Container(
          color: isDark ? const Color(0xFF041412) : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: _communities.map((c) {
                    final isSelected = _selectedCommunity == c;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(c),
                        labelStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w600,
                          color: isSelected
                              ? (isDark ? const Color(0xFFFFD54F) : Colors.white)
                              : (isDark ? Colors.white70 : const Color(0xFF334155)),
                        ),
                        selectedColor: isDark ? const Color(0xFF1E3A34) : const Color(0xFF004D40),
                        backgroundColor: isDark ? const Color(0xFF0D2825) : const Color(0xFFF1F5F9),
                        checkmarkColor: isDark ? const Color(0xFFFFD54F) : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: isDark ? BorderSide(color: isSelected ? const Color(0xFFFFD54F) : const Color(0xFF1E3A34)) : BorderSide.none,
                        ),
                        onSelected: (val) {
                          setState(() => _selectedCommunity = c);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              // Sort Options (Hot, New, Top, Verified Q&A)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'Sort by:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white60 : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ..._sortOptions.map((sort) {
                      final isSelected = _selectedSort == sort;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedSort = sort),
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark ? const Color(0xFF1E3A34) : const Color(0xFFFEF3C7))
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: isDark && isSelected ? Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.4)) : null,
                          ),
                          child: Text(
                            sort,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? (isDark ? const Color(0xFFFFD54F) : const Color(0xFF78350F))
                                  : (isDark ? Colors.white70 : Colors.grey[700]),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Main Feed Thread Cards
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => context.read<ForumViewModel>().fetchThreads(),
            color: const Color(0xFF004D40),
            child: filteredThreads.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 40),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF0D2825)
                                    : const Color(0xFF004D40).withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.forum_outlined,
                                size: 40,
                                color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No community questions yet',
                              style: GoogleFonts.dmSerifDisplay(
                                fontSize: 20,
                                color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Be the first to start a conversation or ask heritage craft masters!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: isDark ? Colors.white60 : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 18),
                            FilledButton.icon(
                              onPressed: () => _showCreateThreadModal(langVM),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF004D40),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                              icon: const Icon(
                                Icons.add_comment_rounded,
                                size: 16,
                                color: Color(0xFFFFD54F),
                              ),
                              label: Text(
                                'Ask a Question',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredThreads.length,
                    itemBuilder: (context, index) {
                      final thread = filteredThreads[index];
                      return _buildRedditPostCard(thread, isDark);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  // REDDIT STYLE POST CARD WITH UPVOTE SIDEBAR
  Widget _buildRedditPostCard(Map<String, dynamic> thread, bool isDark) {
    final bool isArtisan = (thread['isArtisan'] as bool?) ?? false;
    final int userVote = (thread['userVote'] as num?)?.toInt() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D2825) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF1E3A34) : Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _activeThread = thread),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reddit-style vote sidebar
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF041412) : const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_upward_rounded,
                          size: 20,
                          color: userVote == 1
                              ? const Color(0xFFF97316)
                              : Colors.grey[400],
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _voteThread(thread, 1),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${thread['upvotes']}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: userVote == 1
                              ? const Color(0xFFF97316)
                              : (userVote == -1
                                    ? const Color(0xFF6366F1)
                                    : (isDark ? Colors.white70 : const Color(0xFF1E293B))),
                        ),
                      ),
                      const SizedBox(height: 4),
                      IconButton(
                        icon: Icon(
                          Icons.arrow_downward_rounded,
                          size: 20,
                          color: userVote == -1
                              ? const Color(0xFF6366F1)
                              : Colors.grey[400],
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _voteThread(thread, -1),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 14),

                // Post content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (thread['isReported'] == true)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.pending_actions,
                                size: 12,
                                color: Colors.amber.shade900,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Pending Moderation',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Community / author / role / timestamp
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E3A34) : const Color(0xFF004D40).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              thread['community'].toString(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                              ),
                            ),
                          ),
                          Text(
                            '• Posted by ${thread['displayName'] ?? thread['authorName']}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : Colors.grey[600],
                            ),
                          ),
                          if (isArtisan)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'MASTER ARTISAN',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF78350F),
                                ),
                              ),
                            ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                thread['timestamp'].toString(),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  color: isDark ? Colors.white38 : Colors.grey[400],
                                ),
                              ),
                              if (thread['isEdited'] == true) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '(edited)',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontStyle: FontStyle.italic,
                                    color: const Color(0xFFD97706),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Title
                      Text(
                        thread['title'].toString(),
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 16,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          height: 1.3,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Action bar
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Left side: answers + verified badge
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF041412) : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF1E3A34) : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.mode_comment_outlined,
                                        size: 14,
                                        color: isDark ? Colors.white60 : Colors.grey[600],
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        '${thread['repliesCount']} '
                                        '${thread['repliesCount'] == 1 ? 'Answer' : 'Answers'}',
                                        maxLines: 1,
                                        softWrap: false,
                                        overflow: TextOverflow.visible,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white70 : Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (thread['isSolved'] == true)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle_rounded,
                                          size: 12,
                                          color: isDark ? const Color(0xFF34D399) : const Color(0xFF166534),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Verified Answer',
                                          maxLines: 1,
                                          softWrap: false,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? const Color(0xFF34D399) : const Color(0xFF166534),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Right side: fixed edit/delete/report area
                          if (thread['isMe'] == true)
                            SizedBox(
                              width: 56,
                              height: 28,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () =>
                                          _showEditThreadDialog(thread),
                                      borderRadius: BorderRadius.circular(14),
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: Center(
                                          child: Icon(
                                            Icons.edit_outlined,
                                            size: 16,
                                            color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _confirmDeleteThread(thread),
                                      borderRadius: BorderRadius.circular(14),
                                      child: const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: Center(
                                          child: Icon(
                                            Icons.delete_outline_rounded,
                                            size: 16,
                                            color: Color(0xFFEF4444),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            SizedBox(
                              width: 28,
                              height: 28,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _showFlagReportModal(
                                    context,
                                    thread['id'].toString(),
                                    thread['title'].toString(),
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  child: const Center(
                                    child: Icon(
                                      Icons.flag_outlined,
                                      size: 16,
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // QUORA STYLE Q&A THREAD DETAIL VIEW
  Widget _buildQuoraThreadDetailView(LanguageViewModel langVM, bool isDark) {
    final List<Map<String, dynamic>> allMessages = List<Map<String, dynamic>>.from(
      _activeThread!['messages'] ?? [],
    );

    // Only show approved, non-flagged replies in public thread, EXCEPT for the author
    final List<Map<String, dynamic>> messages = allMessages.where((msg) {
      if (msg['isReported'] == true) {
        return msg['isMe'] == true;
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Thread Question Header Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          color: isDark ? const Color(0xFF0D2825) : Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E3A34) : const Color(0xFF004D40).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _activeThread!['community'].toString(),
                        softWrap: true,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Asked by ${_activeThread!['displayName'] ?? _activeThread!['authorName']}',
                      softWrap: true,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _activeThread!['title'].toString(),
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 20,
                  color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                  height: 1.2,
                ),
              ),
              if (_activeThread!['content'] != null &&
                  _activeThread!['content'].toString().isNotEmpty &&
                  _activeThread!['content'].toString() !=
                      _activeThread!['title'].toString()) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF041412) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? const Color(0xFF1E3A34) : const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    _activeThread!['content'].toString(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF041412) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_upward_rounded,
                            size: 16,
                            color:
                                (((_activeThread!['userVote'] as num?)
                                        ?.toInt()) ==
                                    1)
                                ? const Color(0xFFF97316)
                                : Colors.grey[600],
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          constraints: const BoxConstraints(),
                          onPressed: () => _voteThread(_activeThread!, 1),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${(_activeThread!['upvotes'] as num?)?.toInt() ?? 0}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color:
                                (((_activeThread!['userVote'] as num?)
                                        ?.toInt()) ==
                                    1)
                                ? const Color(0xFFF97316)
                                : ((((_activeThread!['userVote'] as num?)
                                              ?.toInt()) ==
                                          -1)
                                      ? const Color(0xFF6366F1)
                                      : (isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40))),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: Icon(
                            Icons.arrow_downward_rounded,
                            size: 16,
                            color:
                                (((_activeThread!['userVote'] as num?)
                                        ?.toInt()) ==
                                    -1)
                                ? const Color(0xFF6366F1)
                                : Colors.grey[600],
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          constraints: const BoxConstraints(),
                          onPressed: () => _voteThread(_activeThread!, -1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${messages.length} Answers',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white60 : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Discussion Header Banner
        Container(
          width: double.infinity,
          color: isDark ? const Color(0xFF041412) : const Color(0xFFF8FAFC),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 16,
                color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
              ),
              const SizedBox(width: 8),
              Text(
                'Discussion & Community Answers (${messages.length})',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: isDark ? const Color(0xFF1E3A34) : Colors.grey[300]),

        // Answers List (Quora Style)
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.mark_chat_unread_outlined,
                          size: 40,
                          color: isDark ? const Color(0xFF1E3A34) : Colors.grey[400],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'No answers yet',
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 18,
                            color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Be the first to share your heritage craft experience or insights below!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  controller: _answersScrollController,
                  padding: const EdgeInsets.all(16),
                  children: messages.asMap().entries.map((entry) {
                    final int index = entry.key;
                    final Map<String, dynamic> msg = entry.value;

                    final String replyId = msg['id'].toString();

                    final GlobalKey replyKey = _replyKeys.putIfAbsent(
                      replyId,
                      () => GlobalKey(),
                    );

                    return Container(
                      key: replyKey,
                      child: _buildQuoraAnswerCard(msg, index, isDark),
                    );
                  }).toList(),
                ),
        ),

        // Answer Bottom Input Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0D2825) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ============================
                // Replying To Banner
                // ============================
                if (_replyingToReplyId != null) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E3A34) : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? const Color(0xFF34D399) : const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.reply_rounded,
                          size: 16,
                          color: isDark ? const Color(0xFF34D399) : const Color(0xFF1D4ED8),
                        ),

                        const SizedBox(width: 8),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Replying to ${_replyingToName ?? 'User'}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? const Color(0xFF34D399) : const Color(0xFF1D4ED8),
                                ),
                              ),

                              if (_replyingToText != null &&
                                  _replyingToText!.isNotEmpty)
                                Text(
                                  _replyingToText!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    color: isDark ? Colors.white70 : Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),

                        IconButton(
                          tooltip: 'Cancel reply',
                          icon: Icon(Icons.close_rounded, size: 16, color: isDark ? Colors.white70 : Colors.black87),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            setState(() {
                              _replyingToReplyId = null;
                              _replyingToName = null;
                              _replyingToText = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],

                // ============================
                // Reply Input Row
                // ============================
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        maxLines: 4,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(context),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: _replyingToName != null
                              ? 'Reply to $_replyingToName...'
                              : 'Write your answer or response...',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: isDark ? Colors.white38 : Colors.grey[400],
                          ),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF041412) : const Color(0xFFF8F9FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(color: isDark ? const Color(0xFF1E3A34) : Colors.grey[200]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(color: isDark ? const Color(0xFF1E3A34) : Colors.grey[200]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    SizedBox(
                      height: 42,
                      child: FilledButton.icon(
                        onPressed: () => _sendMessage(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF004D40),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(
                          Icons.send_rounded,
                          size: 15,
                          color: Color(0xFFFFD54F),
                        ),
                        label: Text(
                          'Reply',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // QUORA ANSWER CARD WITH MASTER VERIFICATION BADGE & UPVOTES
  Widget _buildQuoraAnswerCard(Map<String, dynamic> msg, int index, bool isDark) {
    final bool isMe = msg['isMe'] as bool? ?? false;
    final bool isArtisan = msg['isArtisan'] as bool? ?? false;
    final bool isVerifiedAnswer = msg['isVerifiedAnswer'] as bool? ?? false;
    final int userVote = (msg['userVote'] as num?)?.toInt() ?? 0;

    // ============================
    // Find parent reply
    // ============================
    final String? parentReplyId = msg['parentReplyId']?.toString();

    Map<String, dynamic>? parentReply;

    if (parentReplyId != null &&
        parentReplyId.isNotEmpty &&
        _activeThread != null) {
      final List<dynamic> allMessages =
          (_activeThread!['messages'] as List?) ?? [];

      for (final item in allMessages) {
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);

          if (map['id']?.toString() == parentReplyId) {
            parentReply = map;
            break;
          }
        }
      }
    }

    final String? replyingToName = parentReply == null
        ? null
        : (parentReply['displayName'] ?? parentReply['sender'])?.toString();

    final String? replyingToText = parentReply?['text']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isVerifiedAnswer
            ? (isDark ? const Color(0xFF1E2D1E) : const Color(0xFFFFFBEB))
            : (isDark ? const Color(0xFF0D2825) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isVerifiedAnswer
              ? (isDark ? const Color(0xFF34D399) : const Color(0xFFFDE68A))
              : (isMe
                    ? (isDark ? const Color(0xFF34D399).withValues(alpha: 0.4) : const Color(0xFF004D40).withValues(alpha: 0.3))
                    : (isDark ? const Color(0xFF1E3A34) : Colors.black.withValues(alpha: 0.05))),
          width: isVerifiedAnswer ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Master Verified Answer Banner
          if (isVerifiedAnswer) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF064E3B) : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_rounded,
                    size: 14,
                    color: isDark ? const Color(0xFF34D399) : const Color(0xFFB45309),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'VERIFIED MASTER ARTISAN ANSWER',
                      softWrap: true,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: isDark ? const Color(0xFF34D399) : const Color(0xFF78350F),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (msg['isReported'] == true) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E3A34) : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: isDark ? const Color(0xFF34D399).withValues(alpha: 0.3) : const Color(0xFFFDE68A)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.pending_actions_rounded,
                    size: 12,
                    color: Color(0xFFB45309),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Pending Moderation (Only visible to you)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF78350F),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Author Row
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: isArtisan
                    ? const Color(0xFFD97706)
                    : const Color(0xFF004D40),
                child: Icon(
                  isArtisan ? Icons.palette_rounded : Icons.person_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            (msg['displayName'] ?? msg['sender']).toString(),
                            softWrap: true,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (isArtisan) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'MASTER',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF78350F),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          msg['time'].toString(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: isDark ? Colors.white38 : Colors.grey,
                          ),
                        ),
                        if (msg['isEdited'] == true ||
                            msg['time'].toString().contains('(edited)')) ...[
                          const SizedBox(width: 4),
                          Text(
                            '• (edited)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                              color: const Color(0xFFD97706),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ============================
          // Replying To Parent
          // ============================
          if (replyingToName != null && parentReplyId != null) ...[
            InkWell(
              onTap: () {
                _scrollToReply(parentReplyId);
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF041412) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border(
                    left: BorderSide(
                      color: isArtisan
                          ? const Color(0xFFD97706)
                          : (isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40)),
                      width: 3,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.reply_rounded,
                          size: 14,
                          color: isArtisan
                              ? const Color(0xFFD97706)
                              : (isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40)),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'Replying to $replyingToName',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isArtisan
                                  ? const Color(0xFFB45309)
                                  : (isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40)),
                            ),
                          ),
                        ),

                        // 提示用户这里可以点击
                        const Icon(
                          Icons.arrow_upward_rounded,
                          size: 13,
                          color: Colors.grey,
                        ),
                      ],
                    ),

                    if (replyingToText != null &&
                        replyingToText.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        replyingToText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: isDark ? Colors.white70 : Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),
          ] else
            const SizedBox(height: 2),

          // Answer Text
          Text(
            msg['text'].toString(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
              height: 1.5,
            ),
          ),

          const SizedBox(height: 14),

          // Quora Vote & Controls Bar
          Row(
            children: [
              // 1. Vote 固定放最左边
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF041412) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _voteMessage(msg, 1),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.arrow_upward_rounded,
                          size: 14,
                          color: userVote == 1
                              ? const Color(0xFFF97316)
                              : (isDark ? Colors.white70 : Colors.grey[700]),
                        ),
                      ),
                    ),

                    const SizedBox(width: 5),

                    Text(
                      '${(msg['upvotes'] as num?)?.toInt() ?? 0}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: userVote == 1
                            ? const Color(0xFFC2410C)
                            : userVote == -1
                            ? const Color(0xFF4338CA)
                            : (isDark ? Colors.white70 : Colors.grey[700]),
                      ),
                    ),

                    const SizedBox(width: 5),

                    GestureDetector(
                      onTap: () => _voteMessage(msg, -1),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.arrow_downward_rounded,
                          size: 14,
                          color: userVote == -1
                              ? const Color(0xFF4338CA)
                              : (isDark ? Colors.white70 : Colors.grey[700]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. 这个 Spacer 一定是在 vote 后面
              const Spacer(),

              // 3. Reply button
              IconButton(
                icon: Icon(
                  Icons.reply_rounded,
                  size: 17,
                  color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                ),
                tooltip: 'Reply to ${msg['displayName'] ?? msg['sender']}',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  setState(() {
                    _replyingToReplyId = msg['id'].toString();
                    _replyingToName = (msg['displayName'] ?? msg['sender'])
                        .toString();
                    _replyingToText = msg['text'].toString();
                  });
                },
              ),

              const SizedBox(width: 12),

              if (isMe) ...[
                IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                  ),
                  tooltip: 'Edit Answer',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showEditMessageDialog(
                    msg['id'].toString(),
                    msg['text'].toString(),
                  ),
                ),

                const SizedBox(width: 12),

                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 16,
                    color: Color(0xFFEF4444),
                  ),
                  tooltip: 'Delete Answer',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _confirmDeleteMessage(msg['id'].toString()),
                ),
              ] else ...[
                IconButton(
                  icon: const Icon(
                    Icons.flag_outlined,
                    size: 16,
                    color: Color(0xFFEF4444),
                  ),
                  tooltip: 'Report Content',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showReplyReportModal(
                    context,
                    _activeThread!['id'].toString(),
                    msg['id'].toString(),
                    msg['text'].toString(),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
