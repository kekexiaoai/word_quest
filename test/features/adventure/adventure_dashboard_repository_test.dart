import 'package:flutter_test/flutter_test.dart';
import 'package:word_quest/features/adventure/application/in_memory_adventure_repository.dart';
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
}
