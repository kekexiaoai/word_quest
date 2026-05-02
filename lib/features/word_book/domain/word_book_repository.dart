import 'word_book.dart';

abstract class WordBookRepository {
  const WordBookRepository();

  List<WordBook> loadWordBooks();

  List<WordBook> loadBuiltInWordBooks();

  void saveImportedWordBook(WordBook wordBook);
}
