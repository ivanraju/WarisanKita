import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          _activeThread == null ? 'Live Community Forum' : 'Discussion Thread',
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
      body: _activeThread == null ? _buildForumThreadList() : _buildThreadChatUI(),
    );
  }

  // Forum Home: List View of Active Discussion Threads
  Widget _buildForumThreadList() {
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
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: Icon(
                              isArtisan ? Icons.verified_rounded : Icons.explore_rounded,
                              size: 12,
                              color: isArtisan ? const Color(0xFFD97706) : const Color(0xFF004D40),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
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
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isArtisan ? const Color(0xFFFEF3C7) : const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isArtisan ? 'Artisan Master' : 'Tourist',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isArtisan ? const Color(0xFFB45309) : const Color(0xFF0369A1),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          thread['timestamp'],
                          style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Text(
                  thread['title'],
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 18,
                    color: const Color(0xFF0F172A),
                  ),
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text(
                      '${thread['repliesCount']} replies',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B)),
                    ),
                    const Spacer(),
                    Text(
                      'Tap to open thread →',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF004D40),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Inside a Thread: Real-time Chat UI Interface
  Widget _buildThreadChatUI() {
    final List<Map<String, dynamic>> messages = _activeThread!['messages'];

    return Column(
      children: [
        // Thread Title Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: Colors.white,
          child: Text(
            _activeThread!['title'],
            style: GoogleFonts.dmSerifDisplay(fontSize: 16, color: const Color(0xFF004D40)),
          ),
        ),
        const Divider(height: 1),

        // Chat Message Bubbles List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final msg = messages[index];
              final bool isMe = msg['isMe'] as bool;
              final bool isArtisan = msg['isArtisan'] as bool;

              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  child: Column(
                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      if (!isMe) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              msg['sender'],
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isArtisan ? const Color(0xFFD97706) : const Color(0xFF004D40),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              msg['time'],
                              style: GoogleFonts.plusJakartaSans(fontSize: 9, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],

                      // Bubble Container
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFF004D40) : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: Text(
                          msg['text'],
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: isMe ? Colors.white : const Color(0xFF1E293B),
                            height: 1.4,
                          ),
                        ),
                      ),

                      if (isMe) ...[
                        const SizedBox(height: 2),
                        Text(
                          msg['time'],
                          style: GoogleFonts.plusJakartaSans(fontSize: 9, color: Colors.grey[500]),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Persistent Bottom Input Field (Handling Keyboard Spacing safely via SafeArea)
        SafeArea(
          child: Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey[400]),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF004D40),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
