import 'package:flutter_test/flutter_test.dart';
import 'package:word_quest/core/local_storage/local_key_value_store.dart';
import 'package:word_quest/features/word_book/application/local_learning_word_book_selection_repository.dart';

void main() {
  test('本地学习词表选择按孩子保存并可跨实例读取', () {
    final store = MemoryLocalKeyValueStore();
    final firstRepository =
        LocalLearningWordBookSelectionRepository(store: store);

    firstRepository.saveSelectedWordBookId(
      childId: 'child-brother',
      wordBookId: 'middle-core',
    );
    firstRepository.saveSelectedWordBookId(
      childId: 'child-sister',
      wordBookId: 'primary-basic',
    );

    final secondRepository =
        LocalLearningWordBookSelectionRepository(store: store);

    expect(
      secondRepository.loadSelectedWordBookId(childId: 'child-brother'),
      'middle-core',
    );
    expect(
      secondRepository.loadSelectedWordBookId(childId: 'child-sister'),
      'primary-basic',
    );
  });
}
