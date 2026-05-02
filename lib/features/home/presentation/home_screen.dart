import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: const [
            _Header(),
            SizedBox(height: 20),
            _ChildProgressCard(
              name: '哥哥',
              grade: '初中词表',
              taskText: '新词 12 个 · 复习 24 个 · 错词 6 个',
              accuracy: '86%',
              streak: '连续 5 天',
              progress: 0.68,
            ),
            SizedBox(height: 12),
            _ChildProgressCard(
              name: '妹妹',
              grade: '小学高年级词表',
              taskText: '新词 8 个 · 复习 16 个 · 错词 4 个',
              accuracy: '92%',
              streak: '连续 3 天',
              progress: 0.42,
            ),
            SizedBox(height: 20),
            _TodayTaskPanel(),
            SizedBox(height: 20),
            _ParentPanel(),
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
          style: textTheme.bodyMedium?.copyWith(color: const Color(0xFF66736D)),
        ),
      ],
    );
  }
}

class _ChildProgressCard extends StatelessWidget {
  const _ChildProgressCard({
    required this.name,
    required this.grade,
    required this.taskText,
    required this.accuracy,
    required this.streak,
    required this.progress,
  });

  final String name;
  final String grade;
  final String taskText;
  final String accuracy;
  final String streak;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
                  child: Text(name.characters.first),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(grade),
                    ],
                  ),
                ),
                Text(
                  accuracy,
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(taskText),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 10),
            Text(streak),
          ],
        ),
      ),
    );
  }
}

class _TodayTaskPanel extends StatelessWidget {
  const _TodayTaskPanel();

  @override
  Widget build(BuildContext context) {
    return const _SectionPanel(
      title: '今日学习主线',
      rows: [
        _InfoRow(label: '基础题型', value: '英选中 / 中选英 / 拼写'),
        _InfoRow(label: '听音训练', value: '听音选词 / 听音拼写'),
        _InfoRow(label: '复习策略', value: '答错缩短间隔，答对延后复习'),
      ],
    );
  }
}

class _ParentPanel extends StatelessWidget {
  const _ParentPanel();

  @override
  Widget build(BuildContext context) {
    return const _SectionPanel(
      title: '家长管理',
      rows: [
        _InfoRow(label: '词表', value: '内置词表 + CSV 导入'),
        _InfoRow(label: '看板', value: '完成情况 / 正确率 / 高频错词'),
        _InfoRow(label: '数据', value: '本地保存，支持备份导入导出'),
      ],
    );
  }
}

class _SectionPanel extends StatelessWidget {
  const _SectionPanel({
    required this.title,
    required this.rows,
  });

  final String title;
  final List<Widget> rows;

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
            ...rows,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
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
      ),
    );
  }
}
