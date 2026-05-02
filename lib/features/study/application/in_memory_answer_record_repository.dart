import '../domain/answer_record.dart';
import '../domain/answer_record_repository.dart';

class InMemoryAnswerRecordRepository implements AnswerRecordRepository {
  const InMemoryAnswerRecordRepository({
    List<AnswerRecord>? storage,
  }) : _storage = storage;

  static final List<AnswerRecord> _sharedStorage = [];

  final List<AnswerRecord>? _storage;

  List<AnswerRecord> get _activeStorage {
    return _storage ?? _sharedStorage;
  }

  @override
  void addRecord(AnswerRecord record) {
    _activeStorage.add(record);
  }

  @override
  List<AnswerRecord> loadRecords({required String childId}) {
    return [
      for (final record in _activeStorage)
        if (record.childId == childId) record,
    ];
  }

  @override
  List<AnswerRecord> loadAllRecords() {
    return List<AnswerRecord>.of(_activeStorage);
  }

  @override
  void replaceRecords(List<AnswerRecord> records) {
    _activeStorage
      ..clear()
      ..addAll(records);
  }

  @override
  void clearRecords() {
    _activeStorage.clear();
  }
}
