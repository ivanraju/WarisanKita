import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';
import 'package:warisan_kita/viewmodels/language_viewmodel.dart';
import 'package:warisan_kita/viewmodels/matchmaker_viewmodel.dart';

class CraftMatchmakerQuizWizard extends StatefulWidget {
  final Function(List<String> preferenceTags)? onCompleted;

  const CraftMatchmakerQuizWizard({
    super.key,
    this.onCompleted,
  });

  @override
  State<CraftMatchmakerQuizWizard> createState() => _CraftMatchmakerQuizWizardState();
}

class _CraftMatchmakerQuizWizardState extends State<CraftMatchmakerQuizWizard> {
  int _currentStep = 0;
  bool _isInitialized = false;

  // 4 Preference Questions (C3: Quiz Completion = all 4 questions answered)
  String? _q1ExperienceType; // Hands-on workshop vs Observing master
  String? _q2Environment; // Indoor studio vs Outdoor heritage village
  String? _q3MaterialPreference; // Clay/Ceramics, Textiles/Batik, Wood, Metal/Pewter
  String? _q4CraftOrigin; // East Coast (Kelantan/Terengganu) vs West Coast (Melaka/Perak)

  final List<String> _materialsList = const [
    'Pottery & Clay',
    'Batik & Songket Textiles',
    'Carved Timber & Wood',
    'Royal Pewter & Metal',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final matchmakerVM = context.read<MatchmakerViewModel>();
      final answers = matchmakerVM.answers;
      final personality = matchmakerVM.currentPersonality;

      _q1ExperienceType = answers[0] ?? personality?.experienceType;
      _q2Environment = answers[1] ?? personality?.environment;
      _q3MaterialPreference = answers[2] ?? personality?.material;
      _q4CraftOrigin = answers[3] ?? personality?.region;

      _isInitialized = true;
    }
  }

  bool get _isAllQuestionsAnswered =>
      _q1ExperienceType != null &&
      _q2Environment != null &&
      _q3MaterialPreference != null &&
      _q4CraftOrigin != null;

  Future<void> _submitQuiz() async {
    final langVM = context.read<LanguageViewModel>();
    if (!_isAllQuestionsAnswered) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(langVM.translate('Please answer all 4 questions to save your preferences.')),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final tags = [
      _q1ExperienceType!,
      _q2Environment!,
      _q3MaterialPreference!,
      _q4CraftOrigin!,
    ];

    final authVM = context.read<AuthViewModel>();
    final matchmakerVM = context.read<MatchmakerViewModel>();

    final personality = await matchmakerVM.saveQuizResults(
      experienceType: _q1ExperienceType!,
      environment: _q2Environment!,
      material: _q3MaterialPreference!,
      region: _q4CraftOrigin!,
      userEmail: authVM.currentUser?.email,
    );

    if (mounted) {
      // M3: Profile Updated Successfully / Preferences Saved
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✨ ${langVM.translate('Your Craft Soul:')} ${personality.title}! ${langVM.translate('Preferences updated successfully.')}',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF004D40),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      widget.onCompleted?.call(tags);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final langVM = context.watch<LanguageViewModel>();
    final matchmakerVM = context.watch<MatchmakerViewModel>();
    final isUpdating = matchmakerVM.isQuizCompleted;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: isDark ? const Color(0xFF0D2825) : Colors.white,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 550),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0D2825) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: isDark ? Border.all(color: const Color(0xFF1E3A34)) : null,
        ),
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
                            color: isDark
                                ? const Color(0xFF1E3A34)
                                : const Color(0xFF004D40).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isUpdating
                                ? langVM.translate('Update Craft Matchmaker')
                                : langVM.translate('Craft Matchmaker Wizard'),
                            softWrap: true,
                            style: GoogleFonts.dmSerifDisplay(
                              fontSize: 20,
                              color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: isDark ? Colors.white70 : Colors.grey),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: (_currentStep + 1) / 4,
                backgroundColor: isDark ? const Color(0xFF1E3A34) : const Color(0xFFE2E8F0),
                color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),

              const SizedBox(height: 20),

              // Wizard Questions Step View
              if (_currentStep == 0) _buildQuestion1(isDark),
              if (_currentStep == 1) _buildQuestion2(isDark),
              if (_currentStep == 2) _buildQuestion3(isDark),
              if (_currentStep == 3) _buildQuestion4(isDark),

              const SizedBox(height: 24),

              // Navigation Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep > 0)
                    OutlinedButton(
                      onPressed: () => setState(() => _currentStep--),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                        side: BorderSide(
                          color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                        ),
                      ),
                      child: Text(langVM.translate('Back')),
                    )
                  else
                    const SizedBox.shrink(),

                  if (_currentStep < 3)
                    FilledButton(
                      onPressed: () => setState(() => _currentStep++),
                      style: FilledButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                        foregroundColor: isDark ? const Color(0xFF041412) : Colors.white,
                      ),
                      child: Text(
                        langVM.translate('Next Question'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    )
                  else
                    FilledButton(
                      onPressed: _submitQuiz,
                      style: FilledButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF34D399) : const Color(0xFF10B981),
                        foregroundColor: isDark ? const Color(0xFF041412) : Colors.white,
                      ),
                      child: Text(
                        isUpdating
                            ? langVM.translate('UPDATE PREFERENCES')
                            : langVM.translate('SAVE PREFERENCES'),
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

  Widget _buildQuestion1(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Question 1 of 4',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white54 : Colors.grey[500],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'What type of craft experience do you prefer?',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 18,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 14),
        _buildChoiceTile(
          isDark: isDark,
          title: '🛠️ Hands-on Workshop',
          subtitle: 'I want to craft my own pottery or dye batik fabric',
          value: 'Hands-on Workshop',
          groupValue: _q1ExperienceType,
          onSelect: (val) => setState(() => _q1ExperienceType = val),
        ),
        _buildChoiceTile(
          isDark: isDark,
          title: '👁️ Observing Master Artisans',
          subtitle: 'I prefer watching skilled masters demonstrate traditional heritage techniques',
          value: 'Observing Master Artisans',
          groupValue: _q1ExperienceType,
          onSelect: (val) => setState(() => _q1ExperienceType = val),
        ),
      ],
    );
  }

  Widget _buildQuestion2(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Question 2 of 4',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white54 : Colors.grey[500],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Which studio setting do you enjoy most?',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 18,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 14),
        _buildChoiceTile(
          isDark: isDark,
          title: '🏠 Indoor Art Studio',
          subtitle: 'Air-conditioned gallery and structured indoor workshop setting',
          value: 'Indoor Studio',
          groupValue: _q2Environment,
          onSelect: (val) => setState(() => _q2Environment = val),
        ),
        _buildChoiceTile(
          isDark: isDark,
          title: '🌿 Outdoor Heritage Village',
          subtitle: 'Open-air traditional wooden kampong workshop setup',
          value: 'Outdoor Village',
          groupValue: _q2Environment,
          onSelect: (val) => setState(() => _q2Environment = val),
        ),
      ],
    );
  }

  Widget _buildQuestion3(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Question 3 of 4',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white54 : Colors.grey[500],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'What is your favorite craft material?',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 18,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 14),
        ..._materialsList.map(
          (mat) => _buildChoiceTile(
            isDark: isDark,
            title: mat,
            subtitle: 'Crafts made with authentic $mat',
            value: mat,
            groupValue: _q3MaterialPreference,
            onSelect: (val) => setState(() => _q3MaterialPreference = val),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestion4(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Question 4 of 4',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white54 : Colors.grey[500],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Which Malaysian heritage region interests you?',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 18,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 14),
        _buildChoiceTile(
          isDark: isDark,
          title: '🌊 East Coast Heritage (Kelantan & Terengganu)',
          subtitle: 'Famous for Songket weaving, Wau kites, and Batik canting',
          value: 'East Coast Heritage',
          groupValue: _q4CraftOrigin,
          onSelect: (val) => setState(() => _q4CraftOrigin = val),
        ),
        _buildChoiceTile(
          isDark: isDark,
          title: '🏛️ West Coast Historic Cities (Melaka & Perak)',
          subtitle: 'Famous for Clay Labu Sayong pottery and wood carvings',
          value: 'West Coast Historic',
          groupValue: _q4CraftOrigin,
          onSelect: (val) => setState(() => _q4CraftOrigin = val),
        ),
      ],
    );
  }

  Widget _buildChoiceTile({
    required bool isDark,
    required String title,
    required String subtitle,
    required String value,
    required String? groupValue,
    required ValueChanged<String> onSelect,
  }) {
    final bool isSelected = groupValue == value;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isSelected
            ? (isDark ? const Color(0xFF1E3A34) : const Color(0xFF004D40).withOpacity(0.06))
            : (isDark ? const Color(0xFF041412) : Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected
                ? (isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40))
                : (isDark ? const Color(0xFF1E3A34) : Colors.black.withOpacity(0.08)),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: ListTile(
          onTap: () => onSelect(value),
          title: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? (isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40))
                  : (isDark ? Colors.white : const Color(0xFF1E293B)),
            ),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: isDark ? Colors.white70 : Colors.grey[600],
            ),
          ),
          trailing: isSelected
              ? Icon(
                  Icons.check_circle_rounded,
                  color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                )
              : Icon(
                  Icons.radio_button_unchecked_rounded,
                  color: isDark ? Colors.white38 : Colors.grey,
                ),
        ),
      ),
    );
  }
}