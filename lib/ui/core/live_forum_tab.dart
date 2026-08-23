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
      context.read<ForumViewModel>().fetchThreads();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(BuildContext context) async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _activeThread == null) return;

    final authVM = context.read<AuthViewModel>();
    final forumVM = context.read<ForumViewModel>();
    final user = authVM.currentUser;
    final bool isUserArtisan = user?.isArtisan == true || user?.role == 'Artisan';
    final String effectiveAuthor = (user?.effectiveUsername != null && user!.effectiveUsername.isNotEmpty)
        ? user.effectiveUsername
        : ((user?.displayName != null && user!.displayName!.isNotEmpty)
            ? user.displayName!
            : (user?.email.isNotEmpty == true ? user!.email.split('@').first : 'Community Member'));

    final result = await forumVM.postReply(
      threadId: _activeThread!['id'].toString(),
      text: text,
      authorName: effectiveAuthor,
      authorEmail: user?.email ?? '',
      isArtisan: isUserArtisan,
    );

    if (result.isBlocked) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.block_rounded, color: Color(0xFFEF4444)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Content Blocked',
                  softWrap: true,
                  style: GoogleFonts.dmSerifDisplay(color: const Color(0xFF991B1B)),
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
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF004D40)),
              child: const Text('UNDERSTOOD'),
            ),
          ],
        ),
      );
      return;
    }

    _messageController.clear();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.isAutoFlagged
            ? '⚠️ Answer posted and flagged for moderator review (${result.flagReason})'
            : '💬 Answer posted to discussion!'),
        backgroundColor: result.isAutoFlagged ? const Color(0xFFD97706) : const Color(0xFF004D40),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _voteThread(Map<String, dynamic> thread, int voteDirection) {
    context.read<ForumViewModel>().voteThread(thread['id'].toString(), voteDirection);
  }

  void _voteMessage(Map<String, dynamic> msg, int voteDirection) {
    if (_activeThread == null) return;
    context.read<ForumViewModel>().voteReply(_activeThread!['id'].toString(), msg['id'].toString(), voteDirection);
  }

  void _showFlagReportModal(BuildContext context, String threadId, String title) {
    String selectedReason = 'Inappropriate Content';
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.flag_rounded, color: Color(0xFFEF4444)),
              const SizedBox(width: 10),
              Text(
                'Report / Flag Content',
                style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: const Color(0xFF004D40)),
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
                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[800]),
              ),
              const SizedBox(height: 14),
              Text('Select Moderation Reason:', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[600])),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedReason,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: 'Inappropriate Content', child: Text('Inappropriate / Offensive Content')),
                  DropdownMenuItem(value: 'Misinformation', child: Text('Misinformation / Fake Heritage Claim')),
                  DropdownMenuItem(value: 'Spam/Off-topic', child: Text('Spam or Off-topic Advertisement')),
                  DropdownMenuItem(value: 'Harassment', child: Text('Harassment or Abusive Language')),
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
              onPressed: () {
                final notes = notesController.text.trim();
                context.read<ForumViewModel>().reportThread(threadId, selectedReason, notes);
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🚩 Content reported to Admin Moderation Officers ($selectedReason)'),
                    backgroundColor: const Color(0xFFEF4444),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
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
                style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: const Color(0xFF004D40)),
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
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<ForumViewModel>().deleteReply(threadId, replyId);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🗑️ Response deleted successfully.'),
                  backgroundColor: Color(0xFFEF4444),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
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
                style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: const Color(0xFF004D40)),
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
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
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
                style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: const Color(0xFF004D40)),
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

              final result = await context.read<ForumViewModel>().editReply(threadId, replyId, newText);
              if (result.isBlocked) {
                if (!context.mounted) return;
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
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result.isAutoFlagged
                      ? '⚠️ Answer updated and flagged for moderator review (${result.flagReason}).'
                      : '✏️ Answer updated successfully.'),
                  backgroundColor: result.isAutoFlagged ? const Color(0xFFD97706) : const Color(0xFF004D40),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF004D40)),
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text('SAVE CHANGES'),
          ),
        ],
      ),
    );
  }

  void _showEditThreadDialog(Map<String, dynamic> thread) {
    final threadId = thread['id'].toString();
    final editTitleController = TextEditingController(text: thread['title'].toString());

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
                style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: const Color(0xFF004D40)),
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

              final result = await context.read<ForumViewModel>().editThread(threadId, newTitle);
              if (result.isBlocked) {
                if (!context.mounted) return;
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
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result.isAutoFlagged
                      ? '⚠️ Title updated and flagged for moderator review (${result.flagReason}).'
                      : '✏️ Post title updated.'),
                  backgroundColor: result.isAutoFlagged ? const Color(0xFFD97706) : const Color(0xFF004D40),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF004D40)),
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
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
                            style: GoogleFonts.dmSerifDisplay(fontSize: 22, color: const Color(0xFF004D40)),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(modalContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Text('Select Community Hub:', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedCommunity,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                      ),
                      items: _communities.where((c) => c != 'All').map((c) {
                        return DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedCommunity = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    Text('Question / Title:', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: 'e.g. How to care for handwoven Songket silk?',
                        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey[400]),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text('Details / Context:', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: bodyController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Provide details or background for master artisans...',
                        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[400]),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
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
                          final bool isUserArtisan = user?.isArtisan == true || user?.role == 'Artisan';
                          final String effectiveAuthor = (user?.effectiveUsername != null && user!.effectiveUsername.isNotEmpty)
                              ? user.effectiveUsername
                              : ((user?.displayName != null && user!.displayName!.isNotEmpty)
                                  ? user.displayName!
                                  : (user?.email.isNotEmpty == true ? user!.email.split('@').first : 'Community Member'));

                          final result = await context.read<ForumViewModel>().createThread(
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
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                title: Row(
                                  children: [
                                    const Icon(Icons.block_rounded, color: Color(0xFFEF4444)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Post Blocked',
                                        softWrap: true,
                                        style: GoogleFonts.dmSerifDisplay(color: const Color(0xFF991B1B)),
                                      ),
                                    ),
                                  ],
                                ),
                                content: Text(
                                  result.blockReason ?? 'Your question contains prohibited or offensive keywords.',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.5),
                                ),
                                actions: [
                                  FilledButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF004D40)),
                                    child: const Text('UNDERSTOOD'),
                                  ),
                                ],
                              ),
                            );
                            return;
                          }

                          if (!modalContext.mounted) return;
                          Navigator.of(modalContext).pop();

                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result.isAutoFlagged
                                  ? '⏳ Post held in moderation queue for admin review (${result.flagReason}). It will appear publicly once approved.'
                                  : '🎉 Post published to community hub!'),
                              backgroundColor: result.isAutoFlagged ? const Color(0xFFD97706) : const Color(0xFF004D40),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF004D40),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: Text(
                          'Post Question to Community',
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold),
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

    final List<Map<String, dynamic>> threadsMap = forumVM.threads.map((t) {
      final map = t.toMap();
      final bool isMyThread = currentUser != null &&
          ((currentUser.id.isNotEmpty && t.userId != null && t.userId!.isNotEmpty && t.userId == currentUser.id) ||
           (currentUser.email.isNotEmpty && t.authorEmail.isNotEmpty && t.authorEmail.toLowerCase() == currentUser.email.toLowerCase()));
      
      map['isMe'] = isMyThread;
      if (isMyThread) {
        map['displayName'] = '${t.authorName} (You)';
      } else {
        map['displayName'] = t.authorName;
      }

      final List<Map<String, dynamic>> msgMaps = t.replies.map((r) {
        final rMap = r.toMap();
        final bool isMyMsg = currentUser != null &&
            (currentUser.email.isNotEmpty && r.authorEmail.isNotEmpty && r.authorEmail.toLowerCase() == currentUser.email.toLowerCase());
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
      final updated = threadsMap.firstWhere((t) => t['id'] == _activeThread!['id'], orElse: () => _activeThread!);
      _activeThread = updated;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.forum_rounded, color: Color(0xFF004D40), size: 22),
              const SizedBox(width: 8),
              Text(
                _activeThread == null ? 'Warisan Community Hub' : 'Question & Answers',
                style: GoogleFonts.dmSerifDisplay(color: const Color(0xFF004D40), fontSize: 20),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: _activeThread != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF004D40)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add_comment_rounded, size: 16, color: Color(0xFFFFD54F)),
                label: Text(
                  'Ask Question',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          if (_activeThread != null)
            IconButton(
              icon: const Icon(Icons.flag_outlined, color: Color(0xFFEF4444)),
              tooltip: 'Report / Flag Post',
              onPressed: () => _showFlagReportModal(context, _activeThread!['id'].toString(), _activeThread!['title'].toString()),
            ),
        ],
      ),
      body: _activeThread == null
          ? _buildRedditQuoraFeed(langVM, threadsMap)
          : _buildQuoraThreadDetailView(langVM),
      floatingActionButton: _activeThread == null
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateThreadModal(langVM),
              backgroundColor: const Color(0xFF004D40),
              icon: const Icon(Icons.edit_note_rounded, color: Color(0xFFFFD54F), size: 26),
              label: Text(
                'Ask / Post',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            )
          : null,
    );
  }

  // REDDIT & QUORA HYBRID HOME FEED
  Widget _buildRedditQuoraFeed(LanguageViewModel langVM, List<Map<String, dynamic>> threads) {
    // Only show approved, non-flagged threads in the public community feed
    List<Map<String, dynamic>> filteredThreads = threads.where((t) => t['isReported'] != true).toList();

    // Check if the current user has any post quarantined in moderation review
    final pendingMyPosts = threads.where((t) => t['isReported'] == true && t['isMe'] == true).toList();

    if (_selectedCommunity != 'All') {
      filteredThreads = filteredThreads.where((t) => t['community'] == _selectedCommunity).toList();
    }

    if (_selectedSort == 'New') {
      filteredThreads = filteredThreads.reversed.toList();
    } else if (_selectedSort == 'Top') {
      filteredThreads = List.from(filteredThreads)..sort((a, b) => ((b['upvotes'] as int?) ?? 0).compareTo((a['upvotes'] as int?) ?? 0));
    } else if (_selectedSort == 'Verified Q&A') {
      filteredThreads = filteredThreads.where((t) => t['isSolved'] == true).toList();
    }

    return Column(
      children: [
        if (pendingMyPosts.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(14, 10, 14, 2),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.pending_actions_rounded, color: Color(0xFFB45309), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'You have ${pendingMyPosts.length} question(s) currently held in moderation review.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF78350F),
                    ),
                  ),
                ),
              ],
            ),
          ),
        // Subreddit / Community Filter Chips Header
        Container(
          color: Colors.white,
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
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? Colors.white : const Color(0xFF334155),
                        ),
                        selectedColor: const Color(0xFF004D40),
                        backgroundColor: const Color(0xFFF1F5F9),
                        checkmarkColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                    Text('Sort by:', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                    const SizedBox(width: 8),
                    ..._sortOptions.map((sort) {
                      final isSelected = _selectedSort == sort;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedSort = sort),
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFFEF3C7) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            sort,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? const Color(0xFF78350F) : Colors.grey[700],
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
                                color: const Color(0xFF004D40).withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.forum_outlined, size: 40, color: Color(0xFF004D40)),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No community questions yet',
                              style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: const Color(0xFF004D40)),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Be the first to start a conversation or ask heritage craft masters!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 18),
                            FilledButton.icon(
                              onPressed: () => _showCreateThreadModal(langVM),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF004D40),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                              icon: const Icon(Icons.add_comment_rounded, size: 16, color: Color(0xFFFFD54F)),
                              label: Text(
                                'Ask a Question',
                                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold),
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
                      return _buildRedditPostCard(thread);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  // REDDIT STYLE POST CARD WITH UPVOTE SIDEBAR
  Widget _buildRedditPostCard(Map<String, dynamic> thread) {
    final bool isArtisan = (thread['isArtisan'] as bool?) ?? false;
    final int userVote = (thread['userVote'] as int?) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
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
                // Reddit-Style Upvote / Downvote Vertical Column
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_upward_rounded,
                          size: 20,
                          color: userVote == 1 ? const Color(0xFFF97316) : Colors.grey[400],
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
                              : (userVote == -1 ? const Color(0xFF6366F1) : const Color(0xFF1E293B)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      IconButton(
                        icon: Icon(
                          Icons.arrow_downward_rounded,
                          size: 20,
                          color: userVote == -1 ? const Color(0xFF6366F1) : Colors.grey[400],
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _voteThread(thread, -1),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 14),

                // Post Content Header & Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subreddit & Author Info
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF004D40).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              thread['community'].toString(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF004D40),
                              ),
                            ),
                          ),
                          Text(
                            '• Posted by ${thread['displayName'] ?? thread['authorName']}',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[600]),
                          ),
                          if (isArtisan)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
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
                                style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.grey[400]),
                              ),
                              if (thread['isEdited'] == true) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '(edited)',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 10, fontStyle: FontStyle.italic, color: const Color(0xFFD97706), fontWeight: FontWeight.bold),
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
                          color: const Color(0xFF0F172A),
                          height: 1.3,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Quora/Reddit Action Bar
                      Row(
                        children: [
                          Icon(Icons.mode_comment_outlined, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${thread['repliesCount']} Answers',
                              softWrap: true,
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                            ),
                          ),
                          if (thread['isSolved'] == true) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF166534)),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'Verified Answer',
                                      softWrap: true,
                                      style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF166534)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const Spacer(),

                          if (thread['isMe'] == true) ...[
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF004D40)),
                              tooltip: 'Edit Title',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _showEditThreadDialog(thread),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                              tooltip: 'Delete Post',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _confirmDeleteThread(thread),
                            ),
                          ] else ...[
                            IconButton(
                              icon: const Icon(Icons.flag_outlined, size: 16, color: Color(0xFFEF4444)),
                              tooltip: 'Report Content',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _showFlagReportModal(context, thread['id'].toString(), thread['title'].toString()),
                            ),
                          ],
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
  Widget _buildQuoraThreadDetailView(LanguageViewModel langVM) {
    final List<Map<String, dynamic>> messages = List<Map<String, dynamic>>.from(_activeThread!['messages'] ?? []);

    return Column(
      children: [
        // Thread Question Header Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF004D40).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _activeThread!['community'].toString(),
                        softWrap: true,
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF004D40)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Asked by ${_activeThread!['displayName'] ?? _activeThread!['authorName']}',
                      softWrap: true,
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _activeThread!['title'].toString(),
                style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: const Color(0xFF004D40), height: 1.2),
              ),
              if (_activeThread!['content'] != null &&
                  _activeThread!['content'].toString().isNotEmpty &&
                  _activeThread!['content'].toString() != _activeThread!['title'].toString()) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    _activeThread!['content'].toString(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: const Color(0xFF334155),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_upward_rounded,
                            size: 16,
                            color: ((_activeThread!['userVote'] as int?) == 1) ? const Color(0xFFF97316) : Colors.grey[600],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          constraints: const BoxConstraints(),
                          onPressed: () => _voteThread(_activeThread!, 1),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_activeThread!['upvotes']}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: ((_activeThread!['userVote'] as int?) == 1)
                                ? const Color(0xFFF97316)
                                : (((_activeThread!['userVote'] as int?) == -1) ? const Color(0xFF6366F1) : const Color(0xFF004D40)),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: Icon(
                            Icons.arrow_downward_rounded,
                            size: 16,
                            color: ((_activeThread!['userVote'] as int?) == -1) ? const Color(0xFF6366F1) : Colors.grey[600],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          constraints: const BoxConstraints(),
                          onPressed: () => _voteThread(_activeThread!, -1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${messages.length} Answers',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Discussion Header Banner
        Container(
          width: double.infinity,
          color: const Color(0xFFF8FAFC),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Color(0xFF004D40)),
              const SizedBox(width: 8),
              Text(
                'Discussion & Community Answers (${messages.length})',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF004D40),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Answers List (Quora Style)
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.mark_chat_unread_outlined, size: 40, color: Colors.grey[400]),
                        const SizedBox(height: 10),
                        Text(
                          'No answers yet',
                          style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: const Color(0xFF004D40)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Be the first to share your heritage craft experience or insights below!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return _buildQuoraAnswerCard(msg, index);
                  },
                ),
        ),

        // Answer Bottom Input Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              )
            ],
          ),
          child: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    maxLines: 4,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(context),
                    decoration: InputDecoration(
                      hintText: 'Write your answer or response...',
                      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey[400]),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Color(0xFF004D40), width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.send_rounded, size: 15, color: Color(0xFFFFD54F)),
                    label: Text(
                      'Reply',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // QUORA ANSWER CARD WITH MASTER VERIFICATION BADGE & UPVOTES
  Widget _buildQuoraAnswerCard(Map<String, dynamic> msg, int index) {
    final bool isMe = msg['isMe'] as bool? ?? false;
    final bool isArtisan = msg['isArtisan'] as bool? ?? false;
    final bool isVerifiedAnswer = msg['isVerifiedAnswer'] as bool? ?? false;
    final int userVote = (msg['userVote'] as int?) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isVerifiedAnswer ? const Color(0xFFFFFBEB) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isVerifiedAnswer
              ? const Color(0xFFFDE68A)
              : (isMe ? const Color(0xFF004D40).withOpacity(0.3) : Colors.black.withOpacity(0.05)),
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
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_rounded, size: 14, color: Color(0xFFB45309)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'VERIFIED MASTER ARTISAN ANSWER',
                      softWrap: true,
                      style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF78350F)),
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
                backgroundColor: isArtisan ? const Color(0xFFD97706) : const Color(0xFF004D40),
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
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (isArtisan) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'MASTER',
                              style: GoogleFonts.plusJakartaSans(fontSize: 8, fontWeight: FontWeight.bold, color: const Color(0xFF78350F)),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          msg['time'].toString(),
                          style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.grey),
                        ),
                        if (msg['isEdited'] == true || msg['time'].toString().contains('(edited)')) ...[
                          const SizedBox(width: 4),
                          Text(
                            '• (edited)',
                            style: GoogleFonts.plusJakartaSans(fontSize: 10, fontStyle: FontStyle.italic, color: const Color(0xFFD97706), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Answer Text
          Text(
            msg['text'].toString(),
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF1E293B), height: 1.5),
          ),

          const SizedBox(height: 14),

          // Quora Vote & Controls Bar
          Row(
            children: [
              // Upvote Button
              GestureDetector(
                onTap: () => _voteMessage(msg, 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: userVote == 1 ? const Color(0xFFFFEDD5) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_upward_rounded,
                        size: 14,
                        color: userVote == 1 ? const Color(0xFFF97316) : Colors.grey[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${msg['upvotes']}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: userVote == 1 ? const Color(0xFFC2410C) : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Downvote Button
              GestureDetector(
                onTap: () => _voteMessage(msg, -1),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: userVote == -1 ? const Color(0xFFE0E7FF) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_downward_rounded,
                    size: 14,
                    color: userVote == -1 ? const Color(0xFF4338CA) : Colors.grey[700],
                  ),
                ),
              ),

              const Spacer(),

              if (isMe) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF004D40)),
                  tooltip: 'Edit Answer',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showEditMessageDialog(msg['id'].toString(), msg['text'].toString()),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                  tooltip: 'Delete Answer',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _confirmDeleteMessage(msg['id'].toString()),
                ),
              ] else ...[
                IconButton(
                  icon: const Icon(Icons.flag_outlined, size: 16, color: Color(0xFFEF4444)),
                  tooltip: 'Report Content',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showFlagReportModal(context, _activeThread!['id'].toString(), msg['text'].toString()),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}