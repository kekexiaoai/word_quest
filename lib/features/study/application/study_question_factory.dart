import '../../word_book/domain/word_entry.dart';
import '../domain/study_question.dart';
import '../domain/study_task.dart';

class StudyQuestionFactory {
  const StudyQuestionFactory();

  StudyQuestion buildQuestion({
    required StudyTaskItem item,
    required PracticeMode mode,
    required List<WordEntry> wordBank,
  }) {
    return switch (mode) {
      PracticeMode.englishToChinese => _buildEnglishToChinese(item, wordBank),
      PracticeMode.chineseToEnglish => _buildChineseToEnglish(item, wordBank),
      PracticeMode.spelling => _buildSpelling(item),
      PracticeMode.listeningChoice => _buildListeningChoice(item, wordBank),
      PracticeMode.listeningSpelling => _buildListeningSpelling(item),
    };
  }

  StudyQuestion _buildEnglishToChinese(
    StudyTaskItem item,
    List<WordEntry> wordBank,
  ) {
    return StudyQuestion(
      wordId: item.word.id,
      practiceMode: PracticeMode.englishToChinese,
      type: StudyQuestionType.choice,
      prompt: item.word.spelling,
      correctAnswer: _primaryMeaning(item.word),
      choices: _meaningChoices(item.word, wordBank),
    );
  }

  StudyQuestion _buildChineseToEnglish(
    StudyTaskItem item,
    List<WordEntry> wordBank,
  ) {
    return StudyQuestion(
      wordId: item.word.id,
      practiceMode: PracticeMode.chineseToEnglish,
      type: StudyQuestionType.choice,
      prompt: _primaryMeaning(item.word),
      correctAnswer: item.word.spelling,
      choices: _spellingChoices(item.word, wordBank),
    );
  }

  StudyQuestion _buildSpelling(StudyTaskItem item) {
    return StudyQuestion(
      wordId: item.word.id,
      practiceMode: PracticeMode.spelling,
      type: StudyQuestionType.input,
      prompt: _primaryMeaning(item.word),
      correctAnswer: item.word.spelling,
    );
  }

  StudyQuestion _buildListeningChoice(
    StudyTaskItem item,
    List<WordEntry> wordBank,
  ) {
    return StudyQuestion(
      wordId: item.word.id,
      practiceMode: PracticeMode.listeningChoice,
      type: StudyQuestionType.choice,
      prompt: item.word.spelling,
      correctAnswer: item.word.spelling,
      choices: _spellingChoices(item.word, wordBank),
    );
  }

  StudyQuestion _buildListeningSpelling(StudyTaskItem item) {
    return StudyQuestion(
      wordId: item.word.id,
      practiceMode: PracticeMode.listeningSpelling,
      type: StudyQuestionType.input,
      prompt: item.word.spelling,
      correctAnswer: item.word.spelling,
    );
  }

  List<String> _meaningChoices(WordEntry word, List<WordEntry> wordBank) {
    return _dedupe([
      _primaryMeaning(word),
      for (final candidate in wordBank)
        if (candidate.id != word.id) _primaryMeaning(candidate),
    ]).take(4).toList();
  }

  List<String> _spellingChoices(WordEntry word, List<WordEntry> wordBank) {
    return _dedupe([
      word.spelling,
      for (final candidate in wordBank)
        if (candidate.id != word.id) candidate.spelling,
    ]).take(4).toList();
  }

  String _primaryMeaning(WordEntry word) {
    return word.meanings.isEmpty ? '' : word.meanings.first;
  }

  List<String> _dedupe(List<String> values) {
    final seen = <String>{};
    final result = <String>[];
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isEmpty || seen.contains(trimmed)) {
        continue;
      }
      seen.add(trimmed);
      result.add(trimmed);
    }
    return result;
  }
}
