import 'package:flutter_test/flutter_test.dart';
import 'package:word_quest/features/adventure/application/adventure_level_quiz_builder.dart';
import 'package:word_quest/features/adventure/application/in_memory_adventure_repository.dart';

void main() {
  test('新词热身关生成看词选义题组', () {
    const repository = InMemoryAdventureRepository();
    const builder = AdventureLevelQuizBuilder();
    final adventure = repository.loadAdventure(
      childId: 'child-brother',
      referenceDate: DateTime(2026, 5, 2),
    );

    final quiz = builder.buildForLevel(adventure.levels[0]);

    expect(quiz.activityTitle, '新词热身');
    expect(quiz.progressLabel, '1 / 8');
    expect(quiz.instruction, '看单词，选择中文意思');
    expect(quiz.prompt, 'library');
    expect(quiz.correctAnswer, '图书馆');
    expect(quiz.choices, contains('图书馆'));
  });

  test('复习探索关生成听音选词题组', () {
    const repository = InMemoryAdventureRepository();
    const builder = AdventureLevelQuizBuilder();
    final adventure = repository.loadAdventure(
      childId: 'child-brother',
      referenceDate: DateTime(2026, 5, 2),
    );

    final quiz = builder.buildForLevel(adventure.levels[1]);

    expect(quiz.activityTitle, '听音训练');
    expect(quiz.progressLabel, '1 / 6');
    expect(quiz.instruction, '听发音，选择对应单词');
    expect(quiz.prompt, 'through');
    expect(quiz.correctAnswer, 'through');
    expect(quiz.choices, ['neighbor', 'library', 'through']);
  });

  test('错词 Boss 关生成正向挑战题组', () {
    const repository = InMemoryAdventureRepository();
    const builder = AdventureLevelQuizBuilder();
    final adventure = repository.loadAdventure(
      childId: 'child-brother',
      referenceDate: DateTime(2026, 5, 2),
    );

    final quiz = builder.buildForLevel(adventure.levels[2]);

    expect(quiz.activityTitle, '错词 Boss');
    expect(quiz.progressLabel, '1 / 4');
    expect(quiz.instruction, '收服迷雾单词');
    expect(quiz.prompt, 'through');
    expect(quiz.correctAnswer, '穿过');
    expect(quiz.successTitle, '收服成功');
  });
}
