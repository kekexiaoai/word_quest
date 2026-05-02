import 'package:flutter_test/flutter_test.dart';
import 'package:word_quest/features/adventure/application/adventure_level_quiz_builder.dart';
import 'package:word_quest/features/adventure/application/in_memory_adventure_repository.dart';
import 'package:word_quest/features/study/domain/answer_record.dart';
import 'package:word_quest/features/study/domain/study_task.dart';
import 'package:word_quest/features/word_book/domain/word_book.dart';
import 'package:word_quest/features/word_book/domain/word_entry.dart';

void main() {
  test('新词热身关生成看词选义题组', () {
    const repository = InMemoryAdventureRepository();
    const builder = AdventureLevelQuizBuilder();
    final adventure = repository.loadAdventure(
      childId: 'child-brother',
      referenceDate: DateTime(2026, 5, 2),
    );

    final quiz = builder.buildForLevel(adventure.levels[0]);

    expect(quiz.activityTitle, '新词热身');
    expect(quiz.progressLabel, '1 / 8');
    expect(quiz.instruction, '看单词，选择中文意思');
    expect(quiz.prompt, 'library');
    expect(quiz.wordId, 'library');
    expect(quiz.practiceMode, PracticeMode.englishToChinese);
    expect(quiz.correctAnswer, '图书馆');
    expect(quiz.choices, contains('图书馆'));
  });

  test('新词热身关优先使用导入词表生成题组', () {
    const repository = InMemoryAdventureRepository();
    const builder = AdventureLevelQuizBuilder();
    final adventure = repository.loadAdventure(
      childId: 'child-brother',
      referenceDate: DateTime(2026, 5, 2),
    );

    final quiz = builder.buildForLevel(
      adventure.levels[0],
      wordBooks: const [
        WordBook(
          id: 'built-in',
          name: '内置词表',
          stageLabel: '内置',
          isBuiltIn: true,
          words: [
            WordEntry(id: 'library', spelling: 'library', meanings: ['图书馆']),
            WordEntry(id: 'neighbor', spelling: 'neighbor', meanings: ['邻居']),
          ],
        ),
        WordBook(
          id: 'custom',
          name: '我的导入词表',
          stageLabel: '自定义',
          words: [
            WordEntry(id: 'custom-ocean', spelling: 'ocean', meanings: ['海洋']),
            WordEntry(id: 'custom-river', spelling: 'river', meanings: ['河流']),
            WordEntry(
                id: 'custom-mountain', spelling: 'mountain', meanings: ['高山']),
          ],
        ),
      ],
    );

    expect(quiz.prompt, 'ocean');
    expect(quiz.wordId, 'custom-ocean');
    expect(quiz.correctAnswer, '海洋');
    expect(quiz.choices, containsAll(['海洋', '河流']));
  });

  test('新词热身关按当前学习词表生成题组', () {
    const repository = InMemoryAdventureRepository();
    const builder = AdventureLevelQuizBuilder();
    final adventure = repository.loadAdventure(
      childId: 'child-brother',
      referenceDate: DateTime(2026, 5, 2),
    );

    final quiz = builder.buildForLevel(
      adventure.levels[0],
      selectedWordBookId: 'middle-core',
      wordBooks: const [
        WordBook(
          id: 'primary-basic',
          name: '小学高年级基础词表',
          stageLabel: '小学高年级词表',
          isBuiltIn: true,
          words: [
            WordEntry(id: 'library', spelling: 'library', meanings: ['图书馆']),
          ],
        ),
        WordBook(
          id: 'middle-core',
          name: '初中核心词表',
          stageLabel: '初中词表',
          isBuiltIn: true,
          words: [
            WordEntry(id: 'energy', spelling: 'energy', meanings: ['能量']),
            WordEntry(id: 'planet', spelling: 'planet', meanings: ['行星']),
          ],
        ),
      ],
    );

    expect(quiz.wordId, 'energy');
    expect(quiz.prompt, 'energy');
    expect(quiz.correctAnswer, '能量');
    expect(quiz.choices, contains('行星'));
  });

  test('题组会按题号更新进度和题面', () {
    const repository = InMemoryAdventureRepository();
    const builder = AdventureLevelQuizBuilder();
    final adventure = repository.loadAdventure(
      childId: 'child-brother',
      referenceDate: DateTime(2026, 5, 2),
    );

    final firstQuiz = builder.buildForLevel(adventure.levels[1]);
    final secondQuiz = builder.buildForLevel(
      adventure.levels[1],
      questionIndex: 1,
    );

    expect(firstQuiz.progressLabel, '1 / 6');
    expect(firstQuiz.correctAnswer, 'through');
    expect(secondQuiz.progressLabel, '2 / 6');
    expect(secondQuiz.progressValue, closeTo(2 / 6, 0.001));
    expect(secondQuiz.correctAnswer, 'neighbor');
    expect(secondQuiz.choices, contains('neighbor'));
  });

  test('复习探索关生成听音选词题组', () {
    const repository = InMemoryAdventureRepository();
    const builder = AdventureLevelQuizBuilder();
    final adventure = repository.loadAdventure(
      childId: 'child-brother',
      referenceDate: DateTime(2026, 5, 2),
    );

    final quiz = builder.buildForLevel(adventure.levels[1]);

    expect(quiz.activityTitle, '听音训练');
    expect(quiz.progressLabel, '1 / 6');
    expect(quiz.instruction, '听发音，选择对应单词');
    expect(quiz.prompt, 'through');
    expect(quiz.wordId, 'through');
    expect(quiz.practiceMode, PracticeMode.listeningChoice);
    expect(quiz.correctAnswer, 'through');
    expect(quiz.choices, ['neighbor', 'library', 'through']);
  });

  test('复习探索关优先根据听力薄弱记录生成题目', () {
    const repository = InMemoryAdventureRepository();
    const builder = AdventureLevelQuizBuilder();
    final adventure = repository.loadAdventure(
      childId: 'child-brother',
      referenceDate: DateTime(2026, 5, 2),
    );

    final quiz = builder.buildForLevel(
      adventure.levels[1],
      wordBooks: _wordBooks,
      answerRecords: [
        AnswerRecord(
          childId: 'child-brother',
          wordId: 'library',
          practiceMode: PracticeMode.listeningChoice,
          isCorrect: false,
          answeredAt: DateTime(2026, 5, 2, 8),
          elapsedMilliseconds: 1200,
          weaknessType: AnswerWeaknessType.listening,
        ),
      ],
    );

    expect(quiz.activityTitle, '薄弱点复习');
    expect(quiz.instruction, '听发音，选择对应单词');
    expect(quiz.prompt, 'library');
    expect(quiz.wordId, 'library');
    expect(quiz.practiceMode, PracticeMode.listeningChoice);
    expect(quiz.correctAnswer, 'library');
  });

  test('错词 Boss 关生成正向挑战题组', () {
    const repository = InMemoryAdventureRepository();
    const builder = AdventureLevelQuizBuilder();
    final adventure = repository.loadAdventure(
      childId: 'child-brother',
      referenceDate: DateTime(2026, 5, 2),
    );

    final quiz = builder.buildForLevel(adventure.levels[2]);

    expect(quiz.activityTitle, '错词 Boss');
    expect(quiz.progressLabel, '1 / 4');
    expect(quiz.instruction, '收服迷雾单词');
    expect(quiz.prompt, 'through');
    expect(quiz.correctAnswer, '穿过');
    expect(quiz.successTitle, '收服成功');
  });

  test('错词 Boss 优先根据真实错题记录生成题目', () {
    const repository = InMemoryAdventureRepository();
    const builder = AdventureLevelQuizBuilder();
    final adventure = repository.loadAdventure(
      childId: 'child-brother',
      referenceDate: DateTime(2026, 5, 2),
    );

    final quiz = builder.buildForLevel(
      adventure.levels[2],
      wordBooks: _wordBooks,
      answerRecords: [
        AnswerRecord(
          childId: 'child-sister',
          wordId: 'library',
          practiceMode: PracticeMode.englishToChinese,
          isCorrect: false,
          answeredAt: DateTime(2026, 5, 2, 8),
          elapsedMilliseconds: 1000,
          weaknessType: AnswerWeaknessType.meaning,
        ),
        AnswerRecord(
          childId: 'child-brother',
          wordId: 'neighbor',
          practiceMode: PracticeMode.englishToChinese,
          isCorrect: false,
          answeredAt: DateTime(2026, 5, 2, 9),
          elapsedMilliseconds: 900,
          weaknessType: AnswerWeaknessType.meaning,
        ),
      ],
    );

    expect(quiz.activityTitle, '错词 Boss');
    expect(quiz.prompt, 'neighbor');
    expect(quiz.wordId, 'neighbor');
    expect(quiz.correctAnswer, '邻居');
    expect(quiz.choices, contains('邻居'));
  });

  test('导入词表中的错词可以进入错词 Boss', () {
    const repository = InMemoryAdventureRepository();
    const builder = AdventureLevelQuizBuilder();
    final adventure = repository.loadAdventure(
      childId: 'child-brother',
      referenceDate: DateTime(2026, 5, 2),
    );

    final quiz = builder.buildForLevel(
      adventure.levels[2],
      wordBooks: const [
        WordBook(
          id: 'custom',
          name: '我的导入词表',
          stageLabel: '自定义',
          words: [
            WordEntry(id: 'custom-ocean', spelling: 'ocean', meanings: ['海洋']),
            WordEntry(id: 'custom-river', spelling: 'river', meanings: ['河流']),
            WordEntry(
                id: 'custom-mountain', spelling: 'mountain', meanings: ['高山']),
          ],
        ),
      ],
      answerRecords: [
        AnswerRecord(
          childId: 'child-brother',
          wordId: 'custom-ocean',
          practiceMode: PracticeMode.englishToChinese,
          isCorrect: false,
          answeredAt: DateTime(2026, 5, 2, 9),
          elapsedMilliseconds: 900,
          weaknessType: AnswerWeaknessType.meaning,
        ),
      ],
    );

    expect(quiz.prompt, 'ocean');
    expect(quiz.wordId, 'custom-ocean');
    expect(quiz.correctAnswer, '海洋');
    expect(quiz.choices, contains('河流'));
  });
}

const _wordBooks = [
  WordBook(
    id: 'primary',
    name: '小学词表',
    stageLabel: '小学',
    words: [
      WordEntry(id: 'library', spelling: 'library', meanings: ['图书馆']),
      WordEntry(id: 'neighbor', spelling: 'neighbor', meanings: ['邻居']),
      WordEntry(id: 'through', spelling: 'through', meanings: ['穿过']),
    ],
  ),
];
