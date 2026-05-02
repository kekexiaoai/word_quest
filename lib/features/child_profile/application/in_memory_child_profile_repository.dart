import '../domain/child_profile.dart';
import '../domain/child_profile_repository.dart';

class InMemoryChildProfileRepository implements ChildProfileRepository {
  const InMemoryChildProfileRepository();

  @override
  List<ChildProfile> loadChildren() {
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
}
