import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../adventure/application/adventure_level_quiz_builder.dart';
import '../../adventure/application/adventure_session_controller.dart';
import '../../adventure/application/local_adventure_repository.dart';
import '../../adventure/domain/adventure_dashboard_snapshot.dart';
import '../../adventure/domain/adventure_level.dart';
import '../../adventure/domain/adventure_level_quiz.dart';
import '../../adventure/domain/adventure_repository.dart';
import '../../adventure/domain/pet_profile.dart';
import '../../backup/application/backup_package_codec.dart';
import '../../backup/application/local_data_backup_service.dart';
import '../application/in_memory_home_dashboard_repository.dart';
import '../domain/home_dashboard_repository.dart';
import '../domain/home_dashboard_snapshot.dart';
import '../../study/application/local_answer_record_repository.dart';
import '../../study/application/local_word_learning_progress_repository.dart';
import '../../study/application/pronunciation_player.dart';
import '../../study/application/study_answer_evaluator.dart';
import '../../study/application/study_progress_updater.dart';
import '../../study/domain/answer_record.dart';
import '../../study/domain/answer_record_repository.dart';
import '../../study/domain/study_question.dart';
import '../../study/domain/word_learning_progress.dart';
import '../../study/domain/word_learning_progress_repository.dart';
import '../../word_book/application/csv_word_book_importer.dart';
import '../../word_book/application/local_learning_word_book_selection_repository.dart';
import '../../word_book/application/local_word_book_repository.dart';
import '../../word_book/domain/learning_word_book_selection_repository.dart';
import '../../word_book/domain/word_book.dart';
import '../../word_book/domain/word_book_repository.dart';

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
    this.adventureRepository,
    this.answerRecordRepository,
    this.wordLearningProgressRepository,
    this.wordBookRepository,
    this.learningWordBookSelectionRepository,
    this.pronunciationPlayer,
  });

  final HomeDashboardRepository dashboardRepository;
  final AdventureRepository? adventureRepository;
  final AnswerRecordRepository? answerRecordRepository;
  final WordLearningProgressRepository? wordLearningProgressRepository;
  final WordBookRepository? wordBookRepository;
  final LearningWordBookSelectionRepository?
      learningWordBookSelectionRepository;
  final PronunciationPlayer? pronunciationPlayer;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _sessionController = AdventureSessionController();

  late final HomeDashboardSnapshot _dashboard;
  late final AdventureRepository _adventureRepository;
  late final AnswerRecordRepository _answerRecordRepository;
  late final WordLearningProgressRepository _wordLearningProgressRepository;
  late final WordBookRepository _wordBookRepository;
  late final LearningWordBookSelectionRepository
      _learningWordBookSelectionRepository;
  late final PronunciationPlayer _pronunciationPlayer;
  late String _selectedChildId;
  late AdventureDashboardSnapshot _adventure;
  AdventureLevel? _activeLevel;
  _HomeTab _selectedTab = _HomeTab.today;
  bool _isStudying = false;
  bool _isComplete = false;
  bool _isParentMode = false;

  @override
  void initState() {
    super.initState();
    _adventureRepository =
        widget.adventureRepository ?? LocalAdventureRepository();
    _answerRecordRepository =
        widget.answerRecordRepository ?? LocalAnswerRecordRepository();
    _wordLearningProgressRepository = widget.wordLearningProgressRepository ??
        LocalWordLearningProgressRepository();
    _wordBookRepository =
        widget.wordBookRepository ?? LocalWordBookRepository();
    _learningWordBookSelectionRepository =
        widget.learningWordBookSelectionRepository ??
            LocalLearningWordBookSelectionRepository();
    _pronunciationPlayer =
        widget.pronunciationPlayer ?? createDefaultPronunciationPlayer();
    final referenceDate = DateTime.now();
    _dashboard = widget.dashboardRepository.loadDashboard(
      referenceDate: referenceDate,
    );
    _selectedChildId = _dashboard.children.first.id;
    _adventure = _adventureRepository.loadAdventure(
      childId: _selectedChildId,
      referenceDate: referenceDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentChild = _currentChild;

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
                    _adventureRepository.saveAdventure(_adventure);
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
                answerRecordRepository: _answerRecordRepository,
                wordLearningProgressRepository: _wordLearningProgressRepository,
                wordBooks: _wordBookRepository.loadWordBooks(),
                selectedWordBookId: _selectedWordBook?.id,
                pronunciationPlayer: _pronunciationPlayer,
                onClose: () {
                  setState(() {
                    _isStudying = false;
                  });
                },
                onComplete: () {
                  setState(() {
                    _adventure =
                        _sessionController.completeCurrentLevel(_adventure);
                    _adventureRepository.saveAdventure(_adventure);
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
          isParentMode: _isParentMode,
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
      _HomeTab.wordBook => _WordBookTabView(
          wordBooks: _wordBookRepository.loadWordBooks(),
          selectedWordBookId: _selectedWordBook?.id,
          onImportCsv: _importWordBookFromCsv,
        ),
      _HomeTab.settings => _SettingsTabView(
          currentChild: currentChild,
          children: _dashboard.children,
          isParentMode: _isParentMode,
          selectedWordBookName: _selectedWordBook?.name ?? '尚未选择词表',
          onSelectLearningWordBook: _openLearningWordBookSwitcher,
          onSwitchIdentity: _openIdentitySwitcher,
          onManageData: _openDataManagement,
        ),
    };
  }

  WordBook? get _selectedWordBook {
    final wordBooks = _wordBookRepository.loadWordBooks();
    if (wordBooks.isEmpty) {
      return null;
    }

    final savedWordBookId = _learningWordBookSelectionRepository
        .loadSelectedWordBookId(childId: _selectedChildId);
    for (final wordBook in wordBooks) {
      if (wordBook.id == savedWordBookId) {
        return wordBook;
      }
    }

    for (final wordBook in wordBooks) {
      if (wordBook.stageLabel == _currentChild.gradeLabel) {
        return wordBook;
      }
    }

    return wordBooks.first;
  }

  ChildDashboardSnapshot get _currentChild {
    return _dashboard.children.firstWhere(
      (child) => child.id == _selectedChildId,
      orElse: () => _dashboard.children.first,
    );
  }

  void _selectIdentity({
    required String childId,
    required bool isParentMode,
  }) {
    setState(() {
      _selectedChildId = childId;
      _isParentMode = isParentMode;
      _activeLevel = null;
      _isStudying = false;
      _isComplete = false;
      _adventure = _adventureRepository.loadAdventure(
        childId: childId,
        referenceDate: DateTime.now(),
      );
    });
  }

  Future<void> _openIdentitySwitcher() async {
    await showDialog<void>(
      context: context,
      builder: (context) => _IdentitySwitcherDialog(
        children: _dashboard.children,
        selectedChildId: _selectedChildId,
        isParentMode: _isParentMode,
        onSelectChild: (childId) {
          Navigator.of(context).pop();
          _selectIdentity(childId: childId, isParentMode: false);
        },
        onSelectParent: () {
          Navigator.of(context).pop();
          _selectIdentity(childId: _selectedChildId, isParentMode: true);
        },
      ),
    );
  }

  Future<void> _openLearningWordBookSwitcher() async {
    await showDialog<void>(
      context: context,
      builder: (context) => _LearningWordBookDialog(
        wordBooks: _wordBookRepository.loadWordBooks(),
        selectedWordBookId: _selectedWordBook?.id,
        onSelect: (wordBookId) {
          _learningWordBookSelectionRepository.saveSelectedWordBookId(
            childId: _selectedChildId,
            wordBookId: wordBookId,
          );
          Navigator.of(context).pop();
          setState(() {});
        },
      ),
    );
  }

  Future<void> _openDataManagement() async {
    await showDialog<void>(
      context: context,
      builder: (context) => _DataManagementDialog(
        service: LocalDataBackupService(
          wordBookRepository: _wordBookRepository,
          answerRecordRepository: _answerRecordRepository,
          wordLearningProgressRepository: _wordLearningProgressRepository,
          adventureRepository: _adventureRepository is LocalAdventureRepository
              ? _adventureRepository
              : null,
          learningWordBookSelectionRepository:
              _learningWordBookSelectionRepository
                      is LocalLearningWordBookSelectionRepository
                  ? _learningWordBookSelectionRepository
                  : null,
        ),
        onDataChanged: () {
          if (mounted) {
            setState(() {});
          }
        },
      ),
    );
  }

  Future<void> _importWordBookFromCsv() async {
    final formData = await showDialog<_CsvImportFormData>(
      context: context,
      builder: (context) => const _CsvImportDialog(),
    );
    if (formData == null || !mounted) {
      return;
    }

    final importedCount = _wordBookRepository
        .loadWordBooks()
        .where((wordBook) => !wordBook.isBuiltIn)
        .length;
    final result = const CsvWordBookImporter().import(
      id: 'csv-import-${importedCount + 1}',
      name: formData.name.trim().isEmpty ? 'CSV 导入词表' : formData.name.trim(),
      stageLabel: '自定义',
      csvText: formData.csvText,
    );

    if (!mounted) {
      return;
    }
    if (!result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errors.join('\n'))),
      );
      return;
    }

    _wordBookRepository.saveImportedWordBook(result.wordBook!);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已导入 ${result.wordBook!.wordCount} 个单词')),
    );
  }
}

