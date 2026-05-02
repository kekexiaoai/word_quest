import '../domain/learning_word_book_selection_repository.dart';

class InMemoryLearningWordBookSelectionRepository
    implements LearningWordBookSelectionRepository {
  InMemoryLearningWordBookSelectionRepository({
    Map<String, String>? storage,
  }) : _storage = storage ?? {};

  final Map<String, String> _storage;

  @override
  String? loadSelectedWordBookId({required String childId}) {
    return _storage[childId];
  }

  @override
  void saveSelectedWordBookId({
    required String childId,
    required String wordBookId,
  }) {
    _storage[childId] = wordBookId;
  }
}
