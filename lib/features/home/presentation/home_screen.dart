import 'package:flutter/material.dart';

import '../application/in_memory_home_dashboard_repository.dart';
import '../domain/home_dashboard_repository.dart';
import '../domain/home_dashboard_snapshot.dart';

enum _HomeTab {
  today,
  quest,
  wordBook,
  family,
}

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
  _HomeTab _selectedTab = _HomeTab.today;
  bool _isStudying = false;

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
    final reminderChild =
        _dashboard.children.length > 1 ? _dashboard.children[1] : currentChild;

    if (_isStudying) {
      return Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: _StudyQuizScreen(
                onClose: () {
                  setState(() {
                    _isStudying = false;
                  });
                },
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(18, 0, 18, 8),
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: _BottomTabBar(
              selectedTab: _selectedTab,
              onChanged: (tab) {
                setState(() {
                  _selectedTab = tab;
                });
              },
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: _buildTabContent(currentChild, reminderChild),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(
    ChildDashboardSnapshot currentChild,
    ChildDashboardSnapshot reminderChild,
  ) {
    return switch (_selectedTab) {
      _HomeTab.today => _TodayTabView(
          dashboard: _dashboard,
          currentChild: currentChild,
          reminderChild: reminderChild,
          selectedChildIndex: _selectedChildIndex,
          onChildChanged: (index) {
            setState(() {
              _selectedChildIndex = index;
            });
          },
          onContinue: () {
            setState(() {
              _isStudying = true;
            });
          },
        ),
      _HomeTab.quest => const _QuestTabView(),
      _HomeTab.wordBook => _WordBookTabView(rows: _dashboard.bookHighlights),
      _HomeTab.family => _FamilyTabView(children: _dashboard.children),
    };
  }
}

class _TodayTabView extends StatelessWidget {
  const _TodayTabView({
    required this.dashboard,
    required this.currentChild,
    required this.reminderChild,
    required this.selectedChildIndex,
    required this.onChildChanged,
    required this.onContinue,
  });

  final HomeDashboardSnapshot dashboard;
  final ChildDashboardSnapshot currentChild;
  final ChildDashboardSnapshot reminderChild;
  final int selectedChildIndex;
  final ValueChanged<int> onChildChanged;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      children: [
        const _Header(title: '今天', eyebrow: 'Word Quest'),
        const SizedBox(height: 28),
        _ChildSegment(
          children: dashboard.children,
          selectedIndex: selectedChildIndex,
          onChanged: onChildChanged,
        ),
        const SizedBox(height: 18),
        _TodayTaskCard(
          child: currentChild,
          onContinue: onContinue,
        ),
        const SizedBox(height: 28),
        const _SectionTitle('学习路线'),
        const SizedBox(height: 14),
        const _LearningRouteList(),
        const SizedBox(height: 28),
        const _SectionTitle('内置词表'),
        const SizedBox(height: 14),
        _WordBookList(rows: dashboard.bookHighlights),
        const SizedBox(height: 28),
        const _SectionTitle('家长提醒'),
        const SizedBox(height: 14),
        _ParentReminderCard(childName: reminderChild.name),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.eyebrow,
    this.trailingIcon = Icons.person_outline_rounded,
  });

  final String title;
  final String eyebrow;
  final IconData trailingIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF6F7078),
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: const Color(0xFF111114),
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
        ),
        Container(
          width: 58,
          height: 58,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(
            trailingIcon,
            color: const Color(0xFF007AFF),
            size: 30,
          ),
        ),
      ],
    );
  }
}