class _TodayTabView extends StatelessWidget {
  const _TodayTabView({
    required this.currentChild,
    required this.adventure,
    required this.isParentMode,
    required this.onContinue,
  });

  final ChildDashboardSnapshot currentChild;
  final AdventureDashboardSnapshot adventure;
  final bool isParentMode;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: _tabContentPadding,
      children: [
        _Header(
          title: '词途',
          eyebrow: '每天一小步，单词走得稳',
          trailing: _LearnerPill(name: isParentMode ? '家长' : currentChild.name),
        ),
        const SizedBox(height: 28),
        _TodayTaskCard(
          adventure: adventure,
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
    this.trailing,
  });

  final String title;
  final String eyebrow;
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
            const _CircleIcon(
              width: 58,
              height: 58,
              icon: Icons.person_outline_rounded,
            ),
      ],
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({
    required this.width,
    required this.height,
    required this.icon,
  });

  final double width;
  final double height;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: const Color(0xFF2F856F),
        size: 30,
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 58,
            height: 58,
            child: Icon(
              icon,
              color: const Color(0xFF2F856F),
              size: 30,
            ),
          ),
        ),
      ),
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
    required this.adventure,
    required this.onContinue,
  });

  final AdventureDashboardSnapshot adventure;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final currentLevel = adventure.currentLevel;
    final completedLevels = adventure.levels
        .where((level) => level.status == AdventureLevelStatus.completed)
        .length;
    final totalLevels = adventure.levels.isEmpty ? 1 : adventure.levels.length;
    final progress = completedLevels / totalLevels;
    final progressPercent = (progress * 100).round();
    final questionCount =
        currentLevel.questionCount <= 0 ? 1 : currentLevel.questionCount;
    final taskTitle = currentLevel.type == AdventureLevelType.chestSettlement
        ? '准备打开今日宝箱'
        : '当前关卡还剩 $questionCount 题';

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
                      taskTitle,
                      style: const TextStyle(
                        color: Color(0xFF111114),
                        fontSize: 30,
                        height: 1.12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '下一组：${currentLevel.title} · ${currentLevel.subtitle}',
                      style: const TextStyle(
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
              value: progress,
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
    super.key,
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
  const _WordBookTabView({
    required this.wordBooks,
    required this.selectedWordBookId,
    required this.onImportCsv,
  });

  final List<WordBook> wordBooks;
  final String? selectedWordBookId;
  final VoidCallback onImportCsv;

  @override
  Widget build(BuildContext context) {
    final totalWordCount = wordBooks.fold<int>(
      0,
      (total, wordBook) => total + wordBook.wordCount,
    );
    final importedWordBooks = [
      for (final wordBook in wordBooks)
        if (!wordBook.isBuiltIn) wordBook,
    ];
    final currentWordBook = _selectedWordBook(wordBooks, selectedWordBookId);

    return ListView(
      padding: _tabContentPadding,
      children: [
        _Header(
          title: '词表',
          eyebrow: currentWordBook?.name ?? '尚未选择词表',
          trailing: _CircleIconButton(
            key: const ValueKey('word_book_import_button'),
            icon: Icons.add_rounded,
            tooltip: '导入 CSV 词表',
            onTap: onImportCsv,
          ),
        ),
        const SizedBox(height: 28),
        const _SearchBox(label: '搜索单词、释义或标签'),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                value: '$totalWordCount',
                label: '词表总量',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                value: '${importedWordBooks.length}',
                label: '导入词表',
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        const _SectionTitle('分类'),
        const SizedBox(height: 14),
        _GroupedList(
          children: [
            _RouteRow(
              icon: Icons.layers_rounded,
              iconColor: const Color(0xFF2F856F),
              iconBackground: const Color(0xFFE5F8EC),
              title: currentWordBook?.name ?? '当前词表',
              subtitle: currentWordBook == null
                  ? '暂无词表'
                  : '${currentWordBook.wordCount} 个单词 · ${currentWordBook.stageLabel}',
            ),
            for (final wordBook in importedWordBooks)
              _RouteRow(
                icon: Icons.upload_file_rounded,
                iconColor: const Color(0xFF5856D6),
                iconBackground: const Color(0xFFECEBFF),
                title: wordBook.name,
                subtitle: '${wordBook.wordCount} 个单词 · ${wordBook.stageLabel}',
              ),
            const _RouteRow(
              icon: Icons.warning_amber_rounded,
              iconColor: Color(0xFFFF9500),
              iconBackground: Color(0xFFFFF2D9),
              title: '错词复习',
              subtitle: '拼写 6 个 · 听音 4 个 · 释义 2 个',
            ),
          ],
        ),
        const SizedBox(height: 28),
        const _SectionTitle('最近练过'),
        const SizedBox(height: 14),
        const _GroupedList(
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

  WordBook? _selectedWordBook(List<WordBook> wordBooks, String? wordBookId) {
    for (final wordBook in wordBooks) {
      if (wordBook.id == wordBookId) {
        return wordBook;
      }
    }
    return wordBooks.isEmpty ? null : wordBooks.first;
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

class _CsvImportFormData {
  const _CsvImportFormData({
    required this.name,
    required this.csvText,
  });

  final String name;
  final String csvText;
}

class _CsvImportDialog extends StatefulWidget {
  const _CsvImportDialog();

  @override
  State<_CsvImportDialog> createState() => _CsvImportDialogState();
}

class _CsvImportDialogState extends State<_CsvImportDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _csvController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'CSV 导入词表');
    _csvController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _csvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('导入 CSV 词表'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const ValueKey('word_book_import_name_input'),
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '词表名称',
                  hintText: '例如：海洋主题词表',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const ValueKey('word_book_import_csv_input'),
                controller: _csvController,
                minLines: 8,
                maxLines: 12,
                decoration: const InputDecoration(
                  alignLabelWithHint: true,
                  labelText: 'CSV 内容',
                  hintText: '单词,中文释义\nocean,海洋\nriver,河流',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          key: const ValueKey('word_book_import_submit'),
          onPressed: () {
            Navigator.of(context).pop(
              _CsvImportFormData(
                name: _nameController.text,
                csvText: _csvController.text,
              ),
            );
          },
          child: const Text('导入'),
        ),
      ],
    );
  }
}

class _DataManagementDialog extends StatelessWidget {
  const _DataManagementDialog({
    required this.service,
    required this.onDataChanged,
  });

  final LocalDataBackupService service;
  final VoidCallback onDataChanged;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('数据管理'),
      content: const SizedBox(
        width: 360,
        child: Text('管理本地导入词表与学习记录，可用于迁移设备或重新开始练习。'),
      ),
      actions: [
        TextButton(
          key: const ValueKey('data_clear_records_button'),
          onPressed: () async {
            final confirmed = await _confirmDangerousAction(
              context: context,
              title: '确认清空学习记录',
              message: '这会删除所有本地答题记录，但不会删除导入词表。清空后错词和薄弱点会重新开始累计。',
              confirmKey: const ValueKey('confirm_clear_records_button'),
              confirmLabel: '确认清空',
            );
            if (!confirmed || !context.mounted) {
              return;
            }
            service.clearLearningRecords();
            onDataChanged();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('已清空本地学习记录')),
            );
          },
          child: const Text('清空学习记录'),
        ),
        TextButton(
          key: const ValueKey('data_import_button'),
          onPressed: () => _showImportDialog(context),
          child: const Text('导入备份'),
        ),
        FilledButton(
          key: const ValueKey('data_export_button'),
          onPressed: () {
            final backupJson = service.exportBackup();
            Navigator.of(context).pop();
            showDialog<void>(
              context: context,
              builder: (context) => _BackupExportDialog(backupJson: backupJson),
            );
          },
          child: const Text('导出备份'),
        ),
      ],
    );
  }

  Future<void> _showImportDialog(BuildContext context) async {
    final jsonText = await showDialog<String>(
      context: context,
      builder: (context) => const _BackupImportDialog(),
    );
    if (jsonText == null) {
      return;
    }
    if (!context.mounted) {
      return;
    }

    final confirmed = await _confirmDangerousAction(
      context: context,
      title: '确认导入备份',
      message: '导入备份会覆盖当前导入词表和学习记录。建议先导出当前数据后再继续。',
      confirmKey: const ValueKey('confirm_import_backup_button'),
      confirmLabel: '确认导入',
    );
    if (!confirmed) {
      return;
    }

    try {
      service.importBackup(jsonText);
      onDataChanged();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('备份已导入')),
        );
      }
    } on BackupPackageFormatException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    }
  }

  Future<bool> _confirmDangerousAction({
    required BuildContext context,
    required String title,
    required String message,
    required Key confirmKey,
    required String confirmLabel,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            key: const ValueKey('confirm_cancel_button'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            key: confirmKey,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}

class _BackupExportDialog extends StatelessWidget {
  const _BackupExportDialog({required this.backupJson});

  final String backupJson;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('导出备份'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: SelectableText(backupJson),
        ),
      ),
      actions: [
        TextButton.icon(
          key: const ValueKey('data_copy_backup_button'),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: backupJson));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('备份 JSON 已复制')),
            );
          },
          icon: const Icon(Icons.copy_rounded),
          label: const Text('一键复制'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}

