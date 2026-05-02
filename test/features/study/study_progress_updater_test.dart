import 'package:flutter_test/flutter_test.dart';
import 'package:word_quest/features/study/application/study_progress_updater.dart';
import 'package:word_quest/features/study/domain/answer_record.dart';
import 'package:word_quest/features/study/domain/study_task.dart';
import 'package:word_quest/features/study/domain/word_learning_progress.dart';

void main() {
  group('StudyProgressUpdater', () {
    test('答对会提升熟练度并延后下次复习', () {
      const updater = StudyProgressUpdater();

      final progress = updater.applyAnswer(
        progress: WordLearningProgress(
          childId: 'child-a',
          wordId: 'apple',
          masteryLevel: 1,
          consecutiveMistakes: 1,
          nextReviewAt: DateTime(2026, 5, 2),
          updatedAt: DateTime(2026, 5, 2),
        ),
        answer: _answer(isCorrect: true),
      );

      expect(progress.masteryLevel, 2);
      expect(progress.consecutiveMistakes, 0);
      expect(progress.isMistake, isFalse);
      expect(progress.nextReviewAt, DateTime(2026, 5, 6, 10));
    });

    test('答错会降低熟练度、标记错词并缩短复习间隔', () {
      const updater = StudyProgressUpdater();

      final progress = updater.applyAnswer(
        progress: WordLearningProgress(
          childId: 'child-a',
          wordId: 'apple',
          masteryLevel: 2,
          consecutiveMistakes: 0,
          nextReviewAt: DateTime(2026, 5, 8),
          updatedAt: DateTime(2026, 5, 2),
        ),
        answer: _answer(
          isCorrect: false,
          weaknessType: AnswerWeaknessType.spelling,
        ),
      );

      expect(progress.masteryLevel, 1);
      expect(progress.consecutiveMistakes, 1);
      expect(progress.isMistake, isTrue);
      expect(progress.lastWeaknessType, AnswerWeaknessType.spelling);
      expect(progress.nextReviewAt, DateTime(2026, 5, 3, 10));
    });
  });
}

AnswerRecord _answer({
  required bool isCorrect,
  AnswerWeaknessType? weaknessType,
}) {
  return AnswerRecord(
    childId: 'child-a',
    wordId: 'apple',
    practiceMode: PracticeMode.spelling,
    isCorrect: isCorrect,
    answeredAt: DateTime(2026, 5, 2, 10),
    elapsedMilliseconds: 1200,
    weaknessType: weaknessType,
  );
}