class _ChildSegment extends StatelessWidget {
  const _ChildSegment({
    required this.children,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<ChildDashboardSnapshot> children;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E2E8),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          for (var index = 0; index < children.length; index++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selectedIndex == index
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    children[index].name,
                    style: TextStyle(
                      color: const Color(0xFF111114),
                      fontSize: 16,
                      fontWeight: selectedIndex == index
                          ? FontWeight.w800
                          : FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TodayTaskCard extends StatelessWidget {
  const _TodayTaskCard({
    required this.child,
    required this.onContinue,
  });

  final ChildDashboardSnapshot child;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final progressPercent = (child.progress * 100).round();
    final questionCount = _questionCount(child.taskSummary);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '今日任务',
                      style: TextStyle(
                        color: Color(0xFF34C759),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$questionCount 道题 · 还差 5 分钟',
                      style: const TextStyle(
                        color: Color(0xFF111114),
                        fontSize: 32,
                        height: 1.12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '新词、复习词和错词强化已按顺序排好。',
                      style: TextStyle(
                        color: Color(0xFF70727A),
                        fontSize: 16,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              _ProgressBubble(label: '$progressPercent%'),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              key: const ValueKey('home_continue_learning_button'),
              onPressed: onContinue,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('继续学习'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  value: child.accuracyLabel,
                  label: '正确率',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricTile(
                  value: child.streakLabel.replaceAll('连续 ', ''),
                  label: '连续学习',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _questionCount(String taskSummary) {
    final matches = RegExp(r'\d+').allMatches(taskSummary);
    return matches
        .map((match) => int.tryParse(match.group(0) ?? '') ?? 0)
        .fold(0, (sum, value) => sum + value);
  }
}

class _ProgressBubble extends StatelessWidget {
  const _ProgressBubble({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 94,
      height: 94,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFFE5F8EC),
        shape: BoxShape.circle,
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF34C759),
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF111114),
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF70727A),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF111114),
        fontSize: 28,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _LearningRouteList extends StatelessWidget {
  const _LearningRouteList();

  @override
  Widget build(BuildContext context) {
    return const _GroupedList(
      children: [
        _RouteRow(
          icon: Icons.ads_click_rounded,
          iconColor: Color(0xFF34C759),
          iconBackground: Color(0xFFE5F8EC),
          title: '基础选择题',
          subtitle: '英选中 / 中选英 · 8 题',
          status: '进行中',
          statusColor: Color(0xFF34C759),
        ),
        _RouteRow(
          icon: Icons.keyboard_rounded,
          iconColor: Color(0xFFFF9500),
          iconBackground: Color(0xFFFFF2D9),
          title: '拼写强化',
          subtitle: '输出薄弱词 · 6 题',
        ),
        _RouteRow(
          icon: Icons.volume_up_rounded,
          iconColor: Color(0xFFFF3B30),
          iconBackground: Color(0xFFFFE5E5),
          title: '听音训练',
          subtitle: '听音选词 / 听写 · 4 题',
        ),
      ],
    );
  }
}

class _WordBookList extends StatelessWidget {
  const _WordBookList({required this.rows});

  final List<DashboardSectionLine> rows;

  @override
  Widget build(BuildContext context) {
    return _GroupedList(
      children: [
        for (final row in rows)
          _RouteRow(
            icon: Icons.menu_book_rounded,
            iconColor: const Color(0xFF007AFF),
            iconBackground: const Color(0xFFEAF3FF),
            title: row.label,
            subtitle: row.value,
          ),
      ],
    );
  }
}

class _GroupedList extends StatelessWidget {
  const _GroupedList({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index < children.length - 1)
              const Divider(
                height: 1,
                thickness: 1,
                indent: 70,
                color: Color(0xFFD9D9DE),
              ),
          ],
        ],
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    this.status,
    this.statusColor = const Color(0xFF9B9BA3),
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final String? status;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF111114),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF70727A),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (status != null)
            Text(
              status!,
              style: TextStyle(
                color: statusColor,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            )
          else
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF9B9BA3),
            ),
        ],
      ),
    );
  }
}

class _ParentReminderCard extends StatelessWidget {
  const _ParentReminderCard({required this.childName});

  final String childName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFECEBFF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Color(0xFF5856D6),
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$childName 今天还未开始',
                  style: const TextStyle(
                    color: Color(0xFF111114),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '建议晚饭前安排 10 分钟复习。',
                  style: TextStyle(
                    color: Color(0xFF70727A),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF9B9BA3),
          ),
        ],
      ),
    );
  }
}

class _QuestTabView extends StatelessWidget {
  const _QuestTabView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      children: const [
        _Header(
          title: '闯关',
          eyebrow: '学习路线',
          trailingIcon: Icons.map_outlined,
        ),
        SizedBox(height: 28),
        _SectionTitle('今日路线'),
        SizedBox(height: 14),
        _LearningRouteList(),
        SizedBox(height: 28),
        _SectionTitle('奖励反馈'),
        SizedBox(height: 14),
        _RewardPanel(),
      ],
    );
  }
}