class _BackupImportDialog extends StatefulWidget {
  const _BackupImportDialog();

  @override
  State<_BackupImportDialog> createState() => _BackupImportDialogState();
}

class _BackupImportDialogState extends State<_BackupImportDialog> {
  late final TextEditingController _jsonController;

  @override
  void initState() {
    super.initState();
    _jsonController = TextEditingController();
  }

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('导入备份'),
      content: SizedBox(
        width: 360,
        child: TextField(
          key: const ValueKey('data_import_json_input'),
          controller: _jsonController,
          minLines: 10,
          maxLines: 14,
          decoration: const InputDecoration(
            alignLabelWithHint: true,
            labelText: '备份 JSON',
            border: OutlineInputBorder(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          key: const ValueKey('data_import_submit'),
          onPressed: () => Navigator.of(context).pop(_jsonController.text),
          child: const Text('导入'),
        ),
      ],
    );
  }
}

class _SettingsTabView extends StatelessWidget {
  const _SettingsTabView({
    required this.currentChild,
    required this.children,
    required this.isParentMode,
    required this.selectedWordBookName,
    required this.onSelectLearningWordBook,
    required this.onSwitchIdentity,
    required this.onManageData,
  });

  final ChildDashboardSnapshot currentChild;
  final List<ChildDashboardSnapshot> children;
  final bool isParentMode;
  final String selectedWordBookName;
  final VoidCallback onSelectLearningWordBook;
  final VoidCallback onSwitchIdentity;
  final VoidCallback onManageData;

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
        _ProfileCard(
          name: isParentMode ? '家长模式' : currentChild.name,
          avatar: isParentMode ? '家' : _firstCharacter(currentChild.name),
          subtitle: isParentMode ? '家长看板' : '孩子模式 · ${currentChild.gradeLabel}',
        ),
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
              subtitle: isParentMode ? '家长模式' : currentChild.name,
              onTap: onSwitchIdentity,
              key: const ValueKey('settings_switch_identity'),
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
        const _SectionTitle('学习设置'),
        const SizedBox(height: 14),
        _GroupedList(
          children: [
            _RouteRow(
              icon: Icons.menu_book_rounded,
              iconColor: const Color(0xFF2F856F),
              iconBackground: const Color(0xFFE5F8EC),
              title: '默认学习词表',
              subtitle: selectedWordBookName,
              onTap: onSelectLearningWordBook,
              key: const ValueKey('settings_learning_word_book'),
            ),
          ],
        ),
        const SizedBox(height: 28),
        const _SectionTitle('数据'),
        const SizedBox(height: 14),
        _GroupedList(
          children: [
            _RouteRow(
              icon: Icons.backup_rounded,
              iconColor: const Color(0xFF2F856F),
              iconBackground: const Color(0xFFE5F8EC),
              title: '数据管理',
              subtitle: '导出 / 导入 / 清空学习记录',
              onTap: onManageData,
              key: const ValueKey('settings_data_management'),
            ),
            const _RouteRow(
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

  String _firstCharacter(String value) {
    if (value.isEmpty) {
      return '?';
    }
    return value.substring(0, 1);
  }
}

class _IdentitySwitcherDialog extends StatelessWidget {
  const _IdentitySwitcherDialog({
    required this.children,
    required this.selectedChildId,
    required this.isParentMode,
    required this.onSelectChild,
    required this.onSelectParent,
  });

  final List<ChildDashboardSnapshot> children;
  final String selectedChildId;
  final bool isParentMode;
  final ValueChanged<String> onSelectChild;
  final VoidCallback onSelectParent;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('切换身份'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final child in children)
            ListTile(
              key: ValueKey('identity_${child.id}'),
              leading: const Icon(Icons.face_rounded),
              title: Text(child.name),
              subtitle: Text(child.gradeLabel),
              trailing: !isParentMode && child.id == selectedChildId
                  ? const Icon(Icons.check_rounded)
                  : null,
              onTap: () => onSelectChild(child.id),
            ),
          ListTile(
            key: const ValueKey('identity_parent'),
            leading: const Icon(Icons.admin_panel_settings_rounded),
            title: const Text('家长模式'),
            subtitle: const Text('查看设置和数据管理'),
            trailing: isParentMode ? const Icon(Icons.check_rounded) : null,
            onTap: onSelectParent,
          ),
        ],
      ),
    );
  }
}

