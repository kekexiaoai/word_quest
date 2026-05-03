import 'dart:convert';

import '../../../core/local_storage/local_key_value_store.dart';
import '../domain/child_profile.dart';
import '../domain/child_profile_repository.dart';

class LocalChildProfileRepository implements ChildProfileRepository {
  LocalChildProfileRepository({
    LocalKeyValueStore? store,
  }) : _store = store ?? createDefaultLocalKeyValueStore();

  static const _storageKey = 'child_profiles';

  final LocalKeyValueStore _store;

  @override
  List<ChildProfile> loadChildren() {
    final rawValue = _store.read(_storageKey);
    if (rawValue == null || rawValue.trim().isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(rawValue);
    if (decoded is! List) {
      return const [];
    }

    return [
      for (final item in decoded)
        if (item is Map<String, dynamic>) _childFromJson(item),
    ];
  }

  @override
  void replaceChildren(List<ChildProfile> children) {
    _store.write(
      _storageKey,
      jsonEncode([
        for (final child in children) _childToJson(child),
      ]),
    );
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
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      gradeLabel: json['gradeLabel'] as String? ?? '',
      avatarSeed: json['avatarSeed'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
