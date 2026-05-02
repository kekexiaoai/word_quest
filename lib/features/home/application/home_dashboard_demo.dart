import '../../child_profile/domain/child_profile.dart';
import '../../study/application/study_task_planner.dart';
import '../../study/domain/answer_record.dart';
import '../../study/domain/study_task.dart';
import '../../word_book/domain/word_book.dart';
import '../../word_book/domain/word_entry.dart';
import '../domain/home_dashboard_snapshot.dart';
import 'home_dashboard_builder.dart';

class HomeDashboardDemo {
  const HomeDashboardDemo._();

  static List<ChildDashboardSnapshot> buildChildSnapshots({
    required HomeDashboardBuilder builder,
    required List<ChildProfile> children,
    required DateTime referenceDate,
  }) {
    return [
      for (final child in children)
        _buildSnapshotForChild(
          builder: builder,
          child: child,
          referenceDate: referenceDate,
        ),
    ];
  }

  static List<DashboardSectionLine> buildBookHighlights(
    List<WordBook> wordBooks,
  ) {
    return [
      for (final wordBook in wordBooks)
        DashboardSectionLine(
          label: wordBook.name,
          value: '${wordBook.wordCount} 个单词 · ${wordBook.stageLabel}',
        ),
    ];
  }

  static StudyTask _buildTask({
    required String childId,
    required DateTime date,
    required int newWordLimit,
    required int reviewLimit,
    required int mistakeLimit,
    required String newWordPrefix,
    required String reviewPrefix,
    required String mistakePrefix,
  }) {
    const planner = StudyTaskPlanner();
    return planner.planDailyTask(
      childId: childId,
      date: date,
      newWordCandidates: _words(newWordPrefix, newWordLimit),
      dueReviewWords: _words(reviewPrefix, reviewLimit),
      mistakeWords: _words(mistakePrefix, mistakeLimit),
      config: StudyTaskPlanConfig(
        newWordLimit: newWordLimit,
        reviewLimit: reviewLimit,
        mistakeLimit: mistakeLimit,
      ),
    );
  }

  static List<AnswerRecord> _brotherRecords() {
    return _records(
      childId: 'child-brother',
      seeds: [
        _RecordSeed(
          answeredAt: DateTime(2026, 5, 2, 8),
          practiceMode: PracticeMode.englishToChinese,
          isCorrect: true,
        ),
        _RecordSeed(
          answeredAt: DateTime(2026, 5, 2, 8, 5),
          practiceMode: PracticeMode.chineseToEnglish,
          isCorrect: true,
        ),
        _RecordSeed(
          answeredAt: DateTime(2026, 5, 2, 8, 10),
          practiceMode: PracticeMode.spelling,
          isCorrect: false,
          weaknessType: AnswerWeaknessType.spelling,
        ),
        _RecordSeed(
          answeredAt: DateTime(2026, 5, 2, 8, 15),
          practiceMode: PracticeMode.listeningChoice,
          isCorrect: true,
        ),
        _RecordSeed(
          answeredAt: DateTime(2026, 5, 1, 8),
          practiceMode: PracticeMode.englishToChinese,
          isCorrect: true,
        ),
        _RecordSeed(
          answeredAt: DateTime(2026, 5, 1, 8, 5),
          practiceMode: PracticeMode.listeningSpelling,
          isCorrect: true,
          weaknessType: AnswerWeaknessType.listening,
        ),
        _RecordSeed(
          answeredAt: DateTime(2026, 5, 1, 8, 10),
          practiceMode: PracticeMode.chineseToEnglish,
          isCorrect: true,
        ),
        _RecordSeed(
          answeredAt: DateTime(2026, 4, 30, 8),
          practiceMode: PracticeMode.spelling,
          isCorrect: true,
        ),
        _RecordSeed(
          answeredAt: DateTime(2026, 4, 30, 8, 5),
          practiceMode: PracticeMode.englishToChinese,
          isCorrect: true,
        ),
        _RecordSeed(
          answeredAt: DateTime(2026, 4, 30, 8, 10),
          practiceMode: PracticeMode.listeningChoice,
          isCorrect: true,
          weaknessType: AnswerWeaknessType.listening,
        ),
        _RecordSeed(
          answeredAt: DateTime(2026, 4, 29, 8),
          practiceMode: PracticeMode.chineseToEnglish,
          isCorrect: true,
        ),
        _RecordSeed(
          answeredAt: DateTime(2026, 4, 29, 8, 5),
          practiceMode: PracticeMode.spelling,
          isCorrect: true,
        ),
        _RecordSeed(
          answeredAt: DateTime(2026, 4, 28, 8),
          practiceMode: PracticeMode.englishToChinese,
          isCorrect: false,
          weaknessType: AnswerWeaknessType.spelling,
        ),
        _RecordSeed(
          answeredAt: DateTime(2026, 4, 28, 8, 5),
          practiceMode: PracticeMode.listeningSpelling,
          isCorrect: true,
        ),
      ],
    );
  }

