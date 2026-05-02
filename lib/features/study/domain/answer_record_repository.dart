import 'answer_record.dart';

abstract class AnswerRecordRepository {
  const AnswerRecordRepository();

  void addRecord(AnswerRecord record);

  List<AnswerRecord> loadRecords({required String childId});
}
