import 'package:flutter_test/flutter_test.dart';
import 'package:word_quest/features/study/application/study_task_planner.dart';
import 'package:word_quest/features/study/domain/study_task.dart';
import 'package:word_quest/features/word_book/domain/word_entry.dart';

void main() {
  group('StudyTaskPlanner', () {
    test('按配置生成新词、复习词和错词强化任务', () {
      const planner = StudyTaskPlanner();

      final task = planner.planDailyTask(
        childId: 'child-a',
        date: DateTime(2026, 5, 2, 18, 30),
        newWordCandidates: _words('new', 5),
        dueReviewWords: _words('review', 7),
        mistakeWords: _words('mistake', 3),
        config: const StudyTaskPlanConfig(
          newWordLimit: 4,
          reviewLimit: 6,
          mistakeLimit: 2,
        ),
      );

      expect(task.childId, 'child-a');
      expect(task.date, DateTime(2026, 5, 2));
      expect(task.newWordCount, 4);
      expect(task.reviewCount, 6);
      expect(task.mistakeCount, 2);
      expect(task.items.first.type, StudyTaskType.mistakes);
    });

    test('错词任务包含拼写和听音拼写训练', () {
      const planner = StudyTaskPlanner();

      final task = planner.planDailyTask(
        childId: 'child-a',
        date: DateTime(2026, 5, 2),
        newWordCandidates: const [],
        dueReviewWords: const [],
        mistakeWords: _words('mistake', 1),
      );

      expect(task.items.single.practiceModes, contains(PracticeMode.spelling));
      expect(
        task.items.single.practiceModes,
        contains(PracticeMode.listeningSpelling),
      );
    });

    test('可以关闭听音训练', () {
      const planner = StudyTaskPlanner();

      final task = planner.planDailyTask(
        childId: 'child-a',
        date: DateTime(2026, 5, 2),
        newWordCandidates: const [],
        dueReviewWords: _words('review', 1),
        mistakeWords: const [],
        config: const StudyTaskPlanConfig(includeListening: false),
      );

      expect(
        task.items.single.practiceModes,
        isNot(contains(PracticeMode.listeningChoice)),
      );
    });
  });
}

List<WordEntry> _words(String prefix, int count) {
  return List.generate(
    count,
    (index) => WordEntry(
      id: '$prefix-$index',
      spelling: '$prefix$index',
      meanings: ['释义 $index'],
    ),
  );
}
