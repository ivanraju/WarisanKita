import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CraftMatchmakerQuizWizard extends StatefulWidget {
  final Function(List<String> preferenceTags) onCompleted;

  const CraftMatchmakerQuizWizard({
    super.key,
    required this.onCompleted,
  });

  @override
  State<CraftMatchmakerQuizWizard> createState() => _CraftMatchmakerQuizWizardState();
}

class _CraftMatchmakerQuizWizardState extends State<CraftMatchmakerQuizWizard> {
  int _currentStep = 0;

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

  bool get _isAllQuestionsAnswered =>
      _q1ExperienceType != null &&
      _q2Environment != null &&
      _q3MaterialPreference != null &&
      _q4CraftOrigin != null;

  void _submitQuiz() {
    if (!_isAllQuestionsAnswered) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer all 4 questions to save your preferences.'),
          backgroundColor: Color(0xFFEF4444),
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

    // M3: Profile Updated Successfully / Preferences Saved
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Craft Preference Tags Saved! Your Heritage Directory recommendations are updated.',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF004D40),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    widget.onCompleted(tags);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 550),
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
                            color: const Color(0xFF004D40).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF004D40), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Craft Matchmaker Wizard',
                            softWrap: true,
                            style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: const Color(0xFF004D40)),
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

              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: (_currentStep + 1) / 4,
                backgroundColor: const Color(0xFFE2E8F0),
                color: const Color(0xFF004D40),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),

              const SizedBox(height: 20),

              // Wizard Questions Step View
              if (_currentStep == 0) _buildQuestion1(),
              if (_currentStep == 1) _buildQuestion2(),
              if (_currentStep == 2) _buildQuestion3(),
              if (_currentStep == 3) _buildQuestion4(),

              const SizedBox(height: 24),

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
                      ),
                      child: const Text('Back'),
                    )
                  else
                    const SizedBox.shrink(),

                  if (_currentStep < 3)
                    FilledButton(
                      onPressed: () => setState(() => _currentStep++),
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF004D40)),
                      child: const Text('Next Question'),
                    )
                  else
                    FilledButton(
                      onPressed: _submitQuiz,
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                      child: const Text('SAVE PREFERENCES'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestion1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Question 1 of 4',
          style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[500]),
        ),
        const SizedBox(height: 4),
        Text(
          'What type of craft experience do you prefer?',
          style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 14),
        _buildChoiceTile(
          title: '🛠️ Hands-on Workshop',
          subtitle: 'I want to craft my own pottery or dye batik fabric',
          value: 'Hands-on Workshop',
          groupValue: _q1ExperienceType,
          onSelect: (val) => setState(() => _q1ExperienceType = val),
        ),
        _buildChoiceTile(
          title: '👁️ Observing Master Artisans',
          subtitle: 'I prefer watching skilled masters demonstrate traditional heritage techniques',
          value: 'Observing Master Artisans',
          groupValue: _q1ExperienceType,
          onSelect: (val) => setState(() => _q1ExperienceType = val),
        ),
      ],
    );
  }

  Widget _buildQuestion2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Question 2 of 4',
          style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[500]),
        ),
        const SizedBox(height: 4),
        Text(
          'Which studio setting do you enjoy most?',
          style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 14),
        _buildChoiceTile(
          title: '🏠 Indoor Art Studio',
          subtitle: 'Air-conditioned gallery and structured indoor workshop setting',
          value: 'Indoor Studio',
          groupValue: _q2Environment,
          onSelect: (val) => setState(() => _q2Environment = val),
        ),
        _buildChoiceTile(
          title: '🌿 Outdoor Heritage Village',
          subtitle: 'Open-air traditional wooden kampong workshop setup',
          value: 'Outdoor Village',
          groupValue: _q2Environment,
          onSelect: (val) => setState(() => _q2Environment = val),
        ),
      ],
    );
  }

  Widget _buildQuestion3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Question 3 of 4',
          style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[500]),
        ),
        const SizedBox(height: 4),
        Text(
          'What is your favorite craft material?',
          style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 14),
        ..._materialsList.map(
          (mat) => _buildChoiceTile(
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

  Widget _buildQuestion4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Question 4 of 4',
          style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[500]),
        ),
        const SizedBox(height: 4),
        Text(
          'Which Malaysian heritage region interests you?',
          style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 14),
        _buildChoiceTile(
          title: '🌊 East Coast Heritage (Kelantan & Terengganu)',
          subtitle: 'Famous for Songket weaving, Wau kites, and Batik canting',
          value: 'East Coast Heritage',
          groupValue: _q4CraftOrigin,
          onSelect: (val) => setState(() => _q4CraftOrigin = val),
        ),
        _buildChoiceTile(
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
    required String title,
    required String subtitle,
    required String value,
    required String? groupValue,
    required ValueChanged<String> onSelect,
  }) {
    final bool isSelected = groupValue == value;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF004D40).withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? const Color(0xFF004D40) : Colors.black.withOpacity(0.08),
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
            color: isSelected ? const Color(0xFF004D40) : const Color(0xFF1E293B),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[600]),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle_rounded, color: Color(0xFF004D40))
            : const Icon(Icons.radio_button_unchecked_rounded, color: Colors.grey),
      ),
    );
  }
}