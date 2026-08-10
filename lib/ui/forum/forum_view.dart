import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/ui/forum/forum_thread_view.dart';
import 'package:warisan_kita/domain/models/forum_post.dart';
import 'package:warisan_kita/viewmodels/forum_viewmodel.dart';

class ForumIndexScreen extends StatelessWidget {
  const ForumIndexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final forumState = context.watch<ForumViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(child: _buildArtisanSpotlight()),
          SliverToBoxAdapter(child: _buildTrendingHeader()),
          if (forumState.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: Color(0xFF004D40))),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final thread = forumState.threads[index];
                    return _buildThreadCard(context, thread);
                  },
                  childCount: forumState.threads.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 100,
      floating: true,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        title: Text(
          'Cultural Forum',
          style: GoogleFonts.dmSerifDisplay(
            color: const Color(0xFF004D40),
            fontSize: 26,
          ),
        ),
      ),
    );
  }

  Widget _buildArtisanSpotlight() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF004D40), Color(0xFF00796B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF004D40).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundImage: NetworkImage('https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200'),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MASTER OF THE WEEK',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFFFD54F),
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  'Ahmad Fauzi is answering questions about Batik dyes!',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.white54),
        ],
      ),
    );
  }

  Widget _buildTrendingHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Row(
        children: [
          const Icon(Icons.whatshot_rounded, color: Color(0xFFFF7043), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'TRENDING DISCUSSIONS',
              softWrap: true,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.black26,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFlagPostDialog(BuildContext context, ForumThread thread) {
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
              Text('Report / Flag Post', style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: const Color(0xFF004D40))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Report thread: "${thread.title}"',
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
                    content: Text('🚩 Post reported to Admin Moderation Officers ($selectedReason)'),
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

  Widget _buildThreadCard(BuildContext context, ForumThread thread) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 25,
            offset: const Offset(0, 12),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ForumThreadScreen(thread: thread)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundImage: NetworkImage(thread.authorAvatar),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${thread.authorName} • ${_formatTime(thread.createdAt)}',
                              softWrap: true,
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.flag_outlined, size: 18, color: Colors.black38),
                      tooltip: 'Report / Flag Post',
                      onPressed: () => _showFlagPostDialog(context, thread),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  thread.title,
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 18,
                    color: const Color(0xFF004D40),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _buildStat(Icons.mode_comment_outlined, '${thread.replyCount} responses'),
                    _buildStat(Icons.favorite_outline_rounded, '45'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _buildStat(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.black26),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            softWrap: true,
            style: const TextStyle(color: Colors.black45, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildFab() {
    return Container(
      height: 64,
      width: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFFF7043), Color(0xFFF4511E)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF7043).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add_comment_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}