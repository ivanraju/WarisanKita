import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warisan_kita/data/repositories/matchmaker_repository.dart';
import 'package:warisan_kita/domain/models/user.dart';
import 'package:warisan_kita/viewmodels/craft_personality.dart';

class MatchmakerViewModel extends ChangeNotifier {
  final MatchmakerRepository _repository;

  static const String _keyPrefPrefix = 'wk_quiz_preferences_';
  static const String _keyPersonalityPrefix = 'wk_quiz_personality_';

  MatchmakerViewModel({
    MatchmakerRepository? repository,
  }) : _repository = repository ?? const MatchmakerRepository();

  final Map<int, String> _answers = {};
  CraftPersonality? _currentPersonality;

  Map<int, String> get answers => Map.unmodifiable(_answers);
  CraftPersonality? get currentPersonality => _currentPersonality;
  bool get hasCompletedQuiz => _answers.length >= 4 || _currentPersonality != null;
  List<String> get matchedCrafts => _currentPersonality?.matchingCrafts ?? const ['Songket', 'Batik'];
  List<String> get preferenceTags => _currentPersonality?.preferenceTags ?? _answers.values.toList();

  List<Map<String, dynamic>> get questions => _repository.getQuestions();

  void loadFromUser(UserModel? user) {
    if (user == null) return;

    if (user.quizAnswers.isNotEmpty) {
      _answers.clear();
      _answers.addAll(user.quizAnswers);
    }

    if (user.craftPersonalityTitle != null && user.craftPersonalityTitle!.isNotEmpty) {
      _currentPersonality = _repository.calculatePersonality(_answers.isNotEmpty ? _answers : {
        0: '🛠️ Hands-on Workshop',
        1: '🏠 Indoor Art Studio & Gallery',
        2: '🧵 Silky Threads & Gold Weaves',
        3: '🌊 East Coast Coastal (Kelantan & Terengganu)',
        4: '👑 Intricate Royal Symmetry & Opulence',
      });
    } else if (_answers.isNotEmpty) {
      _currentPersonality = _repository.calculatePersonality(_answers);
    }

    notifyListeners();
  }

  Future<void> restoreFromStorage(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawAnswers = prefs.getString('$_keyPrefPrefix$email');
      if (rawAnswers != null && rawAnswers.isNotEmpty) {
        final decoded = jsonDecode(rawAnswers) as Map<String, dynamic>;
        _answers.clear();
        decoded.forEach((k, v) {
          final idx = int.tryParse(k);
          if (idx != null && v != null) {
            _answers[idx] = v.toString();
          }
        });
        if (_answers.isNotEmpty) {
          _currentPersonality = _repository.calculatePersonality(_answers);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error restoring matchmaker preferences: $e');
    }
  }

  void setAnswer(int questionIndex, String optionLabel) {
    _answers[questionIndex] = optionLabel;
    _currentPersonality = _repository.calculatePersonality(_answers);
    notifyListeners();
  }

  void setAllAnswers(Map<int, String> answers) {
    _answers.clear();
    _answers.addAll(answers);
    _currentPersonality = _repository.calculatePersonality(_answers);
    notifyListeners();
  }

  CraftPersonality calculateResult() {
    final result = _repository.calculatePersonality(_answers);
    _currentPersonality = result;
    return result;
  }

  Future<CraftPersonality> saveQuiz(String email) async {
    final personality = calculateResult();
    try {
      final prefs = await SharedPreferences.getInstance();
      final answersMap = <String, String>{};
      _answers.forEach((k, v) => answersMap[k.toString()] = v);
      await prefs.setString('$_keyPrefPrefix$email', jsonEncode(answersMap));
      await prefs.setString('$_keyPersonalityPrefix$email', jsonEncode(personality.toMap()));
    } catch (e) {
      debugPrint('Error persisting quiz to storage: $e');
    }
    notifyListeners();
    return personality;
  }

  void clearAnswers() {
    _answers.clear();
    _currentPersonality = null;
    notifyListeners();
  }
}