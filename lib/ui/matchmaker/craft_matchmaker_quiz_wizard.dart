import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/data/repositories/matchmaker_repository.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';
import 'package:warisan_kita/viewmodels/craft_personality.dart';
import 'package:warisan_kita/viewmodels/matchmaker_viewmodel.dart';
import 'package:warisan_kita/viewmodels/directory_viewmodel.dart';

class CraftMatchmakerQuizWizard extends StatefulWidget {
  final Function(List<String> preferenceTags)? onCompleted;
  final Map<int, String>? initialAnswers;

  const CraftMatchmakerQuizWizard({
    super.key,
    this.onCompleted,
    this.initialAnswers,
  });

  @override
  State<CraftMatchmakerQuizWizard> createState() => _CraftMatchmakerQuizWizardState();
}

class _CraftMatchmakerQuizWizardState extends State<CraftMatchmakerQuizWizard> {
  int _currentStep = 0;
  final Map<int, String> _selectedAnswers = {};
  bool _isInitialized = false;

  final MatchmakerRepository _repository = const MatchmakerRepository();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final matchVM = context.read<MatchmakerViewModel>();
      final authVM = context.read<AuthViewModel>();
      final user = authVM.currentUser;

      if (widget.initialAnswers != null && widget.initialAnswers!.isNotEmpty) {
        _selectedAnswers.addAll(widget.initialAnswers!);
      } else if (matchVM.answers.isNotEmpty) {
        _selectedAnswers.addAll(matchVM.answers);
      } else if (user != null && user.quizAnswers.isNotEmpty) {
        _selectedAnswers.addAll(user.quizAnswers);
      }

      _isInitialized = true;
    }
  }

  bool get _isAllQuestionsAnswered {
    final questions = _repository.getQuestions();
    for (int i = 0; i < questions.length; i++) {
      if (!_selectedAnswers.containsKey(i) || _selectedAnswers[i] == null) {
        return false;
      }
    }
    return true;
  }

  Future<void> _submitQuiz() async {
    final questions = _repository.getQuestions();
    if (!_isAllQuestionsAnswered) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please answer all ${questions.length} questions to reveal your Craft Soul.'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final matchVM = context.read<MatchmakerViewModel>();
    final authVM = context.read<AuthViewModel>();
    final email = authVM.currentUser?.email ?? 'tourist@warisankita.my';

    // 1. Set answers in MatchmakerViewModel
    matchVM.setAllAnswers(_selectedAnswers);

    // 2. Calculate Personality
    final personality = matchVM.calculateResult();

    // 3. Save to storage & user profile
    await matchVM.saveQuiz(email);

    try {
      await authVM.updateProfile(
        craftPersonalityTitle: personality.title,
        craftPersonalityDescription: personality.description,
        matchedCrafts: personality.matchingCrafts,
        preferenceTags: personality.preferenceTags,
        quizAnswers: _selectedAnswers,
      );
    } catch (_) {}

    if (widget.onCompleted != null) {
      widget.onCompleted!(personality.preferenceTags);
    }

    if (!mounted) return;

    // 4. Show Celebration Modal
    _showCelebrationDialog(context, personality);
  }

  void _showCelebrationDialog(BuildContext context, CraftPersonality personality) {
    Navigator.of(context).pop(); // Close wizard dialog first

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: const Color(0xFF004D40),
        child: Container(
          padding: const EdgeInsets.all(28),
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Celebration Badge Icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFFD54F), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD54F).withValues(alpha: 0.3),
                        blurRadius: 25,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 48,
                    color: Color(0xFFFFD54F),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  'CRAFT SOUL DISCOVERED!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFFFD54F),
                    letterSpacing: 2.0,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  personality.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 26,
                    color: Colors.white,
                  ),
                ),

                Text(
                  personality.tagline,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    children: [
                      Text(
                        personality.description,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.9),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        alignment: WrapAlignment.center,
                        children: personality.matchingCrafts.map((craft) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD54F).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFFD54F)),
                            ),
                            child: Text(
                              craft.toUpperCase(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFFFD54F),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Button: Explore Matching Masters
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(dialogCtx).pop();
                      try {
                        final primaryCraft = personality.matchingCrafts.isNotEmpty
                            ? personality.matchingCrafts.first
                            : 'All Crafts';
                        dialogCtx.read<DirectoryViewModel>().updateFilter(craft: primaryCraft);
                      } catch (_) {}
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD54F),
                      foregroundColor: const Color(0xFF004D40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      'EXPLORE MATCHING MASTERS',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: Text(
                    'CLOSE',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final questions = _repository.getQuestions();
    final currentQ = questions[_currentStep];
    final totalSteps = questions.length;
    final options = (currentQ['options'] as List<dynamic>);
    final isUpdating = _selectedAnswers.isNotEmpty;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Step Progress Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF004D40).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF004D40), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isUpdating ? 'Update Craft Matchmaker' : 'Craft Matchmaker Quiz',
                                softWrap: true,
                                style: GoogleFonts.dmSerifDisplay(fontSize: 19, color: const Color(0xFF004D40)),
                              ),
                              Text(
                                isUpdating ? 'Edit your cultural preferences' : 'Discover your heritage soul archetype',
                                style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: (_currentStep + 1) / totalSteps,
                backgroundColor: const Color(0xFFE2E8F0),
                color: const Color(0xFF004D40),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),

              const SizedBox(height: 20),

              // Question Header
              Text(
                'Question ${_currentStep + 1} of $totalSteps',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFD97706),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                currentQ['question'] as String,
                style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: const Color(0xFF0F172A)),
              ),
              if (currentQ['subtitle'] != null) ...[
                const SizedBox(height: 2),
                Text(
                  currentQ['subtitle'] as String,
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[600]),
                ),
              ],

              const SizedBox(height: 16),

              // Options
              ...options.map((optMap) {
                final label = optMap['label'] as String;
                final desc = optMap['desc'] as String;
                final isSelected = _selectedAnswers[_currentStep] == label;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF004D40).withValues(alpha: 0.06) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF004D40) : Colors.black.withValues(alpha: 0.08),
                      width: isSelected ? 1.8 : 1.0,
                    ),
                  ),
                  child: ListTile(
                    onTap: () {
                      setState(() {
                        _selectedAnswers[_currentStep] = label;
                      });
                    },
                    title: Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? const Color(0xFF004D40) : const Color(0xFF1E293B),
                      ),
                    ),
                    subtitle: Text(
                      desc,
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[600]),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded, color: Color(0xFF004D40))
                        : const Icon(Icons.radio_button_unchecked_rounded, color: Colors.grey),
                  ),
                );
              }),

              const SizedBox(height: 20),

              // Navigation Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep > 0)
                    OutlinedButton(
                      onPressed: () => setState(() => _currentStep--),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF004D40),
                        side: const BorderSide(color: Color(0xFF004D40)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Back'),
                    )
                  else
                    const SizedBox.shrink(),

                  if (_currentStep < totalSteps - 1)
                    FilledButton(
                      onPressed: () {
                        if (_selectedAnswers[_currentStep] == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please choose an option to continue.'),
                              backgroundColor: Color(0xFFEF4444),
                              duration: Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }
                        setState(() => _currentStep++);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF004D40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Next Question'),
                    )
                  else
                    FilledButton(
                      onPressed: _submitQuiz,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text(
                        isUpdating ? 'SAVE & UPDATE SOUL' : 'DISCOVER CRAFT SOUL',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}