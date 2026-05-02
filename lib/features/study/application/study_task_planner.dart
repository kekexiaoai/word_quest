import '../domain/study_task.dart';
import '../../word_book/domain/word_entry.dart';

class StudyTaskPlanConfig {
  const StudyTaskPlanConfig({
    this.newWordLimit = 10,
    this.reviewLimit = 20,
    this.mistakeLimit = 8,
    this.includeListening = true,
  });

  final int newWordLimit;
  final int reviewLimit;
  final int mistakeLimit;
  final bool includeListening;
}

class StudyTaskPlanner {
  const StudyTaskPlanner();

  StudyTask planDailyTask({
    required String childId,
    required DateTime date,
    required List<WordEntry> newWordCandidates,
    required List<WordEntry> dueReviewWords,
    required List<WordEntry> mistakeWords,
    StudyTaskPlanConfig config = const StudyTaskPlanConfig(),
  }) {
    final items = <StudyTaskItem>[
      ...mistakeWords
          .take(config.mistakeLimit)
          .map((word) => _buildItem(word, StudyTaskType.mistakes, config)),
      ...dueReviewWords
          .take(config.reviewLimit)
          .map((word) => _buildItem(word, StudyTaskType.review, config)),
      ...newWordCandidates
          .take(config.newWordLimit)
          .map((word) => _buildItem(word, StudyTaskType.newWords, config)),
    ];

    return StudyTask(
      childId: childId,
      date: DateTime(date.year, date.month, date.day),
      items: items,
    );
  }

  StudyTaskItem _buildItem(
    WordEntry word,
    StudyTaskType type,
    StudyTaskPlanConfig config,
  ) {
    return StudyTaskItem(
      word: word,
      type: type,
      practiceModes: _practiceModesFor(type, config),
    );
  }

  List<PracticeMode> _practiceModesFor(
    StudyTaskType type,
    StudyTaskPlanConfig config,
  ) {
    final modes = switch (type) {
      StudyTaskType.newWords => [
          PracticeMode.englishToChinese,
          PracticeMode.chineseToEnglish,
        ],
      StudyTaskType.review => [
          PracticeMode.englishToChinese,
          PracticeMode.chineseToEnglish,
          PracticeMode.spelling,
        ],
      StudyTaskType.mistakes => [
          PracticeMode.chineseToEnglish,
          PracticeMode.spelling,
        ],
    };

    if (!config.includeListening) {
      return modes;
    }

    return [
      ...modes,
      if (type == StudyTaskType.review) PracticeMode.listeningChoice,
      if (type == StudyTaskType.mistakes) PracticeMode.listeningSpelling,
    ];
  }
}
