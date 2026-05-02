import 'dart:convert';

import '../../../core/local_storage/local_key_value_store.dart';
import '../domain/word_book.dart';
import '../domain/word_book_repository.dart';
import '../domain/word_entry.dart';
import 'in_memory_word_book_repository.dart';

class LocalWordBookRepository implements WordBookRepository {
  LocalWordBookRepository({
    LocalKeyValueStore? store,
    WordBookRepository builtInRepository = const InMemoryWordBookRepository(),
  })  : _store = store ?? createDefaultLocalKeyValueStore(),
        _builtInRepository = builtInRepository;

  static const _storageKey = 'word_quest.imported_word_books.v1';

  final LocalKeyValueStore _store;
  final WordBookRepository _builtInRepository;

  @override
  List<WordBook> loadWordBooks() {
    return [
      ...loadBuiltInWordBooks(),
      ..._loadImportedWordBooks(),
    ];
  }

  @override
  List<WordBook> loadBuiltInWordBooks() {
    return _builtInRepository.loadBuiltInWordBooks();
  }

  @override
  void saveImportedWordBook(WordBook wordBook) {
    final importedWordBooks = _loadImportedWordBooks();
    importedWordBooks.removeWhere((book) => book.id == wordBook.id);
    importedWordBooks.add(wordBook);
    _store.write(
      _storageKey,
      jsonEncode([
        for (final importedWordBook in importedWordBooks)
          _wordBookToJson(importedWordBook),
      ]),
    );
  }

  List<WordBook> _loadImportedWordBooks() {
    final jsonText = _store.read(_storageKey);
    if (jsonText == null || jsonText.trim().isEmpty) {
      return [];
    }

    final decoded = jsonDecode(jsonText);
    if (decoded is! List) {
      return [];
    }

    return [
      for (final item in decoded)
        if (item is Map<String, dynamic>) _wordBookFromJson(item),
    ];
  }

  Map<String, Object?> _wordBookToJson(WordBook wordBook) {
    return {
      'id': wordBook.id,
      'name': wordBook.name,
      'stageLabel': wordBook.stageLabel,
      'description': wordBook.description,
      'isBuiltIn': wordBook.isBuiltIn,
      'words': [
        for (final word in wordBook.words) _wordEntryToJson(word),
      ],
    };
  }

  WordBook _wordBookFromJson(Map<String, dynamic> json) {
    return WordBook(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'CSV 导入词表',
      stageLabel: json['stageLabel'] as String? ?? '自定义',
      description: json['description'] as String?,
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
      words: [
        if (json['words'] case final List<dynamic> words)
          for (final word in words)
            if (word is Map<String, dynamic>) _wordEntryFromJson(word),
      ],
    );
  }

  Map<String, Object?> _wordEntryToJson(WordEntry word) {
    return {
      'id': word.id,
      'spelling': word.spelling,
      'meanings': word.meanings,
      'phonetic': word.phonetic,
      'partOfSpeech': word.partOfSpeech,
      'example': word.example,
      'tags': word.tags,
      'source': word.source,
    };
  }

  WordEntry _wordEntryFromJson(Map<String, dynamic> json) {
    return WordEntry(
      id: json['id'] as String? ?? '',
      spelling: json['spelling'] as String? ?? '',
      meanings: [
        if (json['meanings'] case final List<dynamic> meanings)
          for (final meaning in meanings)
            if (meaning is String) meaning,
      ],
      phonetic: json['phonetic'] as String?,
      partOfSpeech: json['partOfSpeech'] as String?,
      example: json['example'] as String?,
      tags: [
        if (json['tags'] case final List<dynamic> tags)
          for (final tag in tags)
            if (tag is String) tag,
      ],
      source: json['source'] as String?,
    );
  }
}
