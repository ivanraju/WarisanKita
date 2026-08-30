import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:warisan_kita/ui/tourist/artisan_direct_chat_screen.dart';
import 'package:warisan_kita/ui/tourist/quest_completion_screen.dart';

class ArtisanDetailScreen extends StatefulWidget {
  final String artisanName;
  final String craftCategory;
  final String state;
  final String imageUrl;
  final List<String>? imageUrls;
  final String bio;
  final double rating;
  final String experience;
  final List<String> tags;

  const ArtisanDetailScreen({
    super.key,
    this.artisanName = 'Pak Mat Pottery Studio',
    this.craftCategory = 'Pottery & Ceramics',
    this.state = 'Melaka',
    this.imageUrl = 'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=600&auto=format&fit=crop&q=80',
    this.imageUrls,
    this.bio = 'Master Pak Mat has been hand-crafting traditional clay labu sayong and ceramic vessels for over 25 years in Kampung Morten. Each piece is hand-spun and natural clay kilned.',
    this.rating = 4.9,
    this.experience = '25+ Years Experience',
    this.tags = const [],
  });

  @override
  State<ArtisanDetailScreen> createState() => _ArtisanDetailScreenState();
}

class _ArtisanDetailScreenState extends State<ArtisanDetailScreen> {
  final PageController _pageController = PageController();
  int _currentCarouselIndex = 0;
  bool _isPlayingAudioLore = false;

