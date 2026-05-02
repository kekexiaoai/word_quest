import '../../word_book/domain/word_entry.dart';

enum StudyTaskType {
  newWords,
  review,
  mistakes,
}

enum PracticeMode {
  englishToChinese,
  chineseToEnglish,
  spelling,
  listeningChoice,
  listeningSpelling,
}

class StudyTaskItem {
  const StudyTaskItem({
    required this.word,
    required this.type,
    required this.practiceModes,
  });

  final WordEntry word;
  final StudyTaskType type;
  final List<PracticeMode> practiceModes;
}

class StudyTask {
  const StudyTask({
    required this.childId,
    required this.date,
    required this.items,
  });

  final String childId;
  final DateTime date;
  final List<StudyTaskItem> items;

  int get newWordCount =>
      items.where((item) => item.type == StudyTaskType.newWords).length;

  int get reviewCount =>
      items.where((item) => item.type == StudyTaskType.review).length;

  int get mistakeCount =>
      items.where((item) => item.type == StudyTaskType.mistakes).length;
}
