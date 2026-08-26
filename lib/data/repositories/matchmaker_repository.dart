import 'package:warisan_kita/viewmodels/craft_personality.dart';

class MatchmakerRepository {
  const MatchmakerRepository();

  List<Map<String, dynamic>> getQuestions() {
    return const [
      {
        'index': 0,
        'question': 'What type of craft experience speaks to you?',
        'subtitle': 'Select how you prefer to engage with traditional heritage',
        'options': [
          {
            'label': '🛠️ Hands-on Workshop',
            'desc': 'I want to shape clay, canting wax, or weave with my own hands',
            'traits': ['hands_on', 'clay', 'batik', 'weaving'],
          },
          {
            'label': '👁️ Observing Master Artisans',
            'desc': 'I prefer watching skilled masters demonstrate living heritage techniques',
            'traits': ['observing', 'royal', 'woodwork', 'metalwork'],
          },
          {
            'label': '📜 Cultural Lore & Philosophy',
            'desc': 'I want to learn historical folklore, spiritual symbolism, and lineage',
            'traits': ['lore', 'puppets', 'keris', 'songket'],
          },
        ],
      },
      {
        'index': 1,
        'question': 'Which studio setting do you enjoy most?',
        'subtitle': 'Pick your ideal traditional creative atmosphere',
        'options': [
          {
            'label': '🏠 Indoor Art Studio & Gallery',
            'desc': 'Structured gallery, air-conditioned studio, and curated display space',
            'traits': ['indoor', 'songket', 'pewter'],
          },
          {
            'label': '🌿 Outdoor Heritage Village',
            'desc': 'Open-air wooden kampung workshop surrounded by lush nature',
            'traits': ['outdoor', 'woodwork', 'clay', 'wau'],
          },
          {
            'label': '🌊 Riverside & Coastal Workshop',
            'desc': 'Gentle coastal breezes, natural indigo vats, and riverbank clay pits',
            'traits': ['coastal', 'batik', 'clay', 'songket'],
          },
        ],
      },
      {
        'index': 2,
        'question': 'What is your favorite craft material & texture?',
        'subtitle': 'The tactile raw element that sparks your inspiration',
        'options': [
          {
            'label': '🧵 Silky Threads & Gold Weaves',
            'desc': 'Natural-dyed silk, metallic gold Songket threads, and wax batik',
            'traits': ['textiles', 'songket', 'batik'],
          },
          {
            'label': '🏺 Natural River Clay & Earth',
            'desc': 'Ground river clay, woodsmoke kilning, and smooth terracotta vessels',
            'traits': ['clay', 'pottery', 'ceramics'],
          },
          {
            'label': '🪵 Hand-Carved Timber & Hardwood',
            'desc': 'Aromatic Chengal & Teak grain, chisel marks, and floral relief panels',
            'traits': ['woodwork', 'timber', 'carving'],
          },
          {
            'label': '🛡️ Royal Pewter & Molten Metal',
            'desc': 'Lustrous polished pewter, silver filigree, and bladesmithing metallurgy',
            'traits': ['metalwork', 'pewter', 'keris'],
          },
          {
            'label': '🪁 Bamboo, Paper & Natural Fibres',
            'desc': 'Flexible split bamboo, Wau kite paper, and shadow puppet cowhide',
            'traits': ['bamboo', 'wau', 'puppets'],
          },
        ],
      },
      {
        'index': 3,
        'question': 'Which Malaysian heritage region draws your soul?',
        'subtitle': 'Discover your cultural regional connection',
        'options': [
          {
            'label': '🌊 East Coast Coastal (Kelantan & Terengganu)',
            'desc': 'Famous for royal Songket weaving, Wau kites, and Batik canting',
            'traits': ['east_coast', 'songket', 'batik', 'wau'],
          },
          {
            'label': '🏛️ West Coast Historic Straits (Melaka & Perak)',
            'desc': 'Famous for clay Labu Sayong, Royal Pewter, and master woodcarvings',
            'traits': ['west_coast', 'clay', 'woodwork', 'metalwork'],
          },
          {
            'label': '🌴 Borneo Indigenous Traditions (Sabah & Sarawak)',
            'desc': 'Celebrated for Pua Kumbu weaving, beaded tribal arts, and woodcarving',
            'traits': ['borneo', 'weaving', 'woodwork'],
          },
        ],
      },
      {
        'index': 4,
        'question': 'What is your guiding aesthetic philosophy?',
        'subtitle': 'The artistic essence you cherish most in heritage works',
        'options': [
          {
            'label': '👑 Intricate Royal Symmetry & Opulence',
            'desc': 'Harmonious geometric patterns, gold brocade, and court prestige',
            'traits': ['songket', 'pewter', 'royal'],
          },
          {
            'label': '🌱 Earthy, Organic & Wabi-Sabi Warmth',
            'desc': 'Raw earth tones, handmade uniqueness, and natural woodsmoke patina',
            'traits': ['clay', 'woodwork', 'organic'],
          },
          {
            'label': '🎨 Vibrant Expression & Flowing Colors',
            'desc': 'Fluid wax strokes, indigo hues, and expressive floral motifs',
            'traits': ['batik', 'textiles', 'vibrant'],
          },
          {
            'label': '⚡ Ancient Mystery & Legendary Craft',
            'desc': 'Talismanic bladesmithing, folklore puppetry, and sky-bound kites',
            'traits': ['keris', 'wau', 'puppets'],
          },
        ],
      },
    ];
  }

