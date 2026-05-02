import '../domain/adventure_dashboard_snapshot.dart';
import '../domain/adventure_level.dart';
import '../domain/adventure_repository.dart';
import '../domain/pet_profile.dart';

class InMemoryAdventureRepository implements AdventureRepository {
  const InMemoryAdventureRepository();

  @override
  AdventureDashboardSnapshot loadAdventure({
    required String childId,
    required DateTime referenceDate,
  }) {
    final date = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
    );

    return AdventureDashboardSnapshot(
      childId: childId,
      themeTitle: '森林冒险',
      currentNodeTitle: '森林书屋 · 第 4 站',
      starsEarned: 2,
      starsTarget: 3,
      chestProgress: 0.65,
      levels: [
        AdventureLevel(
          id: '$childId-new-word-warmup',
          childId: childId,
          date: date,
          type: AdventureLevelType.newWordWarmup,
          title: '新词热身关',
          subtitle: '8 题 · 英选中 / 中选英',
          status: AdventureLevelStatus.completed,
          questionCount: 8,
          reward: const AdventureReward(
            stars: 1,
            foodName: '普通食物',
            foodCount: 1,
          ),
        ),
        AdventureLevel(
          id: '$childId-review-explore',
          childId: childId,
          date: date,
          type: AdventureLevelType.reviewExplore,
          title: '复习探索关',
          subtitle: '6 题 · 选择 / 拼写 / 听音',
          status: AdventureLevelStatus.current,
          questionCount: 6,
          reward: const AdventureReward(
            stars: 1,
            foodName: '能量饮品',
            foodCount: 1,
            energy: 8,
          ),
        ),
        AdventureLevel(
          id: '$childId-mistake-boss',
          childId: childId,
          date: date,
          type: AdventureLevelType.mistakeBoss,
          title: '错词 Boss 关',
          subtitle: '4 题 · 收服迷雾单词',
          status: AdventureLevelStatus.locked,
          questionCount: 4,
          reward: const AdventureReward(
            stars: 1,
            foodName: '高级食物',
            foodCount: 1,
            chestProgress: 30,
          ),
        ),
        AdventureLevel(
          id: '$childId-chest-settlement',
          childId: childId,
          date: date,
          type: AdventureLevelType.chestSettlement,
          title: '宝箱结算关',
          subtitle: '汇总星星、食物和宠物成长',
          status: AdventureLevelStatus.locked,
          questionCount: 0,
          reward: const AdventureReward(
            growthPoints: 24,
            chestProgress: 100,
          ),
        ),
      ],
      pet: PetProfile(
        childId: childId,
        petId: 'sprout-fox',
        name: '豆豆',
        level: 2,
        growthPoints: 42,
        growthTarget: 60,
        satiety: 68,
        mood: PetMood.waiting,
        equippedDecorationIds: const ['adventure-scarf'],
        unlockedDecorationIds: const ['adventure-scarf'],
        lastFedAt: DateTime(2026, 5, 1, 19),
      ),
    );
  }
}
