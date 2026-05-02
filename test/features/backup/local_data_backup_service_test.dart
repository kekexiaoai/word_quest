import 'package:flutter_test/flutter_test.dart';
import 'package:word_quest/core/local_storage/local_key_value_store.dart';
import 'package:word_quest/features/adventure/application/adventure_session_controller.dart';
import 'package:word_quest/features/adventure/application/local_adventure_repository.dart';
import 'package:word_quest/features/backup/application/local_data_backup_service.dart';
import 'package:word_quest/features/study/application/local_answer_record_repository.dart';
import 'package:word_quest/features/study/domain/answer_record.dart';
import 'package:word_quest/features/study/domain/study_task.dart';
import 'package:word_quest/features/word_book/application/local_word_book_repository.dart';
import 'package:word_quest/features/word_book/domain/word_book.dart';
import 'package:word_quest/features/word_book/domain/word_entry.dart';

void main() {
  test('本地数据备份服务可以导出导入词表和学习记录', () {
    final store = MemoryLocalKeyValueStore();
    final wordBookRepository = LocalWordBookRepository(store: store);
    final answerRecordRepository = LocalAnswerRecordRepository(store: store);
    final adventureRepository = LocalAdventureRepository(store: store);
    final service = LocalDataBackupService(
      wordBookRepository: wordBookRepository,
      answerRecordRepository: answerRecordRepository,
      adventureRepository: adventureRepository,
    );

    wordBookRepository.saveImportedWordBook(
      const WordBook(
        id: 'csv-import-1',
        name: '海洋主题词表',
        stageLabel: '自定义',
        words: [
          WordEntry(id: 'csv-import-1-1', spelling: 'ocean', meanings: ['海洋']),
        ],
      ),
    );
    answerRecordRepository.addRecord(AnswerRecord(
      childId: 'child-brother',
      wordId: 'csv-import-1-1',
      practiceMode: PracticeMode.listeningChoice,
      isCorrect: false,
      answeredAt: DateTime(2026, 5, 2, 20),
      elapsedMilliseconds: 1200,
      weaknessType: AnswerWeaknessType.listening,
    ));
    const controller = AdventureSessionController();
    final adventure = adventureRepository.loadAdventure(
      childId: 'child-brother',
      referenceDate: DateTime(2026, 5, 2),
    );
    adventureRepository.saveAdventure(
      controller.feedPetWithTodayRewards(
        controller.completeCurrentLevel(adventure),
        fedAt: DateTime(2026, 5, 2, 20),
      ),
    );

    final backupJson = service.exportBackup(
      exportedAt: DateTime(2026, 5, 2, 21),
    );
    final targetStore = MemoryLocalKeyValueStore();
    final targetWordBookRepository =
        LocalWordBookRepository(store: targetStore);
    final targetAnswerRecordRepository =
        LocalAnswerRecordRepository(store: targetStore);
    final targetAdventureRepository =
        LocalAdventureRepository(store: targetStore);
    final targetService = LocalDataBackupService(
      wordBookRepository: targetWordBookRepository,
      answerRecordRepository: targetAnswerRecordRepository,
      adventureRepository: targetAdventureRepository,
    );

    targetService.importBackup(backupJson);

    final importedWordBooks = targetWordBookRepository
        .loadWordBooks()
        .where((wordBook) => !wordBook.isBuiltIn)
        .toList();
    expect(importedWordBooks.single.name, '海洋主题词表');
    expect(targetAnswerRecordRepository.loadRecords(childId: 'child-brother'),
        hasLength(1));
    final restoredAdventure = targetAdventureRepository.loadAdventure(
      childId: 'child-brother',
      referenceDate: DateTime(2026, 5, 2),
    );
    expect(restoredAdventure.currentLevel.title, '错词 Boss 关');
    expect(restoredAdventure.pet.level, 3);
  });

  test('本地数据备份服务可以清空学习记录但保留词表', () {
    final store = MemoryLocalKeyValueStore();
    final wordBookRepository = LocalWordBookRepository(store: store);
    final answerRecordRepository = LocalAnswerRecordRepository(store: store);
    final service = LocalDataBackupService(
      wordBookRepository: wordBookRepository,
      answerRecordRepository: answerRecordRepository,
    );

    wordBookRepository.saveImportedWordBook(
      const WordBook(
        id: 'csv-import-1',
        name: '海洋主题词表',
        stageLabel: '自定义',
        words: [
          WordEntry(id: 'csv-import-1-1', spelling: 'ocean', meanings: ['海洋']),
        ],
      ),
    );
    answerRecordRepository.addRecord(AnswerRecord(
      childId: 'child-brother',
      wordId: 'csv-import-1-1',
      practiceMode: PracticeMode.englishToChinese,
      isCorrect: true,
      answeredAt: DateTime(2026, 5, 2, 20),
      elapsedMilliseconds: 900,
    ));

    service.clearLearningRecords();

    expect(
        answerRecordRepository.loadRecords(childId: 'child-brother'), isEmpty);
    expect(wordBookRepository.loadWordBooks().where((book) => !book.isBuiltIn),
        isNotEmpty);
  });
}
