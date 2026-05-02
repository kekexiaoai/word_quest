import '../../study/domain/study_task.dart';

class AdventureLevelQuiz {
  const AdventureLevelQuiz({
    required this.activityTitle,
    required this.progressLabel,
    required this.progressValue,
    required this.instruction,
    required this.wordId,
    required this.practiceMode,
    required this.prompt,
    required this.correctAnswer,
    required this.choices,
    required this.successTitle,
    required this.explanation,
    this.failureTitle = '再试一次',
    this.failureExplanation = '这题会放到本关稍后再试。',
    required this.usesAudioPrompt,
  });

  final String activityTitle;
  final String progressLabel;
  final double progressValue;
  final String instruction;
  final String wordId;
  final PracticeMode practiceMode;
  final String prompt;
  final String correctAnswer;
  final List<String> choices;
  final String successTitle;
  final String explanation;
  final String failureTitle;
  final String failureExplanation;
  final bool usesAudioPrompt;
}
