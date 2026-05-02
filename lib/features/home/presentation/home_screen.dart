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
    final reminderChild =
        _dashboard.children.length > 1 ? _dashboard.children[1] : currentChild;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              children: [
                const _Header(),
                const SizedBox(height: 28),
                _ChildSegment(
                  children: _dashboard.children,
                  selectedIndex: _selectedChildIndex,
                  onChanged: (index) {
                    setState(() {
                      _selectedChildIndex = index;
                    });
                  },
                ),
                const SizedBox(height: 18),
                _TodayTaskCard(child: currentChild),
                const SizedBox(height: 28),
                const _SectionTitle('学习路线'),
                const SizedBox(height: 14),
                const _LearningRouteList(),
                const SizedBox(height: 28),
                const _SectionTitle('内置词表'),
                const SizedBox(height: 14),
                _WordBookList(rows: _dashboard.bookHighlights),
                const SizedBox(height: 28),
                const _SectionTitle('家长提醒'),
                const SizedBox(height: 14),
                _ParentReminderCard(childName: reminderChild.name),
                const SizedBox(height: 18),
                const _BottomTabBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

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
                'Word Quest',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF6F7078),
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '今天',
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
          child: const Icon(
            Icons.person_outline_rounded,
            color: Color(0xFF007AFF),
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
  const _TodayTaskCard({required this.child});

  final ChildDashboardSnapshot child;

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
              onPressed: () {},
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

class _BottomTabBar extends StatelessWidget {
  const _BottomTabBar();

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
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _TabItem(
              icon: Icons.calendar_today_rounded,
              label: '今天',
              isActive: true,
            ),
            _TabItem(
              icon: Icons.map_outlined,
              label: '闯关',
            ),
            _TabItem(
              icon: Icons.menu_book_outlined,
              label: '词表',
            ),
            _TabItem(
              icon: Icons.group_outlined,
              label: '家庭',
            ),
          ],
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.label,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF007AFF) : const Color(0xFF9B9BA3);
    return SizedBox(
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
    );
  }
}
