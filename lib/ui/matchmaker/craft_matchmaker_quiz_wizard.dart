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
  bool _wasInitiallyCompleted = false;

  final Map<int, String> _answers = {};

  final List<Map<String, dynamic>> _quizQuestions = const [
    {
      'title': 'What kind of activity sounds most satisfying?',
      'options': [
        {
          'title': '🎨 Painting flowing patterns',
          'subtitle': 'Expressive batik canting, vibrant dyes, free-flowing textiles',
          'value': 'Painting flowing patterns',
        },
        {
          'title': '🏺 Shaping by hand',
          'subtitle': 'Moulding clay, earthenware pottery, tactile curves',
          'value': 'Shaping by hand',
        },
        {
          'title': '🪵 Carving precise details',
          'subtitle': 'Fine wood chiseling, intricate floral relief, patience',
          'value': 'Carving precise details',
        },
        {
          'title': '⚒️ Forming and polishing metal',
          'subtitle': 'Precision pewter smithing, metal casting, clean edges',
          'value': 'Forming and polishing metal',
        },
      ],
    },
    {
      'title': 'How do you prefer to learn?',
      'options': [
        {
          'title': '✨ Experiment immediately',
          'subtitle': 'Hands-on discovery, learn by touching and doing',
          'value': 'Experiment immediately',
        },
        {
          'title': '👁️ Watch a master first',
          'subtitle': 'Careful observation of traditional artisan techniques',
          'value': 'Watch a master first',
        },
        {
          'title': '📋 Follow clear steps',
          'subtitle': 'Structured methodical instructions and proven rules',
          'value': 'Follow clear steps',
        },
        {
          'title': '📜 Explore the history first',
          'subtitle': 'Deep cultural context, folklore, and heritage roots',
          'value': 'Explore the history first',
        },
      ],
    },
    {
      'title': 'Which working environment appeals to you?',
      'options': [
        {
          'title': '🧵 Colourful textile studio',
          'subtitle': 'Vibrant fabrics, hanging silks, and warm wax aromas',
          'value': 'Colourful textile studio',
        },
        {
          'title': '🏺 Quiet pottery workshop',
          'subtitle': 'Peaceful clay studio, spinning wheels, soothing earth',
          'value': 'Quiet pottery workshop',
        },
        {
          'title': '🌿 Open-air village workshop',
          'subtitle': 'Traditional wooden veranda, timber scents, kampung breeze',
          'value': 'Open-air village workshop',
        },
        {
          'title': '⚙️ Precise metalworking studio',
          'subtitle': 'Organized tool benches, polishers, exact metalcraft',
          'value': 'Precise metalworking studio',
        },
      ],
    },
    {
      'title': 'What matters most in something you create?',
      'options': [
        {
          'title': '🎨 Expressive colour and symbolism',
          'subtitle': 'Emotional motifs, dynamic color, storytelling',
          'value': 'Expressive colour and symbolism',
        },
        {
          'title': '🍵 Useful object with personal touch',
          'subtitle': 'Functional everyday earthenware with soulful warmth',
          'value': 'Useful object with personal touch',
        },
        {
          'title': '🌿 Intricate detail and natural beauty',
          'subtitle': 'Fine grain patterns, heirloom timber craftsmanship',
          'value': 'Intricate detail and natural beauty',
        },
        {
          'title': '🛡️ Strength, accuracy, and lasting quality',
          'subtitle': 'Durable polished alloys, crisp lines, permanent beauty',
          'value': 'Strength, accuracy, and lasting quality',
        },
      ],
    },
    {
      'title': 'What pace feels most comfortable?',
      'options': [
        {
          'title': '🌊 Free-flowing and expressive',
          'subtitle': 'Spontaneous rhythm with room for artistic surprises',
          'value': 'Free-flowing and expressive',
        },
        {
          'title': '🧘 Calm and repetitive',
          'subtitle': 'Therapeutic, meditative rhythm shaping smooth clay',
          'value': 'Calm and repetitive',
        },
        {
          'title': '🔍 Slow and highly focused',
          'subtitle': 'Quiet patience, millimeter-level focus carving grain',
          'value': 'Slow and highly focused',
        },
        {
          'title': '📐 Methodical and exact',
          'subtitle': 'Systematic, measured steps with exact precision',
          'value': 'Methodical and exact',
        },
      ],
    },
    {
      'title': 'Which heritage story interests you most?',
      'options': [
        {
          'title': '👑 Batik and songket traditions',
          'subtitle': 'Royal Malay courts, golden threads, and canting wax legends',
          'value': 'Batik and songket traditions',
        },
        {
          'title': '🏺 Labu Sayong and traditional ceramics',
          'subtitle': 'Perak earthenware, river clays, and natural smoke firing',
          'value': 'Labu Sayong and traditional ceramics',
        },
        {
          'title': '🏛️ Ukiran Melayu and architectural carving',
          'subtitle': 'Traditional woodcarving, Bunga Ukir, and Istana architecture',
          'value': 'Ukiran Melayu and architectural carving',
        },
        {
          'title': '🗡️ Pewter craft and keris making',
          'subtitle': 'Sacred damascus bladesmithing and royal pewter artistry',
          'value': 'Pewter craft and keris making',
        },
      ],
    },
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final matchmakerVM = context.read<MatchmakerViewModel>();
      _wasInitiallyCompleted = matchmakerVM.isQuizCompleted;
      _answers.addAll(matchmakerVM.answers);
      _isInitialized = true;
    }
  }

  bool get _isAllQuestionsAnswered =>
      _answers.length >= 6 &&
      [0, 1, 2, 3, 4, 5].every((i) => _answers[i] != null && _answers[i]!.isNotEmpty);

  void _selectAnswer(int questionIndex, String value) {
    setState(() {
      _answers[questionIndex] = value;
    });
    context.read<MatchmakerViewModel>().setAnswer(questionIndex, value);
  }

  Future<void> _submitQuiz() async {
    final langVM = context.read<LanguageViewModel>();
    if (!_isAllQuestionsAnswered) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(langVM.translate('Please answer all 6 questions to save your preferences.')),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final authVM = context.read<AuthViewModel>();
    final matchmakerVM = context.read<MatchmakerViewModel>();

    final personality = await matchmakerVM.saveQuizResults(
      answers: _answers,
      userEmail: authVM.currentUser?.email,
    );

    if (mounted) {
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

      widget.onCompleted?.call(personality.preferenceTags);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final langVM = context.watch<LanguageViewModel>();
    final isUpdating = _wasInitiallyCompleted;
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
                value: (_currentStep + 1) / 6,
                backgroundColor: isDark ? const Color(0xFF1E3A34) : const Color(0xFFE2E8F0),
                color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),

              const SizedBox(height: 20),

              // Wizard Questions Step View
              _buildCurrentStep(isDark),

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

                  if (_currentStep < 5)
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

  Widget _buildCurrentStep(bool isDark) {
    final currentQ = _quizQuestions[_currentStep];
    final title = currentQ['title'] as String;
    final options = currentQ['options'] as List<Map<String, String>>;
    final selectedValue = _answers[_currentStep];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Question ${_currentStep + 1} of 6',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white54 : Colors.grey[500],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 18,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 14),
        ...options.map(
          (opt) => _buildChoiceTile(
            isDark: isDark,
            title: opt['title']!,
            subtitle: opt['subtitle']!,
            value: opt['value']!,
            groupValue: selectedValue,
            onSelect: (val) => _selectAnswer(_currentStep, val),
          ),
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