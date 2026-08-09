import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/ui/directory/artisan_profile_view.dart';
import 'package:warisan_kita/domain/models/artisan_profile.dart';
import 'package:warisan_kita/viewmodels/directory_viewmodel.dart';

class DirectoryCatalogScreen extends StatelessWidget {
  const DirectoryCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final directoryState = context.watch<DirectoryViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context, directoryState),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: _buildFilterSection(directoryState),
            ),
          ),
          if (directoryState.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: Color(0xFF004D40))),
            )
          else if (directoryState.artisans.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  'No artisans match your filters',
                  style: GoogleFonts.plusJakartaSans(color: Colors.black26, fontWeight: FontWeight.bold),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              sliver: SliverMasonryGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                itemBuilder: (context, index) {
                  final artisan = directoryState.artisans[index];
                  return _buildArtisanCard(context, artisan);
                },
                childCount: directoryState.artisans.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, DirectoryViewModel state) {
    return SliverAppBar(
      expandedHeight: 180,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Master Directory',
                  style: GoogleFonts.dmSerifDisplay(
                    color: const Color(0xFF004D40),
                    fontSize: 32,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSearchBar(state),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(DirectoryViewModel state) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: TextField(
        onChanged: (val) => state.updateSearch(val),
        decoration: InputDecoration(
          hintText: 'Search artisans or crafts...',
          hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.black26),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF004D40)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFilterSection(DirectoryViewModel state) {
    final filters = ['All Crafts', 'Batik', 'Songket', 'Woodwork', 'Metal'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: filters.map((label) {
          bool isSelected = state.selectedCraft == label;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(label),
              selected: isSelected,
              // Fixed: Using named parameter 'craft'
              onSelected: (val) => state.updateFilter(craft: label),
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF004D40),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF004D40),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: BorderSide(color: Colors.black.withOpacity(0.05)),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildArtisanCard(BuildContext context, ArtisanModel artisan) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ArtisanProfileScreen(artisan: artisan),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 25,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'artisan_img_${artisan.id}',
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                child: Image.network(
                  artisan.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artisan.name,
                    style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: const Color(0xFF004D40)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    artisan.craftType.toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFFFF7043),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
