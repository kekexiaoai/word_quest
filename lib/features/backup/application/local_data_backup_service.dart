import '../../child_profile/domain/child_profile.dart';
import '../../study/domain/answer_record_repository.dart';
import '../../word_book/domain/word_book_repository.dart';
import '../domain/backup_package.dart';
import 'backup_package_codec.dart';

class LocalDataBackupService {
  const LocalDataBackupService({
    required this.wordBookRepository,
    required this.answerRecordRepository,
    this.children = const [],
    this.codec = const BackupPackageCodec(),
  });

  final WordBookRepository wordBookRepository;
  final AnswerRecordRepository answerRecordRepository;
  final List<ChildProfile> children;
  final BackupPackageCodec codec;

  String exportBackup({DateTime? exportedAt}) {
    return codec.encode(
      BackupPackage(
        schemaVersion: BackupPackageCodec.currentSchemaVersion,
        exportedAt: exportedAt ?? DateTime.now(),
        children: children,
        wordBooks: wordBookRepository.loadImportedWordBooks(),
        answerRecords: answerRecordRepository.loadAllRecords(),
      ),
    );
  }

  void importBackup(String jsonText) {
    final backupPackage = codec.decode(jsonText);
    wordBookRepository.replaceImportedWordBooks(
      [
        for (final wordBook in backupPackage.wordBooks)
          if (!wordBook.isBuiltIn) wordBook,
      ],
    );
    answerRecordRepository.replaceRecords(backupPackage.answerRecords);
  }

  void clearLearningRecords() {
    answerRecordRepository.clearRecords();
  }
}
