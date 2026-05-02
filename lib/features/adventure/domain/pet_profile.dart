enum PetMood {
  happy,
  waiting,
  cheering,
  celebrating,
}

class PetProfile {
  const PetProfile({
    required this.childId,
    required this.petId,
    required this.name,
    required this.level,
    required this.growthPoints,
    required this.growthTarget,
    required this.satiety,
    required this.mood,
    required this.equippedDecorationIds,
    required this.unlockedDecorationIds,
    required this.lastFedAt,
  });

  final String childId;
  final String petId;
  final String name;
  final int level;
  final int growthPoints;
  final int growthTarget;
  final int satiety;
  final PetMood mood;
  final List<String> equippedDecorationIds;
  final List<String> unlockedDecorationIds;
  final DateTime? lastFedAt;
}
