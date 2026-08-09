import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/ui/matchmaker/tourist_matchmaker_view.dart';
import 'package:warisan_kita/ui/core/live_forum_tab.dart';
import 'package:warisan_kita/ui/tourist/tourist_directory_tab.dart';
import 'package:warisan_kita/ui/tourist/tourist_profile_tab.dart';
import 'package:warisan_kita/viewmodels/language_viewmodel.dart';

class TouristMainScaffold extends StatefulWidget {
  const TouristMainScaffold({super.key});

  @override
  State<TouristMainScaffold> createState() => _TouristMainScaffoldState();
}

class _TouristMainScaffoldState extends State<TouristMainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    TouristDirectoryTab(),
    TouristMatchmakerView(),
    LiveForumTab(),
    TouristProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final langVM = context.watch<LanguageViewModel>();

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
              color: Colors.black.withValues(alpha: 0.06),
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
          selectedItemColor: const Color(0xFF004D40),
          unselectedItemColor: Colors.black38,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.explore_outlined),
              activeIcon: const Icon(Icons.explore),
              label: langVM.translate('nav_explore'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.map_outlined),
              activeIcon: const Icon(Icons.map),
              label: langVM.translate('nav_matchmaker'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.forum_outlined),
              activeIcon: const Icon(Icons.forum),
              label: langVM.translate('nav_forum'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.card_membership_outlined),
              activeIcon: const Icon(Icons.card_membership),
              label: langVM.translate('nav_passport'),
            ),
          ],
        ),
      ),
    );
  }
}
