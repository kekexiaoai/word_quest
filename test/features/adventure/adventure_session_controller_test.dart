import 'package:flutter_test/flutter_test.dart';
import 'package:word_quest/features/adventure/application/adventure_session_controller.dart';
import 'package:word_quest/features/adventure/application/in_memory_adventure_repository.dart';
import 'package:word_quest/features/adventure/domain/adventure_level.dart';
import 'package:word_quest/features/adventure/domain/pet_profile.dart';

void main() {
  test('完成当前关卡后点亮当前节点并解锁下一关', () {
    const repository = InMemoryAdventureRepository();
    const controller = AdventureSessionController();
    final snapshot = repository.loadAdventure(
      childId: 'child-brother',
      referenceDate: DateTime(2026, 5, 2),
    );

    final updated = controller.completeCurrentLevel(snapshot);

    expect(updated.starsEarned, 3);
    expect(updated.levels.map((level) => level.status), [
      AdventureLevelStatus.completed,
      AdventureLevelStatus.completed,
      AdventureLevelStatus.current,
      AdventureLevelStatus.locked,
    ]);
  });

  test('锁定关卡不能进入，当前和已完成关卡可以进入', () {
    const repository = InMemoryAdventureRepository();
    const controller = AdventureSessionController();
    final snapshot = repository.loadAdventure(
      childId: 'child-brother',
      referenceDate: DateTime(2026, 5, 2),
    );

    expect(controller.canEnter(snapshot.levels[0]), isTrue);
    expect(controller.canEnter(snapshot.levels[1]), isTrue);
    expect(controller.canEnter(snapshot.levels[2]), isFalse);
  });

  test('喂食会提升饱腹、消耗今日成长奖励并触发升级', () {
    const repository = InMemoryAdventureRepository();
    const controller = AdventureSessionController();
    final snapshot = repository.loadAdventure(
      childId: 'child-brother',
      referenceDate: DateTime(2026, 5, 2),
    );

    final updated = controller.feedPetWithTodayRewards(
      snapshot,
      fedAt: DateTime(2026, 5, 2, 20),
    );

    expect(updated.pet.satiety, 88);
    expect(updated.pet.level, 3);
    expect(updated.pet.growthPoints, 6);
    expect(updated.pet.mood, PetMood.happy);
    expect(updated.pet.lastFedAt, DateTime(2026, 5, 2, 20));
  });
}
