import 'package:flutter/material.dart';
import 'package:warisan_kita/models/gamification_models.dart';
import 'package:warisan_kita/services/supabase_service.dart';

class GamificationState extends ChangeNotifier {
  final SupabaseService _service = SupabaseService();

  List<HeritageStamp> _stamps = [];
  List<HeritageStamp> get stamps => _stamps;

  List<HeritageTask> _activeTasks = [];
  List<HeritageTask> get activeTasks => _activeTasks;

  double _rankProgress = 0.65;
  double get rankProgress => _rankProgress;

  TierStatus _currentTier = TierStatus.apprentice;
  TierStatus get currentTier => _currentTier;

  GamificationState() {
    _initializeMockData();
  }

  void _initializeMockData() {
    _stamps = [
      HeritageStamp(
        id: '1',
        title: 'Batik Master',
        iconUrl: 'https://images.unsplash.com/photo-1590739225287-bd31519780c3?w=200',
        isUnlocked: true,
      ),
      HeritageStamp(
        id: '2',
        title: 'Songket Weaver',
        iconUrl: 'https://images.unsplash.com/photo-1544967082-d9d25d867d66?w=200',
        isUnlocked: true,
      ),
      HeritageStamp(
        id: '3',
        title: 'Wood Carver',
        iconUrl: 'https://images.unsplash.com/photo-1605721911519-3dfeb3be25e7?w=200',
        isUnlocked: true,
      ),
      HeritageStamp(
        id: '4',
        title: 'Metal Smith',
        iconUrl: 'https://images.unsplash.com/photo-1533090161767-e6ffed986c88?w=200',
        isUnlocked: true,
      ),
      HeritageStamp(
        id: '5',
        title: 'Wau Maker',
        iconUrl: 'https://images.unsplash.com/photo-1550684848-fac1c5b4e853?w=200',
        isUnlocked: false,
      ),
      HeritageStamp(
        id: '6',
        title: 'Pottery Artist',
        iconUrl: 'https://images.unsplash.com/photo-1565193998771-e64b81bd957d?w=200',
        isUnlocked: false,
      ),
    ];

    _activeTasks = [
      HeritageTask(id: '101', workshopId: 'w1', title: 'Observe Cengal wood selection', isCompleted: true),
      HeritageTask(id: '102', workshopId: 'w1', title: 'Watch the initial carving', isCompleted: true),
      HeritageTask(id: '103', workshopId: 'w1', title: 'Scan Workshop QR Code', isCompleted: false),
      HeritageTask(id: '104', workshopId: 'w1', title: 'Try the carving chisel', isCompleted: false, isRequired: false),
    ];
  }

  Future<void> verifyQRCode(String code) async {
    // Logic to verify QR and unlock stamps/tasks
    await Future.delayed(const Duration(seconds: 1));
    
    // Simulating unlocking a new stamp
    for (int i = 0; i < _stamps.length; i++) {
      if (!_stamps[i].isUnlocked) {
        _stamps[i] = HeritageStamp(
          id: _stamps[i].id,
          title: _stamps[i].title,
          iconUrl: _stamps[i].iconUrl,
          isUnlocked: true,
        );
        break;
      }
    }
    
    _rankProgress = 0.85;
    notifyListeners();
  }
}
