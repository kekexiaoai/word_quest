import 'package:flutter/material.dart';

import '../../adventure/application/adventure_level_quiz_builder.dart';
import '../../adventure/application/adventure_session_controller.dart';
import '../../adventure/application/in_memory_adventure_repository.dart';
import '../../adventure/domain/adventure_dashboard_snapshot.dart';
import '../../adventure/domain/adventure_level.dart';
import '../../adventure/domain/adventure_level_quiz.dart';
import '../../adventure/domain/adventure_repository.dart';
import '../../adventure/domain/pet_profile.dart';
import '../application/in_memory_home_dashboard_repository.dart';
import '../domain/home_dashboard_repository.dart';
import '../domain/home_dashboard_snapshot.dart';
import '../../study/application/in_memory_answer_record_repository.dart';
import '../../study/application/study_answer_evaluator.dart';
import '../../study/domain/answer_record_repository.dart';
import '../../study/domain/study_question.dart';

enum _HomeTab {
  today,
  quest,
  wordBook,
  settings,
}

const _tabContentPadding = EdgeInsets.fromLTRB(18, 18, 18, 128);

Color _levelColor(AdventureLevelStatus status) {
  return switch (status) {
    AdventureLevelStatus.completed => const Color(0xFF2F856F),
    AdventureLevelStatus.current => const Color(0xFFFF9500),
    AdventureLevelStatus.reviewable => const Color(0xFF5856D6),
    AdventureLevelStatus.locked => const Color(0xFF9B9BA3),
  };
}

String _levelStatusLabel(AdventureLevelStatus status) {
  return switch (status) {
    AdventureLevelStatus.completed => '已点亮',
    AdventureLevelStatus.current => '进行中',
    AdventureLevelStatus.reviewable => '可复习',
    AdventureLevelStatus.locked => '未解锁',
  };
}

