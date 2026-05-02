import 'package:flutter_test/flutter_test.dart';
import 'package:word_quest/features/word_book/application/csv_word_book_importer.dart';

void main() {
  group('CsvWordBookImporter', () {
    test('从带表头 CSV 导入词表并保留可选字段', () {
      const importer = CsvWordBookImporter();

      final result = importer.import(
        id: 'custom-1',
        name: '我的词表',
        stageLabel: '自定义',
        csvText: '''
单词,中文释义,音标,词性,例句,标签,来源
apple,"苹果, 苹果树",/ˈæpəl/,n.,I eat an apple.,水果|小学,手动导入
brave,勇敢的,/breɪv/,adj.,Be brave.,品质;初中,手动导入
''',
      );

      expect(result.isSuccess, isTrue);
      expect(result.errors, isEmpty);
      expect(result.wordBook?.id, 'custom-1');
      expect(result.wordBook?.name, '我的词表');
      expect(result.wordBook?.words, hasLength(2));
      expect(result.wordBook?.words.first.spelling, 'apple');
      expect(result.wordBook?.words.first.meanings, ['苹果', '苹果树']);
      expect(result.wordBook?.words.first.phonetic, '/ˈæpəl/');
      expect(result.wordBook?.words.first.partOfSpeech, 'n.');
      expect(result.wordBook?.words.first.example, 'I eat an apple.');
      expect(result.wordBook?.words.first.tags, ['水果', '小学']);
      expect(result.wordBook?.words.last.tags, ['品质', '初中']);
    });

    test('缺少单词或释义时返回行级错误', () {
      const importer = CsvWordBookImporter();

      final result = importer.import(
        id: 'bad-custom',
        name: '错误词表',
        stageLabel: '自定义',
        csvText: '''
单词,中文释义
,苹果
banana,
''',
      );

      expect(result.isSuccess, isFalse);
      expect(result.wordBook, isNull);
      expect(result.errors, [
        '第 2 行缺少单词',
        '第 3 行缺少中文释义',
      ]);
    });
  });
}
