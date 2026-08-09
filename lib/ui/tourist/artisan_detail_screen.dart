import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/viewmodels/language_viewmodel.dart';

class ArtisanDetailScreen extends StatefulWidget {
  final String artisanName;
  final String craftCategory;
  final String state;
  final String imageUrl;
  final String bio;
  final double rating;
  final String experience;

  const ArtisanDetailScreen({
    super.key,
    this.artisanName = 'Pak Mat Pottery Studio',
    this.craftCategory = 'Pottery & Ceramics',
    this.state = 'Melaka',
    this.imageUrl = 'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=600&auto=format&fit=crop&q=80',
    this.bio = 'Master Pak Mat has been hand-crafting traditional clay labu sayong and ceramic vessels for over 25 years in Kampung Morten. Each piece is hand-spun and natural clay kilned.',
    this.rating = 4.9,
    this.experience = '25+ Years Experience',
  });

  @override
  State<ArtisanDetailScreen> createState() => _ArtisanDetailScreenState();
}

class _ArtisanDetailScreenState extends State<ArtisanDetailScreen> {
  final PageController _pageController = PageController();
  int _currentCarouselIndex = 0;
  bool _isPlayingAudioLore = false;

  late final List<String> _carouselImages = [
    widget.imageUrl,
    'https://images.unsplash.com/photo-1617038220319-276d3cfab638?w=600&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1544717305-2782549b5136?w=600&auto=format&fit=crop&q=80',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleMessageArtisan() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Chat thread opened with ${widget.artisanName}!'),
        backgroundColor: const Color(0xFF004D40),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
    final langVM = context.watch<LanguageViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleMessageArtisan,
        backgroundColor: const Color(0xFF004D40),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.chat_rounded, size: 20),
        label: Text(
          'Message Master Artisan',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // Top Image Carousel Sliver AppBar
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: const Color(0xFF004D40),
            leading: CircleAvatar(
              backgroundColor: Colors.black.withOpacity(0.4),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            actions: [
              CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.4),
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
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
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
                                : Colors.white.withOpacity(0.5),
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
                              color: const Color(0xFF004D40),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.artisanName,
                          style: GoogleFonts.dmSerifDisplay(
                            color: Colors.white,
                            fontSize: 28,
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

          // Content Details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rating & Location Row
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.rating} ',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        '(128 reviews)',
                        style: GoogleFonts.plusJakartaSans(color: Colors.grey[600], fontSize: 13),
                      ),
                      const Spacer(),
                      const Icon(Icons.location_on_rounded, color: Color(0xFF004D40), size: 18),
                      const SizedBox(width: 4),
                      Text(
                        widget.state,
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 🎧 AUDIO LORE STORY PLAYER PILL
                  GestureDetector(
                    onTap: _toggleAudioLore,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF004D40),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: const Color(0xFF004D40).withOpacity(0.2), blurRadius: 10)],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isPlayingAudioLore ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                            color: const Color(0xFFFFD54F),
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  langVM.translate('audio_story_lore'),
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                Text(
                                  _isPlayingAudioLore ? '▶ Playing 2:15 Audio Lore Story' : 'Tap to hear Pak Mat explain 25 yrs of pottery heritage',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFFFFD54F)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Master Bio Section
                  Text(
                    langVM.translate('master_artisan_bio'),
                    style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: const Color(0xFF004D40)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.bio,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.6, color: Colors.black87),
                  ),

                  const SizedBox(height: 24),

                  // 📜 CULTURAL CRAFT ORIGIN & HERITAGE HISTORY LORE
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
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
                            Text(
                              'Historical Origin & Cultural Lore',
                              style: GoogleFonts.dmSerifDisplay(fontSize: 16, color: const Color(0xFF78350F)),
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
                    children: const [
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
                      border: Border.all(color: Colors.black.withOpacity(0.06)),
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
                                color: Colors.indigo.withOpacity(0.2),
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

                  const SizedBox(height: 28),

                  // Workshop Booking Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Workshop booking request sent to master artisan!'),
                            backgroundColor: Color(0xFF004D40),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF004D40),
                        side: const BorderSide(color: Color(0xFF004D40), width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.calendar_month_rounded, size: 20),
                      label: const Text('BOOK CRAFT WORKSHOP SESSION', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
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
        border: Border.all(color: Colors.black.withOpacity(0.06)),
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
        border: Border.all(color: Colors.black.withOpacity(0.06)),
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
