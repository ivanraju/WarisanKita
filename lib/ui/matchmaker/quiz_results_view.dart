import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/viewmodels/matchmaker_viewmodel.dart';
import 'package:warisan_kita/viewmodels/directory_viewmodel.dart';
import 'package:warisan_kita/viewmodels/navigation_viewmodel.dart';

class QuizResultsScreen extends StatelessWidget {
  const QuizResultsScreen({super.key});

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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  _buildCelebrationBadge(),
                  const SizedBox(height: 40),
                  
                  Text(
                    'YOUR CRAFT SOUL IS...',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFFFFD54F),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
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
                        fontSize: 48,
                        height: 1.1,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  _buildResultCard(result.description, result.matchingCrafts),
                  const Spacer(),
                  
                  _buildExploreButton(context, result.matchingCrafts.isNotEmpty ? result.matchingCrafts.first : 'All Crafts'),
                  
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('TRY AGAIN', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
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
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24),
        boxShadow: [
          BoxShadow(color: const Color(0xFFFFD54F).withOpacity(0.3), blurRadius: 50, spreadRadius: 5)
        ],
      ),
      child: const Icon(Icons.auto_awesome_rounded, size: 80, color: Color(0xFFFFD54F)),
    );
  }

  Widget _buildResultCard(String description, List<String> matchingCrafts) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Text(
            description,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(color: Colors.white.withOpacity(0.9), fontSize: 16, height: 1.8),
          ),
          const SizedBox(height: 24),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFF7043).withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF7043).withOpacity(0.4)),
      ),
      child: Text(label, style: const TextStyle(color: Color(0xFFFF7043), fontSize: 11, fontWeight: FontWeight.w900)),
    );
  }

  Widget _buildExploreButton(BuildContext context, String matchedCraft) {
    return Container(
      width: double.infinity,
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(colors: [Color(0xFFFF7043), Color(0xFFF4511E)]),
        boxShadow: [
          BoxShadow(color: const Color(0xFFFF7043).withOpacity(0.4), blurRadius: 25, offset: const Offset(0, 12))
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          // FIXED: updateFilter requires named parameter 'craft'
          context.read<DirectoryViewModel>().updateFilter(craft: matchedCraft);
          // Switch tab to 'Explore' (Index 1)
          context.read<NavigationViewModel>().setTab(1);
          Navigator.pop(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        child: const Text('EXPLORE MATCHING MASTERS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
      ),
    );
  }
}
