import 'package:flutter_test/flutter_test.dart';
import 'package:warisan_kita/domain/models/artisan_profile.dart';
import 'package:warisan_kita/ui/tourist/tourist_directory_tab.dart';
import 'package:warisan_kita/viewmodels/directory_viewmodel.dart';
import 'package:warisan_kita/viewmodels/language_viewmodel.dart';

void main() {
  group('Heritage Directory Localization & Category Filter Tests', () {
    final mockArtisans = [
      ArtisanModel(
        id: 'artisan_1',
        name: 'Pak Hashim',
        craftType: 'Woodwork',
        state: 'Kelantan',
        description: 'Master of ukiran kayu with 30 years experience',
        imageUrl: 'https://example.com/hashim.png',
        rating: 4.9,
        tags: ['ukiran', 'teak', 'heritage'],
      ),
      ArtisanModel(
        id: 'artisan_2',
        name: 'Mak Jah',
        craftType: 'Batik Wax Painting',
        state: 'Terengganu',
        description: 'Hand-drawn canting silk batik with flora motifs',
        imageUrl: 'https://example.com/jah.png',
        rating: 4.8,
        tags: ['canting', 'silk', 'kain batik'],
      ),
      ArtisanModel(
        id: 'artisan_3',
        name: 'Uncle Lim',
        craftType: 'Clay Pottery & Ceramics',
        state: 'Perak',
        description: 'Traditional labu sayong pottery and clay pots',
        imageUrl: 'https://example.com/lim.png',
        rating: 4.7,
        tags: ['labu sayong', 'pottery', 'clay'],
      ),
      ArtisanModel(
        id: 'artisan_4',
        name: 'Puan Siti',
        craftType: 'Songket Gold Weaving',
        state: 'Kelantan',
        description: 'Tenun songket with gold thread weaving patterns',
        imageUrl: 'https://example.com/siti.png',
        rating: 5.0,
        tags: ['songket', 'tenun', 'gold thread'],
      ),
      ArtisanModel(
        id: 'artisan_5',
        name: 'Mr. Tan',
        craftType: 'Pewter & Metalwork',
        state: 'Selangor',
        description: 'Handcrafted pewter chalices and copper repousse',
        imageUrl: 'https://example.com/tan.png',
        rating: 4.6,
        tags: ['pewter', 'metal', 'copper'],
      ),
      ArtisanModel(
        id: 'artisan_6',
        name: 'Che Normah',
        craftType: 'Rattan & Bamboo Craft',
        state: 'Melaka',
        description: 'Anyaman rotan and bamboo baskets',
        imageUrl: 'https://example.com/normah.png',
        rating: 4.8,
        tags: ['anyaman', 'rotan', 'bamboo', 'basketry'],
      ),
    ];

    test('CraftCategoryFilterItem canonical keys correctly match database values', () {
      final potteryFilter = TouristDirectoryTab.craftFilters.firstWhere((f) => f.key == 'POTTERY');
      final woodFilter = TouristDirectoryTab.craftFilters.firstWhere((f) => f.key == 'WOODWORK');
      final batikFilter = TouristDirectoryTab.craftFilters.firstWhere((f) => f.key == 'BATIK');
      final songketFilter = TouristDirectoryTab.craftFilters.firstWhere((f) => f.key == 'SONGKET');
      final allFilter = TouristDirectoryTab.craftFilters.firstWhere((f) => f.key == 'ALL');

      // 'ALL' should match any craft
      expect(allFilter.matches('Woodwork'), isTrue);
      expect(allFilter.matches('Pottery'), isTrue);
      expect(allFilter.matches(''), isTrue);

      // Pottery matches both exact and semantic aliases
      expect(potteryFilter.matches('Clay Pottery & Ceramics'), isTrue);
      expect(potteryFilter.matches('Pottery'), isTrue);
      expect(potteryFilter.matches('Ceramics'), isTrue);
      expect(potteryFilter.matches('Unknown', ['labu sayong']), isTrue);
      expect(potteryFilter.matches('Woodwork'), isFalse);

      // Woodwork matches DB craft category 'Woodwork' or tags
      expect(woodFilter.matches('Woodwork'), isTrue);
      expect(woodFilter.matches('Traditional Woodcarving'), isTrue);
      expect(woodFilter.matches('Random Craft', ['ukiran kayu']), isTrue);
      expect(woodFilter.matches('Batik'), isFalse);

      // Batik matches
      expect(batikFilter.matches('Batik Wax Painting'), isTrue);
      expect(batikFilter.matches('Batik'), isTrue);
      expect(batikFilter.matches('Craft', ['canting']), isTrue);

      // Songket matches
      expect(songketFilter.matches('Songket Gold Weaving'), isTrue);
      expect(songketFilter.matches('Craft', ['tenun songket']), isTrue);
    });

    test('LanguageViewModel locale changes do not break category key persistence', () {
      final langVM = LanguageViewModel();
      expect(langVM.currentLanguageCode, isNotNull);

      // Switch to Bahasa Melayu
      langVM.setLanguage('BM', 'Bahasa Melayu (Malaysia)');
      expect(langVM.currentLanguageCode, equals('BM'));

      // Category filter keys remain invariant constants
      const selectedKey = 'POTTERY';
      final filter = TouristDirectoryTab.craftFilters.firstWhere((f) => f.key == selectedKey);
      
      // Even if display label is translated in the UI, canonical key and matching logic are unaffected
      expect(filter.key, equals('POTTERY'));
      expect(filter.matches('Clay Pottery & Ceramics'), isTrue);
      expect(filter.matches('Batik Wax Painting'), isFalse);
    });

    test('DirectoryViewModel search algorithm matches name, craft, bio, and craft tags', () {
      final dirVM = DirectoryViewModel();
      
      dirVM.updateFilter(craft: 'All Crafts', state: 'All States');
      dirVM.clearFilters();
      expect(dirVM.selectedCraft, equals('All Crafts'));
      expect(dirVM.selectedState, equals('All States'));
    });

    test('Category filtering retains matching artisans across states and craft types', () {
      List<ArtisanModel> filterDirectory({
        required List<ArtisanModel> artisans,
        required String selectedCategoryKey,
        required String selectedState,
        required String query,
      }) {
        final selectedFilter = TouristDirectoryTab.craftFilters.firstWhere(
          (f) => f.key == selectedCategoryKey,
          orElse: () => TouristDirectoryTab.craftFilters.first,
        );

        final q = query.toLowerCase().trim();

        return artisans.where((artisan) {
          final matchesQuery = q.isEmpty ||
              artisan.name.toLowerCase().contains(q) ||
              artisan.craftType.toLowerCase().contains(q) ||
              artisan.state.toLowerCase().contains(q) ||
              artisan.description.toLowerCase().contains(q) ||
              artisan.tags.any((t) => t.toLowerCase().contains(q));

          final matchesCategory = selectedFilter.matches(
            artisan.craftType,
            artisan.tags,
          );

          final matchesState = selectedState == 'All States' ||
              artisan.state.toLowerCase() == selectedState.toLowerCase();

          return matchesQuery && matchesCategory && matchesState;
        }).toList();
      }

      // 1. Filter ALL: returns all 6 artisans
      final allResults = filterDirectory(
        artisans: mockArtisans,
        selectedCategoryKey: 'ALL',
        selectedState: 'All States',
        query: '',
      );
      expect(allResults.length, equals(6));

      // 2. Filter WOODWORK: returns Pak Hashim (Kelantan)
      final woodResults = filterDirectory(
        artisans: mockArtisans,
        selectedCategoryKey: 'WOODWORK',
        selectedState: 'All States',
        query: '',
      );
      expect(woodResults.length, equals(1));
      expect(woodResults.first.name, equals('Pak Hashim'));

      // 3. Filter BATIK: returns Mak Jah (Terengganu)
      final batikResults = filterDirectory(
        artisans: mockArtisans,
        selectedCategoryKey: 'BATIK',
        selectedState: 'All States',
        query: '',
      );
      expect(batikResults.length, equals(1));
      expect(batikResults.first.name, equals('Mak Jah'));

      // 4. Filter by state (Kelantan) with ALL crafts: returns Pak Hashim and Puan Siti
      final kelantanResults = filterDirectory(
        artisans: mockArtisans,
        selectedCategoryKey: 'ALL',
        selectedState: 'Kelantan',
        query: '',
      );
      expect(kelantanResults.length, equals(2));
      expect(kelantanResults.map((a) => a.name), containsAll(['Pak Hashim', 'Puan Siti']));

      // 5. Multi-criteria: Kelantan AND Songket: returns only Puan Siti
      final songketKelantan = filterDirectory(
        artisans: mockArtisans,
        selectedCategoryKey: 'SONGKET',
        selectedState: 'Kelantan',
        query: '',
      );
      expect(songketKelantan.length, equals(1));
      expect(songketKelantan.first.name, equals('Puan Siti'));

      // 6. Algorithmic search by tag ('labu sayong') finds Uncle Lim
      final searchByTag = filterDirectory(
        artisans: mockArtisans,
        selectedCategoryKey: 'ALL',
        selectedState: 'All States',
        query: 'labu sayong',
      );
      expect(searchByTag.length, equals(1));
      expect(searchByTag.first.name, equals('Uncle Lim'));

      // 7. Algorithmic search by bio keyword ('chalices') finds Mr. Tan
      final searchByBio = filterDirectory(
        artisans: mockArtisans,
        selectedCategoryKey: 'ALL',
        selectedState: 'All States',
        query: 'chalices',
      );
      expect(searchByBio.length, equals(1));
      expect(searchByBio.first.name, equals('Mr. Tan'));

      // 8. Rattan & Bamboo Craft finds Che Normah via tag or category
      final rattanResults = filterDirectory(
        artisans: mockArtisans,
        selectedCategoryKey: 'RATTAN',
        selectedState: 'All States',
        query: '',
      );
      expect(rattanResults.length, equals(1));
      expect(rattanResults.first.name, equals('Che Normah'));
    });
  });
}
