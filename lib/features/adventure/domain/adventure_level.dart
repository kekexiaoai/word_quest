enum AdventureLevelType {
  newWordWarmup,
  reviewExplore,
  mistakeBoss,
  chestSettlement,
}

enum AdventureLevelStatus {
  locked,
  current,
  completed,
  reviewable,
}

class AdventureReward {
  const AdventureReward({
    this.stars = 0,
    this.foodName,
    this.foodCount = 0,
    this.energy = 0,
    this.growthPoints = 0,
    this.chestProgress = 0,
  });

  final int stars;
  final String? foodName;
  final int foodCount;
  final int energy;
  final int growthPoints;
  final int chestProgress;
}

class AdventureLevel {
  const AdventureLevel({
    required this.id,
    required this.childId,
    required this.date,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.questionCount,
    required this.reward,
  });

  final String id;
  final String childId;
  final DateTime date;
  final AdventureLevelType type;
  final String title;
  final String subtitle;
  final AdventureLevelStatus status;
  final int questionCount;
  final AdventureReward reward;
}