  CraftPersonality calculatePersonality(Map<int, String> answers) {
    int scoreTextiles = 0;
    int scoreEarth = 0;
    int scoreWood = 0;
    int scoreMetal = 0;
    int scoreSky = 0;

    final preferenceTags = <String>[];

    // Evaluate answers
    for (final entry in answers.entries) {
      final val = entry.value.toLowerCase();
      preferenceTags.add(entry.value);

      // Question 0: Experience
      if (val.contains('hands-on')) {
        scoreEarth += 2;
        scoreTextiles += 2;
      } else if (val.contains('observing')) {
        scoreWood += 2;
        scoreMetal += 2;
      } else if (val.contains('lore')) {
        scoreSky += 2;
        scoreTextiles += 1;
        scoreMetal += 1;
      }

      // Question 1: Environment
      if (val.contains('indoor')) {
        scoreTextiles += 2;
        scoreMetal += 2;
      } else if (val.contains('village') || val.contains('outdoor')) {
        scoreWood += 2;
        scoreEarth += 1;
        scoreSky += 2;
      } else if (val.contains('riverside') || val.contains('coastal')) {
        scoreEarth += 2;
        scoreTextiles += 2;
      }

      // Question 2: Material & Texture (Crucial Weight)
      if (val.contains('silky') || val.contains('gold weaves') || val.contains('textile')) {
        scoreTextiles += 6;
      } else if (val.contains('clay') || val.contains('earth') || val.contains('pottery')) {
        scoreEarth += 6;
      } else if (val.contains('timber') || val.contains('wood') || val.contains('carv')) {
        scoreWood += 6;
      } else if (val.contains('pewter') || val.contains('metal') || val.contains('blade')) {
        scoreMetal += 6;
      } else if (val.contains('bamboo') || val.contains('paper') || val.contains('wau')) {
        scoreSky += 6;
      }

      // Question 3: Region
      if (val.contains('east coast')) {
        scoreTextiles += 2;
        scoreSky += 2;
      } else if (val.contains('west coast')) {
        scoreEarth += 2;
        scoreMetal += 2;
        scoreWood += 1;
      } else if (val.contains('borneo')) {
        scoreTextiles += 2;
        scoreWood += 2;
      }

      // Question 4: Aesthetic
      if (val.contains('royal symmetry') || val.contains('opulence')) {
        scoreTextiles += 3;
        scoreMetal += 2;
      } else if (val.contains('organic') || val.contains('earthy')) {
        scoreEarth += 3;
        scoreWood += 2;
      } else if (val.contains('vibrant') || val.contains('flowing')) {
        scoreTextiles += 3;
      } else if (val.contains('mystery') || val.contains('legendary')) {
        scoreMetal += 2;
        scoreSky += 3;
        scoreWood += 1;
      }
    }

    // Determine highest score archetype
    final scores = {
      'textiles': scoreTextiles,
      'earth': scoreEarth,
      'wood': scoreWood,
      'metal': scoreMetal,
      'sky': scoreSky,
    };

    String topArchetype = 'textiles';
    int maxScore = -1;
    scores.forEach((key, val) {
      if (val > maxScore) {
        maxScore = val;
        topArchetype = key;
      }
    });

    switch (topArchetype) {
      case 'earth':
        return CraftPersonality(
          title: 'The Earth Sculptor',
          tagline: 'Keeper of River Clay & Primordial Kiln Fire',
          description: 'You find tranquility in the tactile warmth of natural river clay and the alchemical transformation of wood-fired kilns. Your soul thrives on grounding, organic textures.',
          culturalLore: 'Tracing back to Perak’s iconic black Labu Sayong and Melaka riverbank ceramic workshops, turning mother earth into water vessels of life.',
          matchingCrafts: const ['Pottery', 'Ceramics', 'Clay'],
          recommendedCraftCategories: const ['Clay Pottery & Ceramics', 'Pottery & Clay', 'Handicraft & Heritage'],
          accentColorHex: '#D97706',
          iconCodePoint: 0xe395, // local_fire_department
          preferenceTags: preferenceTags,
        );

      case 'wood':
        return CraftPersonality(
          title: 'The Master Carver',
          tagline: 'Guardian of Chengal Timber & Sacred Geometry',
          description: 'You find beauty in the raw, organic strength of ancient Malaysian hardwoods. You appreciate patience, deep focus, and the deliberate carving of relief panels and keris hilts.',
          culturalLore: 'Honoring generations of Malay woodcarvers across Perak and Terengganu whose floral flora-motifs adorn royal palaces and heritage timber houses.',
          matchingCrafts: const ['Woodwork', 'Timber Craft', 'Keris'],
          recommendedCraftCategories: const ['Traditional Woodcarving', 'Carved Timber & Wood', 'Woodwork'],
          accentColorHex: '#059669',
          iconCodePoint: 0xf62c, // carpenter
          preferenceTags: preferenceTags,
        );

      case 'metal':
        return CraftPersonality(
          title: 'The Metallic Alchemist',
          tagline: 'Artisan of Royal Pewter & Enduring Metallurgy',
          description: 'You are fascinated by the lasting strength, metallic luster, and precise engineering of hand-hammered pewter, silver filigree, and bladesmithing.',
          culturalLore: 'Centuries of Malaysian metallurgy, from Royal Selangor pewter craft to traditional Keris forging in the Straits kingdoms.',
          matchingCrafts: const ['Metalwork', 'Pewter', 'Keris'],
          recommendedCraftCategories: const ['Royal Pewter & Metal', 'Metalwork & Pewter', 'Pewter Craft'],
          accentColorHex: '#0284C7',
          iconCodePoint: 0xe5a1, // shield
          preferenceTags: preferenceTags,
        );

      case 'sky':
        return CraftPersonality(
          title: 'The Sky & Puppet Artisan',
          tagline: 'Dreamer of Soaring Kites & Folk Shadows',
          description: 'You are drawn to kinetic folk art, soaring bamboo kites, and theatrical shadow puppetry that bridge the earth with the open heavens.',
          culturalLore: 'East Coast folklore mastery of Wau Bulan aerodynamic paper-cutting and Kelantanese Wayang Kulit puppetry.',
          matchingCrafts: const ['Wau Kite', 'Wayang Kulit', 'Bamboo Craft'],
          recommendedCraftCategories: const ['Wayang Kulit & Puppetry', 'Rattan & Bamboo Craft', 'Paper & Bamboo'],
          accentColorHex: '#EC4899',
          iconCodePoint: 0xe06a, // air
          preferenceTags: preferenceTags,
        );

      case 'textiles':
      default:
        return CraftPersonality(
          title: 'The Weaver of Dreams',
          tagline: 'Master of Royal Symmetry & Lyrical Threads',
          description: 'You possess a patient spirit and an innate eye for delicate symmetry. You resonate with the rhythm of wooden looms, glowing gold threads, and the silent meditation of textile craft.',
          culturalLore: 'Rooted in the royal textile courts of Terengganu and Kelantan, celebrating hand-loomed Songket and intricate natural-dye Batik canting.',
          matchingCrafts: const ['Songket', 'Batik', 'Textiles'],
          recommendedCraftCategories: const ['Batik & Songket Textiles', 'Songket Gold Weaving', 'Batik Wax Painting'],
          accentColorHex: '#8B5CF6',
          iconCodePoint: 0xe0e8, // auto_awesome
          preferenceTags: preferenceTags,
        );
    }
  }
}

