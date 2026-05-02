import 'package:flutter_test/flutter_test.dart';
import 'package:word_quest/features/study/application/study_answer_evaluator.dart';
import 'package:word_quest/features/study/application/study_question_factory.dart';
import 'package:word_quest/features/study/domain/answer_record.dart';
import 'package:word_quest/features/study/domain/study_question.dart';
import 'package:word_quest/features/study/domain/study_task.dart';
import 'package:word_quest/features/word_book/domain/word_entry.dart';

void main() {
  group('StudyQuestionFactory', () {
    test('生成英选中题目并混入干扰选项', () {
      const factory = StudyQuestionFactory();

      final question = factory.buildQuestion(
        item: StudyTaskItem(
          word: _word('apple', '苹果'),
          type: StudyTaskType.newWords,
          practiceModes: const [PracticeMode.englishToChinese],
        ),
        mode: PracticeMode.englishToChinese,
        wordBank: [
          _word('apple', '苹果'),
          _word('banana', '香蕉'),
          _word('brave', '勇敢的'),
          _word('river', '河流'),
        ],
      );

      expect(question.type, StudyQuestionType.choice);
      expect(question.prompt, 'apple');
      expect(question.correctAnswer, '苹果');
      expect(question.choices, containsAll(['苹果', '香蕉', '勇敢的', '河流']));
    });

    test('生成拼写题并判定拼写薄弱', () {
      const factory = StudyQuestionFactory();
      const evaluator = StudyAnswerEvaluator();

      final question = factory.buildQuestion(
        item: StudyTaskItem(
          word: _word('apple', '苹果'),
          type: StudyTaskType.review,
          practiceModes: const [PracticeMode.spelling],
        ),
        mode: PracticeMode.spelling,
        wordBank: [_word('apple', '苹果')],
      );

      final record = evaluator.evaluate(
        childId: 'child-a',
        question: question,
        submittedAnswer: 'appl',
        answeredAt: DateTime(2026, 5, 2, 10),
        elapsedMilliseconds: 1400,
      );

      expect(question.type, StudyQuestionType.input);
      expect(question.prompt, '苹果');
      expect(question.correctAnswer, 'apple');
      expect(record.isCorrect, isFalse);
      expect(record.weaknessType, AnswerWeaknessType.spelling);
    });

    test('拼写题判题忽略大小写和前后空格', () {
      const factory = StudyQuestionFactory();
      const evaluator = StudyAnswerEvaluator();

      final question = factory.buildQuestion(
        item: StudyTaskItem(
          word: _word('Apple', '苹果'),
          type: StudyTaskType.review,
          practiceModes: const [PracticeMode.spelling],
        ),
        mode: PracticeMode.spelling,
        wordBank: [_word('Apple', '苹果')],
      );

      final record = evaluator.evaluate(
        childId: 'child-a',
        question: question,
        submittedAnswer: ' apple ',
        answeredAt: DateTime(2026, 5, 2, 10),
        elapsedMilliseconds: 1400,
      );

      expect(record.isCorrect, isTrue);
      expect(record.weaknessType, isNull);
    });
  });
}

WordEntry _word(String spelling, String meaning) {
  return WordEntry(
    id: spelling,
    spelling: spelling,
    meanings: [meaning],
  );
}
