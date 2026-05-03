import '../domain/child_profile.dart';
import '../domain/child_profile_repository.dart';

class InMemoryChildProfileRepository implements ChildProfileRepository {
  const InMemoryChildProfileRepository({
    List<ChildProfile>? storage,
  }) : _storage = storage;

  final List<ChildProfile>? _storage;

  @override
  List<ChildProfile> loadChildren() {
    final storage = _storage;
    if (storage != null) {
      return List<ChildProfile>.of(storage);
    }

    return [
      ChildProfile(
        id: 'child-brother',
        name: '安安',
        gradeLabel: '初中词表',
        avatarSeed: '安',
        createdAt: DateTime(2026, 5, 1),
      ),
      ChildProfile(
        id: 'child-sister',
        name: '宁宁',
        gradeLabel: '小学高年级词表',
        avatarSeed: '宁',
        createdAt: DateTime(2026, 5, 1),
      ),
    ];
  }

  @override
  void replaceChildren(List<ChildProfile> children) {
    final storage = _storage;
    if (storage == null) {
      return;
    }
    storage
      ..clear()
      ..addAll(children);
  }
}
