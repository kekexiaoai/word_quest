import '../../adventure/application/local_adventure_repository.dart';
import '../../child_profile/domain/child_profile.dart';
import '../../child_profile/domain/child_profile_repository.dart';
import '../../study/domain/answer_record_repository.dart';
import '../../study/domain/word_learning_progress_repository.dart';
import '../../word_book/application/local_learning_word_book_selection_repository.dart';
import '../../word_book/domain/word_book_repository.dart';
import '../domain/backup_package.dart';
import 'backup_package_codec.dart';

class LocalDataBackupService {
  const LocalDataBackupService({
    required this.wordBookRepository,
    required this.answerRecordRepository,
    this.wordLearningProgressRepository,
    this.adventureRepository,
    this.learningWordBookSelectionRepository,
    this.childProfileRepository,
    this.children = const [],
    this.codec = const BackupPackageCodec(),
  });

  final WordBookRepository wordBookRepository;
  final AnswerRecordRepository answerRecordRepository;
  final WordLearningProgressRepository? wordLearningProgressRepository;
  final LocalAdventureRepository? adventureRepository;
  final LocalLearningWordBookSelectionRepository?
      learningWordBookSelectionRepository;
  final ChildProfileRepository? childProfileRepository;
  final List<ChildProfile> children;
  final BackupPackageCodec codec;

  String exportBackup({DateTime? exportedAt}) {
    return codec.encode(
      BackupPackage(
        schemaVersion: BackupPackageCodec.currentSchemaVersion,
        exportedAt: exportedAt ?? DateTime.now(),
        children: childProfileRepository?.loadChildren() ?? children,
        wordBooks: wordBookRepository.loadImportedWordBooks(),
        answerRecords: answerRecordRepository.loadAllRecords(),
        wordLearningProgresses:
            wordLearningProgressRepository?.loadAllProgresses() ?? const [],
        adventureSnapshots:
            adventureRepository?.loadSavedAdventures() ?? const [],
        learningWordBookSelections:
            learningWordBookSelectionRepository?.loadSelections() ?? const {},
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
    wordLearningProgressRepository?.replaceProgresses(
      backupPackage.wordLearningProgresses,
    );
    adventureRepository?.replaceSavedAdventures(
      backupPackage.adventureSnapshots,
    );
    learningWordBookSelectionRepository?.replaceSelections(
      backupPackage.learningWordBookSelections,
    );
    childProfileRepository?.replaceChildren(backupPackage.children);
  }

  void clearLearningRecords() {
    answerRecordRepository.clearRecords();
    wordLearningProgressRepository?.replaceProgresses(const []);
  }
}
