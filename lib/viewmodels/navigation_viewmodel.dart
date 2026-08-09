import 'package:flutter/material.dart';

class NavigationViewModel extends ChangeNotifier {
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  void setTab(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  // Jump to Directory (Tab 1) from Home (Tab 0)
  void goToExplore() {
    _currentIndex = 1;
    notifyListeners();
  }
  
  // Jump to Passport (Tab 3)
  void goToPassport() {
    _currentIndex = 3;
    notifyListeners();
  }
}
