import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/domain/models/artisan_profile.dart';
import 'package:warisan_kita/domain/models/workshop_location.dart';
import 'package:warisan_kita/ui/gamification/workshop_quest_navigation.dart';
import 'package:warisan_kita/ui/tourist/artisan_detail_screen.dart';
import 'package:warisan_kita/ui/core/widgets/translation_language_dialog.dart';
import 'package:warisan_kita/ui/tourist/widgets/rotating_artisan_image_carousel.dart';
import 'package:warisan_kita/ui/tourist/widgets/shimmer_directory_loading.dart';
import 'package:warisan_kita/viewmodels/language_viewmodel.dart';
import 'package:warisan_kita/viewmodels/directory_viewmodel.dart';
import 'package:warisan_kita/viewmodels/gamification_viewmodel.dart';
import 'package:warisan_kita/viewmodels/matchmaker_viewmodel.dart';
import 'package:warisan_kita/ui/matchmaker/craft_matchmaker_quiz_wizard.dart';
import 'package:warisan_kita/ui/core/widgets/heritage_background.dart';

class CraftCategoryFilterItem {
  final String key;
  final String englishName;
  final IconData icon;
  final List<String> matchKeywords;

  const CraftCategoryFilterItem({
    required this.key,
    required this.englishName,
    required this.icon,
    required this.matchKeywords,
  });

  bool matches(String craftCategory, [List<dynamic>? tags]) {
    if (key == 'ALL') return true;
    final catLower = craftCategory.toLowerCase();
    for (final kw in matchKeywords) {
      if (catLower.contains(kw)) return true;
    }
    if (tags != null) {
      for (final t in tags) {
        final tagLower = t.toString().toLowerCase();
        for (final kw in matchKeywords) {
          if (tagLower.contains(kw)) return true;
        }
      }
    }
    return false;
  }
}

class TouristDirectoryTab extends StatefulWidget {
  const TouristDirectoryTab({super.key});

  static const List<CraftCategoryFilterItem> craftFilters = [
    CraftCategoryFilterItem(
      key: 'ALL',
      englishName: 'All Crafts',
      icon: Icons.grid_view_rounded,
      matchKeywords: [],
    ),
    CraftCategoryFilterItem(
      key: 'POTTERY',
      englishName: 'Clay Pottery & Ceramics',
      icon: Icons.water_drop_rounded,
      matchKeywords: [
        'potter',
        'ceramic',
        'clay',
        'tembikar',
        'seramik',
        'labu',
      ],
    ),
    CraftCategoryFilterItem(
      key: 'BATIK',
      englishName: 'Batik Wax Painting',
      icon: Icons.palette_rounded,
      matchKeywords: ['batik', 'wax', 'textile', 'canting', 'kain'],
    ),
    CraftCategoryFilterItem(
      key: 'SONGKET',
      englishName: 'Songket Gold Weaving',
      icon: Icons.auto_awesome_rounded,
      matchKeywords: ['songket', 'weav', 'tenun', 'gold thread'],
    ),
    CraftCategoryFilterItem(
      key: 'WOODWORK',
      englishName: 'Traditional Woodcarving',
      icon: Icons.handyman_rounded,
      matchKeywords: ['wood', 'carv', 'ukir', 'kayu'],
    ),
    CraftCategoryFilterItem(
      key: 'METALWORK',
      englishName: 'Metalwork & Pewter',
      icon: Icons.hardware_rounded,
      matchKeywords: [
        'metal',
        'pewter',
        'keris',
        'besi',
        'tembaga',
        'silver',
        'perak',
      ],
    ),
    CraftCategoryFilterItem(
      key: 'RATTAN',
      englishName: 'Rattan & Bamboo Craft',
      icon: Icons.grass_rounded,
      matchKeywords: [
        'rattan',
        'bamboo',
        'rotan',
        'buluh',
        'anyaman',
        'mengkuang',
      ],
    ),
  ];

  @override
  State<TouristDirectoryTab> createState() => _TouristDirectoryTabState();
}

