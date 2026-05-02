import 'package:flutter_test/flutter_test.dart';
import 'package:word_quest/features/study/application/in_memory_answer_record_repository.dart';
import 'package:word_quest/features/study/domain/answer_record.dart';
import 'package:word_quest/features/study/domain/study_task.dart';

void main() {
  test('内存答题记录仓库按孩子保存记录', () {
    final storage = <AnswerRecord>[];
    final repository = InMemoryAnswerRecordRepository(storage: storage);

    repository.addRecord(AnswerRecord(
      childId: 'child-brother',
      wordId: 'through',
      practiceMode: PracticeMode.listeningChoice,
      isCorrect: false,
      answeredAt: DateTime(2026, 5, 2, 20),
      elapsedMilliseconds: 1200,
      weaknessType: AnswerWeaknessType.listening,
    ));
    repository.addRecord(AnswerRecord(
      childId: 'child-sister',
      wordId: 'library',
      practiceMode: PracticeMode.englishToChinese,
      isCorrect: true,
      answeredAt: DateTime(2026, 5, 2, 20, 1),
      elapsedMilliseconds: 900,
    ));

    final records = repository.loadRecords(childId: 'child-brother');

    expect(records, hasLength(1));
    expect(records.single.wordId, 'through');
    expect(records.single.isCorrect, isFalse);
    expect(records.single.weaknessType, AnswerWeaknessType.listening);
  });
}