class _LearningWordBookDialog extends StatelessWidget {
  const _LearningWordBookDialog({
    required this.wordBooks,
    required this.selectedWordBookId,
    required this.onSelect,
  });

  final List<WordBook> wordBooks;
  final String? selectedWordBookId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('默认学习词表'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final wordBook in wordBooks)
            ListTile(
              key: ValueKey('learning_word_book_${wordBook.id}'),
              leading: Icon(
                wordBook.isBuiltIn
                    ? Icons.school_rounded
                    : Icons.upload_file_rounded,
              ),
              title: Text(wordBook.name),
              subtitle:
                  Text('${wordBook.wordCount} 个单词 · ${wordBook.stageLabel}'),
              trailing: wordBook.id == selectedWordBookId
                  ? const Icon(Icons.check_rounded)
                  : null,
              onTap: () => onSelect(wordBook.id),
            ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.avatar,
    required this.subtitle,
  });

  final String name;
  final String avatar;
  final String subtitle;

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
            child: Text(
              avatar,
              style: const TextStyle(
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
                Text(
                  subtitle,
                  style: const TextStyle(
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
    required this.wordLearningProgressRepository,
    required this.wordBooks,
    required this.selectedWordBookId,
    required this.pronunciationPlayer,
    required this.onClose,
    required this.onComplete,
  });

  final String childId;
  final AdventureLevel level;
  final AnswerRecordRepository answerRecordRepository;
  final WordLearningProgressRepository wordLearningProgressRepository;
  final List<WordBook> wordBooks;
  final String? selectedWordBookId;
  final PronunciationPlayer pronunciationPlayer;
  final VoidCallback onClose;
  final VoidCallback onComplete;

  @override
  State<_StudyQuizScreen> createState() => _StudyQuizScreenState();
}

class _StudyQuizScreenState extends State<_StudyQuizScreen> {
  static const _answerEvaluator = StudyAnswerEvaluator();
  static const _progressUpdater = StudyProgressUpdater();

  late final List<AnswerRecord> _answerRecordsSnapshot;
  late final List<WordLearningProgress> _learningProgressSnapshot;
  late final List<int> _questionQueue = List<int>.generate(
    widget.level.questionCount <= 0 ? 1 : widget.level.questionCount,
    (index) => index,
  );
  int _queueCursor = 0;
  DateTime _questionStartedAt = DateTime.now();
  String? _selectedAnswer;
  bool _showFeedback = false;

  @override
  void initState() {
    super.initState();
    _answerRecordsSnapshot = widget.answerRecordRepository.loadRecords(
      childId: widget.childId,
    );
    _learningProgressSnapshot = widget.wordLearningProgressRepository
        .loadProgresses(childId: widget.childId);
  }

  @override
  Widget build(BuildContext context) {
    final questionIndex = _questionQueue[_queueCursor];
    final quiz = const AdventureLevelQuizBuilder().buildForLevel(
      widget.level,
      questionIndex: questionIndex,
      wordBooks: widget.wordBooks,
      answerRecords: _answerRecordsSnapshot,
      learningProgresses: _learningProgressSnapshot,
      selectedWordBookId: widget.selectedWordBookId,
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
              onTap: () => widget.pronunciationPlayer.speak(quiz.prompt),
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
              _QuestionPrompt(
                quiz: quiz,
                onPlayPronunciation: () =>
                    widget.pronunciationPlayer.speak(quiz.prompt),
              ),
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
              final previousProgress =
                  widget.wordLearningProgressRepository.loadProgress(
                childId: widget.childId,
                wordId: quiz.wordId,
              );
              final nextProgress = _progressUpdater.applyAnswer(
                progress: previousProgress ??
                    WordLearningProgress(
                      childId: widget.childId,
                      wordId: quiz.wordId,
                      masteryLevel: 0,
                      consecutiveMistakes: 0,
                      nextReviewAt: answeredAt,
                      updatedAt: answeredAt,
                    ),
                answer: record,
              );
              widget.wordLearningProgressRepository.saveProgress(nextProgress);

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
  const _QuestionPrompt({
    required this.quiz,
    required this.onPlayPronunciation,
  });

  final AdventureLevelQuiz quiz;
  final VoidCallback onPlayPronunciation;

  @override
  Widget build(BuildContext context) {
    if (quiz.usesAudioPrompt) {
      return GestureDetector(
        onTap: onPlayPronunciation,
        child: const CircleAvatar(
          radius: 48,
          backgroundColor: Color(0xFFE5F3EE),
          child: Icon(
            Icons.volume_up_rounded,
            color: Color(0xFF2F856F),
            size: 54,
          ),
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
