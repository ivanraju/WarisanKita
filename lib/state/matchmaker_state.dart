import 'package:flutter/material.dart';
import 'package:warisan_kita/models/matchmaker_models.dart';

class MatchmakerState extends ChangeNotifier {
  final Map<int, String> _answers = {};
  
  void setAnswer(int questionIndex, String optionLabel) {
    _answers[questionIndex] = optionLabel;
    notifyListeners();
  }

  CraftPersonality calculateResult() {
    final texture = _answers[1] ?? 'Silky Threads'; 
    
    if (texture == 'Silky Threads') {
      return CraftPersonality(
        title: 'The Weaver of Dreams',
        description: 'You possess a patient spirit and an eye for intricate symmetry. You resonate with the rhythmic dance of the Songket loom and the delicate application of wax in Batik.',
        matchingCrafts: ['Songket', 'Batik'],
      );
    } else {
      return CraftPersonality(
        title: 'The Master of Form',
        description: 'You find beauty in the raw, organic strength of nature. Your spirit is matched with the physical mastery of hand-carving and the shaping of ancient metals.',
        matchingCrafts: ['Woodwork', 'Keris'],
      );
    }
  }
}
