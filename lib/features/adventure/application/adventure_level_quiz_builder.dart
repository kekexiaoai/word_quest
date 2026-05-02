import '../domain/adventure_level.dart';
import '../domain/adventure_level_quiz.dart';
import '../../study/domain/answer_record.dart';
import '../../study/domain/study_task.dart';
import '../../study/domain/word_learning_progress.dart';
import '../../word_book/domain/word_book.dart';
import '../../word_book/domain/word_entry.dart';

class AdventureLevelQuizBuilder {
  const AdventureLevelQuizBuilder();

  AdventureLevelQuiz buildForLevel(
    AdventureLevel level, {
    int questionIndex = 0,
    List<WordBook> wordBooks = const [],
    List<AnswerRecord> answerRecords = const [],
    List<WordLearningProgress> learningProgresses = const [],
    String? selectedWordBookId,
  }) {
    final wordCatalog = _wordCatalogFrom(wordBooks);
    return switch (level.type) {
      AdventureLevelType.newWordWarmup => _newWordWarmup(
          level,
          questionIndex,
          wordCatalog,
          selectedWordBookId,
          learningProgresses,
        ),
      AdventureLevelType.reviewExplore =>
        _reviewExplore(level, questionIndex, answerRecords, wordCatalog),
      AdventureLevelType.mistakeBoss =>
        _mistakeBoss(level, questionIndex, answerRecords, wordCatalog),
      AdventureLevelType.chestSettlement =>
        _chestSettlement(level, questionIndex),
    };
  }

  AdventureLevelQuiz _newWordWarmup(
    AdventureLevel level,
    int questionIndex,
    List<_KnownWord> wordCatalog,
    String? selectedWordBookId,
    List<WordLearningProgress> learningProgresses,
  ) {
    final selectedWords = _unmasteredWords(
      level,
      _wordsInBook(wordCatalog, selectedWordBookId),
      learningProgresses,
    );
    final fallbackWords = [
      for (final word in wordCatalog)
        if (!word.isBuiltIn) word,
      if (!wordCatalog.any((word) => !word.isBuiltIn)) ...wordCatalog,
    ];
    final newWords = selectedWords.isNotEmpty
        ? selectedWords
        : _unmasteredWords(level, fallbackWords, learningProgresses);

    if (newWords.isNotEmpty) {
      final word = _seedAt(newWords, questionIndex);
      return AdventureLevelQuiz(
        activityTitle: '新词热身',
        progressLabel: _progressLabel(level, questionIndex),
        progressValue: _progressValue(level, questionIndex),
        instruction: '看单词，选择中文意思',
        wordId: word.id,
        practiceMode: PracticeMode.englishToChinese,
        prompt: word.spelling,
        correctAnswer: word.meaning,
        choices: _meaningChoices(word, wordCatalog),
        successTitle: '热身成功',
        explanation: '${word.spelling} 表示${word.meaning}，先赢一次很重要。',
        usesAudioPrompt: false,
      );
    }

    final seed = _seedAt(
      const [
        _QuizSeed(prompt: 'library', correctAnswer: '图书馆'),
        _QuizSeed(prompt: 'neighbor', correctAnswer: '邻居'),
        _QuizSeed(prompt: 'through', correctAnswer: '穿过'),
      ],
      questionIndex,
    );

    return AdventureLevelQuiz(
      activityTitle: '新词热身',
      progressLabel: _progressLabel(level, questionIndex),
      progressValue: _progressValue(level, questionIndex),
      instruction: '看单词，选择中文意思',
      wordId: seed.prompt,
      practiceMode: PracticeMode.englishToChinese,
      prompt: seed.prompt,
      correctAnswer: seed.correctAnswer,
      choices: const ['图书馆', '邻居', '穿过'],
      successTitle: '热身成功',
      explanation: '${seed.prompt} 表示${seed.correctAnswer}，先赢一次很重要。',
      usesAudioPrompt: false,
    );
  }