class _TouristDirectoryTabState extends State<TouristDirectoryTab> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedState = 'All States';
  String _selectedCategoryKey = 'ALL';
  bool _hasPreferences = true;
  bool _isOpeningQuest = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DirectoryViewModel>().fetchArtisans();
      }
    });
  }

  static List<CraftCategoryFilterItem> get craftFilters =>
      TouristDirectoryTab.craftFilters;

  bool get _isFilterActive =>
      _searchController.text.trim().isNotEmpty ||
      _selectedState != 'All States' ||
      _selectedCategoryKey != 'ALL';

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedState = 'All States';
      _selectedCategoryKey = 'ALL';
    });
  }

  WorkshopLocation? _workshopForArtisan(Map<String, dynamic> artisan) {
    final id = artisan['id']?.toString().trim() ?? '';
    final latitude = (artisan['latitude'] as num?)?.toDouble();
    final longitude = (artisan['longitude'] as num?)?.toDouble();
    if (id.isEmpty ||
        latitude == null ||
        longitude == null ||
        !latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      return null;
    }

    return WorkshopLocation(
      id: id,
      name: artisan['name']?.toString().trim() ?? '',
      craftCategory: artisan['category']?.toString().trim() ?? '',
      address: artisan['address']?.toString().trim() ?? '',
      state: artisan['state']?.toString().trim() ?? '',
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<void> _openArtisanQuest(
    BuildContext context,
    Map<String, dynamic> artisan,
  ) async {
    if (_isOpeningQuest) return;

    final workshop = _workshopForArtisan(artisan);
    if (workshop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Workshop location is unavailable for this quest.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _isOpeningQuest = true;
    try {
      await openWorkshopQuest(context, workshop);
    } finally {
      _isOpeningQuest = false;
      if (context.mounted) {
        await Future.wait([
          context.read<GamificationViewModel>().loadActiveQuestState(),
          context.read<DirectoryViewModel>().fetchArtisans(),
        ]);
      }
    }
  }

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterBottomSheet(LanguageViewModel langVM) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF0D2825) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
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
                              style: GoogleFonts.dmSerifDisplay(
                                fontSize: 22,
                                color: isDark
                                    ? const Color(0xFFFFD54F)
                                    : const Color(0xFF004D40),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Icon(
                            Icons.map_rounded,
                            color: isDark
                                ? const Color(0xFFFFD54F)
                                : const Color(0xFFD97706),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Select Region / State:',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
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
                            label: Text(
                              st == 'All States'
                                  ? langVM.translate('All States')
                                  : st,
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedState = st);
                                setBottomSheetState(() {});
                              }
                            },
                            selectedColor: const Color(0xFF004D40),
                            backgroundColor: isDark
                                ? const Color(0xFF041412)
                                : const Color(0xFFF1F5F9),
                            side: isDark
                                ? const BorderSide(color: Color(0xFF1E3A34))
                                : null,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                        ? Colors.white70
                                        : const Color(0xFF334155)),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Icon(
                            Icons.category_rounded,
                            color: isDark
                                ? const Color(0xFFFFD54F)
                                : const Color(0xFF004D40),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Select Craft Specialization:',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: craftFilters.map((catItem) {
                          final isSelected =
                              _selectedCategoryKey == catItem.key;
                          return ChoiceChip(
                            label: Text(langVM.translate(catItem.englishName)),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(
                                  () => _selectedCategoryKey = catItem.key,
                                );
                                setBottomSheetState(() {});
                              }
                            },
                            selectedColor: const Color(0xFFD97706),
                            backgroundColor: isDark
                                ? const Color(0xFF041412)
                                : const Color(0xFFF1F5F9),
                            side: isDark
                                ? const BorderSide(color: Color(0xFF1E3A34))
                                : null,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                        ? Colors.white70
                                        : const Color(0xFF334155)),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _clearFilters();
                                setBottomSheetState(() {});
                                Navigator.of(context).pop();
                              },
                              icon: const Icon(
                                Icons.refresh_rounded,
                                size: 16,
                                color: Color(0xFF004D40),
                              ),
                              label: Text(
                                langVM.translate('Clear Filters'),
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: const Color(0xFF004D40),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFF004D40),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF004D40),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: Text(
                                langVM.translate('APPLY FILTERS'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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

    // Wire up to DirectoryViewModel to get REAL artisans from Supabase
    final dirVM = context.watch<DirectoryViewModel>();
    final allArtisanModels = dirVM.allArtisans.isNotEmpty
        ? dirVM.allArtisans
        : dirVM.artisans;
    final allDirectoryArtisans = allArtisanModels
        .map(
          (a) => {
            'id': a.id,
            'name': a.name,
            'category': a.craftType,
            'craft': a.craftType,
            'state': a.state,
            'rating': a.rating,
            'image': a.imageUrl,
            'images': a.images,
            'bio': a.description,
            'experienceYears': a.experience,
            'workshopCount': a.workshopCount,
            'tags': a.tags,
            'address': a.address,
            'latitude': a.latitude,
            'longitude': a.longitude,
            'isLiveOpen': a.isLiveOpen,
            'ssmNumber': a.ssmNumber,
            'documents': a.documents,
            'phone': a.phone,
            'premiseType': a.premiseType,
            'artisanModel': a, // pass the model for the detail screen
          },
        )
        .toList();

    final realArtisans = dirVM.artisans
        .map(
          (a) => {
            'id': a.id,
            'name': a.name,
            'category': a.craftType,
            'craft': a.craftType,
            'state': a.state,
            'rating': a.rating,
            'image': a.imageUrl,
            'images': a.images,
            'bio': a.description,
            'experienceYears': a.experience,
            'workshopCount': a.workshopCount,
            'tags': a.tags,
            'address': a.address,
            'latitude': a.latitude,
            'longitude': a.longitude,
            'isLiveOpen': a.isLiveOpen,
            'ssmNumber': a.ssmNumber,
            'documents': a.documents,
            'phone': a.phone,
            'premiseType': a.premiseType,
            'artisanModel': a,
          },
        )
        .toList();

    // Directory is 100% bound to real artisans from Supabase
    final artisans = realArtisans;

    final selectedFilter = craftFilters.firstWhere(
      (f) => f.key == _selectedCategoryKey,
      orElse: () => craftFilters.first,
    );

    final filtered = artisans.where((artisan) {
      final tags = artisan['tags'];
      final tagList = tags is List ? tags : (tags is String ? [tags] : null);
      final bio = artisan['bio']?.toString().toLowerCase() ?? '';

      final matchesQuery =
          query.isEmpty ||
          artisan['name'].toString().toLowerCase().contains(query) ||
          artisan['category'].toString().toLowerCase().contains(query) ||
          artisan['state'].toString().toLowerCase().contains(query) ||
          bio.contains(query) ||
          (tagList != null &&
              tagList.any((t) => t.toString().toLowerCase().contains(query)));

      final matchesCategory = selectedFilter.matches(
        artisan['category']?.toString() ?? '',
        tagList,
      );

      final matchesState =
          _selectedState == 'All States' ||
          artisan['state'].toString().toLowerCase() ==
              _selectedState.toLowerCase();

      return matchesQuery && matchesCategory && matchesState;
    }).toList();

    // Recommendations strictly based on user's 4 quiz choices (Q1: Experience, Q2: Setting, Q3: Material, Q4: Region)
    // Completely self-contained and independent recommendation scoring pipeline
    final matchmakerVM = context.watch<MatchmakerViewModel>();
    List<Map<String, dynamic>> recommendedArtisans = [];
    String recommendationHeaderTitle = langVM.translate(
      'Suggested for You (Based on Quiz)',
    );
    String? recommendationSubtitle;

    if (matchmakerVM.isQuizCompleted) {
      final personality = matchmakerVM.currentPersonality;
      final chosenMaterial =
          matchmakerVM.material ?? personality?.material ?? '';
      final chosenRegion = matchmakerVM.region ?? personality?.region ?? '';
      final chosenExp =
          matchmakerVM.experienceType ?? personality?.experienceType ?? '';
      final chosenEnv =
          matchmakerVM.environment ?? personality?.environment ?? '';

      // Determine material keywords from what user chose in quiz
      final materialKeywords = <String>{};
      final matLower = chosenMaterial.toLowerCase();
      if (matLower.contains('potter') ||
          matLower.contains('clay') ||
          matLower.contains('ceramic')) {
        materialKeywords.addAll([
          'potter',
          'ceramic',
          'clay',
          'tembikar',
          'seramik',
          'labu',
        ]);
      } else if (matLower.contains('batik') ||
          matLower.contains('songket') ||
          matLower.contains('textile')) {
        materialKeywords.addAll([
          'batik',
          'songket',
          'textile',
          'canting',
          'kain',
          'tenun',
          'silk',
          'weav',
        ]);
      } else if (matLower.contains('timber') || matLower.contains('wood')) {
        materialKeywords.addAll(['wood', 'carv', 'ukir', 'kayu', 'timber']);
      } else if (matLower.contains('pewter') || matLower.contains('metal')) {
        materialKeywords.addAll([
          'metal',
          'pewter',
          'keris',
          'besi',
          'tembaga',
          'silver',
          'perak',
          'blade',
          'forg',
        ]);
      }
      for (final mc in matchmakerVM.matchingCrafts) {
        materialKeywords.add(mc.toLowerCase().trim());
        for (final w in mc.toLowerCase().split(RegExp(r'[\s&/,\-]+'))) {
          if (w.length >= 3 &&
              !{
                'and',
                'the',
                'arts',
                'making',
                'crafts',
                'craft',
              }.contains(w)) {
            materialKeywords.add(w);
          }
        }
      }

      if (chosenMaterial.isNotEmpty) {
        for (final w in chosenMaterial.toLowerCase().split(
          RegExp(r'[\s&/,\-]+'),
        )) {
          if (w.length >= 3 &&
              !{
                'and',
                'the',
                'arts',
                'making',
                'crafts',
                'craft',
                'textiles',
                'textile',
              }.contains(w)) {
            materialKeywords.add(w);
          }
        }
      }

      // Target states from user's chosen region in quiz
      final regLower = chosenRegion.toLowerCase();
      final Set<String> targetStates;
      if (regLower.contains('east coast') ||
          regLower.contains('kelantan') ||
          regLower.contains('terengganu') ||
          regLower.contains('pahang')) {
        targetStates = {'kelantan', 'terengganu', 'pahang'};
      } else if (regLower.contains('west coast') ||
          regLower.contains('melaka') ||
          regLower.contains('perak') ||
          regLower.contains('selangor') ||
          regLower.contains('penang') ||
          regLower.contains('johor')) {
        targetStates = {
          'melaka',
          'perak',
          'selangor',
          'penang',
          'johor',
          'kedah',
          'perlis',
          'kuala lumpur',
          'negeri sembilan',
        };
      } else if (regLower.contains('north')) {
        targetStates = {'penang', 'kedah', 'perlis', 'perak'};
      } else if (regLower.contains('central')) {
        targetStates = {'selangor', 'kuala lumpur', 'negeri sembilan'};
      } else if (regLower.contains('south')) {
        targetStates = {'johor', 'melaka'};
      } else if (regLower.contains('borneo') ||
          regLower.contains('sabah') ||
          regLower.contains('sarawak')) {
        targetStates = {'sabah', 'sarawak'};
      } else {
        targetStates = {};
      }

      final scoredArtisans = <Map<String, dynamic>, double>{};

      for (final a in allDirectoryArtisans) {
        final craft = a['craft']?.toString().toLowerCase() ?? '';
        final cat = a['category']?.toString().toLowerCase() ?? '';
        final name = a['name']?.toString().toLowerCase() ?? '';
        final state = a['state']?.toString().toLowerCase() ?? '';
        final address = a['address']?.toString().toLowerCase() ?? '';
        final bio = a['bio']?.toString().toLowerCase() ?? '';
        final tags = a['tags'];
        final tagList = tags is List
            ? tags.map((t) => t.toString().toLowerCase()).toList()
            : (tags is String ? [tags.toLowerCase()] : <String>[]);

        // 1. Material / Craft match (Quiz Q3)
        bool matchesMaterial = false;
        for (final kw in materialKeywords) {
          if (craft.contains(kw) ||
              cat.contains(kw) ||
              name.contains(kw) ||
              tagList.any((t) => t.contains(kw))) {
            matchesMaterial = true;
            break;
          }
        }

        // 2. Region / State match (Quiz Q4)
        bool matchesRegion =
            targetStates.isEmpty ||
            targetStates.any((s) => state.contains(s) || address.contains(s));

        // 3. Experience style match (Quiz Q1: Hands-on Workshop vs Observing Master Artisans)
        bool matchesExp = false;
        final expLower = chosenExp.toLowerCase();
        final workshopCount = (a['workshopCount'] as num?)?.toInt() ?? 0;
        final expYears = a['experienceYears']?.toString().toLowerCase() ?? '';
        if (expLower.isEmpty) {
          matchesExp = true;
        } else if (expLower.contains('hands-on')) {
          matchesExp =
              workshopCount > 0 ||
              tagList.any(
                (t) =>
                    t.contains('workshop') ||
                    t.contains('hands-on') ||
                    t.contains('class') ||
                    t.contains('craft') ||
                    t.contains('learn') ||
                    t.contains('diy') ||
                    t.contains('bengkel') ||
                    t.contains('sesi') ||
                    t.contains('canting') ||
                    t.contains('pottery') ||
                    t.contains('carving'),
              ) ||
              bio.contains('workshop') ||
              bio.contains('hands-on') ||
              bio.contains('class') ||
              bio.contains('learn') ||
              bio.contains('craft') ||
              bio.contains('bengkel') ||
              bio.contains('canting') ||
              bio.contains('pottery') ||
              bio.contains('carving');
        } else if (expLower.contains('observing')) {
          matchesExp =
              expYears.contains('10+') ||
              expYears.contains('20+') ||
              expYears.contains('30+') ||
              expYears.contains('40+') ||
              expYears.contains('master') ||
              tagList.any(
                (t) =>
                    t.contains('master') ||
                    t.contains('heritage') ||
                    t.contains('authentic') ||
                    t.contains('tokoh') ||
                    t.contains('traditional') ||
                    t.contains('artisan') ||
                    t.contains('warisan') ||
                    t.contains('adiguru'),
              ) ||
              bio.contains('master') ||
              bio.contains('heritage') ||
              bio.contains('demonstration') ||
              bio.contains('traditional') ||
              bio.contains('authentic') ||
              bio.contains('tokoh') ||
              bio.contains('warisan') ||
              name.contains('master') ||
              name.contains('mak') ||
              name.contains('pak') ||
              name.contains('uncle') ||
              name.contains('che') ||
              name.contains('madam');
        } else {
          matchesExp = true;
        }

        // 4. Studio setting / environment match (Quiz Q2: Indoor Studio vs Outdoor Village)
        bool matchesEnv = false;
        final envLower = chosenEnv.toLowerCase();
        if (envLower.isEmpty) {
          matchesEnv = true;
        } else if (envLower.contains('indoor')) {
          matchesEnv =
              tagList.any(
                (t) =>
                    t.contains('studio') ||
                    t.contains('gallery') ||
                    t.contains('galeri') ||
                    t.contains('indoor') ||
                    t.contains('center') ||
                    t.contains('centre') ||
                    t.contains('boutique') ||
                    t.contains('shop') ||
                    t.contains('outlet') ||
                    t.contains('complex') ||
                    t.contains('kompleks') ||
                    t.contains('dewan') ||
                    t.contains('hall') ||
                    t.contains('museum') ||
                    t.contains('muzium') ||
                    t.contains('workshop') ||
                    t.contains('painting') ||
                    t.contains('canting') ||
                    t.contains('craft') ||
                    t.contains('batik') ||
                    t.contains('songket') ||
                    t.contains('pewter'),
              ) ||
              bio.contains('studio') ||
              bio.contains('gallery') ||
              bio.contains('galeri') ||
              bio.contains('indoor') ||
              bio.contains('center') ||
              bio.contains('centre') ||
              bio.contains('boutique') ||
              bio.contains('shop') ||
              bio.contains('outlet') ||
              bio.contains('complex') ||
              bio.contains('kompleks') ||
              bio.contains('dewan') ||
              bio.contains('hall') ||
              bio.contains('museum') ||
              bio.contains('muzium') ||
              bio.contains('workshop') ||
              bio.contains('painting') ||
              bio.contains('canting') ||
              bio.contains('craft') ||
              bio.contains('batik') ||
              bio.contains('songket') ||
              bio.contains('pewter') ||
              address.contains('studio') ||
              address.contains('gallery') ||
              address.contains('complex') ||
              address.contains('center') ||
              address.contains('centre') ||
              address.contains('mall') ||
              address.contains('plaza') ||
              address.contains('jalan') ||
              address.contains('lorong') ||
              name.contains('studio') ||
              name.contains('gallery') ||
              name.contains('galeri') ||
              name.contains('boutique');
        } else if (envLower.contains('outdoor') ||
            envLower.contains('village')) {
          matchesEnv =
              tagList.any(
                (t) =>
                    t.contains('village') ||
                    t.contains('kampong') ||
                    t.contains('kampung') ||
                    t.contains('outdoor') ||
                    t.contains('open-air') ||
                    t.contains('garden') ||
                    t.contains('taman') ||
                    t.contains('desa') ||
                    t.contains('river') ||
                    t.contains('sungai') ||
                    t.contains('nature') ||
                    t.contains('seri') ||
                    t.contains('kebun') ||
                    t.contains('chalet') ||
                    t.contains('homestay') ||
                    t.contains('hutan') ||
                    t.contains('traditional') ||
                    t.contains('authentic') ||
                    t.contains('rural') ||
                    t.contains('labu') ||
                    t.contains('clay') ||
                    t.contains('pottery') ||
                    t.contains('wood') ||
                    t.contains('ukir'),
              ) ||
              bio.contains('village') ||
              bio.contains('kampong') ||
              bio.contains('kampung') ||
              bio.contains('outdoor') ||
              bio.contains('open-air') ||
              bio.contains('garden') ||
              bio.contains('taman') ||
              bio.contains('desa') ||
              bio.contains('river') ||
              bio.contains('sungai') ||
              bio.contains('nature') ||
              bio.contains('seri') ||
              bio.contains('kebun') ||
              bio.contains('chalet') ||
              bio.contains('homestay') ||
              bio.contains('hutan') ||
              bio.contains('traditional') ||
              bio.contains('authentic') ||
              bio.contains('rural') ||
              bio.contains('labu') ||
              bio.contains('clay') ||
              bio.contains('pottery') ||
              bio.contains('wood') ||
              bio.contains('ukir') ||
              address.contains('kampung') ||
              address.contains('kampong') ||
              address.contains('desa') ||
              address.contains('taman') ||
              address.contains('sungai') ||
              address.contains('ulu') ||
              address.contains('hulu') ||
              address.contains('kuala');
        } else {
          matchesEnv = true;
        }

        // Only recommend artisans that strictly match ALL 4 quiz questions
        if (matchesMaterial && matchesRegion && matchesExp && matchesEnv) {
          double score = 100.0; // Base score for 4-question match

          // Additional affinity bonuses
          if (expLower.contains('hands-on') &&
              (workshopCount > 0 ||
                  tagList.any(
                    (t) => t.contains('workshop') || t.contains('hands-on'),
                  ))) {
            score += 25.0;
          } else if (expLower.contains('observing') &&
              (expYears.contains('10+') ||
                  expYears.contains('20+') ||
                  tagList.any((t) => t.contains('master')))) {
            score += 25.0;
          }

          if (envLower.contains('indoor') &&
              (tagList.any(
                    (t) => t.contains('studio') || t.contains('gallery'),
                  ) ||
                  bio.contains('studio'))) {
            score += 25.0;
          } else if ((envLower.contains('outdoor') ||
                  envLower.contains('village')) &&
              (tagList.any(
                    (t) => t.contains('village') || t.contains('kampong'),
                  ) ||
                  bio.contains('village'))) {
            score += 25.0;
          }

          // Rating tiebreaker
          final rating = (a['rating'] as num?)?.toDouble() ?? 0.0;
          score += (rating * 2.0);

          scoredArtisans[a] = score;
        }
      }

      final sortedEntries = scoredArtisans.entries.toList()
        ..sort((e1, e2) {
          final scoreComparison = e2.value.compareTo(e1.value);
          if (scoreComparison != 0) return scoreComparison;
          final rA = (e1.key['rating'] as num?)?.toDouble() ?? 0.0;
          final rB = (e2.key['rating'] as num?)?.toDouble() ?? 0.0;
          return rB.compareTo(rA);
        });

      recommendedArtisans = sortedEntries.map((e) => e.key).toList();

      final categoryName = personality?.primaryCategory ?? chosenMaterial;
      recommendationHeaderTitle = personality != null
          ? '${langVM.translate('Suggested for You')} • ${personality.title}'
          : '${langVM.translate('Suggested for You')} • $categoryName';
      recommendationSubtitle =
          chosenMaterial.isNotEmpty && chosenRegion.isNotEmpty
          ? 'Suggested from your quiz: $chosenMaterial • $chosenRegion${chosenExp.isNotEmpty ? " • $chosenExp" : ""}'
          : (personality?.tagline.isNotEmpty == true
                ? personality!.tagline
                : null);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return HeritageBackground(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Klook / Polarsteps Inspired Hero Header App Bar
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: Colors.transparent,
          elevation: 0,
          expandedHeight: 126.0,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              padding: const EdgeInsets.fromLTRB(20, 42, 20, 10),
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFFFD54F,
                                ).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFFFD54F),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.location_on_rounded,
                                    color: Color(0xFFFFD54F),
                                    size: 12,
                                  ),
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                          icon: const Icon(
                            Icons.g_translate_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          tooltip: 'Translate Page Live',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => TranslationLanguageDialog(
                                currentLanguage: langVM.currentLanguageCode,
                                onLanguageChanged: (code, name) {
                                  context.read<LanguageViewModel>().setLanguage(
                                    code,
                                    name,
                                  );
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
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          tooltip: 'Refresh Directory',
                          onPressed: () {
                            context.read<DirectoryViewModel>().fetchArtisans();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Refreshing artisan directory from Supabase...',
                                ),
                                duration: Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
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
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 16.0,
            ),
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
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.3 : 0.05,
                              ),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: langVM.translate(
                              'Search master artisans, state, or craft...',
                            ),
                            hintStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: isDark ? Colors.white38 : Colors.grey[400],
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: isDark
                                  ? const Color(0xFFFFD54F)
                                  : const Color(0xFF004D40),
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                      color: Color(0xFF64748B),
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: isDark
                                ? const Color(0xFF0D2825)
                                : Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: isDark
                                  ? const BorderSide(color: Color(0xFF1E3A34))
                                  : BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: isDark
                                  ? const BorderSide(color: Color(0xFF1E3A34))
                                  : BorderSide.none,
                            ),
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
                            color: const Color(
                              0xFF004D40,
                            ).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.tune_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => _showFilterBottomSheet(langVM),
                      ),
                    ),
                  ],
                ),

                if (_isFilterActive) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF78350F).withValues(alpha: 0.4)
                                : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? const Color(
                                      0xFFD97706,
                                    ).withValues(alpha: 0.5)
                                  : const Color(0xFFFDE68A),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.filter_list_rounded,
                                size: 14,
                                color: isDark
                                    ? const Color(0xFFFDE68A)
                                    : const Color(0xFF92400E),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '${filtered.length} matching result${filtered.length == 1 ? '' : 's'}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? const Color(0xFFFDE68A)
                                        : const Color(0xFF92400E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(
                          Icons.refresh_rounded,
                          size: 14,
                          color: Color(0xFFDC2626),
                        ),
                        label: Text(
                          langVM.translate('Clear Filters'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // Klook Style Quick Category Chips Carousel
                SizedBox(
                  height: 42,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: craftFilters.length,
                    itemBuilder: (context, index) {
                      final catItem = craftFilters[index];
                      final name = langVM.translate(catItem.englishName);
                      final icon = catItem.icon;
                      final isSelected = _selectedCategoryKey == catItem.key;

                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedCategoryKey = catItem.key),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF004D40)
                                : (isDark
                                      ? const Color(0xFF0D2825)
                                      : Colors.white),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF004D40)
                                  : (isDark
                                        ? const Color(0xFF1E3A34)
                                        : const Color(0xFFE2E8F0)),
                              width: 1.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF004D40,
                                      ).withValues(alpha: 0.25),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                icon,
                                size: 16,
                                color: isSelected
                                    ? const Color(0xFFFFD54F)
                                    : (isDark
                                          ? const Color(0xFFFFD54F)
                                          : const Color(0xFF004D40)),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark
                                            ? Colors.white70
                                            : const Color(0xFF334155)),
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
                    Icon(
                      Icons.map_rounded,
                      color: isDark
                          ? const Color(0xFFFFD54F)
                          : const Color(0xFFD97706),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        langVM.translate('Filter by Region / State:'),
                        softWrap: true,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xFFFFD54F)
                              : const Color(0xFFD97706),
                        ),
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
                          label: Text(
                            st == 'All States'
                                ? langVM.translate('All States')
                                : st,
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedState = st);
                          },
                          selectedColor: const Color(0xFFD97706),
                          backgroundColor: isDark
                              ? const Color(0xFF0D2825)
                              : Colors.white,
                          side: isDark
                              ? const BorderSide(color: Color(0xFF1E3A34))
                              : null,
                          labelStyle: GoogleFonts.plusJakartaSans(
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                      ? Colors.white70
                                      : const Color(0xFF475569)),
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
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : Colors.grey[600],
                      ),
                    ),
                    FilterChip(
                      label: Text(
                        _hasPreferences
                            ? '⚡ Personalized (Active)'
                            : 'Off (Show All)',
                      ),
                      selected: _hasPreferences,
                      onSelected: (val) =>
                          setState(() => _hasPreferences = val),
                      selectedColor: isDark
                          ? const Color(0xFF0369A1).withValues(alpha: 0.3)
                          : const Color(0xFFE0F2FE),
                      backgroundColor: isDark ? const Color(0xFF0D2825) : null,
                      side: isDark
                          ? const BorderSide(color: Color(0xFF1E3A34))
                          : null,
                      labelStyle: TextStyle(
                        color: _hasPreferences
                            ? (isDark
                                  ? const Color(0xFF7DD3FC)
                                  : const Color(0xFF0369A1))
                            : (isDark ? Colors.white60 : Colors.grey[700]),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                if (_hasPreferences) ...[
                  const SizedBox(height: 12),
                  if (matchmakerVM.isQuizCompleted &&
                      recommendedArtisans.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0D2825)
                            : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF1E3A34)
                              : const Color(0xFF86EFAC),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                color: isDark
                                    ? const Color(0xFF34D399)
                                    : const Color(0xFF15803D),
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      recommendationHeaderTitle,
                                      softWrap: true,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? const Color(0xFF34D399)
                                            : const Color(0xFF15803D),
                                      ),
                                    ),
                                    if (recommendationSubtitle != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        recommendationSubtitle,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10,
                                          color: isDark
                                              ? Colors.white60
                                              : const Color(0xFF166534),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.tune_rounded,
                                  size: 18,
                                  color: isDark
                                      ? const Color(0xFFFFD54F)
                                      : const Color(0xFF004D40),
                                ),
                                tooltip: 'Update Quiz Preferences',
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => CraftMatchmakerQuizWizard(
                                      onCompleted: (_) => setState(() {}),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 98,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: recommendedArtisans.length,
                              itemBuilder: (context, index) {
                                return _buildRecommendationCard(
                                  context: context,
                                  artisan: recommendedArtisans[index],
                                  langVM: langVM,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (matchmakerVM.isQuizCompleted &&
                      recommendedArtisans.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0D2825)
                            : const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF1E3A34)
                              : const Color(0xFFFDE68A),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E3A34)
                                  : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.info_outline_rounded,
                              color: isDark
                                  ? const Color(0xFFFFD54F)
                                  : const Color(0xFFD97706),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  langVM.translate(
                                    'No artisans match your quiz choices',
                                  ),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? const Color(0xFFFFD54F)
                                        : const Color(0xFFB45309),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${langVM.translate("No artisans currently match your quiz choice for")} "${matchmakerVM.material ?? "Craft"}". ${langVM.translate("Tap below to retake the quiz or browse all crafts.")}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    color: isDark
                                        ? Colors.white60
                                        : const Color(0xFF92400E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => CraftMatchmakerQuizWizard(
                                  onCompleted: (_) => setState(() {}),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: isDark
                                    ? const Color(0xFFFFD54F)
                                    : const Color(0xFFD97706),
                              ),
                              foregroundColor: isDark
                                  ? const Color(0xFFFFD54F)
                                  : const Color(0xFFD97706),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              langVM.translate('Retake Quiz'),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0D2825)
                            : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF1E3A34)
                              : const Color(0xFF86EFAC),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E3A34)
                                  : const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              color: isDark
                                  ? const Color(0xFFFFD54F)
                                  : const Color(0xFF15803D),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  langVM.translate(
                                    'Take the Craft Matchmaker Quiz',
                                  ),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? const Color(0xFFFFD54F)
                                        : const Color(0xFF15803D),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  langVM.translate(
                                    'Answer 4 quick questions to get suggested artisans based on what you choose!',
                                  ),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    color: isDark
                                        ? Colors.white70
                                        : const Color(0xFF166534),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => CraftMatchmakerQuizWizard(
                                  onCompleted: (_) => setState(() {}),
                                ),
                              );
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: isDark
                                  ? const Color(0xFFFFD54F)
                                  : const Color(0xFF004D40),
                              foregroundColor: isDark
                                  ? const Color(0xFF041412)
                                  : Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              langVM.translate('START QUIZ'),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // Trip.com Inspired Experience Cards Grid / List or Empty State Fallback UI
        if (dirVM.isLoading && filtered.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: ShimmerDirectoryLoading(),
            ),
          )
        else if (filtered.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 12.0,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 36.0,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0D2825) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF1E3A34)
                        : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.3)
                          : const Color(0xFF004D40).withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFFFFD54F).withValues(alpha: 0.15)
                            : const Color(0xFFFFFBEB),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFFFFD54F).withValues(alpha: 0.35)
                              : const Color(0xFFFDE68A),
                        ),
                      ),
                      child: Icon(
                        Icons.search_off_rounded,
                        size: 44,
                        color: isDark
                            ? const Color(0xFFFFD54F)
                            : const Color(0xFFD97706),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      langVM.translate('No Results Found'),
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      langVM.translate(
                        'No master craftsmen match your active search filters or query. Try adjusting your search keyword or clearing filters.',
                      ),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(
                        langVM.translate('Clear Filters'),
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: isDark
                            ? const Color(0xFF00695C)
                            : const Color(0xFF004D40),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final artisan = filtered[index];
                return _buildArtisanCard(context, artisan, langVM);
              }, childCount: filtered.length),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    ),
  );
}

  Widget _buildArtisanCard(
    BuildContext context,
    Map<String, dynamic> artisan,
    LanguageViewModel langVM,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final artisanModel = artisan['artisanModel'] as ArtisanModel?;
    final questPotentialXp = artisanModel?.questPotentialXp;
    final rawImagesList = artisan['images'] is List
        ? List<String>.from(artisan['images'])
        : <String>[];
    final defaultImage =
        artisan['image']?.toString() ??
        'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=600&auto=format&fit=crop&q=80';
    final List<String> rawImages = rawImagesList.isNotEmpty
        ? rawImagesList
        : [defaultImage];
    final List<String> images = rawImages.length > 1
        ? rawImages
        : [
            rawImages.first,
            'https://images.unsplash.com/photo-1617038220319-276d3cfab638?w=600&auto=format&fit=crop&q=80',
            'https://images.unsplash.com/photo-1544717305-2782549b5136?w=600&auto=format&fit=crop&q=80',
          ];

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D2825) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark ? const Color(0xFF1E3A34) : const Color(0xFFF1F5F9),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RotatingArtisanImageCarousel(
            images: images,
            height: 195,
            interval: const Duration(seconds: 3),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ArtisanDetailScreen(
                    artisanName: artisan['name'],
                    craftCategory: artisan['category'],
                    state: artisan['state'],
                    imageUrl: images.first,
                    imageUrls: images,
                    bio: artisan['bio'],
                    rating: artisan['rating'],
                    experience: artisan['experienceYears'] ?? '10+ Years',
                    workshopsHosted: (artisan['workshopCount'] as int?) ?? 0,
                    tags: List<String>.from(artisan['tags'] ?? []),
                    address: artisan['address'] as String?,
                    latitude: (artisan['latitude'] as num?)?.toDouble(),
                    longitude: (artisan['longitude'] as num?)?.toDouble(),
                    isLiveOpen: artisan['isLiveOpen'] ?? true,
                    ssmNumber: artisan['ssmNumber'] as String?,
                    documents:
                        (artisan['documents'] as List<Map<String, dynamic>>?) ??
                        const [],
                    onViewQuest: () => _openArtisanQuest(context, artisan),
                    phoneNumber: artisan['phone'] as String?,
                    premiseType: artisan['premiseType'] as String?,
                  ),
                ),
              );
            },
            topLeading: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF004D40),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFFFD54F).withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    (artisan['premiseType'] as String?)?.toLowerCase().contains('village') == true ||
                            (artisan['premiseType'] as String?)?.toLowerCase().contains('desa') == true ||
                            (artisan['premiseType'] as String?)?.toLowerCase().contains('kediaman') == true
                        ? Icons.cottage_outlined
                        : Icons.verified_rounded,
                    color: const Color(0xFFFFD54F),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    (artisan['premiseType'] as String?)?.toLowerCase().contains('village') == true ||
                            (artisan['premiseType'] as String?)?.toLowerCase().contains('desa') == true ||
                            (artisan['premiseType'] as String?)?.toLowerCase().contains('kediaman') == true
                        ? 'VILLAGE CRAFTER'
                        : 'VERIFIED MASTER',
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
            topTrailing: questPotentialXp != null && questPotentialXp > 0
                ? Container(
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
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '+$questPotentialXp XP',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            )
                : null,
            bottomContent: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          color: Color(0xFFFFD54F),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${artisan['craft'] ?? artisan['category']} Studio',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${artisan['experienceYears']} Heritage Master',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF004D40),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            artisan['category'],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFFFFD54F)
                                  : const Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 130),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF78350F).withValues(alpha: 0.4)
                              : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFFD97706).withValues(alpha: 0.5)
                                : const Color(
                                    0xFFF59E0B,
                                  ).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 12,
                              color: isDark
                                  ? const Color(0xFFFDE68A)
                                  : const Color(0xFFD97706),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                artisan['state'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? const Color(0xFFFDE68A)
                                      : const Color(0xFFD97706),
                                ),
                              ),
                            ),
                          ],
                        ),
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
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
                if (artisan['phone'] != null &&
                    artisan['phone'].toString().trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.phone_rounded,
                        size: 13,
                        color: isDark
                            ? const Color(0xFF34D399)
                            : const Color(0xFF004D40),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        artisan['phone'].toString().trim(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFF34D399)
                              : const Color(0xFF004D40),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 14),
                // Travel Ticket Perforated Separator Line
                Row(
                  children: List.generate(
                    24,
                    (index) => Expanded(
                      child: Container(
                        height: 1.5,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        color: isDark
                            ? const Color(0xFF1E3A34)
                            : const Color(0xFFCBD5E1),
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
                                imageUrl: images.first,
                                imageUrls: images,
                                bio: artisan['bio'],
                                rating: artisan['rating'],
                                experience:
                                    artisan['experienceYears'] ?? '10+ Years',
                                workshopsHosted:
                                    (artisan['workshopCount'] as int?) ?? 0,
                                tags: List<String>.from(artisan['tags'] ?? []),
                                address: artisan['address'] as String?,
                                latitude: (artisan['latitude'] as num?)
                                    ?.toDouble(),
                                longitude: (artisan['longitude'] as num?)
                                    ?.toDouble(),
                                isLiveOpen: artisan['isLiveOpen'] ?? true,
                                ssmNumber: artisan['ssmNumber'] as String?,
                                documents:
                                    (artisan['documents']
                                        as List<Map<String, dynamic>>?) ??
                                    const [],
                                onViewQuest: () =>
                                    _openArtisanQuest(context, artisan),
                                phoneNumber: artisan['phone'] as String?,
                                premiseType: artisan['premiseType'] as String?,
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isDark
                                ? const Color(0xFFFFD54F)
                                : const Color(0xFF004D40),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 6,
                          ),
                        ),
                        child: Text(
                          langVM.translate('View Profile'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            color: isDark
                                ? const Color(0xFFFFD54F)
                                : const Color(0xFF004D40),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _openArtisanQuest(context, artisan),
                        style: FilledButton.styleFrom(
                          backgroundColor: isDark
                              ? const Color(0xFF00695C)
                              : const Color(0xFF004D40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 6,
                          ),
                          elevation: 2,
                        ),
                        icon: const Icon(
                          Icons.stars_rounded,
                          size: 16,
                          color: Color(0xFFFFD54F),
                        ),
                        label: Text(
                          langVM.translate('START QUEST'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

  Widget _buildRecommendationCard({
    required BuildContext context,
    required Map<String, dynamic> artisan,
    required LanguageViewModel langVM,
  }) {
    final name = artisan['name']?.toString() ?? '';
    final category = artisan['category']?.toString() ?? '';
    final state = artisan['state']?.toString() ?? '';
    final imageUrl =
        artisan['image']?.toString() ??
        (artisan['images'] != null && (artisan['images'] as List).isNotEmpty
            ? (artisan['images'] as List).first.toString()
            : 'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=600&auto=format&fit=crop&q=80');
    final rawImages = artisan['images'] as List?;
    final images = rawImages != null && rawImages.isNotEmpty
        ? rawImages.map((e) => e.toString()).toList()
        : [imageUrl];
    final bio = artisan['bio']?.toString() ?? '';
    final rating = (artisan['rating'] is num)
        ? (artisan['rating'] as num).toDouble()
        : 4.8;
    final tags = artisan['tags'] != null
        ? List<String>.from(artisan['tags'])
        : <String>[];
    final experience =
        artisan['experienceYears']?.toString() ??
        (artisan['experience']?.toString() ?? '20+ Years');
    final address = artisan['address']?.toString();
    final latitude = (artisan['latitude'] is num)
        ? (artisan['latitude'] as num).toDouble()
        : null;
    final longitude = (artisan['longitude'] is num)
        ? (artisan['longitude'] as num).toDouble()
        : null;

    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF15803D).withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: const Color(0xFF064E3B),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ArtisanDetailScreen(
                  artisanName: name,
                  craftCategory: category,
                  state: state,
                  imageUrl: imageUrl,
                  imageUrls: images,
                  bio: bio,
                  rating: rating,
                  experience: experience,
                  workshopsHosted: (artisan['workshopCount'] as int?) ?? 0,
                  tags: tags,
                  address: address,
                  latitude: latitude,
                  longitude: longitude,
                  isLiveOpen: artisan['isLiveOpen'] ?? true,
                  ssmNumber: artisan['ssmNumber'] as String?,
                  documents:
                      (artisan['documents'] as List<Map<String, dynamic>>?) ??
                      const [],
                  onViewQuest: () => _openArtisanQuest(context, artisan),
                  phoneNumber: artisan['phone'] as String?,
                  premiseType: artisan['premiseType'] as String?,
                ),
              ),
            );
          },
          child: Stack(
            children: [
              // Cover image as background
              Positioned.fill(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: const Color(0xFF004D40)),
                ),
              ),
              // Dark gradient overlay for text readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.black.withValues(alpha: 0.88),
                      ],
                    ),
                  ),
                ),
              ),
              // Card highlight border
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF86EFAC).withValues(alpha: 0.8),
                      width: 1.2,
                    ),
                  ),
                ),
              ),
              // Card interactive content
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(
                        0xFF15803D,
                      ).withValues(alpha: 0.85),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Color(0xFFFFD54F),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            category,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF86EFAC),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                          ),
                          if (state.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  size: 10,
                                  color: Color(0xFFFFD54F),
                                ),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    state,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 10,
                                  color: Colors.white70,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
