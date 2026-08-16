import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/ui/tourist/artisan_detail_screen.dart';
import 'package:warisan_kita/ui/tourist/quest_completion_screen.dart';
import 'package:warisan_kita/ui/core/widgets/translation_language_dialog.dart';
import 'package:warisan_kita/viewmodels/language_viewmodel.dart';

class TouristDirectoryTab extends StatefulWidget {
  const TouristDirectoryTab({super.key});

  @override
  State<TouristDirectoryTab> createState() => _TouristDirectoryTabState();
}

class _TouristDirectoryTabState extends State<TouristDirectoryTab> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedState = 'All States';
  String _selectedCategory = 'All Crafts';
  bool _hasPreferences = true;

  final List<String> _malaysianStates = const [
    'All States',
    'Melaka',
    'Kelantan',
    'Terengganu',
    'Perak',
    'Selangor',
    'Johor',
    'Penang',
    'Kedah',
    'Pahang',
    'Sabah',
    'Sarawak',
  ];

  List<Map<String, dynamic>> _getArtisans(LanguageViewModel langVM) {
    return [
      {
        'id': 'a1',
        'name': langVM.translate('Pak Mat Pottery Studio'),
        'category': langVM.translate('Clay Pottery & Ceramics'),
        'state': 'Melaka',
        'rating': 4.9,
        'image': 'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=600&auto=format&fit=crop&q=80',
        'bio': langVM.translate('Master Pak Mat has been hand-crafting traditional clay labu sayong and ceramic vessels for over 25 years in Kampung Morten.'),
        'exp': '+150 EXP',
        'experienceYears': '25 Yrs',
      },
      {
        'id': 'a2',
        'name': langVM.translate('Wan Songket Heritage Weavers'),
        'category': langVM.translate('Songket Gold Weaving'),
        'state': 'Kelantan',
        'rating': 4.8,
        'image': 'https://images.unsplash.com/photo-1528459801416-a9e53bbf4e17?w=600&auto=format&fit=crop&q=80',
        'bio': langVM.translate('Royal songket weaving utilizing metallic gold and silver threads on handloom wooden apparatus in Kota Bharu.'),
        'exp': '+200 EXP',
        'experienceYears': '32 Yrs',
      },
      {
        'id': 'a3',
        'name': langVM.translate('Siti Batik Craft Workshop'),
        'category': langVM.translate('Batik Wax Painting'),
        'state': 'Terengganu',
        'rating': 4.9,
        'image': 'https://images.unsplash.com/photo-1617038220319-276d3cfab638?w=600&auto=format&fit=crop&q=80',
        'bio': langVM.translate('Hand-drawn canting batik studio utilizing organic natural dyes and silk fabrics in coastal Terengganu.'),
        'exp': '+180 EXP',
        'experienceYears': '18 Yrs',
      },
      {
        'id': 'a4',
        'name': langVM.translate('Master Wong Woodcraft'),
        'category': langVM.translate('Traditional Woodcarving'),
        'state': 'Perak',
        'rating': 4.7,
        'image': 'https://images.unsplash.com/photo-1544717305-2782549b5136?w=600&auto=format&fit=crop&q=80',
        'bio': langVM.translate('Ornate timber carving specializing in traditional Malay architectural wood panels and keris handles in Perak.'),
        'exp': '+160 EXP',
        'experienceYears': '29 Yrs',
      },
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showOfflineToast(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'No internet connection. Showing cached data.',
                softWrap: true,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showFilterBottomSheet(LanguageViewModel langVM) {
    final categories = [
      langVM.translate('All Crafts'),
      langVM.translate('Clay Pottery & Ceramics'),
      langVM.translate('Batik Wax Painting'),
      langVM.translate('Songket Gold Weaving'),
      langVM.translate('Traditional Woodcarving'),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            return Container(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          langVM.translate('Filter Heritage Directory'),
                          softWrap: true,
                          style: GoogleFonts.dmSerifDisplay(fontSize: 22, color: const Color(0xFF004D40)),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      const Icon(Icons.map_rounded, color: Color(0xFFD97706), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Select Region / State:',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _malaysianStates.map((st) {
                      final isSelected = _selectedState == st;
                      return ChoiceChip(
                        label: Text(st == 'All States' ? langVM.translate('All States') : st),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedState = st);
                            setBottomSheetState(() {});
                          }
                        },
                        selectedColor: const Color(0xFF004D40),
                        backgroundColor: const Color(0xFFF1F5F9),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF334155),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      const Icon(Icons.category_rounded, color: Color(0xFF004D40), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Select Craft Specialization:',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedCategory = cat);
                            setBottomSheetState(() {});
                          }
                        },
                        selectedColor: const Color(0xFFD97706),
                        backgroundColor: const Color(0xFFF1F5F9),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF334155),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF004D40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('APPLY FILTERS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
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
    final query = _searchController.text.toLowerCase().trim();
    final artisans = _getArtisans(langVM);

    final filtered = artisans.where((artisan) {
      final matchesQuery = query.isEmpty ||
          artisan['name'].toLowerCase().contains(query) ||
          artisan['category'].toLowerCase().contains(query) ||
          artisan['state'].toLowerCase().contains(query);

      final matchesCategory = _selectedCategory == 'All Crafts' ||
          artisan['category'] == _selectedCategory ||
          _selectedCategory == langVM.translate('All Crafts');

      final matchesState = _selectedState == 'All States' ||
          artisan['state'].toLowerCase() == _selectedState.toLowerCase();

      return matchesQuery && matchesCategory && matchesState;
    }).toList();

    final categories = [
      {'name': langVM.translate('All Crafts'), 'icon': Icons.grid_view_rounded},
      {'name': langVM.translate('Clay Pottery & Ceramics'), 'icon': Icons.water_drop_rounded},
      {'name': langVM.translate('Batik Wax Painting'), 'icon': Icons.palette_rounded},
      {'name': langVM.translate('Songket Gold Weaving'), 'icon': Icons.auto_awesome_rounded},
      {'name': langVM.translate('Traditional Woodcarving'), 'icon': Icons.handyman_rounded},
    ];

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Klook / Polarsteps Inspired Hero Header App Bar
        SliverAppBar(
          floating: true,
          pinned: true,
          backgroundColor: const Color(0xFFF8F9FA),
          elevation: 0,
          expandedHeight: 120.0,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 10),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF004D40), Color(0xFF00251A)],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD54F).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFFD54F)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.location_on_rounded, color: Color(0xFFFFD54F), size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    'MALAYSIA CULTURAL RADAR',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFFFFD54F),
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          langVM.translate('Explore Living Heritage'),
                          style: GoogleFonts.dmSerifDisplay(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.g_translate_rounded, color: Colors.white, size: 20),
                          tooltip: 'Translate Page Live',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => TranslationLanguageDialog(
                                currentLanguage: langVM.currentLanguageCode,
                                onLanguageChanged: (code, name) {
                                  context.read<LanguageViewModel>().setLanguage(code, name);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.wifi_off_rounded, color: Color(0xFFFCA5A5), size: 20),
                          onPressed: () => _showOfflineToast(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Klook Style Glassmorphic Search Bar
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: langVM.translate('Search master artisans, state, or craft...'),
                            hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey[400]),
                            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF004D40)),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF004D40), Color(0xFF00251A)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF004D40).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.tune_rounded, color: Colors.white),
                        onPressed: () => _showFilterBottomSheet(langVM),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Klook Style Quick Category Chips Carousel
                SizedBox(
                  height: 42,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final name = cat['name'] as String;
                      final icon = cat['icon'] as IconData;
                      final isSelected = _selectedCategory == name || (_selectedCategory == 'All Crafts' && index == 0);

                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = name),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF004D40) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF004D40) : const Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF004D40).withValues(alpha: 0.25),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                icon,
                                size: 16,
                                color: isSelected ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : const Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Region / State Filter Chips Row
                Row(
                  children: [
                    const Icon(Icons.map_rounded, color: Color(0xFFD97706), size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        langVM.translate('Filter by Region / State:'),
                        softWrap: true,
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFD97706)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                SizedBox(
                  height: 34,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _malaysianStates.length,
                    itemBuilder: (context, index) {
                      final st = _malaysianStates[index];
                      final isSelected = _selectedState == st;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: ChoiceChip(
                          label: Text(st == 'All States' ? langVM.translate('All States') : st),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedState = st);
                          },
                          selectedColor: const Color(0xFFD97706),
                          backgroundColor: Colors.white,
                          labelStyle: GoogleFonts.plusJakartaSans(
                            color: isSelected ? Colors.white : const Color(0xFF475569),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Recommended Preferences Section Banner
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      'Preferences Matching:',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[600]),
                    ),
                    FilterChip(
                      label: Text(_hasPreferences ? '⚡ Personalized (Active)' : 'Off (Show All)'),
                      selected: _hasPreferences,
                      onSelected: (val) => setState(() => _hasPreferences = val),
                      selectedColor: const Color(0xFFE0F2FE),
                      labelStyle: TextStyle(
                        color: _hasPreferences ? const Color(0xFF0369A1) : Colors.grey[700],
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                if (_hasPreferences) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome_rounded, color: Color(0xFF15803D), size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Recommended for You (Based on Preferences)',
                                softWrap: true,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF15803D),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 72,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _buildRecommendationCard(langVM.translate('Pak Mat Pottery Studio'), langVM.translate('Clay Pottery & Ceramics')),
                              _buildRecommendationCard(langVM.translate('Siti Batik Craft Workshop'), langVM.translate('Batik Wax Painting')),
                              _buildRecommendationCard(langVM.translate('Wan Songket Heritage Weavers'), langVM.translate('Songket Gold Weaving')),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // Trip.com Inspired Experience Cards Grid / List
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final artisan = filtered[index];
                return _buildArtisanCard(context, artisan, langVM);
              },
              childCount: filtered.length,
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildArtisanCard(BuildContext context, Map<String, dynamic> artisan, LanguageViewModel langVM) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF004D40).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                child: Image.network(
                  artisan['image'],
                  height: 190,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              // Gradient Scrim
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.4),
                      ],
                    ),
                  ),
                ),
              ),
              // Verified Master Badge
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF004D40),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFFD54F).withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded, color: Color(0xFFFFD54F), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'VERIFIED MASTER',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // EXP Reward Pill
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF7043), Color(0xFFF4511E)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF7043).withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        artisan['exp'] ?? '+150 EXP',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Image Info Strip (Rating & Experience)
              Positioned(
                bottom: 12,
                left: 14,
                right: 14,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFFFD54F), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${artisan['rating']} (120+ Reviews)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${artisan['experienceYears']} Heritage Master',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFD54F),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            artisan['name'],
                            softWrap: true,
                            style: GoogleFonts.dmSerifDisplay(
                              fontSize: 20,
                              color: const Color(0xFF004D40),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            artisan['category'],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_rounded, size: 12, color: Color(0xFFD97706)),
                          const SizedBox(width: 4),
                          Text(
                            artisan['state'],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  artisan['bio'],
                  maxLines: 2,
                  softWrap: true,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 14),
                // Travel Ticket Perforated Separator Line
                Row(
                  children: List.generate(
                    24,
                    (index) => Expanded(
                      child: Container(
                        height: 1.5,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        color: const Color(0xFFCBD5E1),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ArtisanDetailScreen(
                                artisanName: artisan['name'],
                                craftCategory: artisan['category'],
                                state: artisan['state'],
                                imageUrl: artisan['image'],
                                bio: artisan['bio'],
                                rating: artisan['rating'],
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF004D40), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          langVM.translate('View Profile'),
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF004D40),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => QuestCompletionScreen(
                                workshopName: artisan['name'],
                                craftCategory: artisan['category'],
                              ),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF004D40),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.stars_rounded, size: 16, color: Color(0xFFFFD54F)),
                        label: Text(
                          langVM.translate('START QUEST'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(String title, String category) {
    return Container(
      width: 230,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF86EFAC)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF15803D).withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF15803D).withValues(alpha: 0.1),
            child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF15803D), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                  maxLines: 1,
                  softWrap: true,
                ),
                Text(
                  category,
                  style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFF15803D)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}