  static List<AnswerRecord> _sisterRecords() {
    return _records(
      childId: 'child-sister',
      seeds: [
        _RecordSeed(
          answeredAt: DateTime(2026, 5, 2, 8),
          practiceMode: PracticeMode.englishToChinese,
          isCorrect: true,
        ),
        _RecordSeed(
          answeredAt: DateTime(2026, 5, 2, 8, 5),
          practiceMode: PracticeMode.chineseToEnglish,
          isCorrect: true,
        ),
        _RecordSeed(
          answeredAt: DateTime(2026, 5, 2, 8, 10),
          practiceMode: PracticeMode.spelling,
          isCorrect: true,
        ),
        _RecordSeed(
          answeredAt: DateTime(2026, 5, 2, 8, 15),
          practiceMode: PracticeMode.listeningChoice,
          isCorrect: true,
        ),
        _RecordSeed(
          answeredAt: DateTime(2026, 5, 1, 8),
          practiceMode: PracticeMode.englishToChinese,
          isCorrect: true,
        ),
        _RecordSeed(
          answeredAt: DateTime(2026, 5, 1, 8, 5),
          practiceMode: PracticeMode.chineseToEnglish,
          isCorrect: true,
        ),
        _RecordSeed(
          answeredAt: DateTime(2026, 5, 1, 8, 10),
          practiceMode: PracticeMode.listeningSpelling,
          isCorrect: true,
          weaknessType: AnswerWeaknessType.listening,
        ),
        _RecordSeed(
          answeredAt: DateTime(2026, 5, 1, 8, 15),
          practiceMode: PracticeMode.spelling,
          isCorrect: true,
        ),
        _RecordSeed(
          answeredAt: DateTime(2026, 4, 30, 8),
          practiceMode: PracticeMode.englishToChinese,
          isCorrect: true,
        ),
        _RecordSeed(
          answeredAt: DateTime(2026, 4, 30, 8, 5),
          practiceMode: PracticeMode.chineseToEnglish,
          isCorrect: true,
        ),
        _RecordSeed(
          answeredAt: DateTime(2026, 4, 30, 8, 10),
          practiceMode: PracticeMode.spelling,
          isCorrect: false,
          weaknessType: AnswerWeaknessType.spelling,
        ),
        _RecordSeed(
          answeredAt: DateTime(2026, 4, 30, 8, 15),
          practiceMode: PracticeMode.listeningChoice,
          isCorrect: true,
        ),
        _RecordSeed(
          answeredAt: DateTime(2026, 4, 30, 8, 20),
          practiceMode: PracticeMode.listeningSpelling,
          isCorrect: true,
        ),
      ],
    );
  }

  static List<AnswerRecord> _records({
    required String childId,
    required List<_RecordSeed> seeds,
  }) {
    return seeds
        .map(
          (seed) => AnswerRecord(
            childId: childId,
            wordId: '$childId-${seed.answeredAt.millisecondsSinceEpoch}',
            practiceMode: seed.practiceMode,
            isCorrect: seed.isCorrect,
            answeredAt: seed.answeredAt,
            elapsedMilliseconds: 1800,
            weaknessType: seed.weaknessType,
          ),
        )
        .toList();
  }

  static List<WordEntry> _words(String prefix, int count) {
    return List.generate(
      count,
      (index) => WordEntry(
        id: '$prefix-$index',
        spelling: '$prefix-$index',
        meanings: ['释义 $index'],
      ),
    );
  }

  static DateTime _sameDayAt(DateTime referenceDate, int hour) {
    return DateTime(
        referenceDate.year, referenceDate.month, referenceDate.day, hour);
  }

  static ChildDashboardSnapshot _buildSnapshotForChild({
    required HomeDashboardBuilder builder,
    required ChildProfile child,
    required DateTime referenceDate,
  }) {
    final seed = switch (child.id) {
      'child-brother' => _SeedData(
          task: _buildTask(
            childId: child.id,
            date: _sameDayAt(referenceDate, 18),
            newWordLimit: 12,
            reviewLimit: 24,
            mistakeLimit: 6,
            newWordPrefix: 'brother-new',
            reviewPrefix: 'brother-review',
            mistakePrefix: 'brother-mistake',
          ),
          answerRecords: _brotherRecords(),
          completedItems: 29,
        ),
      'child-sister' => _SeedData(
          task: _buildTask(
            childId: child.id,
            date: _sameDayAt(referenceDate, 18),
            newWordLimit: 8,
            reviewLimit: 16,
            mistakeLimit: 4,
            newWordPrefix: 'sister-new',
            reviewPrefix: 'sister-review',
            mistakePrefix: 'sister-mistake',
          ),
          answerRecords: _sisterRecords(),
          completedItems: 12,
        ),
      _ => _SeedData(
          task: StudyTask(
            childId: child.id,
            date: referenceDate,
            items: const [],
          ),
          answerRecords: const [],
          completedItems: 0,
        ),
    };

    return builder.buildChildSnapshot(
      child: child,
      todayTask: seed.task,
      answerRecords: seed.answerRecords,
      completedItems: seed.completedItems,
      referenceDate: referenceDate,
    );
  }
}

class _SeedData {
  _SeedData({
    required this.task,
    required this.answerRecords,
    required this.completedItems,
  });

  final StudyTask task;
  final List<AnswerRecord> answerRecords;
  final int completedItems;
}

class _RecordSeed {
  const _RecordSeed({
    required this.answeredAt,
    required this.practiceMode,
    required this.isCorrect,
    this.weaknessType,
  });

  final DateTime answeredAt;
  final PracticeMode practiceMode;
  final bool isCorrect;
  final AnswerWeaknessType? weaknessType;
}
