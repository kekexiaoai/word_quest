import 'dart:convert';

import '../../../core/local_storage/local_key_value_store.dart';
import '../domain/adventure_dashboard_snapshot.dart';
import '../domain/adventure_level.dart';
import '../domain/adventure_repository.dart';
import '../domain/pet_profile.dart';
import 'in_memory_adventure_repository.dart';

class LocalAdventureRepository implements AdventureRepository {
  LocalAdventureRepository({
    LocalKeyValueStore? store,
    AdventureRepository fallbackRepository = const InMemoryAdventureRepository(),
  })  : _store = store ?? createDefaultLocalKeyValueStore(),
        _fallbackRepository = fallbackRepository;

  static const _storagePrefix = 'word_quest.adventure_snapshots.v1';

  final LocalKeyValueStore _store;
  final AdventureRepository _fallbackRepository;

  @override
  AdventureDashboardSnapshot loadAdventure({
    required String childId,
    required DateTime referenceDate,
  }) {
    final jsonText = _store.read(_storageKey(
      childId: childId,
      date: _dateOnly(referenceDate),
    ));
    if (jsonText == null || jsonText.trim().isEmpty) {
      return _fallbackRepository.loadAdventure(
        childId: childId,
        referenceDate: referenceDate,
      );
    }

    try {
      final decoded = jsonDecode(jsonText);
      if (decoded is Map<String, dynamic>) {
        return _snapshotFromJson(decoded);
      }
    } on FormatException {
      return _fallbackRepository.loadAdventure(
        childId: childId,
        referenceDate: referenceDate,
      );
    }

    return _fallbackRepository.loadAdventure(
      childId: childId,
      referenceDate: referenceDate,
    );
  }

  @override
  void saveAdventure(AdventureDashboardSnapshot snapshot) {
    final date =
        snapshot.levels.isEmpty ? DateTime.now() : snapshot.levels.first.date;
    _store.write(
      _storageKey(childId: snapshot.childId, date: date),
      jsonEncode(_snapshotToJson(snapshot)),
    );
  }

  String _storageKey({
    required String childId,
    required DateTime date,
  }) {
    final normalizedDate = _dateOnly(date);
    return '$_storagePrefix.$childId.${normalizedDate.year}-'
        '${normalizedDate.month}-${normalizedDate.day}';
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  Map<String, Object?> _snapshotToJson(AdventureDashboardSnapshot snapshot) {
    return {
      'childId': snapshot.childId,
      'themeTitle': snapshot.themeTitle,
      'currentNodeTitle': snapshot.currentNodeTitle,
      'starsEarned': snapshot.starsEarned,
      'starsTarget': snapshot.starsTarget,
      'chestProgress': snapshot.chestProgress,
      'levels': [
        for (final level in snapshot.levels) _levelToJson(level),
      ],
      'pet': _petToJson(snapshot.pet),
    };
  }

  AdventureDashboardSnapshot _snapshotFromJson(Map<String, dynamic> json) {
    return AdventureDashboardSnapshot(
      childId: json['childId'] as String? ?? '',
      themeTitle: json['themeTitle'] as String? ?? '森林冒险',
      currentNodeTitle: json['currentNodeTitle'] as String? ?? '森林书屋',
      starsEarned: json['starsEarned'] as int? ?? 0,
      starsTarget: json['starsTarget'] as int? ?? 3,
      chestProgress: (json['chestProgress'] as num?)?.toDouble() ?? 0,
      levels: [
        if (json['levels'] case final List<dynamic> levels)
          for (final level in levels)
            if (level is Map<String, dynamic>) _levelFromJson(level),
      ],
      pet: _petFromJson(json['pet']),
    );
  }

  Map<String, Object?> _levelToJson(AdventureLevel level) {
    return {
      'id': level.id,
      'childId': level.childId,
      'date': level.date.toIso8601String(),
      'type': level.type.name,
      'title': level.title,
      'subtitle': level.subtitle,
      'status': level.status.name,
      'questionCount': level.questionCount,
      'reward': _rewardToJson(level.reward),
    };
  }

  AdventureLevel _levelFromJson(Map<String, dynamic> json) {
    return AdventureLevel(
      id: json['id'] as String? ?? '',
      childId: json['childId'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      type: _levelTypeFromName(json['type'] as String?),
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      status: _levelStatusFromName(json['status'] as String?),
      questionCount: json['questionCount'] as int? ?? 1,
      reward: _rewardFromJson(json['reward']),
    );
  }

  Map<String, Object?> _rewardToJson(AdventureReward reward) {
    return {
      'stars': reward.stars,
      'foodName': reward.foodName,
      'foodCount': reward.foodCount,
      'energy': reward.energy,
      'growthPoints': reward.growthPoints,
      'chestProgress': reward.chestProgress,
    };
  }

  AdventureReward _rewardFromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      return const AdventureReward();
    }

    return AdventureReward(
      stars: value['stars'] as int? ?? 0,
      foodName: value['foodName'] as String?,
      foodCount: value['foodCount'] as int? ?? 0,
      energy: value['energy'] as int? ?? 0,
      growthPoints: value['growthPoints'] as int? ?? 0,
      chestProgress: value['chestProgress'] as int? ?? 0,
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

  PetProfile _petFromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      return const PetProfile(
        childId: '',
        petId: 'sprout-fox',
        name: '豆豆',
        level: 1,
        growthPoints: 0,
        growthTarget: 60,
        satiety: 50,
        mood: PetMood.waiting,
        equippedDecorationIds: [],
        unlockedDecorationIds: [],
        lastFedAt: null,
      );
    }

    return PetProfile(
      childId: value['childId'] as String? ?? '',
      petId: value['petId'] as String? ?? 'sprout-fox',
      name: value['name'] as String? ?? '豆豆',
      level: value['level'] as int? ?? 1,
      growthPoints: value['growthPoints'] as int? ?? 0,
      growthTarget: value['growthTarget'] as int? ?? 60,
      satiety: value['satiety'] as int? ?? 50,
      mood: _petMoodFromName(value['mood'] as String?),
      equippedDecorationIds: [
        if (value['equippedDecorationIds'] case final List<dynamic> ids)
          for (final id in ids)
            if (id is String) id,
      ],
      unlockedDecorationIds: [
        if (value['unlockedDecorationIds'] case final List<dynamic> ids)
          for (final id in ids)
            if (id is String) id,
      ],
      lastFedAt: DateTime.tryParse(value['lastFedAt'] as String? ?? ''),
    );
  }

  AdventureLevelType _levelTypeFromName(String? name) {
    for (final type in AdventureLevelType.values) {
      if (type.name == name) {
        return type;
      }
    }
    return AdventureLevelType.newWordWarmup;
  }

  AdventureLevelStatus _levelStatusFromName(String? name) {
    for (final status in AdventureLevelStatus.values) {
      if (status.name == name) {
        return status;
      }
    }
    return AdventureLevelStatus.locked;
  }

  PetMood _petMoodFromName(String? name) {
    for (final mood in PetMood.values) {
      if (mood.name == name) {
        return mood;
      }
    }
    return PetMood.waiting;
  }
}
