import 'word_book.dart';

abstract class WordBookRepository {
  const WordBookRepository();

  List<WordBook> loadBuiltInWordBooks();
}
