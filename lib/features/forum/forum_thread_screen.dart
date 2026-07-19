import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/models/forum_models.dart';
import 'package:warisan_kita/state/forum_state.dart';

class ForumThreadScreen extends StatefulWidget {
  final ForumThread thread;
  const ForumThreadScreen({super.key, required this.thread});

  @override
  State<ForumThreadScreen> createState() => _ForumThreadScreenState();
}

class _ForumThreadScreenState extends State<ForumThreadScreen> {
  final TextEditingController _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('Cultural Exchange', style: GoogleFonts.dmSerifDisplay()),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF004D40),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              children: [
                _buildOriginalPost(context),
                const SizedBox(height: 40),
                _buildResponseHeader(),
                const SizedBox(height: 20),
                ...widget.thread.replies.map((reply) => _buildReplyCard(reply)),
              ],
            ),
          ),
          _buildPremiumInput(context),
        ],
      ),
    );
  }

  Widget _buildOriginalPost(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 30,
            offset: const Offset(0, 15),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: NetworkImage(widget.thread.authorAvatar),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.thread.authorName, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14)),
                  const Text('Heritage Member', style: TextStyle(color: Colors.black26, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            widget.thread.title,
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 22,
              color: const Color(0xFF004D40),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: widget.thread.tags.map((t) => _buildTag(t.toUpperCase())).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF004D40).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF004D40), letterSpacing: 1)),
    );
  }

  Widget _buildResponseHeader() {
    return Row(
      children: [
        Text('Discussion', style: GoogleFonts.dmSerifDisplay(fontSize: 18)),
        const SizedBox(width: 8),
        Text('${widget.thread.replies.length} Responses', style: TextStyle(color: Colors.grey.shade400, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildReplyCard(ThreadReply reply) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: reply.isVerifiedArtisan ? const Color(0xFFE0F2F1).withOpacity(0.5) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: reply.isVerifiedArtisan ? Border.all(color: const Color(0xFF004D40).withOpacity(0.1)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(reply.authorName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
              if (reply.isVerifiedArtisan) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified_rounded, color: Color(0xFF004D40), size: 14),
              ],
              const Spacer(),
              Text(reply.timestamp, style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            reply.content,
            style: GoogleFonts.plusJakartaSans(color: Colors.black87, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumInput(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _replyController,
                decoration: InputDecoration(
                  hintText: 'Join the conversation...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              if (_replyController.text.isNotEmpty) {
                context.read<ForumState>().postReply(widget.thread.id, _replyController.text);
                _replyController.clear();
                FocusScope.of(context).unfocus();
              }
            },
            child: Container(
              height: 50,
              width: 50,
              decoration: const BoxDecoration(
                color: Color(0xFF004D40),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
