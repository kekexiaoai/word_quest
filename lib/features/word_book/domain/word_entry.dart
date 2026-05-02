class WordEntry {
  const WordEntry({
    required this.id,
    required this.spelling,
    required this.meanings,
    this.phonetic,
    this.partOfSpeech,
    this.example,
    this.tags = const [],
    this.source,
  });

  final String id;
  final String spelling;
  final List<String> meanings;
  final String? phonetic;
  final String? partOfSpeech;
  final String? example;
  final List<String> tags;
  final String? source;
}
