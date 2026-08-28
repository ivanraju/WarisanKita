import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/ui/matchmaker/quiz_results_view.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';
import 'package:warisan_kita/viewmodels/matchmaker_viewmodel.dart';

class QuizWizardScreen extends StatefulWidget {
  const QuizWizardScreen({super.key});

  @override
  State<QuizWizardScreen> createState() => _QuizWizardScreenState();
}

class _QuizWizardScreenState extends State<QuizWizardScreen> {
  int _currentStep = 0;
  int? _hoveredIndex;

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'What type of craft experience do you prefer?',
      'options': [
        {
          'label': 'Hands-on Workshop',
          'subtitle': 'Craft your own pottery or dye batik fabric',
          'image': 'https://images.unsplash.com/photo-1502622645667-f7ed8fa4d99c?w=600',
          'color': Color(0xFF004D40),
        },
        {
          'label': 'Observing Master Artisans',
          'subtitle': 'Watch skilled masters demonstrate traditional techniques',
          'image': 'https://images.unsplash.com/photo-1550684848-fac1c5b4e853?w=600',
          'color': Color(0xFFFF7043),
        },
      ],
    },
    {
      'question': 'Which studio setting do you enjoy most?',
      'options': [
        {
          'label': 'Indoor Studio',
          'subtitle': 'Air-conditioned gallery & structured workshop',
          'image': 'https://images.unsplash.com/photo-1528459801416-a9e53bbf4e17?w=600',
          'color': const Color(0xFF0284C7),
        },
        {
          'label': 'Outdoor Village',
          'subtitle': 'Open-air traditional wooden kampong workshop setup',
          'image': 'https://images.unsplash.com/photo-1533090161767-e6ffed986c88?w=600',
          'color': const Color(0xFF16A34A),
        },
      ],
    },
    {
      'question': 'What is your favorite craft material?',
      'options': [
        {
          'label': 'Batik & Songket Textiles',
          'subtitle': 'Silk, cotton, wax canting & golden thread',
          'image': 'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=600',
          'color': const Color(0xFFFF7043),
        },
        {
          'label': 'Pottery & Clay',
          'subtitle': 'Terrakotta clay, Labu Sayong & kiln ceramics',
          'image': 'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=600',
          'color': const Color(0xFFD97706),
        },
        {
          'label': 'Carved Timber & Wood',
          'subtitle': 'Hardwood timbers, Ukiran motifs & woodwork',
          'image': 'https://images.unsplash.com/photo-1533090161767-e6ffed986c88?w=600',
          'color': const Color(0xFF5D4037),
        },
        {
          'label': 'Royal Pewter & Metal',
          'subtitle': 'Metallic sheen, pewter casting & keris forging',
          'image': 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=600',
          'color': const Color(0xFF475569),
        },
      ],
    },
    {
      'question': 'Which Malaysian heritage region interests you?',
      'options': [
        {
          'label': 'East Coast Heritage',
          'subtitle': 'Kelantan & Terengganu: Songket, Wau kites & Batik',
          'image': 'https://images.unsplash.com/photo-1596401057633-54a8fe8ef647?w=600',
          'color': const Color(0xFF004D40),
        },
        {
          'label': 'West Coast Historic',
          'subtitle': 'Melaka & Perak: Labu Sayong pottery & carvings',
          'image': 'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=600',
          'color': const Color(0xFFB45309),
        },
      ],
    },
  ];

  Future<void> _handleSelection(String label) async {
    final matchmakerVM = context.read<MatchmakerViewModel>();
    final authVM = context.read<AuthViewModel>();

    matchmakerVM.setAnswer(_currentStep, label);

    if (_currentStep < _questions.length - 1) {
      setState(() => _currentStep++);
    } else {
      await matchmakerVM.saveQuizResults(
        experienceType: matchmakerVM.answers[0] ?? 'Hands-on Workshop',
        environment: matchmakerVM.answers[1] ?? 'Indoor Studio',
        material: matchmakerVM.answers[2] ?? 'Batik & Songket Textiles',
        region: matchmakerVM.answers[3] ?? 'East Coast Heritage',
        userEmail: authVM.currentUser?.email,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const QuizResultsScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_currentStep];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('Heritage Match', style: GoogleFonts.dmSerifDisplay()),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (_currentStep + 1) / _questions.length,
                minHeight: 8,
                backgroundColor: Colors.black12,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD54F)),
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              question['question'],
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 32,
                color: const Color(0xFF004D40),
                height: 1.1,
              ),
            ),
            const SizedBox(height: 48),
            Expanded(
              child: Column(
                children: (question['options'] as List).asMap().entries.map((entry) {
                  int idx = entry.key;
                  var opt = entry.value;
                  return Expanded(
                    child: _buildInteractiveCard(opt, idx),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveCard(dynamic opt, int index) {
    bool isHovered = _hoveredIndex == index;

    return GestureDetector(
      onTapDown: (_) => setState(() => _hoveredIndex = index),
      onTapUp: (_) {
        setState(() => _hoveredIndex = null);
        _handleSelection(opt['label']);
      },
      onTapCancel: () => setState(() => _hoveredIndex = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        margin: EdgeInsets.only(bottom: 24, top: isHovered ? 4 : 0),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          image: DecorationImage(
            image: NetworkImage(opt['image']),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(isHovered ? 0.2 : 0.4),
              BlendMode.darken,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: (opt['color'] as Color).withOpacity(0.3),
              blurRadius: isHovered ? 30 : 20,
              offset: Offset(0, isHovered ? 15 : 10),
            )
          ],
        ),
        child: Center(
          child: Text(
            opt['label'],
            style: GoogleFonts.dmSerifDisplay(
              color: Colors.white,
              fontSize: 32,
              shadows: [const Shadow(blurRadius: 20)],
            ),
          ),
        ),
      ),
    );
  }
}
