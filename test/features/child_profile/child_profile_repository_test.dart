import 'package:flutter_test/flutter_test.dart';
import 'package:word_quest/core/local_storage/local_key_value_store.dart';
import 'package:word_quest/features/child_profile/application/in_memory_child_profile_repository.dart';
import 'package:word_quest/features/child_profile/application/local_child_profile_repository.dart';
import 'package:word_quest/features/child_profile/domain/child_profile.dart';

void main() {
  test('内存孩子仓库返回两个孩子档案', () {
    const repository = InMemoryChildProfileRepository();

    final children = repository.loadChildren();

    expect(children, hasLength(2));
    expect(children.first.name, '安安');
    expect(children.first.gradeLabel, '初中词表');
    expect(children.last.name, '宁宁');
  });

  test('本地孩子仓库保存后新实例仍可读取', () {
    final store = MemoryLocalKeyValueStore();
    final firstRepository = LocalChildProfileRepository(store: store);

    firstRepository.replaceChildren([
      ChildProfile(
        id: 'child-local',
        name: '小明',
        gradeLabel: '初中词表',
        avatarSeed: '小',
        createdAt: DateTime(2026, 5, 3),
      ),
    ]);

    final secondRepository = LocalChildProfileRepository(store: store);
    final children = secondRepository.loadChildren();

    expect(children, hasLength(1));
    expect(children.single.id, 'child-local');
    expect(children.single.name, '小明');
    expect(children.single.gradeLabel, '初中词表');
  });
}
