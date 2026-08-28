import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warisan_kita/viewmodels/craft_personality.dart';

class MatchmakerRepository {
  static const String _keyPrefixPersonality = 'wk_craft_personality_';
  static const String _keyPrefixAnswers = 'wk_craft_quiz_answers_';

  const MatchmakerRepository();

  /// Calculates a culturally authentic Malaysian craft personality based on 4 quiz answers:
  /// - answers[0]: Experience Type ('Hands-on Workshop' or 'Observing Master Artisans')
  /// - answers[1]: Studio Setting ('Indoor Studio' or 'Outdoor Village')
  /// - answers[2]: Material Preference ('Pottery & Clay', 'Batik & Songket Textiles', 'Carved Timber & Wood', 'Royal Pewter & Metal')
  /// - answers[3]: Heritage Region ('East Coast Heritage' or 'West Coast Historic')
  CraftPersonality calculatePersonality(Map<int, String> answers) {
    final exp = answers[0] ?? 'Hands-on Workshop';
    final env = answers[1] ?? 'Indoor Studio';
    final mat = answers[2] ?? (answers[1] == 'Hand-Carved Grain' ? 'Carved Timber & Wood' : 'Batik & Songket Textiles');
    final reg = answers[3] ?? 'East Coast Heritage';

    final preferenceTags = <String>[
      if (answers.containsKey(0)) exp,
      if (answers.containsKey(1)) env,
      if (answers.containsKey(2)) mat,
      if (answers.containsKey(3)) reg,
    ];

    String title;
    String tagline;
    String description;
    List<String> matchingCrafts;
    String primaryCategory;
    String badgeIconName;

    if (mat.contains('Batik') || mat.contains('Songket') || mat.contains('Textile')) {
      primaryCategory = 'Batik & Songket';
      badgeIconName = 'palette_rounded';

      if (reg.contains('East Coast')) {
        title = 'The Royal Textile Connoisseur';
        tagline = 'Master of East Coast Canting, Waxing & Golden Songket Weaves';
        description = 'You are deeply enchanted by the shimmering motifs of Kelantan and Terengganu Songket, delicate wax-resist canting, and the rhythmic symmetry of heritage looms.';
        matchingCrafts = const ['Batik & Songket', 'Songket Weaving', 'Batik Canting', 'Wau Kite Making'];
      } else {
        title = 'The Contemporary Silk Artisan';
        tagline = 'Revitalizer of Modern Batik Patterns & Heritage Dyes';
        description = 'You appreciate the vibrant adaptation of traditional batik motifs in contemporary studios and historic trade hubs across the Malaysian heritage landscape.';
        matchingCrafts = const ['Batik & Songket', 'Batik Silk Painting', 'Textile Arts'];
      }
    } else if (mat.contains('Pottery') || mat.contains('Clay') || mat.contains('Ceramic')) {
      primaryCategory = 'Pottery & Ceramics';
      badgeIconName = 'brush_rounded';

      if (reg.contains('West Coast')) {
        title = 'The Earthen Alchemist';
        tagline = 'Guardian of Traditional Labu Sayong Terracotta & Kiln Firing';
        description = 'You find peace and tactile focus in moulding raw earth. Your spirit connects with the iconic smoky black clay of Kuala Kangsar Labu Sayong water vessels.';
        matchingCrafts = const ['Pottery & Ceramics', 'Labu Sayong', 'Ceramic Pottery'];
      } else {
        title = 'The Clay & Terra Sculptor';
        tagline = 'Sculptor of Heritage Pots, Clay Vessels & Earthenware';
        description = 'You thrive when shaping cool, malleable clay with your hands, creating functional heritage earthenware touched by ancient coastal traditions.';
        matchingCrafts = const ['Pottery & Ceramics', 'Terracotta Sculpting', 'Ceramics'];
      }
    } else if (mat.contains('Timber') || mat.contains('Wood')) {
      primaryCategory = 'Wood Carving';
      badgeIconName = 'handyman_rounded';
      title = 'The Master Wood Sculptor';
      tagline = 'Carver of Intricate Ukiran Motifs & Architectural Timbers';
      description = 'You are captivated by the organic grains of cengal and merbau timber, the delicate curves of Bunga Ukir floral carvings, and traditional wooden craftsmanship.';
      matchingCrafts = const ['Wood Carving', 'Traditional Ukiran', 'Keris Hilt Carving'];
    } else if (mat.contains('Pewter') || mat.contains('Metal')) {
      primaryCategory = 'Royal Pewter & Metal';
      badgeIconName = 'auto_awesome_rounded';
      title = 'The Royal Pewter & Blade Artisan';
      tagline = 'Master of Metallic Luster, Pewter Casting & Keris Forging';
      description = 'You admire the precision, metallurgical brilliance, and timeless legacy of Malaysian pewter casting and traditional keris bladesmithing.';
      matchingCrafts = const ['Royal Pewter & Metal', 'Pewter Casting', 'Keris Forging'];
    } else {
      // General Heritage Explorer fallback
      primaryCategory = 'All Crafts';
      badgeIconName = 'explore_rounded';
      title = 'The Heritage Explorer';
      tagline = 'Seeker of Diverse Malaysian Traditional Arts & Handcrafts';
      description = 'You appreciate the vast cultural tapestry of Malaysian craftsmanship, from textile looms and wood carvings to pottery kilns.';
      matchingCrafts = const ['Batik & Songket', 'Pottery & Ceramics', 'Wood Carving'];
    }

    return CraftPersonality(
      title: title,
      tagline: tagline,
      description: description,
      matchingCrafts: matchingCrafts,
      primaryCategory: primaryCategory,
      preferenceTags: preferenceTags.isNotEmpty ? preferenceTags : [mat, reg, exp, env],
      experienceType: exp,
      environment: env,
      material: mat,
      region: reg,
      badgeIconName: badgeIconName,
      completedAt: DateTime.now(),
    );
  }

