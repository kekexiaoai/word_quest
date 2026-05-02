import 'package:flutter_test/flutter_test.dart';
import 'package:word_quest/features/adventure/domain/adventure_dashboard_snapshot.dart';
import 'package:word_quest/features/adventure/domain/adventure_level.dart';
import 'package:word_quest/features/adventure/domain/pet_profile.dart';
import 'package:word_quest/features/backup/application/backup_package_codec.dart';
import 'package:word_quest/features/backup/domain/backup_package.dart';
import 'package:word_quest/features/child_profile/domain/child_profile.dart';
import 'package:word_quest/features/study/domain/answer_record.dart';
import 'package:word_quest/features/study/domain/study_task.dart';
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
        answerRecords: [
          AnswerRecord(
            childId: 'child-a',
            wordId: 'word-a',
            practiceMode: PracticeMode.listeningChoice,
            isCorrect: false,
            answeredAt: DateTime(2026, 5, 2, 9, 35),
            elapsedMilliseconds: 1400,
            weaknessType: AnswerWeaknessType.listening,
          ),
        ],
        adventureSnapshots: [
          AdventureDashboardSnapshot(
            childId: 'child-a',
            themeTitle: '森林冒险',
            currentNodeTitle: '森林书屋',
            starsEarned: 3,
            starsTarget: 3,
            chestProgress: 0.9,
            levels: [
              AdventureLevel(
                id: 'level-a',
                childId: 'child-a',
                date: DateTime(2026, 5, 2),
                type: AdventureLevelType.mistakeBoss,
                title: '错词 Boss 关',
                subtitle: '4 题',
                status: AdventureLevelStatus.current,
                questionCount: 4,
                reward: const AdventureReward(
                  stars: 1,
                  foodName: '高级食物',
                  foodCount: 1,
                ),
              ),
            ],
            pet: PetProfile(
              childId: 'child-a',
              petId: 'sprout-fox',
              name: '豆豆',
              level: 3,
              growthPoints: 6,
              growthTarget: 90,
              satiety: 88,
              mood: PetMood.happy,
              equippedDecorationIds: const ['scarf'],
              unlockedDecorationIds: const ['scarf'],
              lastFedAt: DateTime(2026, 5, 2, 20),
            ),
          ),
        ],
        learningWordBookSelections: const {
          'child-a': 'book-a',
        },
      );

      final jsonText = codec.encode(package);
      final decoded = codec.decode(jsonText);

      expect(decoded.schemaVersion, 1);
      expect(decoded.exportedAt, DateTime(2026, 5, 2, 9, 30));
      expect(decoded.children.single.name, '哥哥');
      expect(decoded.wordBooks.single.words.single.spelling, 'apple');
      expect(decoded.wordBooks.single.words.single.tags, ['水果']);
      expect(decoded.answerRecords.single.wordId, 'word-a');
      expect(decoded.answerRecords.single.weaknessType,
          AnswerWeaknessType.listening);
      expect(decoded.adventureSnapshots.single.currentLevel.title, '错词 Boss 关');
      expect(decoded.adventureSnapshots.single.pet.level, 3);
      expect(decoded.learningWordBookSelections['child-a'], 'book-a');
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
