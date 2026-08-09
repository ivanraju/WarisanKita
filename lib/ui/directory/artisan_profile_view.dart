import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/domain/models/artisan_profile.dart';
import 'package:warisan_kita/viewmodels/itinerary_viewmodel.dart';

class ArtisanProfileScreen extends StatelessWidget {
  final ArtisanModel artisan;

  const ArtisanProfileScreen({super.key, required this.artisan});

  @override
  Widget build(BuildContext context) {
    final itineraryState = context.watch<ItineraryViewModel>();
    final isSaved = itineraryState.isSaved(artisan.id);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context, isSaved, itineraryState),
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildArtisanIdentity(context),
                    const SizedBox(height: 32),
                    _buildStatsGrid(),
                    const SizedBox(height: 40),
                    _buildSectionHeader('The Heritage Story'),
                    const SizedBox(height: 12),
                    _buildDescriptionText(),
                    const SizedBox(height: 32),
                    _buildSectionHeader('Masterworks Gallery'),
                    const SizedBox(height: 16),
                    _buildMultimediaGallery(),
                    const SizedBox(height: 40),
                    _buildActionCard(context, isSaved, itineraryState),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, bool isSaved, ItineraryViewModel state) {
    return SliverAppBar(
      expandedHeight: 450,
      pinned: true,
      stretch: true,
      backgroundColor: const Color(0xFF004D40),
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.black26,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.black26,
            child: IconButton(
              icon: Icon(
                isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isSaved ? const Color(0xFFFF7043) : Colors.white,
              ),
              onPressed: () => state.toggleSave(artisan),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'artisan_img_${artisan.id}',
              child: Image.network(
                artisan.imageUrl,
                fit: BoxFit.cover,
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtisanIdentity(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFF7043).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'CULTURAL GUARDIAN',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFFFF7043),
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          artisan.name,
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 34,
            color: const Color(0xFF004D40),
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.location_on_rounded, size: 14, color: Colors.black26),
            const SizedBox(width: 4),
            Text(
              '${artisan.state}, Malaysia',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.black38,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat(artisan.experience, 'EXP'),
          _buildStat('VERIFIED', 'STATUS'),
          _buildStat(artisan.workshopCount.toString(), 'WORKSHOPS'),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.dmSerifDisplay(fontSize: 22, color: const Color(0xFF004D40))),
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.black26, letterSpacing: 1)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.dmSerifDisplay(fontSize: 24, color: const Color(0xFF004D40)),
    );
  }

  Widget _buildDescriptionText() {
    return Text(
      artisan.description,
      style: GoogleFonts.plusJakartaSans(
        color: Colors.black54,
        fontSize: 15,
        height: 1.7,
      ),
    );
  }

  Widget _buildMultimediaGallery() {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Container(
            width: 150,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              image: DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1544967082-d9d25d867d66?w=400&idx=$index'),
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, bool isSaved, ItineraryViewModel state) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF004D40), Color(0xFF00796B)],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF004D40).withOpacity(0.3),
            blurRadius: 25,
            offset: const Offset(0, 12),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFD54F), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isSaved ? 'Crafting your journey...' : 'Plan a workshop visit',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              state.toggleSave(artisan);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isSaved ? 'Removed from your itinerary saved list' : 'Saved to your itinerary!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7043),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: Text(
              isSaved ? 'REMOVE FROM ITINERARY' : 'SAVE TO ITINERARY',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
