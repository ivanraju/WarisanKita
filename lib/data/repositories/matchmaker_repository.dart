import 'package:warisan_kita/viewmodels/craft_personality.dart';

class MatchmakerRepository {
  const MatchmakerRepository();

  CraftPersonality calculatePersonality(Map<int, String> answers) {
    final texture = answers[1] ?? 'Silky Threads';
    if (texture == 'Silky Threads') {
      return CraftPersonality(
        title: 'The Weaver of Dreams',
        description: 'You possess a patient spirit and an eye for intricate symmetry.',
        matchingCrafts: const ['Songket', 'Batik'],
      );
    }
    return CraftPersonality(
      title: 'The Master of Form',
      description: 'You find beauty in the raw, organic strength of nature.',
      matchingCrafts: const ['Woodwork', 'Keris'],
    );
  }
}
