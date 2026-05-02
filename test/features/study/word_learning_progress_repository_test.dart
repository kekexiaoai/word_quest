import 'package:flutter_test/flutter_test.dart';
import 'package:word_quest/core/local_storage/local_key_value_store.dart';
import 'package:word_quest/features/study/application/local_word_learning_progress_repository.dart';
import 'package:word_quest/features/study/domain/answer_record.dart';
import 'package:word_quest/features/study/domain/word_learning_progress.dart';

void main() {
  test('本地单词学习进度仓库保存后新实例仍可读取', () {
    final store = MemoryLocalKeyValueStore();
    final firstRepository = LocalWordLearningProgressRepository(store: store);

    firstRepository.saveProgress(
      WordLearningProgress(
        childId: 'child-brother',
        wordId: 'energy',
        masteryLevel: 3,
        consecutiveMistakes: 0,
        nextReviewAt: DateTime(2026, 5, 6),
        updatedAt: DateTime(2026, 5, 2),
        lastWeaknessType: AnswerWeaknessType.spelling,
      ),
    );

    final secondRepository = LocalWordLearningProgressRepository(store: store);
    final progress = secondRepository.loadProgress(
        childId: 'child-brother', wordId: 'energy');

    expect(progress?.masteryLevel, 3);
    expect(progress?.nextReviewAt, DateTime(2026, 5, 6));
    expect(progress?.lastWeaknessType, AnswerWeaknessType.spelling);
    expect(secondRepository.loadProgresses(childId: 'child-brother'),
        hasLength(1));
  });
}
