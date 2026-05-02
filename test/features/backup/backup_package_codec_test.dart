import 'package:flutter_test/flutter_test.dart';
import 'package:word_quest/features/backup/application/backup_package_codec.dart';
import 'package:word_quest/features/backup/domain/backup_package.dart';
import 'package:word_quest/features/child_profile/domain/child_profile.dart';
import 'package:word_quest/features/word_book/domain/word_book.dart';
import 'package:word_quest/features/word_book/domain/word_entry.dart';

void main() {
  group('BackupPackageCodec', () {
    test('将备份包编码为 JSON 后可以完整解码', () {
      const codec = BackupPackageCodec();

      final package = BackupPackage(
        schemaVersion: 1,
        exportedAt: DateTime(2026, 5, 2, 9, 30),
        children: [
          ChildProfile(
            id: 'child-a',
            name: '哥哥',
            gradeLabel: '初中词表',
            avatarSeed: '哥哥',
            createdAt: DateTime(2026, 5, 1),
          ),
        ],
        wordBooks: [
          const WordBook(
            id: 'book-a',
            name: '自定义词表',
            stageLabel: '自定义',
            words: [
              WordEntry(
                id: 'word-a',
                spelling: 'apple',
                meanings: ['苹果'],
                phonetic: '/ˈæpəl/',
                partOfSpeech: 'n.',
                example: 'I eat an apple.',
                tags: ['水果'],
                source: '手动导入',
              ),
            ],
          ),
        ],
      );

      final jsonText = codec.encode(package);
      final decoded = codec.decode(jsonText);

      expect(decoded.schemaVersion, 1);
      expect(decoded.exportedAt, DateTime(2026, 5, 2, 9, 30));
      expect(decoded.children.single.name, '哥哥');
      expect(decoded.wordBooks.single.words.single.spelling, 'apple');
      expect(decoded.wordBooks.single.words.single.tags, ['水果']);
    });

    test('拒绝不支持的备份版本', () {
      const codec = BackupPackageCodec();

      expect(
        () => codec.decode('{"schemaVersion":99,"children":[],"wordBooks":[]}'),
        throwsA(
          isA<BackupPackageFormatException>().having(
            (error) => error.message,
            'message',
            '不支持的备份版本：99',
          ),
        ),
      );
    });
  });
}
