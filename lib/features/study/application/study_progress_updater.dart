import '../domain/answer_record.dart';
import '../domain/word_learning_progress.dart';

class StudyProgressUpdater {
  const StudyProgressUpdater();

  static const _maxMasteryLevel = 5;
  static const _reviewIntervalsInDays = {
    0: 1,
    1: 2,
    2: 4,
    3: 7,
    4: 14,
    5: 30,
  };

  WordLearningProgress applyAnswer({
    required WordLearningProgress progress,
    required AnswerRecord answer,
  }) {
    if (answer.isCorrect) {
      final nextMastery = (progress.masteryLevel + 1).clamp(
        0,
        _maxMasteryLevel,
      );

      return progress.copyWith(
        masteryLevel: nextMastery,
        consecutiveMistakes: 0,
        nextReviewAt: _nextReviewAt(answer.answeredAt, nextMastery),
        updatedAt: answer.answeredAt,
        clearWeaknessType: true,
      );
    }

    final nextMastery = (progress.masteryLevel - 1).clamp(
      0,
      _maxMasteryLevel,
    );

    return progress.copyWith(
      masteryLevel: nextMastery,
      consecutiveMistakes: progress.consecutiveMistakes + 1,
      nextReviewAt: answer.answeredAt.add(const Duration(days: 1)),
      updatedAt: answer.answeredAt,
      lastWeaknessType: answer.weaknessType,
    );
  }

  DateTime _nextReviewAt(DateTime answeredAt, int masteryLevel) {
    final intervalDays = _reviewIntervalsInDays[masteryLevel] ?? 1;
    return answeredAt.add(Duration(days: intervalDays));
  }
}
