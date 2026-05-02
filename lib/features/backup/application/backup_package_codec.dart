import 'dart:convert';

import '../../child_profile/domain/child_profile.dart';
import '../../word_book/domain/word_book.dart';
import '../../word_book/domain/word_entry.dart';
import '../domain/backup_package.dart';

class BackupPackageFormatException implements Exception {
  const BackupPackageFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BackupPackageCodec {
  const BackupPackageCodec();

  static const currentSchemaVersion = 1;

  String encode(BackupPackage package) {
    return jsonEncode(_packageToJson(package));
  }

  BackupPackage decode(String jsonText) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(jsonText);
    } on FormatException catch (error) {
      throw BackupPackageFormatException('备份 JSON 格式错误：${error.message}');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const BackupPackageFormatException('备份 JSON 根节点必须是对象');
    }

    final schemaVersion = _requiredInt(decoded, 'schemaVersion');
    if (schemaVersion != currentSchemaVersion) {
      throw BackupPackageFormatException('不支持的备份版本：$schemaVersion');
    }

    return BackupPackage(
      schemaVersion: schemaVersion,
      exportedAt: _optionalDateTime(decoded, 'exportedAt') ?? DateTime(1970),
      children: [
        for (final item in _requiredList(decoded, 'children'))
          _childFromJson(_asMap(item, 'children')),
      ],
      wordBooks: [
        for (final item in _requiredList(decoded, 'wordBooks'))
          _wordBookFromJson(_asMap(item, 'wordBooks')),
      ],
    );
  }

  Map<String, Object?> _packageToJson(BackupPackage package) {
    return {
      'schemaVersion': package.schemaVersion,
      'exportedAt': package.exportedAt.toIso8601String(),
      'children': [
        for (final child in package.children) _childToJson(child),
      ],
      'wordBooks': [
        for (final wordBook in package.wordBooks) _wordBookToJson(wordBook),
      ],
    };
  }

  Map<String, Object?> _childToJson(ChildProfile child) {
    return {
      'id': child.id,
      'name': child.name,
      'gradeLabel': child.gradeLabel,
      'avatarSeed': child.avatarSeed,
      'createdAt': child.createdAt.toIso8601String(),
    };
  }

  ChildProfile _childFromJson(Map<String, dynamic> json) {
    return ChildProfile(
      id: _requiredString(json, 'id'),
      name: _requiredString(json, 'name'),
      gradeLabel: _requiredString(json, 'gradeLabel'),
      avatarSeed: _requiredString(json, 'avatarSeed'),
      createdAt: _requiredDateTime(json, 'createdAt'),
    );
  }

  Map<String, Object?> _wordBookToJson(WordBook wordBook) {
    return {
      'id': wordBook.id,
      'name': wordBook.name,
      'stageLabel': wordBook.stageLabel,
      'description': wordBook.description,
      'isBuiltIn': wordBook.isBuiltIn,
      'words': [
        for (final word in wordBook.words) _wordToJson(word),
      ],
    };
  }

  WordBook _wordBookFromJson(Map<String, dynamic> json) {
    return WordBook(
      id: _requiredString(json, 'id'),
      name: _requiredString(json, 'name'),
      stageLabel: _requiredString(json, 'stageLabel'),
      description: _optionalString(json, 'description'),
      isBuiltIn: _optionalBool(json, 'isBuiltIn') ?? false,
      words: [
        for (final item in _requiredList(json, 'words'))
          _wordFromJson(_asMap(item, 'words')),
      ],
    );
  }

  Map<String, Object?> _wordToJson(WordEntry word) {
    return {
      'id': word.id,
      'spelling': word.spelling,
      'meanings': word.meanings,
      'phonetic': word.phonetic,
      'partOfSpeech': word.partOfSpeech,
      'example': word.example,
      'tags': word.tags,
      'source': word.source,
    };
  }

  WordEntry _wordFromJson(Map<String, dynamic> json) {
    return WordEntry(
      id: _requiredString(json, 'id'),
      spelling: _requiredString(json, 'spelling'),
      meanings: _requiredStringList(json, 'meanings'),
      phonetic: _optionalString(json, 'phonetic'),
      partOfSpeech: _optionalString(json, 'partOfSpeech'),
      example: _optionalString(json, 'example'),
      tags: _optionalStringList(json, 'tags'),
      source: _optionalString(json, 'source'),
    );
  }

  String _requiredString(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    throw BackupPackageFormatException('字段 $field 必须是非空字符串');
  }

  String? _optionalString(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value == null) {
      return null;
    }
    if (value is String) {
      return value;
    }
    throw BackupPackageFormatException('字段 $field 必须是字符串');
  }

  int _requiredInt(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is int) {
      return value;
    }
    throw BackupPackageFormatException('字段 $field 必须是整数');
  }

  bool? _optionalBool(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value == null) {
      return null;
    }
    if (value is bool) {
      return value;
    }
    throw BackupPackageFormatException('字段 $field 必须是布尔值');
  }

  DateTime _requiredDateTime(Map<String, dynamic> json, String field) {
    final value = _requiredString(json, field);
    return _parseDateTime(value, field);
  }

  DateTime? _optionalDateTime(Map<String, dynamic> json, String field) {
    final value = _optionalString(json, field);
    return value == null ? null : _parseDateTime(value, field);
  }

  DateTime _parseDateTime(String value, String field) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw BackupPackageFormatException('字段 $field 必须是有效日期');
    }
    return parsed;
  }

  List<dynamic> _requiredList(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is List) {
      return value;
    }
    throw BackupPackageFormatException('字段 $field 必须是列表');
  }

  List<String> _requiredStringList(Map<String, dynamic> json, String field) {
    final value = _requiredList(json, field);
    return [
      for (final item in value)
        if (item is String)
          item
        else
          throw BackupPackageFormatException('字段 $field 必须是字符串列表'),
    ];
  }

  List<String> _optionalStringList(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value == null) {
      return const [];
    }
    if (value is! List) {
      throw BackupPackageFormatException('字段 $field 必须是列表');
    }
    return [
      for (final item in value)
        if (item is String)
          item
        else
          throw BackupPackageFormatException('字段 $field 必须是字符串列表'),
    ];
  }

  Map<String, dynamic> _asMap(dynamic value, String field) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    throw BackupPackageFormatException('字段 $field 的元素必须是对象');
  }
}
