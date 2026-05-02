import 'package:flutter_test/flutter_test.dart';
import 'package:word_quest/features/home/application/in_memory_home_dashboard_repository.dart';

void main() {
  test('内存首页仓库提供两个孩子的看板数据', () {
    const repository = InMemoryHomeDashboardRepository();

    final dashboard = repository.loadDashboard(
      referenceDate: DateTime(2026, 5, 2),
    );

    expect(dashboard.children, hasLength(2));
    expect(dashboard.children.first.name, '安安');
    expect(dashboard.children.first.taskSummary, '新词 8 个 · 复习 6 个 · 错词 4 个');
    expect(dashboard.children.first.accuracyLabel, '91%');
    expect(dashboard.children.first.streakLabel, '连续 6 天');
    expect(dashboard.children.last.name, '宁宁');
    expect(dashboard.children.last.accuracyLabel, '92%');
    expect(dashboard.bookHighlights, hasLength(3));
    expect(dashboard.bookHighlights.first.label, '小学高年级基础词表');
    expect(dashboard.todayHighlights, hasLength(3));
    expect(dashboard.parentHighlights, hasLength(3));
  });
}
