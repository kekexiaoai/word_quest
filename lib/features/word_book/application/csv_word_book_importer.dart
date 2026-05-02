import '../domain/word_book.dart';
import '../domain/word_entry.dart';

class WordBookImportResult {
  const WordBookImportResult._({
    required this.wordBook,
    required this.errors,
  });

  factory WordBookImportResult.success(WordBook wordBook) {
    return WordBookImportResult._(
      wordBook: wordBook,
      errors: const [],
    );
  }

  factory WordBookImportResult.failure(List<String> errors) {
    return WordBookImportResult._(
      wordBook: null,
      errors: errors,
    );
  }

  final WordBook? wordBook;
  final List<String> errors;

  bool get isSuccess => errors.isEmpty && wordBook != null;
}

class CsvWordBookImporter {
  const CsvWordBookImporter();

  WordBookImportResult import({
    required String id,
    required String name,
    required String stageLabel,
    required String csvText,
  }) {
    final rows = _parseRows(csvText);
    if (rows.isEmpty) {
      return WordBookImportResult.failure(['CSV 内容为空']);
    }

    final header = _Header.from(rows.first);
    final dataRows = header.hasHeader ? rows.skip(1).toList() : rows;
    final errors = <String>[];
    final words = <WordEntry>[];

    for (var index = 0; index < dataRows.length; index++) {
      final row = dataRows[index];
      final lineNumber = index + (header.hasHeader ? 2 : 1);
      if (_isEmptyRow(row)) {
        continue;
      }

      final spelling = header.value(row, _Column.spelling).trim();
      final meaningText = header.value(row, _Column.meaning).trim();

      if (spelling.isEmpty) {
        errors.add('第 $lineNumber 行缺少单词');
      }
      if (meaningText.isEmpty) {
        errors.add('第 $lineNumber 行缺少中文释义');
      }
      if (spelling.isEmpty || meaningText.isEmpty) {
        continue;
      }

      words.add(
        WordEntry(
          id: '$id-${words.length + 1}',
          spelling: spelling,
          meanings: _splitMeanings(meaningText),
          phonetic: _nullIfBlank(header.value(row, _Column.phonetic)),
          partOfSpeech: _nullIfBlank(header.value(row, _Column.partOfSpeech)),
          example: _nullIfBlank(header.value(row, _Column.example)),
          tags: _splitTags(header.value(row, _Column.tags)),
          source: _nullIfBlank(header.value(row, _Column.source)),
        ),
      );
    }

    if (errors.isNotEmpty) {
      return WordBookImportResult.failure(errors);
    }
    if (words.isEmpty) {
      return WordBookImportResult.failure(['CSV 未包含有效单词']);
    }

    return WordBookImportResult.success(
      WordBook(
        id: id,
        name: name,
        stageLabel: stageLabel,
        words: words,
      ),
    );
  }

  List<List<String>> _parseRows(String csvText) {
    final rows = <List<String>>[];
    var row = <String>[];
    final cell = StringBuffer();
    var inQuotes = false;

    for (var index = 0; index < csvText.length; index++) {
      final char = csvText[index];
      final nextChar = index + 1 < csvText.length ? csvText[index + 1] : null;

      if (char == '"') {
        if (inQuotes && nextChar == '"') {
          cell.write('"');
          index += 1;
        } else {
          inQuotes = !inQuotes;
        }
        continue;
      }

      if (char == ',' && !inQuotes) {
        row.add(cell.toString().trim());
        cell.clear();
        continue;
      }

      if ((char == '\n' || char == '\r') && !inQuotes) {
        if (char == '\r' && nextChar == '\n') {
          index += 1;
        }
        row.add(cell.toString().trim());
        cell.clear();
        if (!_isEmptyRow(row)) {
          rows.add(row);
        }
        row = <String>[];
        continue;
      }

      cell.write(char);
    }

    row.add(cell.toString().trim());
    if (!_isEmptyRow(row)) {
      rows.add(row);
    }

    return rows;
  }

  bool _isEmptyRow(List<String> row) {
    return row.every((cell) => cell.trim().isEmpty);
  }

  List<String> _splitMeanings(String value) {
    return value
        .split(RegExp(r'[,，;；|]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  List<String> _splitTags(String value) {
    return value
        .split(RegExp(r'[|;；,，]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  String? _nullIfBlank(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

enum _Column {
  spelling,
  meaning,
  phonetic,
  partOfSpeech,
  example,
  tags,
  source,
}

class _Header {
  const _Header({
    required this.hasHeader,
    required this.indexes,
  });

  factory _Header.from(List<String> firstRow) {
    final normalized = [
      for (final cell in firstRow) _normalizeHeader(cell),
    ];
    final hasHeader = normalized.any(_knownHeaderNames.contains);

    if (!hasHeader) {
      return const _Header(
        hasHeader: false,
        indexes: {
          _Column.spelling: 0,
          _Column.meaning: 1,
          _Column.phonetic: 2,
          _Column.partOfSpeech: 3,
          _Column.example: 4,
          _Column.tags: 5,
          _Column.source: 6,
        },
      );
    }

    return _Header(
      hasHeader: true,
      indexes: {
        for (var index = 0; index < normalized.length; index++)
          if (_columnByHeaderName[normalized[index]] case final column?)
            column: index,
      },
    );
  }

  final bool hasHeader;
  final Map<_Column, int> indexes;

  String value(List<String> row, _Column column) {
    final index = indexes[column];
    if (index == null || index >= row.length) {
      return '';
    }
    return row[index];
  }
}

const _knownHeaderNames = {
  ..._spellingHeaders,
  ..._meaningHeaders,
  ..._phoneticHeaders,
  ..._partOfSpeechHeaders,
  ..._exampleHeaders,
  ..._tagsHeaders,
  ..._sourceHeaders,
};

const _spellingHeaders = {'word', 'spelling', '单词', '英文'};
const _meaningHeaders = {'meaning', 'meanings', '中文', '中文释义', '释义'};
const _phoneticHeaders = {'phonetic', '音标'};
const _partOfSpeechHeaders = {'partofspeech', 'pos', '词性'};
const _exampleHeaders = {'example', '例句'};
const _tagsHeaders = {'tag', 'tags', '标签'};
const _sourceHeaders = {'source', '来源'};

const _columnByHeaderName = {
  'word': _Column.spelling,
  'spelling': _Column.spelling,
  '单词': _Column.spelling,
  '英文': _Column.spelling,
  'meaning': _Column.meaning,
  'meanings': _Column.meaning,
  '中文': _Column.meaning,
  '中文释义': _Column.meaning,
  '释义': _Column.meaning,
  'phonetic': _Column.phonetic,
  '音标': _Column.phonetic,
  'partofspeech': _Column.partOfSpeech,
  'pos': _Column.partOfSpeech,
  '词性': _Column.partOfSpeech,
  'example': _Column.example,
  '例句': _Column.example,
  'tag': _Column.tags,
  'tags': _Column.tags,
  '标签': _Column.tags,
  'source': _Column.source,
  '来源': _Column.source,
};

String _normalizeHeader(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]+'), '');
}
