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
  /// Calculates a culturally authentic Malaysian craft personality based on a 6-question weighted quiz:
  /// - Q1: Activity satisfying (Painting flowing patterns, Shaping by hand, Carving details, Forming metal)
  /// - Q2: Learning style (Experiment immediately, Watch a master first, Follow clear steps, Explore history)
  /// - Q3: Working environment (Colourful textile, Quiet pottery, Open-air village wood, Precise metalworking)
  /// - Q4: What matters most (Expressive colour, Useful object, Intricate detail, Strength & accuracy)
  /// - Q5: Pace (Free-flowing, Calm and repetitive, Slow and focused, Methodical and exact)
  /// - Q6: Heritage story (Batik & songket, Labu Sayong, Ukiran Melayu, Pewter & keris)
  CraftPersonality calculatePersonality(Map<int, String> answers) {
    final craftScores = <String, int>{
      'Textile': 0,
      'Pottery': 0,
      'Wood': 0,
      'Metal': 0,
    };

    final traitScores = <String, int>{
      'creativity': 0,
      'tactile': 0,
      'patience': 0,
      'precision': 0,
      'hands-on': 0,
      'observation': 0,
      'structure': 0,
      'cultural depth': 0,
    };

    void addCraft(String craft, int points) {
      craftScores[craft] = (craftScores[craft] ?? 0) + points;
    }

    void addTrait(String trait, int points) {
      traitScores[trait] = (traitScores[trait] ?? 0) + points;
    }

    // Question 1: Activity
    final q1 = answers[0]?.toLowerCase() ?? '';
    if (q1.contains('paint') || q1.contains('pattern') || q1.contains('textile')) {
      addCraft('Textile', 3);
      addCraft('Wood', 1);
      addTrait('creativity', 2);
    } else if (q1.contains('shap') || q1.contains('hand') || q1.contains('potter')) {
      addCraft('Pottery', 3);
      addCraft('Metal', 1);
      addTrait('tactile', 2);
    } else if (q1.contains('carv') || q1.contains('detail') || q1.contains('wood')) {
      addCraft('Wood', 3);
      addCraft('Textile', 1);
      addTrait('patience', 2);
    } else if (q1.contains('metal') || q1.contains('polish') || q1.contains('pewter')) {
      addCraft('Metal', 3);
      addCraft('Pottery', 1);
      addTrait('precision', 2);
    }

    // Question 2: Learning preference
    final q2 = answers[1]?.toLowerCase() ?? '';
    if (q2.contains('experiment') || q2.contains('immediately') || q2.contains('hands-on')) {
      addTrait('hands-on', 2);
      addCraft('Pottery', 1);
      addCraft('Textile', 1);
    } else if (q2.contains('watch') || q2.contains('master') || q2.contains('observ')) {
      addTrait('observation', 2);
      addCraft('Wood', 1);
      addCraft('Metal', 1);
    } else if (q2.contains('step') || q2.contains('clear') || q2.contains('structur')) {
      addTrait('structure', 2);
      addCraft('Metal', 1);
      addCraft('Wood', 1);
    } else if (q2.contains('history') || q2.contains('cultural')) {
      addTrait('cultural depth', 2);
      addCraft('Textile', 1);
      addCraft('Pottery', 1);
    }

    // Question 3: Working environment
    final q3 = answers[2]?.toLowerCase() ?? '';
    if (q3.contains('textile') || q3.contains('colourful') || q3.contains('batik')) {
      addCraft('Textile', 3);
      addCraft('Wood', 1);
      addTrait('creativity', 1);
    } else if (q3.contains('pottery') || q3.contains('quiet') || q3.contains('clay')) {
      addCraft('Pottery', 3);
      addCraft('Metal', 1);
      addTrait('tactile', 1);
    } else if (q3.contains('village') || q3.contains('open-air') || q3.contains('wood')) {
      addCraft('Wood', 3);
      addCraft('Pottery', 1);
      addTrait('observation', 1);
    } else if (q3.contains('metal') || q3.contains('precise') || q3.contains('pewter')) {
      addCraft('Metal', 3);
      addCraft('Textile', 1);
      addTrait('precision', 1);
    }

    // Question 4: What matters most
    final q4 = answers[3]?.toLowerCase() ?? '';
    if (q4.contains('colour') || q4.contains('symbolism') || q4.contains('expressive')) {
      addCraft('Textile', 3);
      addCraft('Pottery', 1);
      addTrait('creativity', 2);
    } else if (q4.contains('useful') || q4.contains('personal') || q4.contains('touch')) {
      addCraft('Pottery', 3);
      addCraft('Wood', 1);
      addTrait('tactile', 2);
    } else if (q4.contains('intricate') || q4.contains('natural') || q4.contains('beauty')) {
      addCraft('Wood', 3);
      addCraft('Metal', 1);
      addTrait('patience', 2);
    } else if (q4.contains('strength') || q4.contains('accuracy') || q4.contains('lasting')) {
      addCraft('Metal', 3);
      addCraft('Wood', 1);
      addTrait('precision', 2);
    }

    // Question 5: Pace
    final q5 = answers[4]?.toLowerCase() ?? '';
    if (q5.contains('free-flowing') || q5.contains('expressive')) {
      addCraft('Textile', 3);
      addCraft('Pottery', 1);
      addTrait('creativity', 2);
    } else if (q5.contains('calm') || q5.contains('repetitive')) {
      addCraft('Pottery', 3);
      addCraft('Textile', 1);
      addTrait('tactile', 2);
    } else if (q5.contains('slow') || q5.contains('focused')) {
      addCraft('Wood', 3);
      addCraft('Metal', 1);
      addTrait('patience', 2);
    } else if (q5.contains('methodical') || q5.contains('exact')) {
      addCraft('Metal', 3);
      addCraft('Wood', 1);
      addTrait('precision', 2);
    }

    // Question 6: Heritage story
    final q6 = answers[5]?.toLowerCase() ?? '';
    if (q6.contains('batik') || q6.contains('songket')) {
      addCraft('Textile', 3);
      addCraft('Wood', 1);
      addTrait('cultural depth', 2);
    } else if (q6.contains('labu') || q6.contains('sayong') || q6.contains('ceramic')) {
      addCraft('Pottery', 3);
      addCraft('Textile', 1);
      addTrait('cultural depth', 2);
    } else if (q6.contains('ukiran') || q6.contains('melayu') || q6.contains('architectural')) {
      addCraft('Wood', 3);
      addCraft('Metal', 1);
      addTrait('cultural depth', 2);
    } else if (q6.contains('pewter') || q6.contains('keris')) {
      addCraft('Metal', 3);
      addCraft('Wood', 1);
      addTrait('cultural depth', 2);
    }

    // Backward-compatible fallback for legacy 4-question answers if q5 and q6 are not provided
    if (answers.length < 5) {
      for (final val in answers.values) {
        final v = val.toLowerCase();
        if (v.contains('batik') || v.contains('songket') || v.contains('textile')) {
          addCraft('Textile', 4);
          addTrait('creativity', 2);
        } else if (v.contains('potter') || v.contains('clay') || v.contains('sayong')) {
          addCraft('Pottery', 4);
          addTrait('tactile', 2);
        } else if (v.contains('wood') || v.contains('timber') || v.contains('ukiran')) {
          addCraft('Wood', 4);
          addTrait('patience', 2);
        } else if (v.contains('pewter') || v.contains('metal') || v.contains('keris')) {
          addCraft('Metal', 4);
          addTrait('precision', 2);
        }
      }
    }

    // Determine ranking
    final sortedCrafts = craftScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final firstCraft = sortedCrafts[0].key;
    final firstScore = sortedCrafts[0].value;
    final secondCraft = sortedCrafts[1].key;
    final secondScore = sortedCrafts[1].value;

    // Check for a tie between top crafts (both > 0 and equal)
    final bool isTie = firstScore > 0 && firstScore == secondScore;

    // Top trait determination
    final sortedTraits = traitScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topTrait = sortedTraits.first.key;

    String title;
    String tagline;
    String description;
    String primaryCategory;
    String? secondaryCategory;
    List<String> matchingCrafts;
    String badgeIconName;
    bool isBlended = false;
    List<String> blendedCategories = const [];

    String mapToCategory(String c) {
      switch (c) {
        case 'Textile':
          return 'Batik & Songket';
        case 'Pottery':
          return 'Pottery & Ceramics';
        case 'Wood':
          return 'Wood Carving';
        case 'Metal':
          return 'Royal Pewter & Metal';
        default:
          return 'All Crafts';
      }
    }

    if (isTie) {
      isBlended = true;
      blendedCategories = [firstCraft, secondCraft];
      title = 'The Material Explorer — $firstCraft & $secondCraft';
      tagline = 'Harmonious Fusion of Traditional $firstCraft and $secondCraft Heritage';
      description =
          'You possess an inquisitive and versatile craft spirit, naturally appreciating the balance between $firstCraft and $secondCraft techniques in Malaysian cultural arts.';
      primaryCategory = mapToCategory(firstCraft);
      secondaryCategory = mapToCategory(secondCraft);
      badgeIconName = 'explore_rounded';
      matchingCrafts = [
        primaryCategory,
        secondaryCategory,
        'Heritage Handcrafts',
      ];
    } else {
      primaryCategory = mapToCategory(firstCraft);
      secondaryCategory = mapToCategory(secondCraft);

      switch (firstCraft) {
        case 'Textile':
          badgeIconName = 'palette_rounded';
          matchingCrafts = const ['Batik & Songket', 'Songket Weaving', 'Batik Canting', 'Textile Arts'];
          if (topTrait == 'precision') {
            title = 'The Pattern and Songket Specialist';
            tagline = 'Master of Symmetrical Songket Weaves & Geometric Accuracy';
            description = 'You have a sharp eye for meticulous geometric arrangements, golden songket wefts, and disciplined textile patterns.';
          } else if (topTrait == 'cultural depth') {
            title = 'The Royal Textile Historian';
            tagline = 'Guardian of Royal Kelantan & Terengganu Silk Legacies';
            description = 'You are fascinated by the rich courtly traditions, natural dye heritage, and historical motifs of Malaysian textiles.';
          } else {
            // Default Textile trait: creativity
            title = 'The Expressive Textile Storyteller';
            tagline = 'Painter of Flowing Canting Motifs & Vibrancy';
            description = 'You connect with the emotional freedom of wax-resist painting, flowing dyes, and spontaneous batik expression.';
          }
          break;

        case 'Pottery':
          badgeIconName = 'brush_rounded';
          matchingCrafts = const ['Pottery & Ceramics', 'Labu Sayong', 'Ceramic Pottery', 'Terracotta'];
          if (topTrait == 'precision') {
            title = 'The Master Ceramic Artisan';
            tagline = 'Creator of Balanced Vessels & Kiln-Fired Ceramics';
            description = 'You strive for symmetry, smooth contours, and structural harmony in ceramic craftsmanship.';
          } else if (topTrait == 'patience') {
            title = 'The Serene Kiln Potter';
            tagline = 'Patient Crafter of Traditional Earthenware & Smoke-Fired Pots';
            description = 'You find solace in the slow curing of clay, natural drying cycles, and time-honoured pottery firing.';
          } else {
            // Default Pottery trait: tactile
            title = 'The Earthen Form Maker';
            tagline = 'Shaper of Raw Earth into Soulful Heritage Vessels';
            description = 'You seek deep physical connection with malleable clay, shaping smooth curves and tactile Labu Sayong forms by hand.';
          }
          break;

        case 'Wood':
          badgeIconName = 'handyman_rounded';
          matchingCrafts = const ['Wood Carving', 'Traditional Ukiran', 'Keris Hilt Carving', 'Timber Sculpting'];
          if (topTrait == 'precision') {
            title = 'The Master Wood Sculptor';
            tagline = 'Carver of Crisp Bunga Ukir Curves & Architectural Timbers';
            description = 'You demand razor-sharp chiseling, geometric symmetry, and high-precision floral relief in architectural wood.';
          } else if (topTrait == 'creativity') {
            title = 'The Architectural Timber Artisan';
            tagline = 'Designer of Expressive Malay Carving Motifs';
            description = 'You celebrate the living organic forms of timber, blending traditional motifs with creative flair.';
          } else {
            // Default Wood trait: patience
            title = 'The Heritage Detail Carver';
            tagline = 'Guardian of Intricate Ukiran Melayu & Quiet Focus';
            description = 'You value stillness and patience, carving layer upon layer of delicate Bunga Ukir reliefs into seasoned tropical hardwoods.';
          }
          break;

        case 'Metal':
        default:
          badgeIconName = 'auto_awesome_rounded';
          matchingCrafts = const ['Royal Pewter & Metal', 'Pewter Casting', 'Keris Forging', 'Metalwork'];
          if (topTrait == 'patience') {
            title = 'The Dedicated Bladesmith';
            tagline = 'Forgemaster of Layered Keris Damascus & Hot Anvils';
            description = 'You honor the ancient discipline of heating, folding, and hammering sacred alloys into Malaysian blades.';
          } else {
            // Default Metal trait: precision
            title = 'The Traditional Metal Craftsperson';
            tagline = 'Forming and Polishing Pewter & Heritage Metalworks';
            description = 'You revere metallurgical brilliance, fine polish, and the lasting strength of hand-turned pewter and forged metals.';
          }
          break;
      }
    }

    final preferenceTags = <String>[
      if (isTie) 'Blended Explorer' else firstCraft,
      if (isTie) '$firstCraft & $secondCraft' else secondCraft,
      topTrait,
      ...answers.values,
    ];

    return CraftPersonality(
      title: title,
      tagline: tagline,
      description: description,
      matchingCrafts: matchingCrafts,
      primaryCategory: primaryCategory,
      secondaryCategory: secondaryCategory,
      preferenceTags: preferenceTags,
      experienceType: answers[0],
      environment: answers[2],
      material: isTie ? '$firstCraft & $secondCraft' : firstCraft,
      region: answers[5] ?? 'Malaysia Heritage',
      badgeIconName: badgeIconName,
      completedAt: DateTime.now(),
      craftScores: craftScores,
      traitScores: traitScores,
      topTrait: topTrait,
      isBlended: isTie,
      blendedCategories: blendedCategories,
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
