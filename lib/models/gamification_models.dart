enum TierStatus { observer, apprentice, guardian }

class HeritageStamp {
  final String id;
  final String title;
  final String iconUrl;
  final bool isUnlocked;
  final String description;

  HeritageStamp({
    required this.id,
    required this.title,
    required this.iconUrl,
    this.isUnlocked = false,
    this.description = '',
  });
}

class HeritageTask {
  final String id;
  final String workshopId;
  final String title;
  final bool isCompleted;
  final bool isRequired;
  final String xpReward;

  HeritageTask({
    required this.id,
    required this.workshopId,
    required this.title,
    this.isCompleted = false,
    this.isRequired = true,
    this.xpReward = '50 XP',
  });
}
