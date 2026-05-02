import 'study_task.dart';

enum AnswerWeaknessType {
  meaning,
  spelling,
  listening,
}

class AnswerRecord {
  const AnswerRecord({
    required this.childId,
    required this.wordId,
    required this.practiceMode,
    required this.isCorrect,
    required this.answeredAt,
    required this.elapsedMilliseconds,
    this.weaknessType,
  });

  final String childId;
  final String wordId;
  final PracticeMode practiceMode;
  final bool isCorrect;
  final DateTime answeredAt;
  final int elapsedMilliseconds;
  final AnswerWeaknessType? weaknessType;
}