  AdventureLevelQuiz _reviewExplore(
    AdventureLevel level,
    int questionIndex,
    List<AnswerRecord> answerRecords,
    List<_KnownWord> wordCatalog,
  ) {
    final weaknessSeeds = _weaknessReviewSeeds(
      level,
      answerRecords,
      wordCatalog,
    );
    if (weaknessSeeds.isNotEmpty) {
      final seed = _seedAt(weaknessSeeds, questionIndex);
      return _weaknessReviewQuiz(level, questionIndex, seed);
    }

    final seed = _seedAt(
      const [
        _QuizSeed(
          prompt: 'through',
          correctAnswer: 'through',
          explanation: 'through 表示穿过，也可表示从头到尾完成。',
        ),
        _QuizSeed(
          prompt: 'neighbor',
          correctAnswer: 'neighbor',
          explanation: 'neighbor 表示邻居，听到开头 nei 要先想到它。',
        ),
        _QuizSeed(
          prompt: 'library',
          correctAnswer: 'library',
          explanation: 'library 表示图书馆，结尾是 ary。',
        ),
      ],
      questionIndex,
    );

    return AdventureLevelQuiz(
      activityTitle: '听音训练',
      progressLabel: _progressLabel(level, questionIndex),
      progressValue: _progressValue(level, questionIndex),
      instruction: '听发音，选择对应单词',
      wordId: seed.prompt,
      practiceMode: PracticeMode.listeningChoice,
      prompt: seed.prompt,
      correctAnswer: seed.correctAnswer,
      choices: const ['neighbor', 'library', 'through'],
      successTitle: '答对了',
      explanation: seed.explanation,
      usesAudioPrompt: true,
    );
  }

  AdventureLevelQuiz _mistakeBoss(
    AdventureLevel level,
    int questionIndex,
    List<AnswerRecord> answerRecords,
    List<_KnownWord> wordCatalog,
  ) {
    final mistakeSeeds = _mistakeSeeds(level, answerRecords, wordCatalog);
    if (mistakeSeeds.isNotEmpty) {
      final word = _seedAt(mistakeSeeds, questionIndex);
      return AdventureLevelQuiz(
        activityTitle: '错词 Boss',
        progressLabel: _progressLabel(level, questionIndex),
        progressValue: _progressValue(level, questionIndex),
        instruction: '收服真实错题',
        wordId: word.id,
        practiceMode: PracticeMode.englishToChinese,
        prompt: word.spelling,
        correctAnswer: word.meaning,
        choices: _meaningChoices(word, wordCatalog),
        successTitle: '收服成功',
        explanation: '${word.spelling} 是最近答错过的词，这次收服后会降低它的迷雾值。',
        usesAudioPrompt: false,
      );
    }

    final seed = _seedAt(
      const [
        _QuizSeed(prompt: 'through', correctAnswer: '穿过'),
        _QuizSeed(prompt: 'neighbor', correctAnswer: '邻居'),
        _QuizSeed(prompt: 'library', correctAnswer: '图书馆'),
      ],
      questionIndex,
    );

    return AdventureLevelQuiz(
      activityTitle: '错词 Boss',
      progressLabel: _progressLabel(level, questionIndex),
      progressValue: _progressValue(level, questionIndex),
      instruction: '收服迷雾单词',
      wordId: seed.prompt,
      practiceMode: PracticeMode.englishToChinese,
      prompt: seed.prompt,
      correctAnswer: seed.correctAnswer,
      choices: const ['穿过', '图书馆', '邻居'],
      successTitle: '收服成功',
      explanation: '${seed.prompt} 这段迷雾被你打散了，稍后还会再巩固一次。',
      usesAudioPrompt: false,
    );
  }

  AdventureLevelQuiz _weaknessReviewQuiz(
    AdventureLevel level,
    int questionIndex,
    _WeaknessReviewSeed seed,
  ) {
    final word = seed.word;
    return AdventureLevelQuiz(
      activityTitle: '薄弱点复习',
      progressLabel: _progressLabel(level, questionIndex),
      progressValue: _progressValue(level, questionIndex),
      instruction: _instructionFor(seed.practiceMode),
      wordId: word.id,
      practiceMode: seed.practiceMode,
      prompt: _promptFor(word, seed.practiceMode),
      correctAnswer: _correctAnswerFor(word, seed.practiceMode),
      choices: _choicesFor(word, seed.practiceMode, seed.wordCatalog),
      successTitle: '薄弱点修复',
      explanation: _explanationFor(word, seed.weaknessType),
      usesAudioPrompt: seed.practiceMode == PracticeMode.listeningChoice,
    );
  }

  AdventureLevelQuiz _chestSettlement(AdventureLevel level, int questionIndex) {
    return AdventureLevelQuiz(
      activityTitle: '宝箱回顾',
      progressLabel: _progressLabel(level, questionIndex),
      progressValue: 1,
      instruction: '打开宝箱前，回顾今天的收获',
      wordId: 'daily-chest',
      practiceMode: PracticeMode.chineseToEnglish,
      prompt: '今天完成关卡后会获得什么？',
      correctAnswer: '星星、食物和宠物成长',
      choices: ['星星、食物和宠物成长', '排名惩罚', '随机抽卡'],
      successTitle: '宝箱打开',
      explanation: '学习奖励只用于鼓励和记录，不制造压力。',
      usesAudioPrompt: false,
    );
  }

