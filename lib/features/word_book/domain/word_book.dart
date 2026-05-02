import 'word_entry.dart';

class WordBook {
  const WordBook({
    required this.id,
    required this.name,
    required this.stageLabel,
    required this.words,
    this.description,
    this.isBuiltIn = false,
  });

  final String id;
  final String name;
  final String stageLabel;
  final List<WordEntry> words;
  final String? description;
  final bool isBuiltIn;
}
