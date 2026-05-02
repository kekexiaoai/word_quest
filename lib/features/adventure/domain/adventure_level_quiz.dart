class AdventureLevelQuiz {
  const AdventureLevelQuiz({
    required this.activityTitle,
    required this.progressLabel,
    required this.progressValue,
    required this.instruction,
    required this.prompt,
    required this.correctAnswer,
    required this.choices,
    required this.successTitle,
    required this.explanation,
    required this.usesAudioPrompt,
  });

  final String activityTitle;
  final String progressLabel;
  final double progressValue;
  final String instruction;
  final String prompt;
  final String correctAnswer;
  final List<String> choices;
  final String successTitle;
  final String explanation;
  final bool usesAudioPrompt;
}
