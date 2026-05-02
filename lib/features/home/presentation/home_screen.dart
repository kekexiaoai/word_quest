import 'package:flutter/material.dart';

import '../application/in_memory_home_dashboard_repository.dart';
import '../domain/home_dashboard_repository.dart';
import '../domain/home_dashboard_snapshot.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.dashboardRepository = const InMemoryHomeDashboardRepository(),
  });

  final HomeDashboardRepository dashboardRepository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeDashboardSnapshot _dashboard;
  int _selectedChildIndex = 0;

  @override
  void initState() {
    super.initState();
    _dashboard = widget.dashboardRepository.loadDashboard(
      referenceDate: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentChild = _dashboard.children[_selectedChildIndex];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const _Header(),
            const SizedBox(height: 20),
            _ChildTabs(
              children: _dashboard.children,
              selectedIndex: _selectedChildIndex,
              onChanged: (index) {
                setState(() {
                  _selectedChildIndex = index;
                });
              },
            ),
            const SizedBox(height: 16),
            _ChildSummaryCard(child: currentChild),
            const SizedBox(height: 20),
            _SectionPanel(
              title: '内置词表',
              rows: _dashboard.bookHighlights,
            ),
            const SizedBox(height: 20),
            const _SectionPanel(
              title: '今日学习主线',
              rows: [
                DashboardSectionLine(
                  label: '基础题型',
                  value: '英选中 / 中选英 / 拼写',
                ),
                DashboardSectionLine(
                  label: '听音训练',
                  value: '听音选词 / 听音拼写',
                ),
                DashboardSectionLine(
                  label: '复习策略',
                  value: '答错缩短间隔，答对延后复习',
                ),
              ],
            ),
            const SizedBox(height: 20),
            const _SectionPanel(
              title: '家长管理',
              rows: [
                DashboardSectionLine(label: '词表', value: '内置词表 + CSV 导入'),
                DashboardSectionLine(label: '看板', value: '完成情况 / 正确率 / 高频错词'),
                DashboardSectionLine(label: '数据', value: '本地保存，支持备份导入导出'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Word Quest',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF26352F),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '每日任务推进闯关进度，两个孩子独立学习，家长轻量掌握状态。',
          style: textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF66736D),
          ),
        ),
      ],
    );
  }
}

class _ChildTabs extends StatelessWidget {
  const _ChildTabs({
    required this.children,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<ChildDashboardSnapshot> children;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      segments: [
        for (var index = 0; index < children.length; index++)
          ButtonSegment<int>(
            value: index,
            label: Text(children[index].name),
          ),
      ],
      selected: {selectedIndex},
      onSelectionChanged: (selection) => onChanged(selection.first),
      showSelectedIcon: false,
    );
  }
}

class _ChildSummaryCard extends StatelessWidget {
  const _ChildSummaryCard({
    required this.child,
  });

  final ChildDashboardSnapshot child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(child.name.characters.first),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        child.name,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(child.gradeLabel),
                    ],
                  ),
                ),
                Text(
                  child.accuracyLabel,
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(child.taskSummary),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(value: child.progress),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: Text(child.streakLabel)),
                Text(
                  '${(child.progress * 100).round()}%',
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (child.weaknessHighlights.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '薄弱点：${child.weaknessHighlights.join(' · ')}',
                style: textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF66736D),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('开始今日任务'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('查看错词'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionPanel extends StatelessWidget {
  const _SectionPanel({
    required this.title,
    required this.rows,
  });

  final String title;
  final List<DashboardSectionLine> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            for (final row in rows) ...[
              _InfoRow(label: row.label, value: row.value),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF66736D),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }
}
