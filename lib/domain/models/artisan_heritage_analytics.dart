class DailyVerifiedVisitors {
  final DateTime date;
  final int count;

  const DailyVerifiedVisitors({required this.date, required this.count});
}

class ArtisanHeritageAnalytics {
  final int totalUniqueVisitors;
  final List<DailyVerifiedVisitors> dailyVisitors;
  final String visitorSource;
  final int? passportStampsAwarded;
  final int? completedTourists;
  final int? completionTarget;

  const ArtisanHeritageAnalytics({
    required this.totalUniqueVisitors,
    required this.dailyVisitors,
    this.visitorSource = 'arrival_task',
    required this.passportStampsAwarded,
    required this.completedTourists,
    this.completionTarget,
  });

  double? get completionProgress {
    final completed = completedTourists;
    final target = completionTarget;
    if (completed == null || target == null || target <= 0) return null;
    return (completed / target).clamp(0.0, 1.0);
  }

  int get highlightedDayIndex {
    if (dailyVisitors.isEmpty) return -1;
    var selectedIndex = 0;
    for (var index = 1; index < dailyVisitors.length; index++) {
      if (dailyVisitors[index].count >= dailyVisitors[selectedIndex].count) {
        selectedIndex = index;
      }
    }
    return selectedIndex;
  }
}
