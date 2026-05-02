import 'package:flutter_test/flutter_test.dart';
import 'package:word_quest/features/home/application/in_memory_home_dashboard_repository.dart';

void main() {
  test('内存首页仓库提供两个孩子的看板数据', () {
    const repository = InMemoryHomeDashboardRepository();

    final dashboard = repository.loadDashboard(
      referenceDate: DateTime(2026, 5, 2),
    );

    expect(dashboard.children, hasLength(2));
    expect(dashboard.children.first.name, '哥哥');
    expect(dashboard.children.first.taskSummary, '新词 12 个 · 复习 24 个 · 错词 6 个');
    expect(dashboard.children.first.accuracyLabel, '86%');
    expect(dashboard.children.first.streakLabel, '连续 5 天');
    expect(dashboard.children.last.name, '妹妹');
    expect(dashboard.children.last.accuracyLabel, '92%');
    expect(dashboard.todayHighlights, hasLength(3));
    expect(dashboard.parentHighlights, hasLength(3));
  });
}
