import 'package:flutter/material.dart';
import 'package:warisan_kita/data/repositories/matchmaker_repository.dart';
import 'package:warisan_kita/viewmodels/craft_personality.dart';

class MatchmakerViewModel extends ChangeNotifier {
  final MatchmakerRepository _repository;

  MatchmakerViewModel({
    MatchmakerRepository? repository,
  }) : _repository = repository ?? const MatchmakerRepository();

  final Map<int, String> _answers = {};

  Map<int, String> get answers => Map.unmodifiable(_answers);

  void setAnswer(int questionIndex, String optionLabel) {
    _answers[questionIndex] = optionLabel;
    notifyListeners();
  }

  CraftPersonality calculateResult() {
    return _repository.calculatePersonality(_answers);
  }

  void clearAnswers() {
    _answers.clear();
    notifyListeners();
  }
}