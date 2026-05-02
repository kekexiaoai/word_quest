import '../domain/adventure_level.dart';
import '../domain/adventure_level_quiz.dart';

class AdventureLevelQuizBuilder {
  const AdventureLevelQuizBuilder();

  AdventureLevelQuiz buildForLevel(AdventureLevel level) {
    return switch (level.type) {
      AdventureLevelType.newWordWarmup => _newWordWarmup(level),
      AdventureLevelType.reviewExplore => _reviewExplore(level),
      AdventureLevelType.mistakeBoss => _mistakeBoss(level),
      AdventureLevelType.chestSettlement => _chestSettlement(level),
    };
  }

  AdventureLevelQuiz _newWordWarmup(AdventureLevel level) {
    return AdventureLevelQuiz(
      activityTitle: '新词热身',
      progressLabel: _progressLabel(level),
      progressValue: _progressValue(level),
      instruction: '看单词，选择中文意思',
      prompt: 'library',
      correctAnswer: '图书馆',
      choices: const ['图书馆', '邻居', '穿过'],
      successTitle: '热身成功',
      explanation: 'library 表示图书馆，是今天的新词。',
      usesAudioPrompt: false,
    );
  }

  AdventureLevelQuiz _reviewExplore(AdventureLevel level) {
    return AdventureLevelQuiz(
      activityTitle: '听音训练',
      progressLabel: _progressLabel(level),
      progressValue: _progressValue(level),
      instruction: '听发音，选择对应单词',
      prompt: 'through',
      correctAnswer: 'through',
      choices: const ['neighbor', 'library', 'through'],
      successTitle: '答对了',
      explanation: 'through 表示穿过，也可表示从头到尾完成。',
      usesAudioPrompt: true,
    );
  }

  AdventureLevelQuiz _mistakeBoss(AdventureLevel level) {
    return AdventureLevelQuiz(
      activityTitle: '错词 Boss',
      progressLabel: _progressLabel(level),
      progressValue: _progressValue(level),
      instruction: '收服迷雾单词',
      prompt: 'through',
      correctAnswer: '穿过',
      choices: const ['穿过', '图书馆', '邻居'],
      successTitle: '收服成功',
      explanation: '这个迷雾单词被你打败了，稍后还会再巩固一次。',
      usesAudioPrompt: false,
    );
  }

  AdventureLevelQuiz _chestSettlement(AdventureLevel level) {
    return const AdventureLevelQuiz(
      activityTitle: '宝箱回顾',
      progressLabel: '1 / 1',
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

  String _progressLabel(AdventureLevel level) {
    return '1 / ${level.questionCount <= 0 ? 1 : level.questionCount}';
  }

  double _progressValue(AdventureLevel level) {
    final questionCount = level.questionCount <= 0 ? 1 : level.questionCount;
    return 1 / questionCount;
  }
}
