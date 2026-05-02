import 'dart:convert';

import '../../adventure/domain/adventure_dashboard_snapshot.dart';
import '../../adventure/domain/adventure_level.dart';
import '../../adventure/domain/pet_profile.dart';
import '../../child_profile/domain/child_profile.dart';
import '../../study/domain/answer_record.dart';
import '../../study/domain/study_task.dart';
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
      answerRecords: [
        for (final item in _optionalList(decoded, 'answerRecords'))
          _answerRecordFromJson(_asMap(item, 'answerRecords')),
      ],
      adventureSnapshots: [
        for (final item in _optionalList(decoded, 'adventureSnapshots'))
          _adventureSnapshotFromJson(_asMap(item, 'adventureSnapshots')),
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
      'answerRecords': [
        for (final record in package.answerRecords) _answerRecordToJson(record),
      ],
      'adventureSnapshots': [
        for (final snapshot in package.adventureSnapshots)
          _adventureSnapshotToJson(snapshot),
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

  Map<String, Object?> _answerRecordToJson(AnswerRecord record) {
    return {
      'childId': record.childId,
      'wordId': record.wordId,
      'practiceMode': record.practiceMode.name,
      'isCorrect': record.isCorrect,
      'answeredAt': record.answeredAt.toIso8601String(),
      'elapsedMilliseconds': record.elapsedMilliseconds,
      'weaknessType': record.weaknessType?.name,
    };
  }

  AnswerRecord _answerRecordFromJson(Map<String, dynamic> json) {
    return AnswerRecord(
      childId: _requiredString(json, 'childId'),
      wordId: _requiredString(json, 'wordId'),
      practiceMode: _practiceModeFromName(
        _requiredString(json, 'practiceMode'),
      ),
      isCorrect: _requiredBool(json, 'isCorrect'),
      answeredAt: _requiredDateTime(json, 'answeredAt'),
      elapsedMilliseconds: _requiredInt(json, 'elapsedMilliseconds'),
      weaknessType:
          _weaknessTypeFromName(_optionalString(json, 'weaknessType')),
    );
  }

  Map<String, Object?> _adventureSnapshotToJson(
    AdventureDashboardSnapshot snapshot,
  ) {
    return {
      'childId': snapshot.childId,
      'themeTitle': snapshot.themeTitle,
      'currentNodeTitle': snapshot.currentNodeTitle,
      'starsEarned': snapshot.starsEarned,
      'starsTarget': snapshot.starsTarget,
      'chestProgress': snapshot.chestProgress,
      'levels': [
        for (final level in snapshot.levels) _adventureLevelToJson(level),
      ],
      'pet': _petToJson(snapshot.pet),
    };
  }

  AdventureDashboardSnapshot _adventureSnapshotFromJson(
    Map<String, dynamic> json,
  ) {
    return AdventureDashboardSnapshot(
      childId: _requiredString(json, 'childId'),
      themeTitle: _requiredString(json, 'themeTitle'),
      currentNodeTitle: _requiredString(json, 'currentNodeTitle'),
      starsEarned: _requiredInt(json, 'starsEarned'),
      starsTarget: _requiredInt(json, 'starsTarget'),
      chestProgress: _requiredDouble(json, 'chestProgress'),
      levels: [
        for (final item in _requiredList(json, 'levels'))
          _adventureLevelFromJson(_asMap(item, 'levels')),
      ],
      pet: _petFromJson(_asMap(json['pet'], 'pet')),
    );
  }

  Map<String, Object?> _adventureLevelToJson(AdventureLevel level) {
    return {
      'id': level.id,
      'childId': level.childId,
      'date': level.date.toIso8601String(),
      'type': level.type.name,
      'title': level.title,
      'subtitle': level.subtitle,
      'status': level.status.name,
      'questionCount': level.questionCount,
      'reward': _adventureRewardToJson(level.reward),
    };
  }

  AdventureLevel _adventureLevelFromJson(Map<String, dynamic> json) {
    return AdventureLevel(
      id: _requiredString(json, 'id'),
      childId: _requiredString(json, 'childId'),
      date: _requiredDateTime(json, 'date'),
      type: _adventureLevelTypeFromName(_requiredString(json, 'type')),
      title: _requiredString(json, 'title'),
      subtitle: _requiredString(json, 'subtitle'),
      status: _adventureLevelStatusFromName(_requiredString(json, 'status')),
      questionCount: _requiredInt(json, 'questionCount'),
      reward: _adventureRewardFromJson(_asMap(json['reward'], 'reward')),
    );
  }

  Map<String, Object?> _adventureRewardToJson(AdventureReward reward) {
    return {
      'stars': reward.stars,
      'foodName': reward.foodName,
      'foodCount': reward.foodCount,
      'energy': reward.energy,
      'growthPoints': reward.growthPoints,
      'chestProgress': reward.chestProgress,
    };
  }

  AdventureReward _adventureRewardFromJson(Map<String, dynamic> json) {
    return AdventureReward(
      stars: _optionalInt(json, 'stars') ?? 0,
      foodName: _optionalString(json, 'foodName'),
      foodCount: _optionalInt(json, 'foodCount') ?? 0,
      energy: _optionalInt(json, 'energy') ?? 0,
      growthPoints: _optionalInt(json, 'growthPoints') ?? 0,
      chestProgress: _optionalInt(json, 'chestProgress') ?? 0,
    );
  }

  Map<String, Object?> _petToJson(PetProfile pet) {
    return {
      'childId': pet.childId,
      'petId': pet.petId,
      'name': pet.name,
      'level': pet.level,
      'growthPoints': pet.growthPoints,
      'growthTarget': pet.growthTarget,
      'satiety': pet.satiety,
      'mood': pet.mood.name,
      'equippedDecorationIds': pet.equippedDecorationIds,
      'unlockedDecorationIds': pet.unlockedDecorationIds,
      'lastFedAt': pet.lastFedAt?.toIso8601String(),
    };
  }

  PetProfile _petFromJson(Map<String, dynamic> json) {
    return PetProfile(
      childId: _requiredString(json, 'childId'),
      petId: _requiredString(json, 'petId'),
      name: _requiredString(json, 'name'),
      level: _requiredInt(json, 'level'),
      growthPoints: _requiredInt(json, 'growthPoints'),
      growthTarget: _requiredInt(json, 'growthTarget'),
      satiety: _requiredInt(json, 'satiety'),
      mood: _petMoodFromName(_requiredString(json, 'mood')),
      equippedDecorationIds: _requiredStringList(json, 'equippedDecorationIds'),
      unlockedDecorationIds: _requiredStringList(json, 'unlockedDecorationIds'),
      lastFedAt: _optionalDateTime(json, 'lastFedAt'),
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

  int? _optionalInt(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    throw BackupPackageFormatException('字段 $field 必须是整数');
  }

  double _requiredDouble(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is num) {
      return value.toDouble();
    }
    throw BackupPackageFormatException('字段 $field 必须是数字');
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

  bool _requiredBool(Map<String, dynamic> json, String field) {
    final value = json[field];
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

  List<dynamic> _optionalList(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value == null) {
      return [];
    }
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

  PracticeMode _practiceModeFromName(String name) {
    for (final mode in PracticeMode.values) {
      if (mode.name == name) {
        return mode;
      }
    }
    throw BackupPackageFormatException('字段 practiceMode 不支持：$name');
  }

  AnswerWeaknessType? _weaknessTypeFromName(String? name) {
    if (name == null) {
      return null;
    }
    for (final weaknessType in AnswerWeaknessType.values) {
      if (weaknessType.name == name) {
        return weaknessType;
      }
    }
    throw BackupPackageFormatException('字段 weaknessType 不支持：$name');
  }

  AdventureLevelType _adventureLevelTypeFromName(String name) {
    for (final type in AdventureLevelType.values) {
      if (type.name == name) {
        return type;
      }
    }
    throw BackupPackageFormatException('未知冒险关卡类型：$name');
  }

  AdventureLevelStatus _adventureLevelStatusFromName(String name) {
    for (final status in AdventureLevelStatus.values) {
      if (status.name == name) {
        return status;
      }
    }
    throw BackupPackageFormatException('未知冒险关卡状态：$name');
  }

  PetMood _petMoodFromName(String name) {
    for (final mood in PetMood.values) {
      if (mood.name == name) {
        return mood;
      }
    }
    throw BackupPackageFormatException('未知宠物状态：$name');
  }
}
