import 'word_learning_progress.dart';

abstract class WordLearningProgressRepository {
  const WordLearningProgressRepository();

  WordLearningProgress? loadProgress({
    required String childId,
    required String wordId,
  });

  List<WordLearningProgress> loadProgresses({required String childId});

  List<WordLearningProgress> loadAllProgresses();

  void saveProgress(WordLearningProgress progress);

  void replaceProgresses(List<WordLearningProgress> progresses);
}
