import 'package:flutter_test/flutter_test.dart';
import 'package:word_quest/features/child_profile/application/in_memory_child_profile_repository.dart';

void main() {
  test('内存孩子仓库返回两个孩子档案', () {
    const repository = InMemoryChildProfileRepository();

    final children = repository.loadChildren();

    expect(children, hasLength(2));
    expect(children.first.name, '安安');
    expect(children.first.gradeLabel, '初中词表');
    expect(children.last.name, '宁宁');
  });
}
