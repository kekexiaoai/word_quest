import 'dart:convert';

import '../../../core/local_storage/local_key_value_store.dart';
import '../domain/learning_word_book_selection_repository.dart';

class LocalLearningWordBookSelectionRepository
    implements LearningWordBookSelectionRepository {
  LocalLearningWordBookSelectionRepository({
    LocalKeyValueStore? store,
  }) : _store = store ?? createDefaultLocalKeyValueStore();

  static const _storageKey = 'word_quest.learning_word_book_selection.v1';

  final LocalKeyValueStore _store;

  @override
  String? loadSelectedWordBookId({required String childId}) {
    return _loadSelections()[childId];
  }

  @override
  void saveSelectedWordBookId({
    required String childId,
    required String wordBookId,
  }) {
    _store.write(
      _storageKey,
      jsonEncode({
        ..._loadSelections(),
        childId: wordBookId,
      }),
    );
  }

  Map<String, String> loadSelections() {
    return _loadSelections();
  }

  void replaceSelections(Map<String, String> selections) {
    _store.write(_storageKey, jsonEncode(selections));
  }

  Map<String, String> _loadSelections() {
    final jsonText = _store.read(_storageKey);
    if (jsonText == null || jsonText.trim().isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(jsonText);
      if (decoded is Map<String, dynamic>) {
        return {
          for (final entry in decoded.entries)
            if (entry.value is String) entry.key: entry.value as String,
        };
      }
    } on FormatException {
      return {};
    }
    return {};
  }
}
