import 'study_task.dart';

enum StudyQuestionType {
  choice,
  input,
}

class StudyQuestion {
  const StudyQuestion({
    required this.wordId,
    required this.practiceMode,
    required this.type,
    required this.prompt,
    required this.correctAnswer,
    this.choices = const [],
  });

  final String wordId;
  final PracticeMode practiceMode;
  final StudyQuestionType type;
  final String prompt;
  final String correctAnswer;
  final List<String> choices;
}
