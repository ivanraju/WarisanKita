import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/viewmodels/language_viewmodel.dart';

class ArtisanDirectChatScreen extends StatefulWidget {
  final String artisanName;
  final String craftCategory;
  final String imageUrl;

  const ArtisanDirectChatScreen({
    super.key,
    required this.artisanName,
    required this.craftCategory,
    required this.imageUrl,
  });

  @override
  State<ArtisanDirectChatScreen> createState() => _ArtisanDirectChatScreenState();
}

class _ArtisanDirectChatScreenState extends State<ArtisanDirectChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _messages.add({
      'sender': widget.artisanName,
      'isMe': false,
      'time': 'Just now',
      'text': 'Selamat datang! Welcome to ${widget.artisanName}! How can I assist you with our traditional ${widget.craftCategory} craft today?',
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage([String? presetText]) {
    final text = presetText ?? _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'sender': 'You',
        'isMe': true,
        'time': 'Just now',
        'text': text,
      });
      if (presetText == null) _messageController.clear();
    });

    // Simulate realistic Master Artisan reply after 1 second
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'sender': widget.artisanName,
          'isMe': false,
          'time': 'Just now',
          'text': 'Terima kasih for your message! Our workshop is open today. Feel free to drop by to observe live crafting or ask any questions!',
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final langVM = context.watch<LanguageViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF004D40)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(widget.imageUrl),
                ),
                const Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 5,
                    backgroundColor: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.artisanName,
                    style: GoogleFonts.dmSerifDisplay(fontSize: 16, color: const Color(0xFF004D40)),
                  ),
                  Text(
                    '🟢 Online • ${widget.craftCategory}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFF10B981), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Quick Preset Questions Chips Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickChip(langVM.translate('🏺 What hours is your studio open?'), langVM),
                  const SizedBox(width: 8),
                  _buildQuickChip(langVM.translate('🌿 Can I observe live demonstrations?'), langVM),
                  const SizedBox(width: 8),
                  _buildQuickChip(langVM.translate('📜 How long does labu sayong kilning take?'), langVM),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Messages List Feed
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final bool isMe = msg['isMe'] as bool;

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    padding: const EdgeInsets.all(16),
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
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        )
                      ],
                      border: Border.all(
                        color: isMe ? const Color(0xFF004D40) : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                msg['sender'],
                                softWrap: true,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isMe ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                                ),
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

          // Message Text Input Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
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
                      hintText: langVM.translate('Type message to Master Artisan...'),
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
                    onPressed: () => _sendMessage(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label, LanguageViewModel langVM) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ActionChip(
      onPressed: () => _sendMessage(label),
      backgroundColor: isDark ? const Color(0xFF1E3A34) : const Color(0xFFF1F5F9),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      label: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF0F172A),
        ),
      ),
    );
  }
}