import 'answer_record.dart';

class WordLearningProgress {
  const WordLearningProgress({
    required this.childId,
    required this.wordId,
    required this.masteryLevel,
    required this.consecutiveMistakes,
    required this.nextReviewAt,
    required this.updatedAt,
    this.lastWeaknessType,
  });

  final String childId;
  final String wordId;
  final int masteryLevel;
  final int consecutiveMistakes;
  final DateTime nextReviewAt;
  final DateTime updatedAt;
  final AnswerWeaknessType? lastWeaknessType;

  bool get isMistake => consecutiveMistakes > 0;

  bool get isMastered => masteryLevel >= 3 && consecutiveMistakes == 0;

  WordLearningProgress copyWith({
    int? masteryLevel,
    int? consecutiveMistakes,
    DateTime? nextReviewAt,
    DateTime? updatedAt,
    AnswerWeaknessType? lastWeaknessType,
    bool clearWeaknessType = false,
  }) {
    return WordLearningProgress(
      childId: childId,
      wordId: wordId,
      masteryLevel: masteryLevel ?? this.masteryLevel,
      consecutiveMistakes: consecutiveMistakes ?? this.consecutiveMistakes,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastWeaknessType:
          clearWeaknessType ? null : lastWeaknessType ?? this.lastWeaknessType,
    );
  }
}
