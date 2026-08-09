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

  double _maxDistance = 25.0; // km
  String _selectedCategory = 'All Crafts';
  bool _hasPreferences = true;

  List<Map<String, dynamic>> _getArtisans(LanguageViewModel langVM) {
    return [
      {
        'id': 'a1',
        'name': langVM.translate('pak_mat_name'),
        'category': langVM.translate('clay_pottery'),
        'state': 'Melaka',
        'rating': 4.9,
        'image': 'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=600&auto=format&fit=crop&q=80',
        'bio': langVM.translate('pak_mat_bio'),
      },
      {
        'id': 'a2',
        'name': langVM.translate('wan_songket_name'),
        'category': langVM.translate('songket_weaving'),
        'state': 'Kelantan',
        'rating': 4.8,
        'image': 'https://images.unsplash.com/photo-1528459801416-a9e53bbf4e17?w=600&auto=format&fit=crop&q=80',
        'bio': langVM.translate('wan_songket_bio'),
      },
      {
        'id': 'a3',
        'name': langVM.translate('siti_batik_name'),
        'category': langVM.translate('batik_wax'),
        'state': 'Terengganu',
        'rating': 4.9,
        'image': 'https://images.unsplash.com/photo-1617038220319-276d3cfab638?w=600&auto=format&fit=crop&q=80',
        'bio': langVM.translate('siti_batik_bio'),
      },
      {
        'id': 'a4',
        'name': langVM.translate('wong_woodcraft_name'),
        'category': langVM.translate('woodcarving'),
        'state': 'Perak',
        'rating': 4.7,
        'image': 'https://images.unsplash.com/photo-1544717305-2782549b5136?w=600&auto=format&fit=crop&q=80',
        'bio': langVM.translate('wong_woodcraft_bio'),
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
        content: const Row(
          children: [
            Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text('No internet connection. Showing cached data.'),
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
      langVM.translate('all_crafts'),
      langVM.translate('clay_pottery'),
      langVM.translate('batik_wax'),
      langVM.translate('songket_weaving'),
      langVM.translate('woodcarving'),
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
                      Text(
                        'Filter Heritage Directory',
                        style: GoogleFonts.dmSerifDisplay(fontSize: 22, color: const Color(0xFF004D40)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Text('Maximum Distance (${_maxDistance.toInt()} km)', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold)),
                  Slider(
                    value: _maxDistance,
                    min: 5.0,
                    max: 100.0,
                    divisions: 19,
                    activeColor: const Color(0xFF004D40),
                    label: '${_maxDistance.toInt()} km',
                    onChanged: (val) {
                      setBottomSheetState(() => _maxDistance = val);
                      setState(() => _maxDistance = val);
                    },
                  ),

                  const SizedBox(height: 20),

                  Text('Craft Category', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((cat) {
                      final isSelected = _selectedCategory == cat || (_selectedCategory == 'All Crafts' && cat == categories[0]);
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setBottomSheetState(() => _selectedCategory = cat);
                            setState(() => _selectedCategory = cat);
                          }
                        },
                        selectedColor: const Color(0xFF004D40),
                        labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF1E293B)),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 28),

                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setBottomSheetState(() {
                            _maxDistance = 25.0;
                            _selectedCategory = 'All Crafts';
                          });
                          setState(() {
                            _maxDistance = 25.0;
                            _selectedCategory = 'All Crafts';
                          });
                        },
                        child: Text(
                          'Reset Filters',
                          style: GoogleFonts.plusJakartaSans(color: Colors.grey[700], fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF004D40)),
                        child: const Text('Apply Filters'),
                      ),
                    ],
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
          _selectedCategory == langVM.translate('all_crafts');

      return matchesQuery && matchesCategory;
    }).toList();

    final categories = [
      langVM.translate('all_crafts'),
      langVM.translate('clay_pottery'),
      langVM.translate('batik_wax'),
      langVM.translate('songket_weaving'),
      langVM.translate('woodcarving'),
    ];

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // App Bar
        SliverAppBar(
          floating: true,
          pinned: true,
          backgroundColor: const Color(0xFFF8F9FA),
          elevation: 0,
          title: Text(
            langVM.translate('discover_heritage'),
            style: GoogleFonts.dmSerifDisplay(
              color: const Color(0xFF004D40),
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.g_translate_rounded, color: Color(0xFF004D40)),
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
            IconButton(
              icon: const Icon(Icons.wifi_off_rounded, color: Color(0xFFEF4444)),
              onPressed: () => _showOfflineToast(context),
            ),
          ],
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Field
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: langVM.translate('search_placeholder'),
                          hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey[400]),
                          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF004D40)),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      decoration: BoxDecoration(color: const Color(0xFF004D40), borderRadius: BorderRadius.circular(16)),
                      child: IconButton(
                        icon: const Icon(Icons.tune_rounded, color: Colors.white),
                        onPressed: () => _showFilterBottomSheet(langVM),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // FR600_1: Recommended Preferences Section Banner
                Row(
                  children: [
                    Text(
                      'Preferences Matching:',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 8),
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
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome_rounded, color: Color(0xFF15803D), size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Recommended for You (Based on Preferences)',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF15803D),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 70,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _buildRecommendationCard(langVM.translate('pak_mat_name'), langVM.translate('clay_pottery')),
                              _buildRecommendationCard(langVM.translate('siti_batik_name'), langVM.translate('batik_wax')),
                              _buildRecommendationCard(langVM.translate('wan_songket_name'), langVM.translate('songket_weaving')),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Category Chips List
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = _selectedCategory == category || (_selectedCategory == 'All Crafts' && index == 0);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedCategory = category);
                          },
                          selectedColor: const Color(0xFF004D40),
                          backgroundColor: Colors.white,
                          labelStyle: GoogleFonts.plusJakartaSans(
                            color: isSelected ? Colors.white : const Color(0xFF004D40),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),

        // Artisan List Cards Grid / Column
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

        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  Widget _buildArtisanCard(BuildContext context, Map<String, dynamic> artisan, LanguageViewModel langVM) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Image.network(
                  artisan['image'],
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        artisan['rating'].toString(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF78350F),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      artisan['name'],
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 20,
                        color: const Color(0xFF004D40),
                      ),
                    ),
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
                const SizedBox(height: 4),
                Text(
                  artisan['bio'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 16),

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
                          side: const BorderSide(color: Color(0xFF004D40)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          langVM.translate('view_profile'),
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF004D40),
                            fontSize: 11,
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
                          backgroundColor: const Color(0xFFD97706),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.stars_rounded, size: 16),
                        label: Text(
                          langVM.translate('start_quest'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
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
      width: 220,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF15803D).withValues(alpha: 0.1),
            child: const Icon(Icons.star_rounded, color: Color(0xFF15803D), size: 18),
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
                  overflow: TextOverflow.ellipsis,
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
