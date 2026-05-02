import '../domain/adventure_level.dart';
import '../domain/adventure_level_quiz.dart';

class AdventureLevelQuizBuilder {
  const AdventureLevelQuizBuilder();

  AdventureLevelQuiz buildForLevel(
    AdventureLevel level, {
    int questionIndex = 0,
  }) {
    return switch (level.type) {
      AdventureLevelType.newWordWarmup => _newWordWarmup(level, questionIndex),
      AdventureLevelType.reviewExplore => _reviewExplore(level, questionIndex),
      AdventureLevelType.mistakeBoss => _mistakeBoss(level, questionIndex),
      AdventureLevelType.chestSettlement =>
        _chestSettlement(level, questionIndex),
    };
  }

  AdventureLevelQuiz _newWordWarmup(AdventureLevel level, int questionIndex) {
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
      prompt: seed.prompt,
      correctAnswer: seed.correctAnswer,
      choices: const ['图书馆', '邻居', '穿过'],
      successTitle: '热身成功',
      explanation: '${seed.prompt} 表示${seed.correctAnswer}，先赢一次很重要。',
      usesAudioPrompt: false,
    );
  }

  AdventureLevelQuiz _reviewExplore(AdventureLevel level, int questionIndex) {
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
      prompt: seed.prompt,
      correctAnswer: seed.correctAnswer,
      choices: const ['neighbor', 'library', 'through'],
      successTitle: '答对了',
      explanation: seed.explanation,
      usesAudioPrompt: true,
    );
  }

  AdventureLevelQuiz _mistakeBoss(AdventureLevel level, int questionIndex) {
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
      prompt: seed.prompt,
      correctAnswer: seed.correctAnswer,
      choices: const ['穿过', '图书馆', '邻居'],
      successTitle: '收服成功',
      explanation: '${seed.prompt} 这段迷雾被你打散了，稍后还会再巩固一次。',
      usesAudioPrompt: false,
    );
  }

  AdventureLevelQuiz _chestSettlement(AdventureLevel level, int questionIndex) {
    return AdventureLevelQuiz(
      activityTitle: '宝箱回顾',
      progressLabel: _progressLabel(level, questionIndex),
      progressValue: 1,
      instruction: '打开宝箱前，回顾今天的收获',
      prompt: '今天完成关卡后会获得什么？',
      correctAnswer: '星星、食物和宠物成长',
      choices: ['星星、食物和宠物成长', '排名惩罚', '随机抽卡'],
      successTitle: '宝箱打开',
      explanation: '学习奖励只用于鼓励和记录，不制造压力。',
      usesAudioPrompt: false,
    );
  }

  _QuizSeed _seedAt(List<_QuizSeed> seeds, int questionIndex) {
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
