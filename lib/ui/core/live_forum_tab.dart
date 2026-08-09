import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/viewmodels/language_viewmodel.dart';

class LiveForumTab extends StatefulWidget {
  const LiveForumTab({super.key});

  @override
  State<LiveForumTab> createState() => _LiveForumTabState();
}

class _LiveForumTabState extends State<LiveForumTab> {
  Map<String, dynamic>? _activeThread;

  final List<Map<String, dynamic>> _threads = [
    {
      'id': 't1',
      'title': '🌿 Natural Indigo Batik Dyeing Techniques in Terengganu',
      'authorName': 'Kak Lina',
      'isArtisan': true,
      'repliesCount': 18,
      'timestamp': '10m ago',
      'messages': [
        {
          'sender': 'Kak Lina (Master Artisan)',
          'isMe': false,
          'isArtisan': true,
          'time': '10:14 AM',
          'text': 'Selamat pagi everyone! Our natural indigo batik dyeing workshop in Kuala Terengganu has 3 open slots for this weekend.',
        },
        {
          'sender': 'Aiman Haziq (Tourist)',
          'isMe': false,
          'isArtisan': false,
          'time': '10:18 AM',
          'text': 'Hi Kak Lina! Can beginners with zero batik experience join?',
        },
        {
          'sender': 'Kak Lina (Master Artisan)',
          'isMe': false,
          'isArtisan': true,
          'time': '10:20 AM',
          'text': 'Yes absolutely! We provide canting tools, natural indigo dyes, and silk fabric.',
        },
        {
          'sender': 'You',
          'isMe': true,
          'isArtisan': false,
          'time': '10:22 AM',
          'text': 'That sounds amazing! Are children allowed in the pottery & batik sessions?',
        },
      ],
    },
    {
      'id': 't2',
      'title': '🏺 Kilning Clay Labu Sayong: Tips for Beginners',
      'authorName': 'Pak Mat',
      'isArtisan': true,
      'repliesCount': 24,
      'timestamp': '1h ago',
      'messages': [
        {
          'sender': 'Pak Mat (Master Artisan)',
          'isMe': false,
          'isArtisan': true,
          'time': '09:00 AM',
          'text': 'Welcome to the pottery thread! Clay kilning requires careful temperature control at 900°C.',
        },
      ],
    },
    {
      'id': 't3',
      'title': '📌 Recommended Heritage Craft Spots in Melaka & Kelantan',
      'authorName': 'Mei Ling',
      'isArtisan': false,
      'repliesCount': 12,
      'timestamp': '3h ago',
      'messages': [
        {
          'sender': 'Mei Ling (Tourist)',
          'isMe': false,
          'isArtisan': false,
          'time': '07:30 AM',
          'text': 'Hey community! What are the best traditional wood carving workshops in Perak?',
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

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty || _activeThread == null) return;

    setState(() {
      final List<Map<String, dynamic>> msgs = List.from(_activeThread!['messages']);
      msgs.add({
        'sender': 'You',
        'isMe': true,
        'isArtisan': false,
        'time': 'Just now',
        'text': text,
      });
      _activeThread!['messages'] = msgs;
      _activeThread!['repliesCount'] = msgs.length;
      _messageController.clear();
    });
  }

  void _showCreateThreadModal(LanguageViewModel langVM) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    String selectedCategory = 'General Discussion';

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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        langVM.translate('Create New Discussion Thread'),
                        style: GoogleFonts.dmSerifDisplay(fontSize: 22, color: const Color(0xFF004D40)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Category Selector Dropdown
                  Text(
                    langVM.translate('Topic Category'),
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: [
                      'General Discussion',
                      'Pottery & Ceramics',
                      'Batik Canting',
                      'Songket & Weaving',
                      'Woodcarving',
                      'Events & Workshops',
                    ].map((cat) => DropdownMenuItem(value: cat, child: Text(langVM.translate(cat)))).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedCategory = val);
                    },
                  ),

                  const SizedBox(height: 16),

                  // Thread Title Input
                  Text(
                    langVM.translate('Thread Title'),
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: langVM.translate('e.g., Tips for learning canting batik at home...'),
                      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[400]),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Thread Body Input
                  Text(
                    langVM.translate('Initial Message'),
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: bodyController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: langVM.translate('Share your questions or story with the heritage community...'),
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

                        if (title.isEmpty || body.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(langVM.translate('Please fill in both thread title and message.')),
                              backgroundColor: const Color(0xFFEF4444),
                            ),
                          );
                          return;
                        }

