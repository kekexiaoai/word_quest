import '../domain/word_learning_progress.dart';
import '../domain/word_learning_progress_repository.dart';

class InMemoryWordLearningProgressRepository
    implements WordLearningProgressRepository {
  InMemoryWordLearningProgressRepository({
    List<WordLearningProgress>? storage,
  }) : _storage = storage ?? [];

  final List<WordLearningProgress> _storage;

  @override
  WordLearningProgress? loadProgress({
    required String childId,
    required String wordId,
  }) {
    for (final progress in _storage) {
      if (progress.childId == childId && progress.wordId == wordId) {
        return progress;
      }
    }
    return null;
  }

  @override
  List<WordLearningProgress> loadProgresses({required String childId}) {
    return [
      for (final progress in _storage)
        if (progress.childId == childId) progress,
    ];
  }

  @override
  List<WordLearningProgress> loadAllProgresses() {
    return List<WordLearningProgress>.of(_storage);
  }

  @override
  void saveProgress(WordLearningProgress progress) {
    _storage.removeWhere(
      (item) =>
          item.childId == progress.childId && item.wordId == progress.wordId,
    );
    _storage.add(progress);
  }

  @override
  void replaceProgresses(List<WordLearningProgress> progresses) {
    _storage
      ..clear()
      ..addAll(progresses);
  }
}