  T _seedAt<T>(List<T> seeds, int questionIndex) {
    return seeds[questionIndex % seeds.length];
  }

  String _progressLabel(AdventureLevel level, int questionIndex) {
    final questionCount = level.questionCount <= 0 ? 1 : level.questionCount;
    final displayIndex = questionIndex.clamp(0, questionCount - 1) + 1;
    return '$displayIndex / $questionCount';
  }

  double _progressValue(AdventureLevel level, int questionIndex) {
    final questionCount = level.questionCount <= 0 ? 1 : level.questionCount;
    final displayIndex = questionIndex.clamp(0, questionCount - 1) + 1;
    return displayIndex / questionCount;
  }

  List<_WeaknessReviewSeed> _weaknessReviewSeeds(
    AdventureLevel level,
    List<AnswerRecord> answerRecords,
    List<_KnownWord> wordCatalog,
  ) {
    final sortedRecords = _sortedIncorrectRecords(level, answerRecords);
    final seenWordIds = <String>{};
    final seeds = <_WeaknessReviewSeed>[];

    for (final record in sortedRecords) {
      final weaknessType = record.weaknessType;
      final word = _knownWordById(record.wordId, wordCatalog);
      if (weaknessType == null || word == null || !seenWordIds.add(word.id)) {
        continue;
      }

      seeds.add(
        _WeaknessReviewSeed(
          word: word,
          weaknessType: weaknessType,
          practiceMode: _practiceModeFor(weaknessType),
          wordCatalog: wordCatalog,
        ),
      );
    }

    return seeds;
  }

  List<_KnownWord> _mistakeSeeds(
    AdventureLevel level,
    List<AnswerRecord> answerRecords,
    List<_KnownWord> wordCatalog,
  ) {
    final sortedRecords = _sortedIncorrectRecords(level, answerRecords);
    final seenWordIds = <String>{};
    final words = <_KnownWord>[];

    for (final record in sortedRecords) {
      final word = _knownWordById(record.wordId, wordCatalog);
      if (word == null || !seenWordIds.add(word.id)) {
        continue;
      }
      words.add(word);
    }

    return words;
  }

  List<AnswerRecord> _sortedIncorrectRecords(
    AdventureLevel level,
    List<AnswerRecord> answerRecords,
  ) {
    final records = [
      for (final record in answerRecords)
        if (record.childId == level.childId && !record.isCorrect) record,
    ];

    records.sort((a, b) => b.answeredAt.compareTo(a.answeredAt));
    return records;
  }

  List<_KnownWord> _wordsInBook(
    List<_KnownWord> wordCatalog,
    String? wordBookId,
  ) {
    if (wordBookId == null || wordBookId.trim().isEmpty) {
      return const [];
    }

    return [
      for (final word in wordCatalog)
        if (word.wordBookId == wordBookId) word,
    ];
  }

  List<_KnownWord> _unmasteredWords(
    AdventureLevel level,
    List<_KnownWord> words,
    List<WordLearningProgress> learningProgresses,
  ) {
    if (words.isEmpty) {
      return const [];
    }

    final masteredWordIds = {
      for (final progress in learningProgresses)
        if (progress.childId == level.childId && progress.isMastered)
          progress.wordId,
    };
    final unmasteredWords = [
      for (final word in words)
        if (!masteredWordIds.contains(word.id)) word,
    ];

    return unmasteredWords.isEmpty ? words : unmasteredWords;
  }

  List<_KnownWord> _wordCatalogFrom(List<WordBook> wordBooks) {
    final words = <_KnownWord>[];
    final seenIds = <String>{};

    for (final wordBook in wordBooks) {
      for (final word in wordBook.words) {
        final knownWord = _KnownWord.fromEntry(wordBook, word);
        if (knownWord == null || !seenIds.add(knownWord.id)) {
          continue;
        }
        words.add(knownWord);
      }
    }

    return words;
  }

  _KnownWord? _knownWordById(String id, List<_KnownWord> wordCatalog) {
    for (final word in wordCatalog) {
      if (word.id == id) {
        return word;
      }
    }
    return null;
  }

  PracticeMode _practiceModeFor(AnswerWeaknessType weaknessType) {
    return switch (weaknessType) {
      AnswerWeaknessType.meaning => PracticeMode.englishToChinese,
      AnswerWeaknessType.spelling => PracticeMode.chineseToEnglish,
      AnswerWeaknessType.listening => PracticeMode.listeningChoice,
    };
  }

