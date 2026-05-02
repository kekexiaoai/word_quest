import '../domain/adventure_dashboard_snapshot.dart';
import '../domain/adventure_level.dart';
import '../domain/pet_profile.dart';

class AdventureSessionController {
  const AdventureSessionController();

  bool canEnter(AdventureLevel level) {
    return switch (level.status) {
      AdventureLevelStatus.current ||
      AdventureLevelStatus.completed ||
      AdventureLevelStatus.reviewable =>
        true,
      AdventureLevelStatus.locked => false,
    };
  }

  AdventureDashboardSnapshot completeCurrentLevel(
    AdventureDashboardSnapshot snapshot,
  ) {
    final currentIndex = snapshot.levels.indexWhere(
      (level) => level.status == AdventureLevelStatus.current,
    );
    if (currentIndex == -1) {
      return snapshot;
    }

    final updatedLevels = [
      for (var index = 0; index < snapshot.levels.length; index++)
        _levelWithStatus(
          snapshot.levels[index],
          _nextStatus(snapshot, index, currentIndex),
        ),
    ];
    final currentReward = snapshot.levels[currentIndex].reward;

    return AdventureDashboardSnapshot(
      childId: snapshot.childId,
      themeTitle: snapshot.themeTitle,
      currentNodeTitle: snapshot.currentNodeTitle,
      starsEarned:
          (snapshot.starsEarned + currentReward.stars).clamp(0, 999).toInt(),
      starsTarget: snapshot.starsTarget,
      chestProgress: (snapshot.chestProgress +
              (currentReward.chestProgress > 0
                  ? currentReward.chestProgress / 100
                  : 0))
          .clamp(0, 1),
      levels: updatedLevels,
      pet: snapshot.pet,
    );
  }

  AdventureDashboardSnapshot feedPetWithTodayRewards(
    AdventureDashboardSnapshot snapshot, {
    required DateTime fedAt,
  }) {
    final growthReward = snapshot.levels.fold<int>(
      0,
      (total, level) => total + level.reward.growthPoints,
    );
    final fedPet = _growPet(
      snapshot.pet,
      growthReward: growthReward,
      fedAt: fedAt,
    );

    return AdventureDashboardSnapshot(
      childId: snapshot.childId,
      themeTitle: snapshot.themeTitle,
      currentNodeTitle: snapshot.currentNodeTitle,
      starsEarned: snapshot.starsEarned,
      starsTarget: snapshot.starsTarget,
      chestProgress: snapshot.chestProgress,
      levels: snapshot.levels,
      pet: fedPet,
    );
  }

  AdventureLevelStatus _nextStatus(
    AdventureDashboardSnapshot snapshot,
    int index,
    int currentIndex,
  ) {
    final currentStatus = snapshot.levels[index].status;
    if (index == currentIndex) {
      return AdventureLevelStatus.completed;
    }
    if (index == currentIndex + 1 &&
        currentStatus == AdventureLevelStatus.locked) {
      return AdventureLevelStatus.current;
    }
    return currentStatus;
  }

  AdventureLevel _levelWithStatus(
    AdventureLevel level,
    AdventureLevelStatus status,
  ) {
    return AdventureLevel(
      id: level.id,
      childId: level.childId,
      date: level.date,
      type: level.type,
      title: level.title,
      subtitle: level.subtitle,
      status: status,
      questionCount: level.questionCount,
      reward: level.reward,
    );
  }

  PetProfile _growPet(
    PetProfile pet, {
    required int growthReward,
    required DateTime fedAt,
  }) {
    final satiety = (pet.satiety + 20).clamp(0, 100).toInt();
    var level = pet.level;
    var growthPoints = pet.growthPoints + growthReward;
    var growthTarget = pet.growthTarget;

    while (growthPoints >= growthTarget) {
      growthPoints -= growthTarget;
      level += 1;
      growthTarget += 30;
    }

    return PetProfile(
      childId: pet.childId,
      petId: pet.petId,
      name: pet.name,
      level: level,
      growthPoints: growthPoints,
      growthTarget: growthTarget,
      satiety: satiety,
      mood: PetMood.happy,
      equippedDecorationIds: pet.equippedDecorationIds,
      unlockedDecorationIds: pet.unlockedDecorationIds,
      lastFedAt: fedAt,
    );
  }
}
