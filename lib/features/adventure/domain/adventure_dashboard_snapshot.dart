import 'adventure_level.dart';
import 'pet_profile.dart';

class AdventureDashboardSnapshot {
  const AdventureDashboardSnapshot({
    required this.childId,
    required this.themeTitle,
    required this.currentNodeTitle,
    required this.starsEarned,
    required this.starsTarget,
    required this.chestProgress,
    required this.levels,
    required this.pet,
  });

  final String childId;
  final String themeTitle;
  final String currentNodeTitle;
  final int starsEarned;
  final int starsTarget;
  final double chestProgress;
  final List<AdventureLevel> levels;
  final PetProfile pet;

  AdventureLevel get currentLevel {
    return levels.firstWhere(
      (level) => level.status == AdventureLevelStatus.current,
      orElse: () => levels.last,
    );
  }
}