String _shortLevelTitle(AdventureLevelType type) {
  return switch (type) {
    AdventureLevelType.newWordWarmup => '新词',
    AdventureLevelType.reviewExplore => '复习',
    AdventureLevelType.mistakeBoss => 'Boss',
    AdventureLevelType.chestSettlement => '宝箱',
  };
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.dashboardRepository = const InMemoryHomeDashboardRepository(),
    this.adventureRepository = const InMemoryAdventureRepository(),
    this.answerRecordRepository = const InMemoryAnswerRecordRepository(),
  });

  final HomeDashboardRepository dashboardRepository;
  final AdventureRepository adventureRepository;
  final AnswerRecordRepository answerRecordRepository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _sessionController = AdventureSessionController();

  late final HomeDashboardSnapshot _dashboard;
  late AdventureDashboardSnapshot _adventure;
  AdventureLevel? _activeLevel;
  _HomeTab _selectedTab = _HomeTab.today;
  bool _isStudying = false;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    final referenceDate = DateTime.now();
    _dashboard = widget.dashboardRepository.loadDashboard(
      referenceDate: referenceDate,
    );
    _adventure = widget.adventureRepository.loadAdventure(
      childId: _dashboard.children.first.id,
      referenceDate: referenceDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentChild = _dashboard.children.first;

    if (_isComplete) {
      return Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: _StudyCompleteScreen(
                adventure: _adventure,
                onFeedPet: () {
                  setState(() {
                    _adventure = _sessionController.feedPetWithTodayRewards(
                      _adventure,
                      fedAt: DateTime.now(),
                    );
                    widget.adventureRepository.saveAdventure(_adventure);
                    _isStudying = false;
                    _isComplete = false;
                    _selectedTab = _HomeTab.today;
                  });
                },
                onReview: () {
                  setState(() {
                    _isComplete = false;
                    _selectedTab = _HomeTab.wordBook;
                  });
                },
              ),
            ),
          ),
        ),
      );
    }

    if (_isStudying) {
      return Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: _StudyQuizScreen(
                childId: currentChild.id,
                level: _activeLevel ?? _adventure.currentLevel,
                answerRecordRepository: widget.answerRecordRepository,
                onClose: () {
                  setState(() {
                    _isStudying = false;
                  });
                },
                onComplete: () {
                  setState(() {
                    _adventure =
                        _sessionController.completeCurrentLevel(_adventure);
                    widget.adventureRepository.saveAdventure(_adventure);
                    _isStudying = false;
                    _isComplete = true;
                  });
                },
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      extendBody: true,
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
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: _buildTabContent(currentChild),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(ChildDashboardSnapshot currentChild) {
    return switch (_selectedTab) {
      _HomeTab.today => _TodayTabView(
          currentChild: currentChild,
          adventure: _adventure,
          onContinue: () {
            setState(() {
              _activeLevel = _adventure.currentLevel;
              _isStudying = true;
            });
          },
        ),
      _HomeTab.quest => _QuestTabView(
          adventure: _adventure,
          canEnterLevel: _sessionController.canEnter,
          onEnterLevel: (level) {
            setState(() {
              _activeLevel = level;
              _isStudying = true;
            });
          },
        ),
      _HomeTab.wordBook => const _WordBookTabView(),
      _HomeTab.settings => _SettingsTabView(currentChild: currentChild),
    };
  }
}

class _TodayTabView extends StatelessWidget {
  const _TodayTabView({
    required this.currentChild,
    required this.adventure,
    required this.onContinue,
  });

  final ChildDashboardSnapshot currentChild;
  final AdventureDashboardSnapshot adventure;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: _tabContentPadding,
      children: [
        _Header(
          title: '词途',
          eyebrow: '每天一小步，单词走得稳',
          trailing: _LearnerPill(name: currentChild.name),
        ),
        const SizedBox(height: 28),
        _TodayTaskCard(
          child: currentChild,
          onContinue: onContinue,
        ),
        const SizedBox(height: 24),
        _AdventureOverviewCard(adventure: adventure),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                value: currentChild.accuracyLabel,
                label: '近 7 日正确率',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                value: currentChild.streakLabel.replaceAll('连续 ', ''),
                label: '连续学习',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AdventureOverviewCard extends StatelessWidget {
  const _AdventureOverviewCard({required this.adventure});

  final AdventureDashboardSnapshot adventure;

  @override
  Widget build(BuildContext context) {
    final currentLevel = adventure.currentLevel;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Text(
                      '今日冒险',
                      style: TextStyle(
                        color: Color(0xFF111114),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        adventure.themeTitle,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF2F856F),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _CompactBadge(
                label: '${adventure.starsEarned}/${adventure.starsTarget} 星',
                icon: Icons.star_rounded,
                color: const Color(0xFFFF9500),
                backgroundColor: const Color(0xFFFFF2D9),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _PetInlinePanel(pet: adventure.pet),
          const SizedBox(height: 12),
          _CompactBadge(
            label: currentLevel.title,
            icon: Icons.explore_rounded,
            color: const Color(0xFFFF9500),
            backgroundColor: const Color(0xFFFFF2D9),
          ),
          const SizedBox(height: 14),
          Text(
            adventure.currentNodeTitle,
            style: const TextStyle(
              color: Color(0xFF70727A),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          _MiniLevelRoute(levels: adventure.levels),
        ],
      ),
    );
  }
}

class _MiniLevelRoute extends StatelessWidget {
  const _MiniLevelRoute({required this.levels});

  final List<AdventureLevel> levels;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < levels.length; index++) ...[
          Expanded(child: _MiniLevelNode(level: levels[index])),
          if (index < levels.length - 1)
            Container(
              width: 14,
              height: 3,
              color: const Color(0xFFD7DED9),
            ),
        ],
      ],
    );
  }
}

class _MiniLevelNode extends StatelessWidget {
  const _MiniLevelNode({required this.level});

  final AdventureLevel level;

  @override
  Widget build(BuildContext context) {
    final color = _levelColor(level.status);
    final icon = switch (level.status) {
      AdventureLevelStatus.completed => Icons.check_rounded,
      AdventureLevelStatus.current => Icons.play_arrow_rounded,
      AdventureLevelStatus.reviewable => Icons.replay_rounded,
      AdventureLevelStatus.locked => Icons.lock_rounded,
    };

    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 6),
        Text(
          _shortLevelTitle(level.type),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _PetInlinePanel extends StatelessWidget {
  const _PetInlinePanel({required this.pet});

  final PetProfile pet;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6F1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFF2F856F),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pets_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${pet.name} Lv.${pet.level}',
                  style: const TextStyle(
                    color: Color(0xFF111114),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '饱腹 ${pet.satiety}%',
                  style: const TextStyle(
                    color: Color(0xFF70727A),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2F856F),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            child: const Text('喂食'),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.eyebrow,
    this.trailingIcon = Icons.person_outline_rounded,
    this.trailing,
  });

