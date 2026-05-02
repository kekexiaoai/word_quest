import 'package:flutter_test/flutter_test.dart';
import 'package:word_quest/features/word_book/application/in_memory_word_book_repository.dart';

void main() {
  test('内存词表仓库返回三个内置词表', () {
    const repository = InMemoryWordBookRepository();

    final wordBooks = repository.loadBuiltInWordBooks();

    expect(wordBooks, hasLength(3));
    expect(wordBooks.first.name, '小学高年级基础词表');
    expect(wordBooks.first.wordCount, 6);
    expect(wordBooks.last.stageLabel, '高中核心词表');
  });
}
