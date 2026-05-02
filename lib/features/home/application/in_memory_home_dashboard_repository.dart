import '../domain/home_dashboard_repository.dart';
import '../domain/home_dashboard_snapshot.dart';
import 'home_dashboard_builder.dart';
import 'home_dashboard_demo.dart';

class InMemoryHomeDashboardRepository implements HomeDashboardRepository {
  const InMemoryHomeDashboardRepository();

  @override
  HomeDashboardSnapshot loadDashboard({required DateTime referenceDate}) {
    const builder = HomeDashboardBuilder();
    return HomeDashboardSnapshot(
      children: HomeDashboardDemo.buildChildSnapshots(
        builder: builder,
        referenceDate: referenceDate,
      ),
      todayHighlights: const [
        DashboardSectionLine(label: '基础题型', value: '英选中 / 中选英 / 拼写'),
        DashboardSectionLine(label: '听音训练', value: '听音选词 / 听音拼写'),
        DashboardSectionLine(label: '复习策略', value: '答错缩短间隔，答对延后复习'),
      ],
      parentHighlights: const [
        DashboardSectionLine(label: '词表', value: '内置词表 + CSV 导入'),
        DashboardSectionLine(label: '看板', value: '完成情况 / 正确率 / 高频错词'),
        DashboardSectionLine(label: '数据', value: '本地保存，支持备份导入导出'),
      ],
    );
  }
}