  final String title;
  final String eyebrow;
  final IconData trailingIcon;
  final Widget? trailing;

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
        trailing ??
            Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                trailingIcon,
                color: const Color(0xFF2F856F),
                size: 30,
              ),
            ),
      ],
    );
  }
}

class _LearnerPill extends StatelessWidget {
  const _LearnerPill({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Color(0xFF2F856F),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            name,
            style: const TextStyle(
              color: Color(0xFF111114),
              fontSize: 18,
              fontWeight: FontWeight.w900,
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

    return Container(
      padding: const EdgeInsets.all(20),
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '今日任务',
                      style: TextStyle(
                        color: Color(0xFF34C759),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '12 分钟完成剩余练习',
                      style: TextStyle(
                        color: Color(0xFF111114),
                        fontSize: 30,
                        height: 1.12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '还剩 7 题，下一组是听音和错词复习。',
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
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: child.progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E2E8),
              color: const Color(0xFF2F856F),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              key: const ValueKey('home_continue_learning_button'),
              onPressed: onContinue,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('继续学习'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2F856F),
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
        ],
      ),
    );
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
          color: Color(0xFF2F856F),
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CompactBadge extends StatelessWidget {
  const _CompactBadge({
    required this.label,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
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
  const _LearningRouteList({
    required this.levels,
    required this.canEnterLevel,
    required this.onEnterLevel,
  });

  final List<AdventureLevel> levels;
  final bool Function(AdventureLevel level) canEnterLevel;
  final ValueChanged<AdventureLevel> onEnterLevel;

  @override
  Widget build(BuildContext context) {
    return _GroupedList(
      children: [
        for (final level in levels)
          _RouteRow(
            icon: _levelIcon(level.type),
            iconColor: _levelColor(level.status),
            iconBackground: _levelColor(level.status).withValues(alpha: 0.14),
            title: level.title,
            subtitle: level.subtitle,
            status: _levelStatusLabel(level.status),
            statusColor: _levelColor(level.status),
            onTap: canEnterLevel(level) ? () => onEnterLevel(level) : null,
          ),
      ],
    );
  }

  IconData _levelIcon(AdventureLevelType type) {
    return switch (type) {
      AdventureLevelType.newWordWarmup => Icons.auto_awesome_rounded,
      AdventureLevelType.reviewExplore => Icons.explore_rounded,
      AdventureLevelType.mistakeBoss => Icons.shield_rounded,
      AdventureLevelType.chestSettlement => Icons.inventory_2_rounded,
    };
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
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final String? status;
  final Color statusColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
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
      ),
    );
  }
}

class _QuestTabView extends StatelessWidget {
  const _QuestTabView({
    required this.adventure,
    required this.canEnterLevel,
    required this.onEnterLevel,
  });

  final AdventureDashboardSnapshot adventure;
  final bool Function(AdventureLevel level) canEnterLevel;
  final ValueChanged<AdventureLevel> onEnterLevel;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: _tabContentPadding,
      children: [
        _Header(
          title: adventure.themeTitle,
          eyebrow: '学习路线',
          trailing: _CompactBadge(
            label: '${adventure.starsEarned}/${adventure.starsTarget} 星',
            icon: Icons.star_rounded,
            color: const Color(0xFFFF9500),
            backgroundColor: const Color(0xFFFFF2D9),
          ),
        ),
        const SizedBox(height: 18),
        _MapProgressCard(adventure: adventure),
        const SizedBox(height: 28),
        const _SectionTitle('今日路线'),
        const SizedBox(height: 14),
        _LearningRouteList(
          levels: adventure.levels,
          canEnterLevel: canEnterLevel,
          onEnterLevel: onEnterLevel,
        ),
        const SizedBox(height: 28),
        const _SectionTitle('奖励反馈'),
        const SizedBox(height: 14),
        _RewardPanel(adventure: adventure),
      ],
    );
  }
}

class _RewardPanel extends StatelessWidget {
  const _RewardPanel({required this.adventure});

