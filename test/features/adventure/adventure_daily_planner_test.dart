import 'package:flutter_test/flutter_test.dart';
import 'package:word_quest/features/adventure/application/adventure_daily_planner.dart';
import 'package:word_quest/features/adventure/application/in_memory_adventure_repository.dart';
import 'package:word_quest/features/study/domain/answer_record.dart';
import 'package:word_quest/features/study/domain/word_learning_progress.dart';
import 'package:word_quest/features/word_book/domain/word_book.dart';
import 'package:word_quest/features/word_book/domain/word_entry.dart';

void main() {
  test('没有词表上下文时保留默认题量', () {
    const repository = InMemoryAdventureRepository();
    const planner = AdventureDailyPlanner();
    final snapshot = repository.loadAdventure(
      childId: 'child-brother',
      referenceDate: DateTime(2026, 5, 2),
    );

    final planned = planner.plan(
      snapshot: snapshot,
      wordBooks: const [],
      learningProgresses: const [],
      selectedWordBookId: null,
    );

    expect(planned.levels[0].questionCount, 8);
    expect(planned.levels[1].questionCount, 6);
    expect(planned.levels[2].questionCount, 4);
  });

  test('按当前词表未学词、到期复习和错词数量生成题量', () {
    const repository = InMemoryAdventureRepository();
    const planner = AdventureDailyPlanner();
    final snapshot = repository.loadAdventure(
      childId: 'child-brother',
      referenceDate: DateTime(2026, 5, 2),
    );

    final planned = planner.plan(
      snapshot: snapshot,
      selectedWordBookId: 'middle-core',
      wordBooks: const [
        WordBook(
          id: 'middle-core',
          name: '初中核心词表',
          stageLabel: '初中',
          words: [
            WordEntry(id: 'word-1', spelling: 'word1', meanings: ['词 1']),
            WordEntry(id: 'word-2', spelling: 'word2', meanings: ['词 2']),
            WordEntry(id: 'word-3', spelling: 'word3', meanings: ['词 3']),
            WordEntry(id: 'word-4', spelling: 'word4', meanings: ['词 4']),
            WordEntry(id: 'word-5', spelling: 'word5', meanings: ['词 5']),
            WordEntry(id: 'word-6', spelling: 'word6', meanings: ['词 6']),
            WordEntry(id: 'word-7', spelling: 'word7', meanings: ['词 7']),
            WordEntry(id: 'word-8', spelling: 'word8', meanings: ['词 8']),
            WordEntry(id: 'word-9', spelling: 'word9', meanings: ['词 9']),
            WordEntry(id: 'word-10', spelling: 'word10', meanings: ['词 10']),
          ],
        ),
      ],
      learningProgresses: [
        WordLearningProgress(
          childId: 'child-brother',
          wordId: 'word-1',
          masteryLevel: 3,
          consecutiveMistakes: 0,
          nextReviewAt: DateTime(2026, 5, 9),
          updatedAt: DateTime(2026, 5, 1),
        ),
        WordLearningProgress(
          childId: 'child-brother',
          wordId: 'word-2',
          masteryLevel: 2,
          consecutiveMistakes: 0,
          nextReviewAt: DateTime(2026, 5, 2),
          updatedAt: DateTime(2026, 5, 1),
        ),
        WordLearningProgress(
          childId: 'child-brother',
          wordId: 'word-3',
          masteryLevel: 1,
          consecutiveMistakes: 0,
          nextReviewAt: DateTime(2026, 5, 1),
          updatedAt: DateTime(2026, 5, 1),
        ),
        WordLearningProgress(
          childId: 'child-brother',
          wordId: 'word-4',
          masteryLevel: 0,
          consecutiveMistakes: 2,
          nextReviewAt: DateTime(2026, 5, 2),
          updatedAt: DateTime(2026, 5, 1),
          lastWeaknessType: AnswerWeaknessType.meaning,
        ),
      ],
    );

    expect(planned.levels[0].questionCount, 6);
    expect(planned.levels[0].subtitle, '6 题 · 新词热身');
    expect(planned.levels[1].questionCount, 3);
    expect(planned.levels[1].subtitle, '3 题 · 到期复习');
    expect(planned.levels[2].questionCount, 2);
    expect(planned.levels[2].subtitle, '2 题 · 收服迷雾单词');
  });

  test('高掌握比例时减少新词量并提高复习量', () {
    const repository = InMemoryAdventureRepository();
    const planner = AdventureDailyPlanner();
    final snapshot = repository.loadAdventure(
      childId: 'child-brother',
      referenceDate: DateTime(2026, 5, 2),
    );

    final planned = planner.plan(
      snapshot: snapshot,
      selectedWordBookId: 'middle-core',
      wordBooks: const [
        WordBook(
          id: 'middle-core',
          name: '初中核心词表',
          stageLabel: '初中',
          words: [
            WordEntry(id: 'word-1', spelling: 'word1', meanings: ['词 1']),
            WordEntry(id: 'word-2', spelling: 'word2', meanings: ['词 2']),
            WordEntry(id: 'word-3', spelling: 'word3', meanings: ['词 3']),
            WordEntry(id: 'word-4', spelling: 'word4', meanings: ['词 4']),
            WordEntry(id: 'word-5', spelling: 'word5', meanings: ['词 5']),
          ],
        ),
      ],
      learningProgresses: [
        for (final index in [1, 2, 3, 4])
          WordLearningProgress(
            childId: 'child-brother',
            wordId: 'word-$index',
            masteryLevel: 3,
            consecutiveMistakes: 0,
            nextReviewAt: DateTime(2026, 5, 2),
            updatedAt: DateTime(2026, 5, 1),
          ),
      ],
    );

    expect(planned.levels[0].questionCount, 2);
    expect(planned.levels[1].questionCount, 6);
    expect(planned.levels[2].questionCount, 2);
  });

  test('只统计当前孩子和当前词表的学习进度', () {
    const repository = InMemoryAdventureRepository();
    const planner = AdventureDailyPlanner();
    final snapshot = repository.loadAdventure(
      childId: 'child-brother',
      referenceDate: DateTime(2026, 5, 2),
    );

    final planned = planner.plan(
      snapshot: snapshot,
      selectedWordBookId: 'middle-core',
      wordBooks: const [
        WordBook(
          id: 'middle-core',
          name: '初中核心词表',
          stageLabel: '初中',
          words: [
            WordEntry(id: 'word-1', spelling: 'word1', meanings: ['词 1']),
            WordEntry(id: 'word-2', spelling: 'word2', meanings: ['词 2']),
            WordEntry(id: 'word-3', spelling: 'word3', meanings: ['词 3']),
            WordEntry(id: 'word-4', spelling: 'word4', meanings: ['词 4']),
          ],
        ),
        WordBook(
          id: 'other-book',
          name: '其他词表',
          stageLabel: '其他',
          words: [
            WordEntry(id: 'other-1', spelling: 'other1', meanings: ['其他 1']),
          ],
        ),
      ],
      learningProgresses: [
        WordLearningProgress(
          childId: 'child-sister',
          wordId: 'word-1',
          masteryLevel: 3,
          consecutiveMistakes: 0,
          nextReviewAt: DateTime(2026, 5, 2),
          updatedAt: DateTime(2026, 5, 1),
        ),
        WordLearningProgress(
          childId: 'child-brother',
          wordId: 'other-1',
          masteryLevel: 0,
          consecutiveMistakes: 3,
          nextReviewAt: DateTime(2026, 5, 2),
          updatedAt: DateTime(2026, 5, 1),
        ),
      ],
    );

    expect(planned.levels[0].questionCount, 4);
    expect(planned.levels[1].questionCount, 3);
    expect(planned.levels[2].questionCount, 2);
  });
}
