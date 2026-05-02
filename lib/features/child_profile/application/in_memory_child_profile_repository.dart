import '../domain/child_profile.dart';
import '../domain/child_profile_repository.dart';

class InMemoryChildProfileRepository implements ChildProfileRepository {
  const InMemoryChildProfileRepository();

  @override
  List<ChildProfile> loadChildren() {
    return [
      ChildProfile(
        id: 'child-brother',
        name: '哥哥',
        gradeLabel: '初中词表',
        avatarSeed: '哥哥',
        createdAt: DateTime(2026, 5, 1),
      ),
      ChildProfile(
        id: 'child-sister',
        name: '妹妹',
        gradeLabel: '小学高年级词表',
        avatarSeed: '妹妹',
        createdAt: DateTime(2026, 5, 1),
      ),
    ];
  }
}
