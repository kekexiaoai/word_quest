import 'dart:convert';

import '../../../core/local_storage/local_key_value_store.dart';
import '../domain/answer_record.dart';
import '../domain/answer_record_repository.dart';
import '../domain/study_task.dart';

class LocalAnswerRecordRepository implements AnswerRecordRepository {
  LocalAnswerRecordRepository({
    LocalKeyValueStore? store,
  }) : _store = store ?? createDefaultLocalKeyValueStore();

  static const _storageKey = 'word_quest.answer_records.v1';

  final LocalKeyValueStore _store;

  @override
  void addRecord(AnswerRecord record) {
    final records = _loadAllRecords()..add(record);
    _store.write(
      _storageKey,
      jsonEncode([
        for (final item in records) _recordToJson(item),
      ]),
    );
  }

  @override
  List<AnswerRecord> loadRecords({required String childId}) {
    return [
      for (final record in _loadAllRecords())
        if (record.childId == childId) record,
    ];
  }

  List<AnswerRecord> _loadAllRecords() {
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
        if (item is Map<String, dynamic>) _recordFromJson(item),
    ];
  }

  Map<String, Object?> _recordToJson(AnswerRecord record) {
    return {
      'childId': record.childId,
      'wordId': record.wordId,
      'practiceMode': record.practiceMode.name,
      'isCorrect': record.isCorrect,
      'answeredAt': record.answeredAt.toIso8601String(),
      'elapsedMilliseconds': record.elapsedMilliseconds,
      'weaknessType': record.weaknessType?.name,
    };
  }

  AnswerRecord _recordFromJson(Map<String, dynamic> json) {
    return AnswerRecord(
      childId: json['childId'] as String? ?? '',
      wordId: json['wordId'] as String? ?? '',
      practiceMode: _practiceModeFromName(json['practiceMode'] as String?),
      isCorrect: json['isCorrect'] as bool? ?? false,
      answeredAt: DateTime.tryParse(json['answeredAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      elapsedMilliseconds: json['elapsedMilliseconds'] as int? ?? 0,
      weaknessType: _weaknessTypeFromName(json['weaknessType'] as String?),
    );
  }

  PracticeMode _practiceModeFromName(String? name) {
    for (final mode in PracticeMode.values) {
      if (mode.name == name) {
        return mode;
      }
    }
    return PracticeMode.englishToChinese;
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