  String _instructionFor(PracticeMode practiceMode) {
    return switch (practiceMode) {
      PracticeMode.englishToChinese => '看单词，修复释义薄弱点',
      PracticeMode.chineseToEnglish => '看释义，选择正确拼写',
      PracticeMode.listeningChoice => '听发音，选择对应单词',
      PracticeMode.spelling => '看释义，拼出单词',
      PracticeMode.listeningSpelling => '听发音，拼出单词',
    };
  }

  String _promptFor(_KnownWord word, PracticeMode practiceMode) {
    return switch (practiceMode) {
      PracticeMode.englishToChinese ||
      PracticeMode.listeningChoice =>
        word.spelling,
      PracticeMode.chineseToEnglish ||
      PracticeMode.spelling ||
      PracticeMode.listeningSpelling =>
        word.meaning,
    };
  }

  String _correctAnswerFor(_KnownWord word, PracticeMode practiceMode) {
    return switch (practiceMode) {
      PracticeMode.englishToChinese => word.meaning,
      PracticeMode.chineseToEnglish ||
      PracticeMode.spelling ||
      PracticeMode.listeningChoice ||
      PracticeMode.listeningSpelling =>
        word.spelling,
    };
  }

  List<String> _choicesFor(
    _KnownWord word,
    PracticeMode practiceMode,
    List<_KnownWord> wordCatalog,
  ) {
    return switch (practiceMode) {
      PracticeMode.englishToChinese => _meaningChoices(word, wordCatalog),
      PracticeMode.chineseToEnglish ||
      PracticeMode.spelling ||
      PracticeMode.listeningChoice ||
      PracticeMode.listeningSpelling =>
        _spellingChoices(word, wordCatalog),
    };
  }

  List<String> _meaningChoices(_KnownWord word, List<_KnownWord> wordCatalog) {
    return [
      word.meaning,
      for (final candidate in _choiceCandidates(word, wordCatalog))
        if (candidate.id != word.id) candidate.meaning,
    ].take(3).toList();
  }

  List<String> _spellingChoices(_KnownWord word, List<_KnownWord> wordCatalog) {
    return [
      word.spelling,
      for (final candidate in _choiceCandidates(word, wordCatalog))
        if (candidate.id != word.id) candidate.spelling,
    ].take(3).toList();
  }

  List<_KnownWord> _choiceCandidates(
    _KnownWord word,
    List<_KnownWord> wordCatalog,
  ) {
    return [
      for (final candidate in wordCatalog)
        if (candidate.wordBookId == word.wordBookId) candidate,
      for (final candidate in wordCatalog)
        if (candidate.wordBookId != word.wordBookId) candidate,
    ];
  }

  String _explanationFor(_KnownWord word, AnswerWeaknessType weaknessType) {
    return switch (weaknessType) {
      AnswerWeaknessType.meaning =>
        '${word.spelling} 的意思是${word.meaning}，这次专门修复释义薄弱点。',
      AnswerWeaknessType.spelling =>
        '${word.meaning} 对应 ${word.spelling}，注意拼写顺序。',
      AnswerWeaknessType.listening => '听到 ${word.spelling} 的发音时，要先锁定这个单词。',
    };
  }
}

class _QuizSeed {
  const _QuizSeed({
    required this.prompt,
    required this.correctAnswer,
    this.explanation = '',
  });

  final String prompt;
  final String correctAnswer;
  final String explanation;
}

class _KnownWord {
  const _KnownWord({
    required this.id,
    required this.wordBookId,
    required this.isBuiltIn,
    required this.spelling,
    required this.meaning,
  });

  final String id;
  final String wordBookId;
  final bool isBuiltIn;
  final String spelling;
  final String meaning;

  static _KnownWord? fromEntry(WordBook wordBook, WordEntry entry) {
    if (entry.meanings.isEmpty) {
      return null;
    }

    return _KnownWord(
      id: entry.id,
      wordBookId: wordBook.id,
      isBuiltIn: wordBook.isBuiltIn,
      spelling: entry.spelling,
      meaning: entry.meanings.first,
    );
  }
}

class _WeaknessReviewSeed {
  const _WeaknessReviewSeed({
    required this.word,
    required this.weaknessType,
    required this.practiceMode,
    required this.wordCatalog,
  });

  final _KnownWord word;
  final AnswerWeaknessType weaknessType;
  final PracticeMode practiceMode;
  final List<_KnownWord> wordCatalog;
}
