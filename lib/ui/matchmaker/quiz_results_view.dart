import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/ui/matchmaker/craft_matchmaker_quiz_wizard.dart';
import 'package:warisan_kita/viewmodels/matchmaker_viewmodel.dart';
import 'package:warisan_kita/viewmodels/directory_viewmodel.dart';
import 'package:warisan_kita/viewmodels/navigation_viewmodel.dart';
import 'package:warisan_kita/viewmodels/language_viewmodel.dart';

class QuizResultsScreen extends StatelessWidget {
  const QuizResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final langVM = context.watch<LanguageViewModel>();
    final matchState = context.watch<MatchmakerViewModel>();
    final result = matchState.calculateResult();

    return Scaffold(
      backgroundColor: const Color(0xFF004D40),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
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
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _buildCelebrationBadge(),
                  const SizedBox(height: 24),

                  Text(
                    langVM.translate('YOUR CRAFT SOUL IS...'),
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

                  if (result.tagline.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      result.tagline,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFFFFD54F).withOpacity(0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  _buildResultCard(context, langVM, result.description, result.matchingCrafts),
                  const SizedBox(height: 28),

                  _buildExploreButton(
                    context,
                    langVM,
                    result.primaryCategory != 'All Crafts'
                        ? result.primaryCategory
                        : (result.matchingCrafts.isNotEmpty ? result.matchingCrafts.first : 'All Crafts'),
                  ),

                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => CraftMatchmakerQuizWizard(
                              onCompleted: (_) {},
                            ),
                          );
                        },
                        icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 18),
                        label: Text(
                          langVM.translate('UPDATE PREFERENCES'),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
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
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24),
        boxShadow: [
          BoxShadow(color: const Color(0xFFFFD54F).withOpacity(0.3), blurRadius: 50, spreadRadius: 5)
        ],
      ),
      child: const Icon(Icons.auto_awesome_rounded, size: 70, color: Color(0xFFFFD54F)),
    );
  }

  Widget _buildResultCard(BuildContext context, LanguageViewModel langVM, String description, List<String> matchingCrafts) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Text(
            description,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(color: Colors.white.withOpacity(0.9), fontSize: 14, height: 1.7),
          ),
          const SizedBox(height: 20),
          Text(
            langVM.translate('MATCHING HERITAGE DISCIPLINES').toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
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
        color: const Color(0xFFFF7043).withOpacity(0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFF7043).withOpacity(0.4)),
      ),
      child: Text(label, style: const TextStyle(color: Color(0xFFFF7043), fontSize: 11, fontWeight: FontWeight.w900)),
    );
  }

  Widget _buildExploreButton(BuildContext context, LanguageViewModel langVM, String matchedCraft) {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [Color(0xFFFF7043), Color(0xFFF4511E)]),
        boxShadow: [
          BoxShadow(color: const Color(0xFFFF7043).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))
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
        child: Text(
          langVM.translate('EXPLORE MATCHING MASTERS'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 14),
        ),
      ),
    );
  }
}
