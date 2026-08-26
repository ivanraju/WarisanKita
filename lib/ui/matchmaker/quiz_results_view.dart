import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';
import 'package:warisan_kita/viewmodels/matchmaker_viewmodel.dart';
import 'package:warisan_kita/viewmodels/directory_viewmodel.dart';
import 'package:warisan_kita/viewmodels/navigation_viewmodel.dart';

class QuizResultsScreen extends StatefulWidget {
  const QuizResultsScreen({super.key});

  @override
  State<QuizResultsScreen> createState() => _QuizResultsScreenState();
}

class _QuizResultsScreenState extends State<QuizResultsScreen> {
  bool _isSaved = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isSaved) {
      _isSaved = true;
      _persistResult();
    }
  }

  Future<void> _persistResult() async {
    final matchVM = context.read<MatchmakerViewModel>();
    final authVM = context.read<AuthViewModel>();
    final email = authVM.currentUser?.email ?? 'tourist@warisankita.my';
    final personality = matchVM.calculateResult();

    await matchVM.saveQuiz(email);
    try {
      await authVM.updateProfile(
        craftPersonalityTitle: personality.title,
        craftPersonalityDescription: personality.description,
        matchedCrafts: personality.matchingCrafts,
        preferenceTags: personality.preferenceTags,
        quizAnswers: matchVM.answers,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final matchState = context.watch<MatchmakerViewModel>();
    final result = matchState.calculateResult();

    return Scaffold(
      backgroundColor: const Color(0xFF004D40),
      body: Stack(
        children: [
          // Dynamic Background Pattern
          Positioned(
            top: -120,
            left: -120,
            child: Opacity(
              opacity: 0.15,
              child: Container(
                width: 450,
                height: 450,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFD54F),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildCelebrationBadge(),
                  const SizedBox(height: 24),

                  Text(
                    'YOUR CRAFT SOUL IS...',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFFFFD54F),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.white, Color(0xFFFFD54F)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ).createShader(bounds),
                    child: Text(
                      result.title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSerifDisplay(
                        color: Colors.white,
                        fontSize: 36,
                        height: 1.1,
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),
                  Text(
                    result.tagline,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 24),
                  _buildResultCard(result.description, result.culturalLore, result.matchingCrafts),
                  const SizedBox(height: 32),

                  _buildExploreButton(context, result.matchingCrafts.isNotEmpty ? result.matchingCrafts.first : 'All Crafts'),

                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('RETAKE / UPDATE QUIZ', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCelebrationBadge() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24),
        boxShadow: [
          BoxShadow(color: const Color(0xFFFFD54F).withValues(alpha: 0.3), blurRadius: 50, spreadRadius: 5)
        ],
      ),
      child: const Icon(Icons.auto_awesome_rounded, size: 68, color: Color(0xFFFFD54F)),
    );
  }

  Widget _buildResultCard(String description, String lore, List<String> matchingCrafts) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Text(
            description,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.95), fontSize: 14.5, height: 1.6),
          ),
          if (lore.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '📜 $lore',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white70,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: matchingCrafts.map((craft) => _buildTag(craft.toUpperCase())).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD54F).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD54F)),
      ),
      child: Text(label, style: const TextStyle(color: Color(0xFFFFD54F), fontSize: 11, fontWeight: FontWeight.w900)),
    );
  }

  Widget _buildExploreButton(BuildContext context, String matchedCraft) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [Color(0xFFFFD54F), Color(0xFFFFB300)]),
        boxShadow: [
          BoxShadow(color: const Color(0xFFFFD54F).withValues(alpha: 0.4), blurRadius: 25, offset: const Offset(0, 10))
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          context.read<DirectoryViewModel>().updateFilter(craft: matchedCraft);
          context.read<NavigationViewModel>().setTab(1);
          Navigator.pop(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: const Text('EXPLORE MATCHING MASTERS', style: TextStyle(color: Color(0xFF004D40), fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 14)),
      ),
    );
  }
}

