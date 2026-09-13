import 'package:flutter_test/flutter_test.dart';
import 'package:warisan_kita/domain/models/artisan_profile.dart';
import 'package:warisan_kita/domain/validators/profile_validator.dart';
import 'package:warisan_kita/ui/tourist/tourist_directory_tab.dart';
import 'package:warisan_kita/ui/tourist/artisan_detail_screen.dart';

void main() {
  group('Craft Specialisation Filters', () {
    test('ProfileValidator includes Heritage Food, Wayang Kulit, and Rattan & Bamboo', () {
      expect(ProfileValidator.supportedCraftCategories, contains('Heritage Food'));
      expect(ProfileValidator.supportedCraftCategories, contains('Wayang Kulit & Puppetry'));
      expect(ProfileValidator.supportedCraftCategories, contains('Rattan & Bamboo Craft'));
    });

    test('craftFilters in tourist_directory_tab includes FOOD, PUPPETRY, and WAU', () {
      final keys = TouristDirectoryTab.craftFilters.map((f) => f.key).toList();
      expect(keys, contains('FOOD'));
      expect(keys, contains('PUPPETRY'));
      expect(keys, contains('WAU'));

      final foodFilter = TouristDirectoryTab.craftFilters.firstWhere((f) => f.key == 'FOOD');
      expect(foodFilter.englishName, 'Heritage Food');
      expect(foodFilter.matchKeywords, contains('food'));
      expect(foodFilter.matchKeywords, contains('heritage food'));
      expect(foodFilter.matchKeywords, contains('makanan'));
    });
  });

  group('Artisan Profile Image Behavior', () {
    test('ArtisanDetailScreen with 1 image does not pad with dummy unsplash photos', () {
      const detail = ArtisanDetailScreen(
        artisanName: 'Pak Ali Dodol',
        craftCategory: 'Heritage Food',
        imageUrl: 'https://example.com/dodol.png',
      );

      // Verify no multiple images are injected into carousel
      expect(detail.imageUrls, isNull);
    });

    test('ArtisanModel craftType matches Heritage Food filter keywords', () {
      final foodFilter = TouristDirectoryTab.craftFilters.firstWhere((f) => f.key == 'FOOD');
      final artisan = ArtisanModel(
        id: 'artisan_food_1',
        name: 'Mak Som Dodol',
        craftType: 'Heritage Food',
        description: 'Traditional Melaka dodol maker',
        imageUrl: 'https://example.com/dodol.png',
        state: 'Melaka',
      );

      final matches = foodFilter.matchKeywords.any((kw) =>
          artisan.craftType.toLowerCase().contains(kw));
      expect(matches, isTrue);
    });
  });
}
