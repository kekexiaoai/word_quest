abstract class LearningWordBookSelectionRepository {
  const LearningWordBookSelectionRepository();

  String? loadSelectedWordBookId({required String childId});

  void saveSelectedWordBookId({
    required String childId,
    required String wordBookId,
  });
}
