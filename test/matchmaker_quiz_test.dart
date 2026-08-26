import 'package:flutter_test/flutter_test.dart';
import 'package:warisan_kita/data/repositories/matchmaker_repository.dart';
import 'package:warisan_kita/viewmodels/matchmaker_viewmodel.dart';
import 'package:warisan_kita/domain/models/user.dart';

void main() {
  group('MatchmakerRepository Scoring Algorithm Tests', () {
    const repo = MatchmakerRepository();

    test('Questions list returns 5 comprehensive questions', () {
      final questions = repo.getQuestions();
      expect(questions.length, equals(5));
      expect(questions[0]['question'], contains('experience'));
      expect(questions[1]['question'], contains('studio setting'));
      expect(questions[2]['question'], contains('material'));
      expect(questions[3]['question'], contains('region'));
      expect(questions[4]['question'], contains('philosophy'));
    });

    test('Answers with Silky Threads & East Coast evaluate to The Weaver of Dreams', () {
      final answers = {
        0: '🛠️ Hands-on Workshop',
        1: '🏠 Indoor Art Studio & Gallery',
        2: '🧵 Silky Threads & Gold Weaves',
        3: '🌊 East Coast Coastal (Kelantan & Terengganu)',
        4: '👑 Intricate Royal Symmetry & Opulence',
      };

      final personality = repo.calculatePersonality(answers);
      expect(personality.title, equals('The Weaver of Dreams'));
      expect(personality.matchingCrafts, contains('Songket'));
      expect(personality.matchingCrafts, contains('Batik'));
      expect(personality.accentColorHex, equals('#8B5CF6'));
    });

    test('Answers with Natural River Clay evaluate to The Earth Sculptor', () {
      final answers = {
        0: '🛠️ Hands-on Workshop',
        1: '🌿 Outdoor Heritage Village',
        2: '🏺 Natural River Clay & Earth',
        3: '🏛️ West Coast Historic Straits (Melaka & Perak)',
        4: '🌱 Earthy, Organic & Wabi-Sabi Warmth',
      };

      final personality = repo.calculatePersonality(answers);
      expect(personality.title, equals('The Earth Sculptor'));
      expect(personality.matchingCrafts, contains('Pottery'));
      expect(personality.matchingCrafts, contains('Ceramics'));
    });

    test('Answers with Hand-Carved Timber evaluate to The Master Carver', () {
      final answers = {
        0: '👁️ Observing Master Artisans',
        1: '🌿 Outdoor Heritage Village',
        2: '🪵 Hand-Carved Timber & Hardwood',
        3: '🏛️ West Coast Historic Straits (Melaka & Perak)',
        4: '🌱 Earthy, Organic & Wabi-Sabi Warmth',
      };

      final personality = repo.calculatePersonality(answers);
      expect(personality.title, equals('The Master Carver'));
      expect(personality.matchingCrafts, contains('Woodwork'));
    });

    test('Answers with Royal Pewter evaluate to The Metallic Alchemist', () {
      final answers = {
        0: '👁️ Observing Master Artisans',
        1: '🏠 Indoor Art Studio & Gallery',
        2: '🛡️ Royal Pewter & Molten Metal',
        3: '🏛️ West Coast Historic Straits (Melaka & Perak)',
        4: '👑 Intricate Royal Symmetry & Opulence',
      };

      final personality = repo.calculatePersonality(answers);
      expect(personality.title, equals('The Metallic Alchemist'));
      expect(personality.matchingCrafts, contains('Pewter'));
      expect(personality.matchingCrafts, contains('Metalwork'));
    });

    test('Answers with Bamboo & Paper evaluate to The Sky & Puppet Artisan', () {
      final answers = {
        0: '📜 Cultural Lore & Philosophy',
        1: '🌿 Outdoor Heritage Village',
        2: '🪁 Bamboo, Paper & Natural Fibres',
        3: '🌊 East Coast Coastal (Kelantan & Terengganu)',
        4: '⚡ Ancient Mystery & Legendary Craft',
      };

      final personality = repo.calculatePersonality(answers);
      expect(personality.title, equals('The Sky & Puppet Artisan'));
      expect(personality.matchingCrafts, contains('Wau Kite'));
      expect(personality.matchingCrafts, contains('Wayang Kulit'));
    });
  });

  group('MatchmakerViewModel State & UserModel Integration Tests', () {
    test('loadFromUser populates answers and personality from UserModel', () {
      final vm = MatchmakerViewModel();
      final user = UserModel(
        id: 'u1',
        email: 'tourist@warisankita.my',
        username: 'aiman',
        role: 'Tourist',
        craftPersonalityTitle: 'The Earth Sculptor',
        craftPersonalityDescription: 'Keeper of River Clay',
        matchedCrafts: const ['Pottery', 'Ceramics'],
        quizAnswers: const {
          0: '🛠️ Hands-on Workshop',
          1: '🌿 Outdoor Heritage Village',
          2: '🏺 Natural River Clay & Earth',
          3: '🏛️ West Coast Historic Straits (Melaka & Perak)',
          4: '🌱 Earthy, Organic & Wabi-Sabi Warmth',
        },
      );

      vm.loadFromUser(user);
      expect(vm.hasCompletedQuiz, isTrue);
      expect(vm.answers.length, equals(5));
      expect(vm.currentPersonality?.title, equals('The Earth Sculptor'));
      expect(vm.matchedCrafts, contains('Pottery'));
    });

    test('setAnswer dynamically updates live personality', () {
      final vm = MatchmakerViewModel();
      expect(vm.answers.isEmpty, isTrue);

      vm.setAnswer(2, '🪵 Hand-Carved Timber & Hardwood');
      expect(vm.answers[2], equals('🪵 Hand-Carved Timber & Hardwood'));
      expect(vm.currentPersonality?.title, equals('The Master Carver'));
    });
  });
}