class _RewardPanel extends StatelessWidget {
  const _RewardPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        children: [
          _IconBadge(
            icon: Icons.star_rounded,
            iconColor: Color(0xFFFF9500),
            backgroundColor: Color(0xFFFFF2D9),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '完成今日任务可获得 3 颗星',
                  style: TextStyle(
                    color: Color(0xFF111114),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '星星会推进地图节点，连续学习会额外加成。',
                  style: TextStyle(
                    color: Color(0xFF70727A),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WordBookTabView extends StatelessWidget {
  const _WordBookTabView({required this.rows});

  final List<DashboardSectionLine> rows;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      children: [
        const _Header(
          title: '错词与词表',
          eyebrow: '词表',
          trailingIcon: Icons.search_rounded,
        ),
        const SizedBox(height: 28),
        const _SectionTitle('高频错词'),
        const SizedBox(height: 14),
        const _GroupedList(
          children: [
            _RouteRow(
              icon: Icons.keyboard_rounded,
              iconColor: Color(0xFFFF3B30),
              iconBackground: Color(0xFFFFE5E5),
              title: '拼写薄弱',
              subtitle: 'neighbor / library / difficult',
              status: '复习',
              statusColor: Color(0xFFFF3B30),
            ),
            _RouteRow(
              icon: Icons.volume_up_rounded,
              iconColor: Color(0xFFFF9500),
              iconBackground: Color(0xFFFFF2D9),
              title: '听音薄弱',
              subtitle: '听写错词 · 4 个',
            ),
          ],
        ),
        const SizedBox(height: 28),
        const _SectionTitle('内置词表'),
        const SizedBox(height: 14),
        _WordBookList(rows: rows),
      ],
    );
  }
}

class _FamilyTabView extends StatelessWidget {
  const _FamilyTabView({required this.children});

  final List<ChildDashboardSnapshot> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      children: [
        const _Header(
          title: '家庭',
          eyebrow: '本地优先',
          trailingIcon: Icons.settings_outlined,
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            const Expanded(
              child: _MetricTile(
                value: '1/2',
                label: '今日完成',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                value: _averageAccuracy(children),
                label: '平均正确率',
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        const _SectionTitle('孩子状态'),
        const SizedBox(height: 14),
        _GroupedList(
          children: [
            for (final child in children)
              _RouteRow(
                icon: Icons.person_rounded,
                iconColor: const Color(0xFF34C759),
                iconBackground: const Color(0xFFE5F8EC),
                title: child.name,
                subtitle: '${child.taskSummary} · 正确率 ${child.accuracyLabel}',
                status: child.progress > 0
                    ? '${(child.progress * 100).round()}%'
                    : '提醒',
                statusColor: child.progress > 0
                    ? const Color(0xFF34C759)
                    : const Color(0xFFFF9500),
              ),
          ],
        ),
        const SizedBox(height: 28),
        const _SectionTitle('管理'),
        const SizedBox(height: 14),
        const _GroupedList(
          children: [
            _RouteRow(
              icon: Icons.upload_rounded,
              iconColor: Color(0xFF34C759),
              iconBackground: Color(0xFFE5F8EC),
              title: '导入 CSV 词表',
              subtitle: '扩展自定义单词',
            ),
            _RouteRow(
              icon: Icons.backup_rounded,
              iconColor: Color(0xFF5856D6),
              iconBackground: Color(0xFFECEBFF),
              title: '备份与恢复',
              subtitle: '学习数据保存为 JSON 备份',
            ),
          ],
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFE5F8EC),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                color: Color(0xFF34C759),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '学习数据保存在本机，可随时导出 JSON 备份。',
                  style: TextStyle(
                    color: Color(0xFF111114),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _averageAccuracy(List<ChildDashboardSnapshot> children) {
    final values = [
      for (final child in children)
        int.tryParse(child.accuracyLabel.replaceAll('%', '')) ?? 0,
    ];
    if (values.isEmpty) {
      return '0%';
    }
    final average = values.reduce((a, b) => a + b) / values.length;
    return '${average.round()}%';
  }
}

class _StudyQuizScreen extends StatefulWidget {
  const _StudyQuizScreen({required this.onClose});

  final VoidCallback onClose;

  @override
  State<_StudyQuizScreen> createState() => _StudyQuizScreenState();
}

class _StudyQuizScreenState extends State<_StudyQuizScreen> {
  String? _selectedAnswer;
  bool _showFeedback = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      children: [
        Row(
          children: [
            _CircleButton(
              icon: Icons.close_rounded,
              onTap: widget.onClose,
            ),
            const Expanded(
              child: Column(
                children: [
                  Text(
                    '基础选择题',
                    style: TextStyle(
                      color: Color(0xFF111114),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '第 1 / 18 题',
                    style: TextStyle(
                      color: Color(0xFF70727A),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            _CircleButton(
              icon: Icons.volume_up_rounded,
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: 28),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: const LinearProgressIndicator(
            value: 1 / 18,
            minHeight: 8,
            backgroundColor: Color(0xFFE2E2E8),
            color: Color(0xFF007AFF),
          ),
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 36),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: const Column(
            children: [
              Text(
                '请选择中文释义',
                style: TextStyle(
                  color: Color(0xFF70727A),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 18),
              Text(
                'neighbor',
                style: TextStyle(
                  color: Color(0xFF111114),
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 16),
              Text(
                '/ˈneɪbər/',
                style: TextStyle(
                  color: Color(0xFF70727A),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        for (final answer in const ['图书馆', '邻居', '穿过', '困难的']) ...[
          _ChoiceTile(
            label: answer,
            isSelected: _selectedAnswer == answer,
            isCorrect: answer == '邻居',
            showFeedback: _showFeedback,
            onTap: () {
              setState(() {
                _selectedAnswer = answer;
                _showFeedback = true;
              });
            },
          ),
          const SizedBox(height: 12),
        ],
        if (_showFeedback)
          const _AnswerFeedbackPanel()
        else
          const SizedBox(height: 102),
        const SizedBox(height: 18),
        SizedBox(
          height: 58,
          child: FilledButton(
            onPressed: _showFeedback ? widget.onClose : null,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF007AFF),
              disabledBackgroundColor: const Color(0xFFB7D7FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            child: const Text('下一题'),
          ),
        ),
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.label,
    required this.isSelected,
    required this.isCorrect,
    required this.showFeedback,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool isCorrect;
  final bool showFeedback;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final highlight = showFeedback && isCorrect;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: highlight ? const Color(0xFFE5F8EC) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: highlight || isSelected
                ? const Color(0xFF34C759)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: highlight
                    ? const Color(0xFF34C759)
                    : const Color(0xFFE2E2E8),
                shape: BoxShape.circle,
              ),
              child: highlight
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 22)
                  : null,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF111114),
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnswerFeedbackPanel extends StatelessWidget {
  const _AnswerFeedbackPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F8EC),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '答对了',
            style: TextStyle(
              color: Color(0xFF34C759),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'neighbor 表示住在附近的人，也可以作动词表示邻近。',
            style: TextStyle(
              color: Color(0xFF70727A),
              fontSize: 16,
              height: 1.35,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        height: 58,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF70727A), size: 30),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(icon, color: iconColor, size: 30),
    );
  }
}

class _BottomTabBar extends StatelessWidget {
  const _BottomTabBar({
    required this.selectedTab,
    required this.onChanged,
  });

  final _HomeTab selectedTab;
  final ValueChanged<_HomeTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        height: 78,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _TabItem(
              tapKey: const ValueKey('home_tab_today'),
              icon: Icons.calendar_today_rounded,
              label: '今天',
              isActive: selectedTab == _HomeTab.today,
              onTap: () => onChanged(_HomeTab.today),
            ),
            _TabItem(
              tapKey: const ValueKey('home_tab_quest'),
              icon: Icons.map_outlined,
              label: '闯关',
              isActive: selectedTab == _HomeTab.quest,
              onTap: () => onChanged(_HomeTab.quest),
            ),
            _TabItem(
              tapKey: const ValueKey('home_tab_word_book'),
              icon: Icons.menu_book_outlined,
              label: '词表',
              isActive: selectedTab == _HomeTab.wordBook,
              onTap: () => onChanged(_HomeTab.wordBook),
            ),
            _TabItem(
              tapKey: const ValueKey('home_tab_family'),
              icon: Icons.group_outlined,
              label: '家庭',
              isActive: selectedTab == _HomeTab.family,
              onTap: () => onChanged(_HomeTab.family),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.tapKey,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  final Key tapKey;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF007AFF) : const Color(0xFF9B9BA3);
    return GestureDetector(
      key: tapKey,
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 62,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 25),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
