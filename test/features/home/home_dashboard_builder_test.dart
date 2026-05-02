import 'package:flutter_test/flutter_test.dart';
import 'package:word_quest/features/child_profile/domain/child_profile.dart';
import 'package:word_quest/features/home/application/home_dashboard_builder.dart';
import 'package:word_quest/features/study/domain/answer_record.dart';
import 'package:word_quest/features/study/domain/study_task.dart';
import 'package:word_quest/features/word_book/domain/word_entry.dart';

void main() {
  test('首页摘要会汇总任务、准确率、连续学习和薄弱点', () {
    const builder = HomeDashboardBuilder();

    final snapshot = builder.buildChildSnapshot(
      child: ChildProfile(
        id: 'child-a',
        name: '哥哥',
        gradeLabel: '初中词表',
        avatarSeed: '哥哥',
        createdAt: DateTime(2026, 5, 1),
      ),
      todayTask: StudyTask(
        childId: 'child-a',
        date: DateTime(2026, 5, 2),
        items: [
          _taskItem('1', StudyTaskType.newWords),
          _taskItem('2', StudyTaskType.newWords),
          _taskItem('3', StudyTaskType.newWords),
          _taskItem('4', StudyTaskType.newWords),
          _taskItem('5', StudyTaskType.review),
          _taskItem('6', StudyTaskType.review),
          _taskItem('7', StudyTaskType.review),
          _taskItem('8', StudyTaskType.review),
          _taskItem('9', StudyTaskType.review),
          _taskItem('10', StudyTaskType.review),
          _taskItem('11', StudyTaskType.mistakes),
          _taskItem('12', StudyTaskType.mistakes),
        ],
      ),
      answerRecords: [
        _answerRecord(
          answeredAt: DateTime(2026, 5, 2, 9),
          isCorrect: true,
        ),
        _answerRecord(
          answeredAt: DateTime(2026, 5, 2, 9, 5),
          isCorrect: true,
          weaknessType: AnswerWeaknessType.spelling,
        ),
        _answerRecord(
          answeredAt: DateTime(2026, 5, 1, 9),
          isCorrect: true,
          weaknessType: AnswerWeaknessType.listening,
        ),
        _answerRecord(
          answeredAt: DateTime(2026, 4, 30, 9),
          isCorrect: false,
          weaknessType: AnswerWeaknessType.spelling,
        ),
      ],
      completedItems: 6,
      referenceDate: DateTime(2026, 5, 2),
    );

    expect(snapshot.name, '哥哥');
    expect(snapshot.gradeLabel, '初中词表');
    expect(snapshot.taskSummary, '新词 4 个 · 复习 6 个 · 错词 2 个');
    expect(snapshot.accuracyLabel, '75%');
    expect(snapshot.streakLabel, '连续 3 天');
    expect(snapshot.progress, closeTo(0.5, 0.0001));
    expect(snapshot.weaknessHighlights, ['拼写薄弱', '听音薄弱']);
  });
}

StudyTaskItem _taskItem(String id, StudyTaskType type) {
  return StudyTaskItem(
    word: WordEntry(
      id: id,
      spelling: 'word$id',
      meanings: ['释义$id'],
    ),
    type: type,
    practiceModes: const [PracticeMode.englishToChinese],
  );
}

AnswerRecord _answerRecord({
  required DateTime answeredAt,
  required bool isCorrect,
  AnswerWeaknessType? weaknessType,
}) {
  return AnswerRecord(
    childId: 'child-a',
    wordId: '${answeredAt.millisecondsSinceEpoch}',
    practiceMode: PracticeMode.englishToChinese,
    isCorrect: isCorrect,
    answeredAt: answeredAt,
    elapsedMilliseconds: 1200,
    weaknessType: weaknessType,
  );
}
