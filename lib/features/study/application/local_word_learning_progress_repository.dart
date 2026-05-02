import 'dart:convert';

import '../../../core/local_storage/local_key_value_store.dart';
import '../domain/answer_record.dart';
import '../domain/word_learning_progress.dart';
import '../domain/word_learning_progress_repository.dart';

class LocalWordLearningProgressRepository
    implements WordLearningProgressRepository {
  LocalWordLearningProgressRepository({
    LocalKeyValueStore? store,
  }) : _store = store ?? createDefaultLocalKeyValueStore();

  static const _storageKey = 'word_quest.word_learning_progresses.v1';

  final LocalKeyValueStore _store;

  @override
  WordLearningProgress? loadProgress({
    required String childId,
    required String wordId,
  }) {
    for (final progress in _loadAllProgresses()) {
      if (progress.childId == childId && progress.wordId == wordId) {
        return progress;
      }
    }
    return null;
  }

  @override
  List<WordLearningProgress> loadProgresses({required String childId}) {
    return [
      for (final progress in _loadAllProgresses())
        if (progress.childId == childId) progress,
    ];
  }

  @override
  List<WordLearningProgress> loadAllProgresses() {
    return _loadAllProgresses();
  }

  @override
  void saveProgress(WordLearningProgress progress) {
    final progresses = _loadAllProgresses()
      ..removeWhere(
        (item) =>
            item.childId == progress.childId && item.wordId == progress.wordId,
      )
      ..add(progress);
    _saveAllProgresses(progresses);
  }

  @override
  void replaceProgresses(List<WordLearningProgress> progresses) {
    _saveAllProgresses(progresses);
  }

  List<WordLearningProgress> _loadAllProgresses() {
    final jsonText = _store.read(_storageKey);
    if (jsonText == null || jsonText.trim().isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(jsonText);
      if (decoded is List) {
        return [
          for (final item in decoded)
            if (item is Map<String, dynamic>) _progressFromJson(item),
        ];
      }
    } on FormatException {
      return [];
    }
    return [];
  }

  void _saveAllProgresses(List<WordLearningProgress> progresses) {
    _store.write(
      _storageKey,
      jsonEncode([
        for (final progress in progresses) _progressToJson(progress),
      ]),
    );
  }

  Map<String, Object?> _progressToJson(WordLearningProgress progress) {
    return {
      'childId': progress.childId,
      'wordId': progress.wordId,
      'masteryLevel': progress.masteryLevel,
      'consecutiveMistakes': progress.consecutiveMistakes,
      'nextReviewAt': progress.nextReviewAt.toIso8601String(),
      'updatedAt': progress.updatedAt.toIso8601String(),
      'lastWeaknessType': progress.lastWeaknessType?.name,
    };
  }

  WordLearningProgress _progressFromJson(Map<String, dynamic> json) {
    return WordLearningProgress(
      childId: json['childId'] as String? ?? '',
      wordId: json['wordId'] as String? ?? '',
      masteryLevel: json['masteryLevel'] as int? ?? 0,
      consecutiveMistakes: json['consecutiveMistakes'] as int? ?? 0,
      nextReviewAt: DateTime.tryParse(json['nextReviewAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      lastWeaknessType:
          _weaknessTypeFromName(json['lastWeaknessType'] as String?),
    );
  }

  AnswerWeaknessType? _weaknessTypeFromName(String? name) {
    for (final weaknessType in AnswerWeaknessType.values) {
      if (weaknessType.name == name) {
        return weaknessType;
      }
    }
    return null;
  }
}
