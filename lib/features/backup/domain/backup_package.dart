import '../../child_profile/domain/child_profile.dart';
import '../../adventure/domain/adventure_dashboard_snapshot.dart';
import '../../study/domain/answer_record.dart';
import '../../word_book/domain/word_book.dart';

class BackupPackage {
  const BackupPackage({
    required this.schemaVersion,
    required this.exportedAt,
    required this.children,
    required this.wordBooks,
    this.answerRecords = const [],
    this.adventureSnapshots = const [],
    this.learningWordBookSelections = const {},
  });

  final int schemaVersion;
  final DateTime exportedAt;
  final List<ChildProfile> children;
  final List<WordBook> wordBooks;
  final List<AnswerRecord> answerRecords;
  final List<AdventureDashboardSnapshot> adventureSnapshots;
  final Map<String, String> learningWordBookSelections;
}
