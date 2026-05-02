import '../domain/answer_record.dart';
import '../domain/study_question.dart';
import '../domain/study_task.dart';

class StudyAnswerEvaluator {
  const StudyAnswerEvaluator();

  AnswerRecord evaluate({
    required String childId,
    required StudyQuestion question,
    required String submittedAnswer,
    required DateTime answeredAt,
    required int elapsedMilliseconds,
  }) {
    final isCorrect =
        _normalize(submittedAnswer) == _normalize(question.correctAnswer);

    return AnswerRecord(
      childId: childId,
      wordId: question.wordId,
      practiceMode: question.practiceMode,
      isCorrect: isCorrect,
      answeredAt: answeredAt,
      elapsedMilliseconds: elapsedMilliseconds,
      weaknessType: isCorrect ? null : _weaknessTypeFor(question.practiceMode),
    );
  }

  AnswerWeaknessType _weaknessTypeFor(PracticeMode mode) {
    return switch (mode) {
      PracticeMode.englishToChinese ||
      PracticeMode.chineseToEnglish =>
        AnswerWeaknessType.meaning,
      PracticeMode.spelling => AnswerWeaknessType.spelling,
      PracticeMode.listeningChoice ||
      PracticeMode.listeningSpelling =>
        AnswerWeaknessType.listening,
    };
  }

  String _normalize(String value) {
    return value.trim().toLowerCase();
  }
}
