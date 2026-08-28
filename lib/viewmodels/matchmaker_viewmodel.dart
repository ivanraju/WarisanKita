import 'package:flutter/material.dart';
import 'package:warisan_kita/data/repositories/matchmaker_repository.dart';
import 'package:warisan_kita/viewmodels/craft_personality.dart';

class MatchmakerViewModel extends ChangeNotifier {
  final MatchmakerRepository _repository;
  String? _currentUserEmail;

  MatchmakerViewModel({
    MatchmakerRepository? repository,
    String? initialUserEmail,
  })  : _repository = repository ?? const MatchmakerRepository(),
        _currentUserEmail = initialUserEmail {
    loadSavedPreferences(userEmail: initialUserEmail);
  }

  final Map<int, String> _answers = {};
  CraftPersonality? _currentPersonality;
  bool _isLoading = false;

  Map<int, String> get answers => Map.unmodifiable(_answers);
  CraftPersonality? get currentPersonality => _currentPersonality;
  bool get isLoading => _isLoading;
  bool get isQuizCompleted => _currentPersonality != null || _answers.length >= 4;

  List<String> get preferenceTags =>
      _currentPersonality?.preferenceTags.isNotEmpty == true
          ? _currentPersonality!.preferenceTags
          : _answers.values.toList();

  String? get experienceType => _answers[0] ?? _currentPersonality?.experienceType;
  String? get environment => _answers[1] ?? _currentPersonality?.environment;
  String? get material => _answers[2] ?? _currentPersonality?.material;
  String? get region => _answers[3] ?? _currentPersonality?.region;
  List<String> get matchingCrafts => _currentPersonality?.matchingCrafts ?? const [];
  String get primaryCategory => _currentPersonality?.primaryCategory ?? 'All Crafts';

  /// Update user context (e.g. after login/logout)
  void updateUserContext(String? email) {
    if (_currentUserEmail != email) {
      _currentUserEmail = email;
      loadSavedPreferences(userEmail: email);
    }
  }

  /// Load persisted quiz answers and craft personality from storage
  Future<void> loadSavedPreferences({String? userEmail}) async {
    final targetEmail = userEmail ?? _currentUserEmail;
    _isLoading = true;
    notifyListeners();

    try {
      final savedPersonality = await _repository.getSavedPersonality(userEmail: targetEmail);
      final savedAnswers = await _repository.getSavedAnswers(userEmail: targetEmail);

      if (savedAnswers != null && savedAnswers.isNotEmpty) {
        _answers.clear();
        _answers.addAll(savedAnswers);
      }

      if (savedPersonality != null) {
        _currentPersonality = savedPersonality;
      } else if (_answers.length >= 4) {
        _currentPersonality = _repository.calculatePersonality(_answers);
      }
    } catch (e) {
      debugPrint('Error loading saved matchmaker preferences: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update a single answer during quiz progress
  void setAnswer(int questionIndex, String optionLabel) {
    _answers[questionIndex] = optionLabel;
    notifyListeners();
  }

  /// Save complete quiz results, compute personality and persist to storage
  Future<CraftPersonality> saveQuizResults({
    required String experienceType,
    required String environment,
    required String material,
    required String region,
    String? userEmail,
  }) async {
    final targetEmail = userEmail ?? _currentUserEmail;
    _answers[0] = experienceType;
    _answers[1] = environment;
    _answers[2] = material;
    _answers[3] = region;

    final calculatedPersonality = _repository.calculatePersonality(_answers);
    _currentPersonality = calculatedPersonality;

    await _repository.saveQuizData(
      answers: _answers,
      personality: calculatedPersonality,
      userEmail: targetEmail,
    );

    notifyListeners();
    return calculatedPersonality;
  }

  /// Calculate or retrieve current personality result
  CraftPersonality calculateResult() {
    if (_currentPersonality != null) {
      return _currentPersonality!;
    }
    final result = _repository.calculatePersonality(_answers);
    _currentPersonality = result;
    return result;
  }

  /// Reset all answers and clear storage
  Future<void> clearAnswers({String? userEmail}) async {
    final targetEmail = userEmail ?? _currentUserEmail;
    _answers.clear();
    _currentPersonality = null;
    await _repository.clearSavedPreferences(userEmail: targetEmail);
    notifyListeners();
  }
}