import 'package:flutter_test/flutter_test.dart';
import 'package:word_quest/core/local_storage/local_key_value_store.dart';
import 'package:word_quest/features/word_book/application/in_memory_word_book_repository.dart';
import 'package:word_quest/features/word_book/application/local_word_book_repository.dart';
import 'package:word_quest/features/word_book/domain/word_book.dart';
import 'package:word_quest/features/word_book/domain/word_entry.dart';

void main() {
  test('内存词表仓库返回内置词表', () {
    const repository = InMemoryWordBookRepository();

    final wordBooks = repository.loadBuiltInWordBooks();

    expect(wordBooks, hasLength(4));
    expect(wordBooks.first.name, '小学高年级基础词表');
    expect(wordBooks.first.wordCount, 6);
    expect(wordBooks.last.stageLabel, '高中核心词表');
  });

  test('内存词表仓库包含北京版英语三年级词库', () {
    const repository = InMemoryWordBookRepository();

    final wordBook = repository
        .loadBuiltInWordBooks()
        .singleWhere((wordBook) => wordBook.id == 'beijing-primary-grade-3');

    expect(wordBook.name, '北京版英语三年级词表');
    expect(wordBook.stageLabel, '小学三年级词表');
    expect(wordBook.wordCount, 261);
    expect(wordBook.words.first.spelling, 'hello');
    expect(wordBook.words.first.meanings, ['你好（问候语）']);
    expect(wordBook.words.first.tags, ['北京版', '三年级', '三上']);
    expect(wordBook.words.first.source, '北京出版社北京版（新）三年级英语 Word List');
    expect(
      wordBook.words.map((word) => word.spelling),
      containsAll(['hello', 'sheep', 'weather', 'Beijing opera', 'party']),
    );
    expect(
      wordBook.words.singleWhere((word) => word.spelling == 'weather').tags,
      ['北京版', '三年级', '三下'],
    );
  });

  test('内存词表仓库可以合并导入词表', () {
    const repository = InMemoryWordBookRepository(
      importedWordBooks: [
        WordBook(
          id: 'custom',
          name: '我的导入词表',
          stageLabel: '自定义',
          words: [
            WordEntry(id: 'custom-ocean', spelling: 'ocean', meanings: ['海洋']),
          ],
        ),
      ],
    );

    final wordBooks = repository.loadWordBooks();

    expect(wordBooks.map((book) => book.id), contains('custom'));
    expect(wordBooks.last.words.single.spelling, 'ocean');
  });

  test('内存词表仓库保存导入词表后可以立即读取', () {
    final importedStorage = <WordBook>[];
    final repository = InMemoryWordBookRepository(
      importedWordBooks: importedStorage,
    );

    repository.saveImportedWordBook(
      const WordBook(
        id: 'csv-import-1',
        name: 'CSV 导入词表',
        stageLabel: '自定义',
        words: [
          WordEntry(id: 'csv-import-1-1', spelling: 'ocean', meanings: ['海洋']),
        ],
      ),
    );

    final wordBooks = repository.loadWordBooks();

    expect(importedStorage, hasLength(1));
    expect(wordBooks.last.id, 'csv-import-1');
    expect(wordBooks.last.words.single.spelling, 'ocean');
  });

  test('本地词表仓库保存导入词表后新实例仍可读取', () {
    final store = MemoryLocalKeyValueStore();
    final firstRepository = LocalWordBookRepository(store: store);

    firstRepository.saveImportedWordBook(
      const WordBook(
        id: 'csv-import-1',
        name: 'CSV 导入词表',
        stageLabel: '自定义',
        words: [
          WordEntry(
            id: 'csv-import-1-1',
            spelling: 'ocean',
            meanings: ['海洋'],
            phonetic: '/ˈəʊʃn/',
            tags: ['主题'],
          ),
        ],
      ),
    );

    final secondRepository = LocalWordBookRepository(store: store);
    final importedWordBooks = secondRepository
        .loadWordBooks()
        .where((wordBook) => !wordBook.isBuiltIn)
        .toList();

    expect(importedWordBooks, hasLength(1));
    expect(importedWordBooks.single.name, 'CSV 导入词表');
    expect(importedWordBooks.single.words.single.spelling, 'ocean');
    expect(importedWordBooks.single.words.single.phonetic, '/ˈəʊʃn/');
    expect(importedWordBooks.single.words.single.tags, ['主题']);
  });
}
