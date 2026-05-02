import '../../study/domain/word_learning_progress.dart';
import '../../word_book/domain/word_book.dart';
import '../domain/adventure_dashboard_snapshot.dart';
import '../domain/adventure_level.dart';

class AdventureDailyPlanner {
  const AdventureDailyPlanner();

  AdventureDashboardSnapshot plan({
    required AdventureDashboardSnapshot snapshot,
    required List<WordBook> wordBooks,
    required List<WordLearningProgress> learningProgresses,
    required String? selectedWordBookId,
  }) {
    final currentWordBook = _currentWordBook(
      wordBooks: wordBooks,
      selectedWordBookId: selectedWordBookId,
    );
    if (currentWordBook == null || currentWordBook.words.isEmpty) {
      return snapshot;
    }

    final metrics = _DailyPlanMetrics.from(
      childId: snapshot.childId,
      referenceDate:
          snapshot.levels.isEmpty ? DateTime.now() : snapshot.levels.first.date,
      wordBook: currentWordBook,
      learningProgresses: learningProgresses,
    );

    return AdventureDashboardSnapshot(
      childId: snapshot.childId,
      themeTitle: snapshot.themeTitle,
      currentNodeTitle: snapshot.currentNodeTitle,
      starsEarned: snapshot.starsEarned,
      starsTarget: snapshot.starsTarget,
      chestProgress: snapshot.chestProgress,
      levels: [
        for (final level in snapshot.levels) _plannedLevel(level, metrics),
      ],
      pet: snapshot.pet,
    );
  }

  WordBook? _currentWordBook({
    required List<WordBook> wordBooks,
    required String? selectedWordBookId,
  }) {
    if (wordBooks.isEmpty) {
      return null;
    }

    for (final wordBook in wordBooks) {
      if (wordBook.id == selectedWordBookId) {
        return wordBook;
      }
    }

    return wordBooks.first;
  }

  AdventureLevel _plannedLevel(
    AdventureLevel level,
    _DailyPlanMetrics metrics,
  ) {
    final plannedQuestionCount = switch (level.type) {
      AdventureLevelType.newWordWarmup => metrics.newWordQuestionCount,
      AdventureLevelType.reviewExplore => metrics.reviewQuestionCount,
      AdventureLevelType.mistakeBoss => metrics.mistakeBossQuestionCount,
      AdventureLevelType.chestSettlement => level.questionCount,
    };

    return AdventureLevel(
      id: level.id,
      childId: level.childId,
      date: level.date,
      type: level.type,
      title: level.title,
      subtitle: _plannedSubtitle(level, plannedQuestionCount),
      status: level.status,
      questionCount: plannedQuestionCount,
      reward: level.reward,
    );
  }

  String _plannedSubtitle(AdventureLevel level, int questionCount) {
    return switch (level.type) {
      AdventureLevelType.newWordWarmup => '$questionCount 题 · 新词热身',
      AdventureLevelType.reviewExplore => '$questionCount 题 · 到期复习',
      AdventureLevelType.mistakeBoss => '$questionCount 题 · 收服迷雾单词',
      AdventureLevelType.chestSettlement => level.subtitle,
    };
  }
}

class _DailyPlanMetrics {
  const _DailyPlanMetrics({
    required this.wordCount,
    required this.unstartedWordCount,
    required this.masteredWordCount,
    required this.dueReviewCount,
    required this.mistakeWordCount,
  });

  final int wordCount;
  final int unstartedWordCount;
  final int masteredWordCount;
  final int dueReviewCount;
  final int mistakeWordCount;

  int get newWordQuestionCount {
    if (unstartedWordCount <= 0) {
      return masteredRatio >= 0.8 ? 2 : 3;
    }

    if (masteredRatio >= 0.7) {
      return _clampInt(unstartedWordCount, min: 2, max: 4);
    }
    if (masteredRatio >= 0.3) {
      return _clampInt(unstartedWordCount, min: 3, max: 6);
    }
    return _clampInt(unstartedWordCount, min: 4, max: 8);
  }

  int get reviewQuestionCount {
    final masteryBonus = (masteredRatio * 3).round();
    return _clampInt(dueReviewCount + masteryBonus, min: 3, max: 10);
  }

  int get mistakeBossQuestionCount {
    return _clampInt(mistakeWordCount, min: 2, max: 6);
  }

  double get masteredRatio {
    if (wordCount <= 0) {
      return 0;
    }
    return masteredWordCount / wordCount;
  }

  static _DailyPlanMetrics from({
    required String childId,
    required DateTime referenceDate,
    required WordBook wordBook,
    required List<WordLearningProgress> learningProgresses,
  }) {
    final wordIds = {for (final word in wordBook.words) word.id};
    final progressByWordId = <String, WordLearningProgress>{};
    for (final progress in learningProgresses) {
      if (progress.childId != childId || !wordIds.contains(progress.wordId)) {
        continue;
      }
      final existing = progressByWordId[progress.wordId];
      if (existing == null || progress.updatedAt.isAfter(existing.updatedAt)) {
        progressByWordId[progress.wordId] = progress;
      }
    }

    final referenceDay = _dateOnly(referenceDate);
    var masteredWordCount = 0;
    var dueReviewCount = 0;
    var mistakeWordCount = 0;
    for (final progress in progressByWordId.values) {
      if (progress.isMastered) {
        masteredWordCount += 1;
      }
      if (progress.consecutiveMistakes > 0) {
        mistakeWordCount += 1;
        continue;
      }
      if (!_dateOnly(progress.nextReviewAt).isAfter(referenceDay)) {
        dueReviewCount += 1;
      }
    }

    return _DailyPlanMetrics(
      wordCount: wordIds.length,
      unstartedWordCount: wordIds.length - progressByWordId.length,
      masteredWordCount: masteredWordCount,
      dueReviewCount: dueReviewCount,
      mistakeWordCount: mistakeWordCount,
    );
  }

  static int _clampInt(int value, {required int min, required int max}) {
    if (value < min) {
      return min;
    }
    if (value > max) {
      return max;
    }
    return value;
  }

  static DateTime _dateOnly(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }
}