  late final List<String> _carouselImages = widget.imageUrls != null && widget.imageUrls!.isNotEmpty
      ? widget.imageUrls!
      : [
          widget.imageUrl,
          'https://images.unsplash.com/photo-1617038220319-276d3cfab638?w=600&auto=format&fit=crop&q=80',
          'https://images.unsplash.com/photo-1544717305-2782549b5136?w=600&auto=format&fit=crop&q=80',
        ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleAudioLore() {
    setState(() => _isPlayingAudioLore = !_isPlayingAudioLore);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isPlayingAudioLore
            ? '🎧 Playing Audio Story Lore: "${widget.artisanName} Craft History"'
            : '⏸ Audio Story Lore Paused'),
        backgroundColor: const Color(0xFF004D40),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Top Image Carousel Sliver AppBar
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: const Color(0xFF004D40),
            leading: CircleAvatar(
              backgroundColor: Colors.black.withValues(alpha: 0.4),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            actions: [
              CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.4),
                child: IconButton(
                  icon: const Icon(Icons.share_rounded, color: Colors.white),
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 12),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: (idx) => setState(() => _currentCarouselIndex = idx),
                    itemCount: _carouselImages.length,
                    itemBuilder: (context, index) {
                      return Image.network(
                        _carouselImages[index],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: const Color(0xFF004D40)),
                      );
                    },
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 50,
                    right: 20,
                    child: Row(
                      children: List.generate(
                        _carouselImages.length,
                        (index) => Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentCarouselIndex == index
                                ? const Color(0xFFFFD54F)
                                : Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 24,
                    right: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD54F),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            widget.craftCategory,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: const Color(0xFF004D40),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.artisanName,
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 28,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Screen Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location & Experience Row
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: Color(0xFF004D40), size: 18),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${widget.state}, Malaysia',
                          softWrap: true,
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF004D40)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          widget.experience,
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 11, color: const Color(0xFFB45309)),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Rating & Live Status Bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.verified_rounded, color: Color(0xFF004D40), size: 22),
                            const SizedBox(width: 6),
                            Text(
                              'Verified Artisan Studio',
                              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF004D40)),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                              Text('OPEN DEMOS', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF15803D))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Audio Lore Story Banner
                  GestureDetector(
                    onTap: _toggleAudioLore,
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF004D40), Color(0xFF00251A)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF004D40).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isPlayingAudioLore ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                            color: const Color(0xFFFFD54F),
                            size: 38,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isPlayingAudioLore ? 'NOW PLAYING AUDIO LORE' : 'LISTEN TO CULTURAL AUDIO STORY',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFFFFD54F), letterSpacing: 1),
                                ),
                                Text(
                                  'Master Pak Mat: 4th Gen Labu Sayong Heritage Story',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Master Bio Card
                  Text('Artisan Biography', style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: const Color(0xFF004D40))),
                  const SizedBox(height: 8),
                  Text(
                    widget.bio,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF475569), height: 1.6),
                  ),

                  const SizedBox(height: 24),

                  // Historical Lore Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFF59E0B)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.history_edu_rounded, color: Color(0xFFD97706), size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Historical Origin & Cultural Lore',
                                softWrap: true,
                                style: GoogleFonts.dmSerifDisplay(fontSize: 16, color: const Color(0xFF78350F)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Labu Sayong origin dates back to 19th Century Sayong, Kuala Kangsar, Perak. Hand-shaped using iron-rich riverbank clay and kilned under paddy husk ash to achieve its iconic matte black porous finish for natural water cooling thermal insulation.',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFFB45309), height: 1.5),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 🏆 AUTHENTICITY & CERTIFICATION CREDENTIALS
                  Text(
                    'Master Authenticity & Credentials',
                    style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: const Color(0xFF004D40)),
                  ),
                  const SizedBox(height: 12),

                  _buildCredentialTile(
                    icon: Icons.verified_rounded,
                    title: 'Kraftangan Malaysia Certified Master',
                    subtitle: 'License #KFG-2024-889 • Verified Authentic Master Craftsman',
                  ),
                  _buildCredentialTile(
                    icon: Icons.business_rounded,
                    title: 'SSM Business Registration',
                    subtitle: 'Registration #002941-X • Official Registered Heritage Studio',
                  ),
                  _buildCredentialTile(
                    icon: Icons.military_tech_rounded,
                    title: 'UNESCO Living Heritage Nominee',
                    subtitle: 'Recognized for 25+ years preserving Malaccan clay pottery',
                  ),

                  const SizedBox(height: 24),

                  // 🛠️ TRADITIONAL MATERIALS & TOOLS USED
                  Text(
                    'Materials & Traditional Tools Used',
                    style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: const Color(0xFF004D40)),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.tags.isNotEmpty 
                      ? widget.tags.map((tag) => Chip(
                          label: Text(tag, style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                        )).toList()
                      : const [
                          Chip(avatar: Icon(Icons.landscape_rounded, size: 16), label: Text('Kampung Morten River Clay')),
                          Chip(avatar: Icon(Icons.local_fire_department_rounded, size: 16), label: Text('Paddy Husk Kiln Ash')),
                          Chip(avatar: Icon(Icons.palette_rounded, size: 16), label: Text('Organic Indigo Dyes')),
                          Chip(avatar: Icon(Icons.handyman_rounded, size: 16), label: Text('Hand-spun Wooden Wheel')),
                        ],
                  ),

                  const SizedBox(height: 28),

                  // Experience & Studio Highlights Chips
                  Row(
                    children: [
                      Expanded(
                        child: _buildHighlightChip(
                          icon: Icons.workspace_premium_rounded,
                          title: 'Craft Experience',
                          value: widget.experience,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildHighlightChip(
                          icon: Icons.storefront_rounded,
                          title: 'Workshops Hosted',
                          value: '14 Completed',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Studio Location Map Card
                  Text(
                    'Studio Location & Workshop Map',
                    style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: const Color(0xFF004D40)),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            color: const Color(0xFFE0E7FF),
                            child: Center(
                              child: Icon(
                                Icons.map_outlined,
                                size: 80,
                                color: Colors.indigo.withValues(alpha: 0.2),
                              ),
                            ),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))
                                ],
                              ),
                              child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 24),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                              ),
                              child: Text(
                                'Kampung Morten, ${widget.state} (12 mins away)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, -6),
              )
            ],
            border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ArtisanDirectChatScreen(
                          artisanName: widget.artisanName,
                          craftCategory: widget.craftCategory,
                          imageUrl: widget.imageUrl,
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF004D40), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF004D40), size: 18),
                  label: Text(
                    'Chat Master',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: const Color(0xFF004D40)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => QuestCompletionScreen(
                          workshopName: widget.artisanName,
                          craftCategory: widget.craftCategory,
                        ),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF004D40),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.stars_rounded, color: Color(0xFFFFD54F), size: 18),
                  label: Text(
                    'START QUEST',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCredentialTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF004D40), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightChip({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF004D40), size: 22),
          const SizedBox(height: 8),
          Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[600])),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}