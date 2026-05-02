import '../domain/word_book.dart';
import '../domain/word_book_repository.dart';
import '../domain/word_entry.dart';

class InMemoryWordBookRepository implements WordBookRepository {
  const InMemoryWordBookRepository({
    List<WordBook>? importedWordBooks,
  }) : _importedWordBooks = importedWordBooks;

  static final List<WordBook> _sharedImportedWordBooks = [];

  final List<WordBook>? _importedWordBooks;

  List<WordBook> get _activeImportedWordBooks {
    return _importedWordBooks ?? _sharedImportedWordBooks;
  }

  @override
  List<WordBook> loadWordBooks() {
    return [
      ...loadBuiltInWordBooks(),
      ..._activeImportedWordBooks,
    ];
  }

  @override
  List<WordBook> loadBuiltInWordBooks() {
    return [
      WordBook(
        id: 'primary-basic',
        name: '小学高年级基础词表',
        stageLabel: '小学高年级词表',
        isBuiltIn: true,
        words: _words('primary-basic', 6),
      ),
      WordBook(
        id: 'middle-core',
        name: '初中核心词表',
        stageLabel: '初中词表',
        isBuiltIn: true,
        words: _words('middle-core', 6),
      ),
      WordBook(
        id: 'high-core',
        name: '高中核心词表',
        stageLabel: '高中核心词表',
        isBuiltIn: true,
        words: _words('high-core', 6),
      ),
    ];
  }

  @override
  void saveImportedWordBook(WordBook wordBook) {
    _activeImportedWordBooks.removeWhere((book) => book.id == wordBook.id);
    _activeImportedWordBooks.add(wordBook);
  }

  List<WordEntry> _words(String prefix, int count) {
    const demoWords = [
      WordEntry(id: 'library', spelling: 'library', meanings: ['图书馆']),
      WordEntry(id: 'neighbor', spelling: 'neighbor', meanings: ['邻居']),
      WordEntry(id: 'through', spelling: 'through', meanings: ['穿过']),
    ];
    final generatedWords = List.generate(
      count - demoWords.length,
      (index) {
        final displayIndex = index + demoWords.length;
        return WordEntry(
          id: '$prefix-$displayIndex',
          spelling: '$prefix-$displayIndex',
          meanings: ['释义 $displayIndex'],
        );
      },
    );

    return [
      ...demoWords,
      ...generatedWords,
    ];
  }
}
