import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:warisan_kita/features/directory/directory_catalog_screen.dart';
import 'package:warisan_kita/features/matchmaker/quiz_wizard_screen.dart';
import 'package:warisan_kita/features/forum/forum_index_screen.dart';
import 'package:warisan_kita/features/gamification/passport_dashboard_screen.dart';
import 'package:warisan_kita/state/navigation_state.dart';

class TouristDashboardScreen extends StatelessWidget {
  const TouristDashboardScreen({super.key});

  final List<Widget> _pages = const [
    TouristHomeContent(),
    DirectoryCatalogScreen(),
    ForumIndexScreen(),
    PassportDashboardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // 4-Layer Architecture: UI listening to Global Navigation State
    final navState = context.watch<NavigationState>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: IndexedStack(
        index: navState.currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNav(context, navState),
    );
  }

  Widget _buildBottomNav(BuildContext context, NavigationState navState) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF004D40).withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BottomNavigationBar(
          currentIndex: navState.currentIndex,
          onTap: (index) => navState.setTab(index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF004D40),
          unselectedItemColor: Colors.black26,
          showSelectedLabels: true,
          showUnselectedLabels: false,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              activeIcon: Icon(Icons.home_filled, size: 28),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore, size: 28),
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.forum_outlined),
              activeIcon: Icon(Icons.forum, size: 28),
              label: 'Forum',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.card_membership_outlined),
              activeIcon: Icon(Icons.card_membership, size: 28),
              label: 'Passport',
            ),
          ],
        ),
      ),
    );
  }
}

class TouristHomeContent extends StatelessWidget {
  const TouristHomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildAppBar(),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildHeroCard(context),
                const SizedBox(height: 40),
                _buildSectionHeader('Top Curations', 'Hand-picked for you'),
                const SizedBox(height: 20),
                _buildCurationList(),
                const SizedBox(height: 40),
                _buildSectionHeader('Explore States', 'Traditions by region'),
                const SizedBox(height: 20),
                _buildStateGrid(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: const Color(0xFFF8F9FA),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        title: Text(
          'WarisanKita',
          style: GoogleFonts.dmSerifDisplay(
            color: const Color(0xFF004D40),
            fontSize: 28,
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF004D40)),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF004D40), Color(0xFF00796B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF004D40).withOpacity(0.3),
            blurRadius: 25,
            offset: const Offset(0, 15),
          )
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(Icons.auto_awesome_mosaic_rounded, size: 200, color: Colors.white.withOpacity(0.05)),
          ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Discovery\nBegins Here',
                  style: GoogleFonts.dmSerifDisplay(color: Colors.white, fontSize: 32, height: 1.1),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Match your soul with the\nperfect Malaysian craft.',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuizWizardScreen())),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD54F),
                    foregroundColor: const Color(0xFF004D40),
                  ),
                  child: const Text('START QUIZ', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.dmSerifDisplay(fontSize: 22, color: const Color(0xFF004D40))),
        Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.black26, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildCurationList() {
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: 4,
        itemBuilder: (context, index) => Container(
          width: 180,
          margin: const EdgeInsets.only(right: 20, bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Image.network(
                    'https://images.unsplash.com/photo-1544967082-d9d25d867d66?w=400&idx=$index',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Silk Songket', style: GoogleFonts.dmSerifDisplay(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStateGrid() {
    final states = ['Kelantan', 'Terengganu', 'Melaka', 'Perak'];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: 4,
      itemBuilder: (context, index) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Center(
          child: Text(
            states[index],
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: const Color(0xFF004D40)),
          ),
        ),
      ),
    );
  }
}