  final AdventureDashboardSnapshot adventure;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const _IconBadge(
            icon: Icons.star_rounded,
            iconColor: Color(0xFFFF9500),
            backgroundColor: Color(0xFFFFF2D9),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '完成今日任务可获得 3 颗星',
                  style: TextStyle(
                    color: Color(0xFF111114),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '宝箱进度 ${(adventure.chestProgress * 100).round()}%，${adventure.pet.name} 会获得成长值。',
                  style: const TextStyle(
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

class _MapProgressCard extends StatelessWidget {
  const _MapProgressCard({required this.adventure});

  final AdventureDashboardSnapshot adventure;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            adventure.currentNodeTitle,
            style: const TextStyle(
              color: Color(0xFF111114),
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${adventure.pet.name} Lv.${adventure.pet.level} 正在陪你闯关 · 饱腹 ${adventure.pet.satiety}%',
            style: const TextStyle(
              color: Color(0xFF70727A),
              fontSize: 15,
              height: 1.35,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          _CompactBadge(
            label: '${adventure.pet.name} Lv.${adventure.pet.level}',
            icon: Icons.pets_rounded,
            color: const Color(0xFF2F856F),
            backgroundColor: const Color(0xFFE5F8EC),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: adventure.chestProgress,
              minHeight: 9,
              backgroundColor: const Color(0xFFE2E2E8),
              color: const Color(0xFF2F856F),
            ),
          ),
        ],
      ),
    );
  }
}

class _WordBookTabView extends StatelessWidget {
  const _WordBookTabView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: _tabContentPadding,
      children: const [
        _Header(
          title: '词表',
          eyebrow: '小学高年级基础词表',
          trailingIcon: Icons.add_rounded,
        ),
        SizedBox(height: 28),
        _SearchBox(label: '搜索单词、释义或标签'),
        SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                value: '240',
                label: '词表总量',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                value: '12',
                label: '待复习错词',
              ),
            ),
          ],
        ),
        SizedBox(height: 28),
        _SectionTitle('分类'),
        SizedBox(height: 14),
        _GroupedList(
          children: [
            _RouteRow(
              icon: Icons.layers_rounded,
              iconColor: Color(0xFF2F856F),
              iconBackground: Color(0xFFE5F8EC),
              title: '当前词表',
              subtitle: '小学高年级基础 · 掌握 126 个',
            ),
            _RouteRow(
              icon: Icons.warning_amber_rounded,
              iconColor: Color(0xFFFF9500),
              iconBackground: Color(0xFFFFF2D9),
              title: '错词复习',
              subtitle: '拼写 6 个 · 听音 4 个 · 释义 2 个',
            ),
          ],
        ),
        SizedBox(height: 28),
        _SectionTitle('最近练过'),
        SizedBox(height: 14),
        _GroupedList(
          children: [
            _RouteRow(
              icon: Icons.abc_rounded,
              iconColor: Color(0xFF111114),
              iconBackground: Color(0xFFFFFFFF),
              title: 'neighbor',
              subtitle: '邻居 · 听音待复习',
              status: '今天',
              statusColor: Color(0xFFFF9500),
            ),
            _RouteRow(
              icon: Icons.abc_rounded,
              iconColor: Color(0xFF111114),
              iconBackground: Color(0xFFFFFFFF),
              title: 'library',
              subtitle: '图书馆 · 已掌握',
              status: '稳定',
              statusColor: Color(0xFF2F856F),
            ),
          ],
        ),
      ],
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E2E8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: Color(0xFF70727A),
            size: 28,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF70727A),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTabView extends StatelessWidget {
  const _SettingsTabView({required this.currentChild});

  final ChildDashboardSnapshot currentChild;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: _tabContentPadding,
      children: [
        const _Header(
          title: '设置',
          eyebrow: 'Word Quest',
          trailing: SizedBox.shrink(),
        ),
        const SizedBox(height: 28),
        _ProfileCard(name: currentChild.name),
        const SizedBox(height: 28),
        const _SectionTitle('身份与档案'),
        const SizedBox(height: 14),
        _GroupedList(
          children: [
            _RouteRow(
              icon: Icons.switch_account_rounded,
              iconColor: const Color(0xFF2F856F),
              iconBackground: const Color(0xFFE5F8EC),
              title: '切换孩子 / 家长',
              subtitle: currentChild.name,
            ),
            const _RouteRow(
              icon: Icons.shield_outlined,
              iconColor: Color(0xFF5856D6),
              iconBackground: Color(0xFFECEBFF),
              title: '家长管理',
              subtitle: '轻量看板',
            ),
          ],
        ),
        const SizedBox(height: 28),
        const _SectionTitle('数据'),
        const SizedBox(height: 14),
        const _GroupedList(
          children: [
            _RouteRow(
              icon: Icons.backup_rounded,
              iconColor: Color(0xFF2F856F),
              iconBackground: Color(0xFFE5F8EC),
              title: '备份与恢复',
              subtitle: '本机',
            ),
            _RouteRow(
              icon: Icons.download_rounded,
              iconColor: Color(0xFFFF9500),
              iconBackground: Color(0xFFFFF2D9),
              title: '导入学习备份',
              subtitle: 'JSON',
            ),
          ],
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '词途',
                style: TextStyle(
                  color: Color(0xFF111114),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 14),
              Text(
                '每天一小步，单词走得稳',
                style: TextStyle(
                  color: Color(0xFF70727A),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 12),
              Text(
                '内部代号：Word Quest',
                style: TextStyle(
                  color: Color(0xFF9B9BA3),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFF2F856F),
              shape: BoxShape.circle,
            ),
            child: const Text(
              '安',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Color(0xFF111114),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '孩子模式 · 五年级',
                  style: TextStyle(
                    color: Color(0xFF70727A),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
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

class _StudyQuizScreen extends StatefulWidget {
  const _StudyQuizScreen({
    required this.childId,
    required this.level,
    required this.answerRecordRepository,
    required this.onClose,
    required this.onComplete,
  });

  final String childId;
  final AdventureLevel level;
  final AnswerRecordRepository answerRecordRepository;
  final VoidCallback onClose;
  final VoidCallback onComplete;

  @override
  State<_StudyQuizScreen> createState() => _StudyQuizScreenState();
}

class _StudyQuizScreenState extends State<_StudyQuizScreen> {
  static const _answerEvaluator = StudyAnswerEvaluator();

  late final List<int> _questionQueue = List<int>.generate(
    widget.level.questionCount <= 0 ? 1 : widget.level.questionCount,
    (index) => index,
  );
  int _queueCursor = 0;
  DateTime _questionStartedAt = DateTime.now();
  String? _selectedAnswer;
  bool _showFeedback = false;

  @override
  Widget build(BuildContext context) {
    final questionIndex = _questionQueue[_queueCursor];
    final quiz = const AdventureLevelQuizBuilder().buildForLevel(
      widget.level,
      questionIndex: questionIndex,
    );
    final isAnswerCorrect = _selectedAnswer == quiz.correctAnswer;
    final isLastQueuedQuestion = _queueCursor >= _questionQueue.length - 1;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      children: [
        Row(
          children: [
            _CircleButton(
              icon: Icons.close_rounded,
              onTap: widget.onClose,
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    widget.level.title,
                    style: const TextStyle(
                      color: Color(0xFF111114),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    quiz.progressLabel,
                    style: const TextStyle(
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
          child: LinearProgressIndicator(
            value: quiz.progressValue,
            minHeight: 8,
            backgroundColor: const Color(0xFFE2E2E8),
            color: const Color(0xFF2F856F),
          ),
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 44),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            children: [
              Text(
                quiz.activityTitle,
                style: const TextStyle(
                  color: Color(0xFF2F856F),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                quiz.instruction,
                style: const TextStyle(
                  color: Color(0xFF70727A),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 28),
              _QuestionPrompt(quiz: quiz),
              const SizedBox(height: 24),
              Text(
                quiz.usesAudioPrompt ? '可重复播放 2 次' : quiz.prompt,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF9B9BA3),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _LevelContextPanel(level: widget.level),
        const SizedBox(height: 16),
        for (final answer in quiz.choices) ...[
          _ChoiceTile(
            label: answer,
            isSelected: _selectedAnswer == answer,
            isCorrect: answer == quiz.correctAnswer,
            showFeedback: _showFeedback,
            onTap: () {
              if (_showFeedback) {
                return;
              }
              final answeredAt = DateTime.now();
              final elapsedMilliseconds =
                  answeredAt.difference(_questionStartedAt).inMilliseconds;
              final record = _answerEvaluator.evaluate(
                childId: widget.childId,
                question: StudyQuestion(
                  wordId: quiz.wordId,
                  practiceMode: quiz.practiceMode,
                  type: StudyQuestionType.choice,
                  prompt: quiz.prompt,
                  correctAnswer: quiz.correctAnswer,
                  choices: quiz.choices,
                ),
                submittedAnswer: answer,
                answeredAt: answeredAt,
                elapsedMilliseconds:
                    elapsedMilliseconds <= 0 ? 1 : elapsedMilliseconds,
              );
              widget.answerRecordRepository.addRecord(record);

              setState(() {
                _selectedAnswer = answer;
                _showFeedback = true;
              });
            },
          ),
          const SizedBox(height: 12),
        ],
        if (_showFeedback)
          _AnswerFeedbackPanel(
            quiz: quiz,
            isCorrect: isAnswerCorrect,
          )
        else
          const SizedBox(height: 102),
        const SizedBox(height: 18),
        SizedBox(
          height: 58,
          child: FilledButton(
            onPressed: _showFeedback
                ? () {
                    final nextQueue = List<int>.of(_questionQueue);
                    if (!isAnswerCorrect) {
                      nextQueue.add(questionIndex);
                    }

                    final shouldComplete =
                        isAnswerCorrect && isLastQueuedQuestion;
                    if (shouldComplete) {
                      widget.onComplete();
                      return;
                    }

                    setState(() {
                      _questionQueue
                        ..clear()
                        ..addAll(nextQueue);
                      _queueCursor += 1;
                      _selectedAnswer = null;
                      _showFeedback = false;
                      _questionStartedAt = DateTime.now();
                    });
                  }
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2F856F),
              disabledBackgroundColor: const Color(0xFFA8D4C6),
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

class _QuestionPrompt extends StatelessWidget {
  const _QuestionPrompt({required this.quiz});

  final AdventureLevelQuiz quiz;

  @override
  Widget build(BuildContext context) {
    if (quiz.usesAudioPrompt) {
      return const CircleAvatar(
        radius: 48,
        backgroundColor: Color(0xFFE5F3EE),
        child: Icon(
          Icons.volume_up_rounded,
          color: Color(0xFF2F856F),
          size: 54,
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 96),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F3EE),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        quiz.prompt,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF2F856F),
          fontSize: 32,
          fontWeight: FontWeight.w900,
        ),
      ),
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

class _LevelContextPanel extends StatelessWidget {
  const _LevelContextPanel({required this.level});

  final AdventureLevel level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6F1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(
            Icons.explore_rounded,
            color: _levelColor(level.status),
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              level.subtitle,
              style: const TextStyle(
                color: Color(0xFF2F856F),
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerFeedbackPanel extends StatelessWidget {
  const _AnswerFeedbackPanel({
    required this.quiz,
    required this.isCorrect,
  });

  final AdventureLevelQuiz quiz;
  final bool isCorrect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F8EC),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isCorrect ? quiz.successTitle : quiz.failureTitle,
            style: TextStyle(
              color:
                  isCorrect ? const Color(0xFF34C759) : const Color(0xFFFF9500),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isCorrect ? quiz.explanation : quiz.failureExplanation,
            style: const TextStyle(
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

class _PetRewardStrip extends StatelessWidget {
  const _PetRewardStrip({
    required this.adventure,
    required this.onFeedPet,
  });

  final AdventureDashboardSnapshot adventure;
  final VoidCallback onFeedPet;

  @override
  Widget build(BuildContext context) {
    final growthReward = _totalGrowthReward(adventure.levels);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6F1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.pets_rounded,
            color: Color(0xFF2F856F),
            size: 26,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${adventure.pet.name} 获得成长 +$growthReward，离下一级更近了。',
              style: const TextStyle(
                color: Color(0xFF2F856F),
                fontSize: 15,
                height: 1.3,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          TextButton(
            onPressed: onFeedPet,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2F856F),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            child: Text('喂食${adventure.pet.name}'),
          ),
        ],
      ),
    );
  }
}

class _RewardSummaryGrid extends StatelessWidget {
  const _RewardSummaryGrid({required this.adventure});

  final AdventureDashboardSnapshot adventure;

  @override
  Widget build(BuildContext context) {
    final firstFood = adventure.levels
        .map((level) => level.reward)
        .firstWhere((reward) => reward.foodName != null);
    final growthReward = _totalGrowthReward(adventure.levels);

    return Row(
      children: [
        Expanded(
          child: _RewardChip(
            icon: Icons.star_rounded,
            label: '获得 ${adventure.starsTarget} 颗星',
            color: const Color(0xFFFF9500),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _RewardChip(
            icon: Icons.restaurant_rounded,
            label: '${firstFood.foodName} +${firstFood.foodCount}',
            color: const Color(0xFF2F856F),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _RewardChip(
            icon: Icons.pets_rounded,
            label: '宠物成长 +$growthReward',
            color: const Color(0xFF5856D6),
          ),
        ),
      ],
    );
  }
}

class _RewardChip extends StatelessWidget {
  const _RewardChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 86),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF111114),
              fontSize: 14,
              height: 1.2,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

int _totalGrowthReward(List<AdventureLevel> levels) {
  return levels.fold(
    0,
    (total, level) => total + level.reward.growthPoints,
  );
}

class _StudyCompleteScreen extends StatelessWidget {
  const _StudyCompleteScreen({
    required this.adventure,
    required this.onFeedPet,
    required this.onReview,
  });

  final AdventureDashboardSnapshot adventure;
  final VoidCallback onFeedPet;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      children: [
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 42),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 48,
                backgroundColor: Color(0xFFFFF2D9),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFFFF9500),
                  size: 52,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                '今天完成了',
                style: TextStyle(
                  color: Color(0xFF111114),
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                '安安获得 3 颗星，森林书屋第 4 站已点亮。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF70727A),
                  fontSize: 18,
                  height: 1.35,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              _PetRewardStrip(
                adventure: adventure,
                onFeedPet: onFeedPet,
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        const Row(
          children: [
            Expanded(
              child: _MetricTile(
                value: '18',
                label: '完成',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                value: '94%',
                label: '正确率',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                value: '2',
                label: '待复习',
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        const _SectionTitle('今日奖励'),
        const SizedBox(height: 14),
        _RewardSummaryGrid(adventure: adventure),
        const SizedBox(height: 28),
        const _SectionTitle('明天优先复习'),
        const SizedBox(height: 14),
        const _GroupedList(
          children: [
            _RouteRow(
              icon: Icons.edit_outlined,
              iconColor: Color(0xFFFF9500),
              iconBackground: Color(0xFFFFF2D9),
              title: 'through',
              subtitle: '拼写仍不稳定',
            ),
            _RouteRow(
              icon: Icons.volume_up_rounded,
              iconColor: Color(0xFF5856D6),
              iconBackground: Color(0xFFECEBFF),
              title: 'neighbor',
              subtitle: '听音反应稍慢',
            ),
          ],
        ),
        const SizedBox(height: 120),
        SizedBox(
          height: 58,
          child: FilledButton(
            onPressed: onFeedPet,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2F856F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            child: Text('喂食${adventure.pet.name}'),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 58,
          child: OutlinedButton(
            onPressed: onReview,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2F856F),
              side: BorderSide.none,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            child: const Text('马上复习错词'),
          ),
        ),
      ],
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
        key: const ValueKey('home_tab_bar'),
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
              tapKey: const ValueKey('home_tab_settings'),
              icon: Icons.settings_outlined,
              label: '设置',
              isActive: selectedTab == _HomeTab.settings,
              onTap: () => onChanged(_HomeTab.settings),
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
    final color = isActive ? const Color(0xFF2F856F) : const Color(0xFF9B9BA3);
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
