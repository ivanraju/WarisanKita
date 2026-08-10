import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';
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

  final List<Map<String, dynamic>> _threads = [
    {
      'id': 't1',
      'community': 'c/BatikCraft',
      'title': '🌿 How do master artisans achieve deep indigo shades in traditional Batik dye?',
      'authorName': 'Kak Lina',
      'isArtisan': true,
      'upvotes': 142,
      'userVote': 0, // -1, 0, 1
      'repliesCount': 18,
      'timestamp': '2h ago',
      'isSolved': true,
      'messages': [
        {
          'id': 'm1',
          'sender': 'Kak Lina (Master Artisan)',
          'isMe': false,
          'isArtisan': true,
          'upvotes': 89,
          'userVote': 1,
          'isVerifiedAnswer': true,
          'time': '2h ago',
          'text': 'Selamat pagi! Natural indigo dyeing requires fermenting Indigofera tinctoria leaves with lime and gula melaka for 48 hours to ferment the natural blue pigment. We invite everyone to see it live at our studio in Terengganu!',
        },
        {
          'id': 'm2',
          'sender': 'Aiman Haziq (Tourist)',
          'isMe': false,
          'isArtisan': false,
          'upvotes': 24,
          'userVote': 0,
          'isVerifiedAnswer': false,
          'time': '1h ago',
          'text': 'Hi Kak Lina! Can beginners with zero batik experience join the natural dyeing workshop this weekend?',
        },
        {
          'id': 'm3',
          'sender': 'Kak Lina (Master Artisan)',
          'isMe': false,
          'isArtisan': true,
          'upvotes': 31,
          'userVote': 0,
          'isVerifiedAnswer': false,
          'time': '45m ago',
          'text': 'Yes absolutely! We provide canting tools, natural indigo dyes, and silk fabric for all beginner participants.',
        },
        {
          'id': 'm4',
          'sender': 'You',
          'isMe': true,
          'isArtisan': false,
          'upvotes': 5,
          'userVote': 0,
          'isVerifiedAnswer': false,
          'time': '20m ago',
          'text': 'That sounds amazing! Are children allowed in the pottery & batik sessions?',
        },
      ],
    },
    {
      'id': 't2',
      'community': 'c/PotterySayong',
      'title': '🏺 Kilning Clay Labu Sayong: What temperature prevents cracking?',
      'authorName': 'Pak Mat',
      'isArtisan': true,
      'upvotes': 98,
      'userVote': 0,
      'repliesCount': 24,
      'timestamp': '5h ago',
      'isSolved': true,
      'messages': [
        {
          'id': 'm201',
          'sender': 'Pak Mat (Master Artisan)',
          'isMe': false,
          'isArtisan': true,
          'upvotes': 67,
          'userVote': 1,
          'isVerifiedAnswer': true,
          'time': '5h ago',
          'text': 'Clay kilning for Labu Sayong requires gradual heating up to 900°C over 6 hours, followed by smothering in rice husks to produce the iconic black metallic shine.',
        },
      ],
    },
    {
      'id': 't3',
      'community': 'c/TravelQnA',
      'title': '📌 What are the best traditional wood carving workshops in Perak & Melaka?',
      'authorName': 'Mei Ling',
      'isArtisan': false,
      'upvotes': 45,
      'userVote': 0,
      'repliesCount': 12,
      'timestamp': '8h ago',
      'isSolved': false,
      'messages': [
        {
          'id': 'm301',
          'sender': 'Mei Ling (Tourist)',
          'isMe': false,
          'isArtisan': false,
          'upvotes': 12,
          'userVote': 0,
          'isVerifiedAnswer': false,
          'time': '8h ago',
          'text': 'Hey community! I am planning a 3-day cultural heritage trip. Which wood carving masters offer interactive tourist demos?',
        },
      ],
    },
  ];

  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage(BuildContext context) {
    final text = _messageController.text.trim();
    if (text.isEmpty || _activeThread == null) return;

    final authVM = context.read<AuthViewModel>();
    final bool isUserArtisan = authVM.currentUser?.role == 'Artisan';

    setState(() {
      final List<Map<String, dynamic>> msgs = List.from(_activeThread!['messages']);
      msgs.add({
        'id': 'm_${DateTime.now().millisecondsSinceEpoch}',
        'sender': isUserArtisan ? 'You (Master Artisan)' : 'You',
        'isMe': true,
        'isArtisan': isUserArtisan,
        'upvotes': 1,
        'userVote': 1,
        'isVerifiedAnswer': isUserArtisan,
        'time': 'Just now',
        'text': text,
      });
      _activeThread!['messages'] = msgs;
      _activeThread!['repliesCount'] = msgs.length;
      if (isUserArtisan) {
        _activeThread!['isSolved'] = true;
      }
      _messageController.clear();
    });
  }

  void _voteThread(Map<String, dynamic> thread, int voteDirection) {
    setState(() {
      final currentVote = thread['userVote'] as int;
      if (currentVote == voteDirection) {
        // Undo vote
        thread['upvotes'] = (thread['upvotes'] as int) - voteDirection;
        thread['userVote'] = 0;
      } else {
        thread['upvotes'] = (thread['upvotes'] as int) - currentVote + voteDirection;
        thread['userVote'] = voteDirection;
      }
    });
  }

  void _voteMessage(Map<String, dynamic> msg, int voteDirection) {
    setState(() {
      final currentVote = msg['userVote'] as int;
      if (currentVote == voteDirection) {
        msg['upvotes'] = (msg['upvotes'] as int) - voteDirection;
        msg['userVote'] = 0;
      } else {
        msg['upvotes'] = (msg['upvotes'] as int) - currentVote + voteDirection;
        msg['userVote'] = voteDirection;
      }
    });
  }

  void _showFlagReportModal(BuildContext context, String title) {
    String selectedReason = 'Inappropriate Content';
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
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

  void _confirmDeleteMessage(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                final List<Map<String, dynamic>> msgs = List.from(_activeThread!['messages']);
                msgs.removeAt(index);
                _activeThread!['messages'] = msgs;
                _activeThread!['repliesCount'] = msgs.length;
              });
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _threads.removeWhere((t) => t['id'] == thread['id']);
                if (_activeThread?['id'] == thread['id']) {
                  _activeThread = null;
                }
              });
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

  void _showEditMessageDialog(int index, String currentText) {
    final editController = TextEditingController(text: currentText);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          FilledButton.icon(
            onPressed: () {
              final newText = editController.text.trim();
              if (newText.isEmpty) return;

              Navigator.pop(context);
              setState(() {
                final List<Map<String, dynamic>> msgs = List.from(_activeThread!['messages']);
                msgs[index]['text'] = newText;
                msgs[index]['isEdited'] = true;
                _activeThread!['messages'] = msgs;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✏️ Answer updated successfully.'),
                  backgroundColor: Color(0xFF004D40),
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
    final editTitleController = TextEditingController(text: thread['title'].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          FilledButton.icon(
            onPressed: () {
              final newTitle = editTitleController.text.trim();
              if (newTitle.isEmpty) return;

              Navigator.pop(context);
              setState(() {
                thread['title'] = newTitle;
                thread['isEdited'] = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✏️ Post title updated.'),
                  backgroundColor: Color(0xFF004D40),
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
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                          onPressed: () => Navigator.pop(context),
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
                      onPressed: () {
                        final title = titleController.text.trim();
                        final body = bodyController.text.trim();

                        if (title.isEmpty) return;

                        final newThread = {
                          'id': 't_${DateTime.now().millisecondsSinceEpoch}',
                          'community': selectedCommunity,
                          'title': title,
                          'authorName': 'You',
                          'isArtisan': false,
                          'upvotes': 1,
                          'userVote': 1,
                          'repliesCount': body.isNotEmpty ? 1 : 0,
                          'timestamp': 'Just now',
                          'isSolved': false,
                          'messages': body.isNotEmpty
                              ? [
                                  {
                                    'id': 'm_${DateTime.now().millisecondsSinceEpoch}',
                                    'sender': 'You',
                                    'isMe': true,
                                    'isArtisan': false,
                                    'upvotes': 1,
                                    'userVote': 1,
                                    'isVerifiedAnswer': false,
                                    'time': 'Just now',
                                    'text': body,
                                  }
                                ]
                              : [],
                        };

                        setState(() {
                          _threads.insert(0, newThread);
                          _activeThread = newThread;
                        });

                        Navigator.of(context).pop();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🎉 Post published to community hub!'),
                            backgroundColor: Color(0xFF004D40),
                            behavior: SnackBarBehavior.floating,
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
        actions: _activeThread != null
            ? [
                IconButton(
                  icon: const Icon(Icons.flag_outlined, color: Color(0xFFEF4444)),
                  tooltip: 'Report / Flag Post',
                  onPressed: () => _showFlagReportModal(context, _activeThread!['title']),
                ),
              ]
            : null,
      ),
      body: _activeThread == null ? _buildRedditQuoraFeed(langVM) : _buildQuoraThreadDetailView(langVM),
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
  Widget _buildRedditQuoraFeed(LanguageViewModel langVM) {
    List<Map<String, dynamic>> filteredThreads = _threads;

    if (_selectedCommunity != 'All') {
      filteredThreads = filteredThreads.where((t) => t['community'] == _selectedCommunity).toList();
    }

    return Column(
      children: [
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
              // Sort Options (Hot, New, Top)
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
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: filteredThreads.length,
            itemBuilder: (context, index) {
              final thread = filteredThreads[index];
              return _buildRedditPostCard(thread);
            },
          ),
        ),
      ],
    );
  }

  // REDDIT STYLE POST CARD WITH UPVOTE SIDEBAR
  Widget _buildRedditPostCard(Map<String, dynamic> thread) {
    final bool isArtisan = thread['isArtisan'] as bool;
    final int userVote = thread['userVote'] as int;

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
                              thread['community'],
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF004D40),
                              ),
                            ),
                          ),
                          Text(
                            '• Posted by ${thread['authorName']}',
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
                                thread['timestamp'],
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
                        thread['title'],
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

                          if (thread['authorName'] == 'You') ...[
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
                              onPressed: () => _showFlagReportModal(context, thread['title']),
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
    final List<Map<String, dynamic>> messages = _activeThread!['messages'];

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
                        _activeThread!['community'],
                        softWrap: true,
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF004D40)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Asked by ${_activeThread!['authorName']}',
                      softWrap: true,
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _activeThread!['title'],
                style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: const Color(0xFF004D40), height: 1.2),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.arrow_upward_rounded, size: 14, color: Color(0xFF004D40)),
                        const SizedBox(width: 4),
                        Text(
                          '${_activeThread!['upvotes']} Upvotes',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF004D40)),
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
        const Divider(height: 1),

        // Answers List (Quora Style)
        Expanded(
          child: ListView.builder(
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, -2),
              )
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Answer this question with heritage insights...',
                    hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey[400]),
                    filled: true,
                    fillColor: const Color(0xFFF8F9FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF004D40),
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, color: Color(0xFFFFD54F), size: 20),
                  onPressed: () => _sendMessage(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // QUORA ANSWER CARD WITH MASTER VERIFICATION BADGE & UPVOTES
  Widget _buildQuoraAnswerCard(Map<String, dynamic> msg, int index) {
    final bool isMe = msg['isMe'] as bool;
    final bool isArtisan = msg['isArtisan'] as bool;
    final bool isVerifiedAnswer = msg['isVerifiedAnswer'] ?? false;
    final int userVote = msg['userVote'] as int;

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
                            msg['sender'],
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
                          msg['time'],
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
            msg['text'],
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
                  onPressed: () => _showEditMessageDialog(index, msg['text']),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                  tooltip: 'Delete Answer',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _confirmDeleteMessage(index),
                ),
              ] else ...[
                IconButton(
                  icon: const Icon(Icons.flag_outlined, size: 16, color: Color(0xFFEF4444)),
                  tooltip: 'Report Content',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showFlagReportModal(context, msg['text']),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}