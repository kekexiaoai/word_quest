import 'package:flutter_test/flutter_test.dart';
import 'package:word_quest/core/local_storage/local_key_value_store.dart';
import 'package:word_quest/features/adventure/application/adventure_session_controller.dart';
import 'package:word_quest/features/adventure/application/in_memory_adventure_repository.dart';
import 'package:word_quest/features/adventure/application/local_adventure_repository.dart';
import 'package:word_quest/features/adventure/domain/adventure_dashboard_snapshot.dart';
import 'package:word_quest/features/adventure/domain/adventure_level.dart';
import 'package:word_quest/features/adventure/domain/pet_profile.dart';

void main() {
  test('为每日冒险生成四个有顺序的关卡', () {
    const repository = InMemoryAdventureRepository();

    final snapshot = repository.loadAdventure(
      childId: 'child-brother',
      referenceDate: DateTime(2026, 5, 2),
    );

    expect(snapshot.themeTitle, '森林冒险');
    expect(snapshot.levels.map((level) => level.type), [
      AdventureLevelType.newWordWarmup,
      AdventureLevelType.reviewExplore,
      AdventureLevelType.mistakeBoss,
      AdventureLevelType.chestSettlement,
    ]);
    expect(snapshot.levels.map((level) => level.status), [
      AdventureLevelStatus.completed,
      AdventureLevelStatus.current,
      AdventureLevelStatus.locked,
      AdventureLevelStatus.locked,
    ]);
    expect(snapshot.levels[0].reward.foodName, '普通食物');
    expect(snapshot.levels[1].reward.energy, 8);
    expect(snapshot.levels[2].reward.foodName, '高级食物');
    expect(snapshot.levels[3].reward.growthPoints, 24);
  });

  test('默认宠物用于首页和结算反馈', () {
    const repository = InMemoryAdventureRepository();

    final snapshot = repository.loadAdventure(
      childId: 'child-brother',
      referenceDate: DateTime(2026, 5, 2),
    );

    expect(snapshot.pet.petId, 'sprout-fox');
    expect(snapshot.pet.name, '豆豆');
    expect(snapshot.pet.level, 2);
    expect(snapshot.pet.satiety, 68);
    expect(snapshot.pet.mood, PetMood.waiting);
    expect(snapshot.pet.growthPoints, 42);
    expect(snapshot.pet.growthTarget, 60);
  });

  test('保存后的冒险状态可以再次读取', () {
    final storage = <String, AdventureDashboardSnapshot>{};
    final repository = InMemoryAdventureRepository(storage: storage);
    const controller = AdventureSessionController();
    final snapshot = repository.loadAdventure(
      childId: 'child-brother',
      referenceDate: DateTime(2026, 5, 2),
    );

    final completed = controller.completeCurrentLevel(snapshot);
    final fed = controller.feedPetWithTodayRewards(
      completed,
      fedAt: DateTime(2026, 5, 2, 20),
    );
    repository.saveAdventure(fed);

    final restored = repository.loadAdventure(
      childId: 'child-brother',
      referenceDate: DateTime(2026, 5, 2),
    );

    expect(restored.starsEarned, 3);
    expect(restored.currentLevel.title, '错词 Boss 关');
    expect(restored.pet.name, '豆豆');
    expect(restored.pet.level, 3);
    expect(restored.pet.satiety, 88);
  });

  test('本地冒险仓库保存后新实例仍可恢复关卡和宠物', () {
    final store = MemoryLocalKeyValueStore();
    final firstRepository = LocalAdventureRepository(store: store);
    const controller = AdventureSessionController();
    final snapshot = firstRepository.loadAdventure(
      childId: 'child-brother',
      referenceDate: DateTime(2026, 5, 2),
    );

    final completed = controller.completeCurrentLevel(snapshot);
    final fed = controller.feedPetWithTodayRewards(
      completed,
      fedAt: DateTime(2026, 5, 2, 20),
    );
    firstRepository.saveAdventure(fed);

    final secondRepository = LocalAdventureRepository(store: store);
    final restored = secondRepository.loadAdventure(
      childId: 'child-brother',
      referenceDate: DateTime(2026, 5, 2),
    );

    expect(restored.starsEarned, 3);
    expect(restored.currentLevel.title, '错词 Boss 关');
    expect(restored.pet.level, 3);
    expect(restored.pet.satiety, 88);
    expect(restored.pet.lastFedAt, DateTime(2026, 5, 2, 20));
  });
}
