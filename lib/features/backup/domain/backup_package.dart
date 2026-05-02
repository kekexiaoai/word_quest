import '../../child_profile/domain/child_profile.dart';
import '../../word_book/domain/word_book.dart';

class BackupPackage {
  const BackupPackage({
    required this.schemaVersion,
    required this.exportedAt,
    required this.children,
    required this.wordBooks,
  });

  final int schemaVersion;
  final DateTime exportedAt;
  final List<ChildProfile> children;
  final List<WordBook> wordBooks;
}
