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
          Text(
            'TRENDING DISCUSSIONS',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.black26,
              letterSpacing: 1.2,
            ),
          ),
        ],
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
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundImage: NetworkImage(thread.authorAvatar),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${thread.authorName} • ${_formatTime(thread.createdAt)}',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  thread.title,
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 18,
                    color: const Color(0xFF004D40),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStat(Icons.mode_comment_outlined, '${thread.replyCount} responses'),
                    const SizedBox(width: 16),
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
      children: [
        Icon(icon, size: 16, color: Colors.black26),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.black45, fontSize: 12, fontWeight: FontWeight.w600)),
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
