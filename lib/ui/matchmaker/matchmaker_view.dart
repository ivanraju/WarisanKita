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
      'question': 'What kind of activity sounds most satisfying?',
      'options': [
        {
          'label': 'Painting flowing patterns',
          'subtitle': 'Batik canting, dynamic pigments & fabric flow',
          'image': 'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=600',
          'color': const Color(0xFF004D40),
        },
        {
          'label': 'Shaping by hand',
          'subtitle': 'Moulding earthenware clay & tactile curves',
          'image': 'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=600',
          'color': const Color(0xFFD97706),
        },
        {
          'label': 'Carving precise details',
          'subtitle': 'Hardwood chisel relief, fine lines & patience',
          'image': 'https://images.unsplash.com/photo-1533090161767-e6ffed986c88?w=600',
          'color': const Color(0xFF5D4037),
        },
        {
          'label': 'Forming and polishing metal',
          'subtitle': 'Pewter casting, clean edges & metallic sheen',
          'image': 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=600',
          'color': const Color(0xFF475569),
        },
      ],
    },
    {
      'question': 'How do you prefer to learn?',
      'options': [
        {
          'label': 'Experiment immediately',
          'subtitle': 'Dive straight in and learn hands-on by feeling',
          'image': 'https://images.unsplash.com/photo-1502622645667-f7ed8fa4d99c?w=600',
          'color': const Color(0xFF0D9488),
        },
        {
          'label': 'Watch a master first',
          'subtitle': 'Observe traditional techniques & artisan posture',
          'image': 'https://images.unsplash.com/photo-1550684848-fac1c5b4e853?w=600',
          'color': const Color(0xFFB45309),
        },
        {
          'label': 'Follow clear steps',
          'subtitle': 'Step-by-step guidance & structured methods',
          'image': 'https://images.unsplash.com/photo-1528459801416-a9e53bbf4e17?w=600',
          'color': const Color(0xFF2563EB),
        },
        {
          'label': 'Explore the history first',
          'subtitle': 'Understand cultural depth, heritage & origins',
          'image': 'https://images.unsplash.com/photo-1596401057633-54a8fe8ef647?w=600',
          'color': const Color(0xFF7C3AED),
        },
      ],
    },
    {
      'question': 'Which working environment appeals to you?',
      'options': [
        {
          'label': 'Colourful textile studio',
          'subtitle': 'Vibrant fabrics, hanging silks & wax aroma',
          'image': 'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=600',
          'color': const Color(0xFF004D40),
        },
        {
          'label': 'Quiet pottery workshop',
          'subtitle': 'Spinning wheels, soothing earth & calm clay',
          'image': 'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=600',
          'color': const Color(0xFFD97706),
        },
        {
          'label': 'Open-air village workshop',
          'subtitle': 'Verandas, timber scents & tropical breeze',
          'image': 'https://images.unsplash.com/photo-1533090161767-e6ffed986c88?w=600',
          'color': const Color(0xFF16A34A),
        },
        {
          'label': 'Precise metalworking studio',
          'subtitle': 'Organized tool benches & polished metalcraft',
          'image': 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=600',
          'color': const Color(0xFF475569),
        },
      ],
    },
    {
      'question': 'What matters most in something you create?',
      'options': [
        {
          'label': 'Expressive colour and symbolism',
          'subtitle': 'Emotional motifs, dynamic color & storytelling',
          'image': 'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=600',
          'color': const Color(0xFFE11D48),
        },
        {
          'label': 'Useful object with personal touch',
          'subtitle': 'Functional everyday earthenware with soulful warmth',
          'image': 'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=600',
          'color': const Color(0xFFD97706),
        },
        {
          'label': 'Intricate detail and natural beauty',
          'subtitle': 'Fine grain patterns & heirloom craftsmanship',
          'image': 'https://images.unsplash.com/photo-1533090161767-e6ffed986c88?w=600',
          'color': const Color(0xFF5D4037),
        },
        {
          'label': 'Strength, accuracy, and lasting quality',
          'subtitle': 'Durable alloys, clean lines & permanent beauty',
          'image': 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=600',
          'color': const Color(0xFF334155),
        },
      ],
    },
    {
      'question': 'What pace feels most comfortable?',
      'options': [
        {
          'label': 'Free-flowing and expressive',
          'subtitle': 'Spontaneous rhythm with room for surprises',
          'image': 'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=600',
          'color': const Color(0xFF0284C7),
        },
        {
          'label': 'Calm and repetitive',
          'subtitle': 'Therapeutic, meditative rhythm with clay',
          'image': 'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=600',
          'color': const Color(0xFF059669),
        },
        {
          'label': 'Slow and highly focused',
          'subtitle': 'Quiet patience & millimeter-level focus',
          'image': 'https://images.unsplash.com/photo-1533090161767-e6ffed986c88?w=600',
          'color': const Color(0xFFB45309),
        },
        {
          'label': 'Methodical and exact',
          'subtitle': 'Systematic, measured steps & exact precision',
          'image': 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=600',
          'color': const Color(0xFF475569),
        },
      ],
    },
    {
      'question': 'Which heritage story interests you most?',
      'options': [
        {
          'label': 'Batik and songket traditions',
          'subtitle': 'Royal courts, golden threads & canting legends',
          'image': 'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=600',
          'color': const Color(0xFF004D40),
        },
        {
          'label': 'Labu Sayong and traditional ceramics',
          'subtitle': 'Perak earthenware & river clay smoke firing',
          'image': 'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=600',
          'color': const Color(0xFFD97706),
        },
        {
          'label': 'Ukiran Melayu and architectural carving',
          'subtitle': 'Malay timber carvings & Istana architecture',
          'image': 'https://images.unsplash.com/photo-1533090161767-e6ffed986c88?w=600',
          'color': const Color(0xFF5D4037),
        },
        {
          'label': 'Pewter craft and keris making',
          'subtitle': 'Sacred bladesmithing & royal pewter artistry',
          'image': 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=600',
          'color': const Color(0xFF334155),
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
        answers: matchmakerVM.answers,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Text(
              question['question'],
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 26,
                color: const Color(0xFF004D40),
                height: 1.15,
              ),
            ),
            const SizedBox(height: 28),
            ...((question['options'] as List).asMap().entries.map((entry) {
              int idx = entry.key;
              var opt = entry.value;
              return _buildInteractiveCard(opt, idx);
            }).toList()),
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
        height: 105,
        margin: EdgeInsets.only(bottom: 16, top: isHovered ? 2 : 0),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: NetworkImage(opt['image']),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(isHovered ? 0.3 : 0.5),
              BlendMode.darken,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: (opt['color'] as Color).withOpacity(0.3),
              blurRadius: isHovered ? 20 : 12,
              offset: Offset(0, isHovered ? 8 : 4),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                opt['label'],
                style: GoogleFonts.dmSerifDisplay(
                  color: Colors.white,
                  fontSize: 20,
                  shadows: [const Shadow(blurRadius: 10)],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                opt['subtitle'],
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white.withOpacity(0.92),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
