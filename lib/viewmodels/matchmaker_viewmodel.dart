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
  bool get isQuizCompleted => _currentPersonality != null || _answers.length >= 6;

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
  String? get secondaryCategory => _currentPersonality?.secondaryCategory;
  Map<String, int> get craftScores => _currentPersonality?.craftScores ?? const {};
  Map<String, int> get traitScores => _currentPersonality?.traitScores ?? const {};
  String get topTrait => _currentPersonality?.topTrait ?? '';
  bool get isBlended => _currentPersonality?.isBlended ?? false;
  List<String> get blendedCategories => _currentPersonality?.blendedCategories ?? const [];

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
      } else if (_answers.length >= 6) {
        _currentPersonality = _repository.calculatePersonality(_answers);
      }
    } catch (e) {
      debugPrint('Error loading saved matchmaker preferences: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update a single answer during quiz progress and dynamically recalculate if all questions answered
  void setAnswer(int questionIndex, String optionLabel) {
    _answers[questionIndex] = optionLabel;
    if (_answers.length >= 6) {
      _currentPersonality = _repository.calculatePersonality(_answers);
    }
    notifyListeners();
  }

  /// Save complete quiz results, compute personality and persist to storage
  Future<CraftPersonality> saveQuizResults({
    String? experienceType,
    String? environment,
    String? material,
    String? region,
    Map<int, String>? answers,
    String? userEmail,
  }) async {
    final targetEmail = userEmail ?? _currentUserEmail;
    if (answers != null) {
      _answers.addAll(answers);
    }
    if (experienceType != null) _answers[0] = experienceType;
    if (environment != null) _answers[1] = environment;
    if (material != null) _answers[2] = material;
    if (region != null) _answers[3] = region;

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