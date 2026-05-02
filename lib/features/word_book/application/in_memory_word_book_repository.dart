import '../domain/word_book.dart';
import '../domain/word_book_repository.dart';
import '../domain/word_entry.dart';

class InMemoryWordBookRepository implements WordBookRepository {
  const InMemoryWordBookRepository();

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

  List<WordEntry> _words(String prefix, int count) {
    return List.generate(
      count,
      (index) => WordEntry(
        id: '$prefix-$index',
        spelling: '$prefix-$index',
        meanings: ['释义 $index'],
      ),
    );
  }
}
