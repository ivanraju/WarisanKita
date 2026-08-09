import 'package:flutter/material.dart';
import 'package:warisan_kita/ui/artisan/artisan_dashboard_tab.dart';
import 'package:warisan_kita/ui/artisan/artisan_settings_screen.dart';
import 'package:warisan_kita/ui/artisan/profile_builder_tab.dart';
import 'package:warisan_kita/ui/core/live_forum_tab.dart';

class ArtisanMainScaffold extends StatefulWidget {
  const ArtisanMainScaffold({super.key});

  @override
  State<ArtisanMainScaffold> createState() => _ArtisanMainScaffoldState();
}

class _ArtisanMainScaffoldState extends State<ArtisanMainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    ArtisanDashboardTab(),
    ProfileBuilderTab(),
    LiveForumTab(),
    ArtisanSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            )
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFFD97706),
          unselectedItemColor: Colors.black38,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.edit_note_outlined),
              activeIcon: Icon(Icons.edit_note),
              label: 'Edit Profile',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.forum_outlined),
              activeIcon: Icon(Icons.forum),
              label: 'Forum',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
