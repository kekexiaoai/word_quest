import '../../child_profile/domain/child_profile.dart';
import '../../study/domain/answer_record.dart';
import '../../study/domain/study_task.dart';
import '../domain/home_dashboard_snapshot.dart';

class HomeDashboardBuilder {
  const HomeDashboardBuilder();

  ChildDashboardSnapshot buildChildSnapshot({
    required ChildProfile child,
    required StudyTask todayTask,
    required List<AnswerRecord> answerRecords,
    required int completedItems,
    required DateTime referenceDate,
  }) {
    final totalItems = todayTask.items.length;
    final safeCompletedItems = completedItems.clamp(0, totalItems).toInt();

    return ChildDashboardSnapshot(
      id: child.id,
      name: child.name,
      gradeLabel: child.gradeLabel,
      taskSummary: _taskSummary(todayTask),
      accuracyLabel: _accuracyLabel(answerRecords),
      streakLabel: _streakLabel(answerRecords, referenceDate),
      progress: totalItems == 0 ? 0 : safeCompletedItems / totalItems,
      weaknessHighlights: _weaknessHighlights(answerRecords),
    );
  }

  String _taskSummary(StudyTask task) {
    return '新词 ${task.newWordCount} 个 · 复习 ${task.reviewCount} 个 · 错词 ${task.mistakeCount} 个';
  }

  String _accuracyLabel(List<AnswerRecord> answerRecords) {
    if (answerRecords.isEmpty) {
      return '暂无记录';
    }

    final correctCount =
        answerRecords.where((record) => record.isCorrect).length;
    final percentage = (correctCount / answerRecords.length) * 100;
    return '${percentage.round()}%';
  }

  String _streakLabel(
      List<AnswerRecord> answerRecords, DateTime referenceDate) {
    final streakDays = _streakDays(answerRecords, referenceDate);
    if (streakDays == 0) {
      return '暂无连续';
    }

    return '连续 $streakDays 天';
  }

  int _streakDays(List<AnswerRecord> answerRecords, DateTime referenceDate) {
    final activeDates =
        answerRecords.map((record) => _dateKey(record.answeredAt)).toSet();

    if (activeDates.isEmpty) {
      return 0;
    }

    var currentDate = _dateKey(referenceDate);
    var streakDays = 0;
    while (activeDates.contains(currentDate)) {
      streakDays += 1;
      currentDate = currentDate.subtract(const Duration(days: 1));
    }

    return streakDays;
  }

  List<String> _weaknessHighlights(List<AnswerRecord> answerRecords) {
    final highlights = <String>[];

    for (final record in answerRecords) {
      final weaknessType = record.weaknessType;
      if (weaknessType == null) {
        continue;
      }

      final label = switch (weaknessType) {
        AnswerWeaknessType.meaning => '释义薄弱',
        AnswerWeaknessType.spelling => '拼写薄弱',
        AnswerWeaknessType.listening => '听音薄弱',
      };

      if (!highlights.contains(label)) {
        highlights.add(label);
      }
    }

    return highlights;
  }

  DateTime _dateKey(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