                        final newThread = {
                          'id': 't_${DateTime.now().millisecondsSinceEpoch}',
                          'title': '💬 $title',
                          'authorName': 'You',
                          'isArtisan': false,
                          'repliesCount': 1,
                          'timestamp': 'Just now',
                          'messages': [
                            {
                              'sender': 'You',
                              'isMe': true,
                              'isArtisan': false,
                              'time': 'Just now',
                              'text': body,
                            },
                          ],
                        };

                        setState(() {
                          _threads.insert(0, newThread);
                          _activeThread = newThread;
                        });

                        Navigator.of(context).pop();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                const SizedBox(width: 10),
                                Text(langVM.translate('🎉 Thread created successfully!')),
                              ],
                            ),
                            backgroundColor: const Color(0xFF004D40),
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
                        langVM.translate('Publish Discussion Thread'),
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          _activeThread == null ? langVM.translate('Live Community Forum') : langVM.translate('Discussion Thread'),
          style: GoogleFonts.dmSerifDisplay(color: const Color(0xFF004D40), fontSize: 22),
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
      ),
      body: _activeThread == null ? _buildForumThreadList(langVM) : _buildThreadChatUI(langVM),
      floatingActionButton: _activeThread == null
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateThreadModal(langVM),
              backgroundColor: const Color(0xFF004D40),
              icon: const Icon(Icons.add_comment_rounded, color: Color(0xFFFFD54F)),
              label: Text(
                langVM.translate('New Thread'),
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            )
          : null,
    );
  }

  // Forum Home: List View of Active Discussion Threads
  Widget _buildForumThreadList(LanguageViewModel langVM) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _threads.length,
      itemBuilder: (context, index) {
        final thread = _threads[index];
        final bool isArtisan = thread['isArtisan'] as bool;

        return GestureDetector(
          onTap: () => setState(() => _activeThread = thread),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black.withOpacity(0.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: isArtisan ? const Color(0xFFD97706) : const Color(0xFF004D40),
                          child: Icon(
                            isArtisan ? Icons.palette_rounded : Icons.person_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                        if (isArtisan)
                          const Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 6,
                              backgroundColor: Color(0xFFFFD54F),
                              child: Icon(Icons.star, size: 8, color: Color(0xFF004D40)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              thread['authorName'],
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            if (isArtisan) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  langVM.translate('MASTER ARTISAN'),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF78350F),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          thread['timestamp'],
                          style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.chat_bubble_outline_rounded, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            thread['repliesCount'].toString(),
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  langVM.translate(thread['title']),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Inside a Thread: Real-time Chat UI Interface
  Widget _buildThreadChatUI(LanguageViewModel langVM) {
    final List<Map<String, dynamic>> messages = _activeThread!['messages'];

    return Column(
      children: [
        // Thread Title Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: Colors.white,
          child: Text(
            langVM.translate(_activeThread!['title']),
            style: GoogleFonts.dmSerifDisplay(fontSize: 16, color: const Color(0xFF004D40)),
          ),
        ),
        const Divider(height: 1),

        // Chat Message Bubbles List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final msg = messages[index];
              final bool isMe = msg['isMe'] as bool;
              final bool isArtisan = msg['isArtisan'] as bool;

              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isMe
                        ? const Color(0xFF004D40)
                        : (isArtisan ? const Color(0xFFFFFBEB) : Colors.white),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                      bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                    ),
                    border: Border.all(
                      color: isMe
                          ? const Color(0xFF004D40)
                          : (isArtisan ? const Color(0xFFFDE68A) : Colors.black.withOpacity(0.06)),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            msg['sender'],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isMe
                                  ? const Color(0xFFFFD54F)
                                  : (isArtisan ? const Color(0xFF92400E) : const Color(0xFF0F172A)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            msg['time'],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              color: isMe ? Colors.white70 : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        langVM.translate(msg['text']),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: isMe ? Colors.white : const Color(0xFF1E293B),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Message Input Bottom Bar
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
                    hintText: langVM.translate('Type your message or response...'),
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
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