  /// Persist quiz answers and calculated personality to SharedPreferences
  Future<void> saveQuizData({
    required Map<int, String> answers,
    required CraftPersonality personality,
    String? userEmail,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKey = (userEmail != null && userEmail.trim().isNotEmpty)
          ? userEmail.trim().toLowerCase()
          : 'guest';

      final encodedAnswers = jsonEncode(
        answers.map((key, value) => MapEntry(key.toString(), value)),
      );
      final encodedPersonality = jsonEncode(personality.toMap());

      await prefs.setString('$_keyPrefixAnswers$userKey', encodedAnswers);
      await prefs.setString('$_keyPrefixPersonality$userKey', encodedPersonality);
      debugPrint('Saved craft quiz data for user: $userKey');
    } catch (e) {
      debugPrint('Error saving quiz data to SharedPreferences: $e');
    }
  }

  /// Restores persisted CraftPersonality from SharedPreferences
  Future<CraftPersonality?> getSavedPersonality({String? userEmail}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKey = (userEmail != null && userEmail.trim().isNotEmpty)
          ? userEmail.trim().toLowerCase()
          : 'guest';

      final rawPersonality = prefs.getString('$_keyPrefixPersonality$userKey');
      if (rawPersonality != null && rawPersonality.isNotEmpty) {
        final decoded = jsonDecode(rawPersonality) as Map<String, dynamic>;
        return CraftPersonality.fromMap(decoded);
      }
    } catch (e) {
      debugPrint('Error retrieving saved personality from SharedPreferences: $e');
    }
    return null;
  }

  /// Restores persisted raw answers map from SharedPreferences
  Future<Map<int, String>?> getSavedAnswers({String? userEmail}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKey = (userEmail != null && userEmail.trim().isNotEmpty)
          ? userEmail.trim().toLowerCase()
          : 'guest';

      final rawAnswers = prefs.getString('$_keyPrefixAnswers$userKey');
      if (rawAnswers != null && rawAnswers.isNotEmpty) {
        final decoded = jsonDecode(rawAnswers) as Map<String, dynamic>;
        final Map<int, String> result = {};
        decoded.forEach((key, value) {
          final intKey = int.tryParse(key);
          if (intKey != null && value is String) {
            result[intKey] = value;
          }
        });
        return result;
      }
    } catch (e) {
      debugPrint('Error retrieving saved answers from SharedPreferences: $e');
    }
    return null;
  }

  /// Clears persisted quiz answers and personality
  Future<void> clearSavedPreferences({String? userEmail}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKey = (userEmail != null && userEmail.trim().isNotEmpty)
          ? userEmail.trim().toLowerCase()
          : 'guest';

      await prefs.remove('$_keyPrefixAnswers$userKey');
      await prefs.remove('$_keyPrefixPersonality$userKey');
    } catch (e) {
      debugPrint('Error clearing saved quiz data: $e');
    }
  }
}
