import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../adventure/application/adventure_daily_planner.dart';
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
import '../../child_profile/application/in_memory_child_profile_repository.dart';
import '../../child_profile/domain/child_profile.dart';
import '../../child_profile/domain/child_profile_repository.dart';
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

String _firstCharacter(String value) {
  if (value.isEmpty) {
    return '?';
  }
  return value.substring(0, 1);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.dashboardRepository,
    this.childProfileRepository,
    this.adventureRepository,
    this.answerRecordRepository,
    this.wordLearningProgressRepository,
    this.wordBookRepository,
    this.learningWordBookSelectionRepository,
    this.pronunciationPlayer,
  });

  final HomeDashboardRepository? dashboardRepository;
  final ChildProfileRepository? childProfileRepository;
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
  static const _dailyPlanner = AdventureDailyPlanner();

  late HomeDashboardSnapshot _dashboard;
  late final HomeDashboardRepository _dashboardRepository;
  late final ChildProfileRepository _childProfileRepository;
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
  bool _isPetFedInCompletion = false;
  _StudySessionSummary? _completionSummary;
  String? _selectedParentDetailChildId;
  String? _activeStudyChildId;
  String? _activeStudySelectedWordBookId;
  bool _activeStudyCompletesAdventure = true;

  @override
  void initState() {
    super.initState();
    _answerRecordRepository =
        widget.answerRecordRepository ?? LocalAnswerRecordRepository();
    _wordLearningProgressRepository = widget.wordLearningProgressRepository ??
        LocalWordLearningProgressRepository();
    _wordBookRepository =
        widget.wordBookRepository ?? LocalWordBookRepository();
    _childProfileRepository =
        widget.childProfileRepository ?? const InMemoryChildProfileRepository();
    _dashboardRepository = widget.dashboardRepository ??
        InMemoryHomeDashboardRepository(
          childProfileRepository: _childProfileRepository,
          wordBookRepository: _wordBookRepository,
        );
    _learningWordBookSelectionRepository =
        widget.learningWordBookSelectionRepository ??
            LocalLearningWordBookSelectionRepository();
    _adventureRepository =
        widget.adventureRepository ?? LocalAdventureRepository();
    _pronunciationPlayer =
        widget.pronunciationPlayer ?? createDefaultPronunciationPlayer();
    final referenceDate = DateTime.now();
    _dashboard = _loadDashboard(referenceDate);
    _selectedChildId =
        _dashboard.children.isEmpty ? '' : _dashboard.children.first.id;
    if (_selectedChildId.isNotEmpty) {
      _adventure = _loadPlannedAdventure(
        childId: _selectedChildId,
        referenceDate: referenceDate,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dashboard.children.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: _OnboardingScreen(
                wordBooks: _wordBookRepository.loadBuiltInWordBooks(),
                onComplete: _completeOnboarding,
              ),
            ),
          ),
        ),
      );
    }

    final currentChild = _currentChild;

    if (_isComplete) {
      return Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: _StudyCompleteScreen(
                childName: currentChild.name,
                adventure: _adventure,
                summary: _completionSummary ??
                    _StudySessionSummary.empty(
                      level: _activeLevel ?? _adventure.currentLevel,
                    ),
                isPetFed: _isPetFedInCompletion,
                onFeedPet: () {
                  setState(() {
                    final summary = _completionSummary ??
                        _StudySessionSummary.empty(
                          level: _activeLevel ?? _adventure.currentLevel,
                        );
                    _adventure = _sessionController.feedPetWithReward(
                      _adventure,
                      reward: summary.reward,
                      fedAt: DateTime.now(),
                    );
                    _adventureRepository.saveAdventure(_adventure);
                    _isPetFedInCompletion = true;
                  });
                },
                onReturnHome: () {
                  setState(() {
                    _isStudying = false;
                    _isComplete = false;
                    _isPetFedInCompletion = false;
                    _completionSummary = null;
                    _selectedTab = _HomeTab.today;
                  });
                },
                onReview: () {
                  setState(() {
                    _isComplete = false;
                    _isPetFedInCompletion = false;
                    _completionSummary = null;
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
                childId: _activeStudyChildId ?? currentChild.id,
                level: _activeLevel ?? _adventure.currentLevel,
                answerRecordRepository: _answerRecordRepository,
                wordLearningProgressRepository: _wordLearningProgressRepository,
                wordBooks: _wordBookRepository.loadWordBooks(),
                selectedWordBookId:
                    _activeStudySelectedWordBookId ?? _selectedWordBook?.id,
                pronunciationPlayer: _pronunciationPlayer,
                onClose: () {
                  setState(() {
                    _isStudying = false;
                    _clearActiveStudyOverride();
                  });
                },
                onComplete: (summary) {
                  setState(() {
                    if (_activeStudyCompletesAdventure) {
                      _adventure = _planAdventureSnapshot(
                        _sessionController.completeCurrentLevel(_adventure),
                      );
                      _adventureRepository.saveAdventure(_adventure);
                    }
                    _isStudying = false;
                    _isComplete = _activeStudyCompletesAdventure;
                    _completionSummary =
                        _activeStudyCompletesAdventure ? summary : null;
                    _isPetFedInCompletion = false;
                    _clearActiveStudyOverride();
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
                  if (tab != _HomeTab.today) {
                    _selectedParentDetailChildId = null;
                  }
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
      _HomeTab.today => _isParentMode
          ? _buildParentTodayTab()
          : _TodayTabView(
              currentChild: currentChild,
              adventure: _adventure,
              onContinue: () {
                setState(() {
                  _activeLevel = _adventure.currentLevel;
                  _isStudying = true;
                  _activeStudyChildId = null;
                  _activeStudySelectedWordBookId = null;
                  _activeStudyCompletesAdventure = true;
                  _isPetFedInCompletion = false;
                  _completionSummary = null;
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
              _activeStudyChildId = null;
              _activeStudySelectedWordBookId = null;
              _activeStudyCompletesAdventure = true;
              _isPetFedInCompletion = false;
              _completionSummary = null;
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

  HomeDashboardSnapshot _loadDashboard(DateTime referenceDate) {
    return _dashboardRepository.loadDashboard(referenceDate: referenceDate);
  }

  void _completeOnboarding(_OnboardingProfile profile) {
    final createdAt = DateTime.now();
    final child = ChildProfile(
      id: 'child-${createdAt.microsecondsSinceEpoch}',
      name: profile.childName,
      gradeLabel: profile.wordBook.stageLabel,
      avatarSeed: _firstCharacter(profile.childName),
      createdAt: createdAt,
    );
    _childProfileRepository.replaceChildren([child]);
    _learningWordBookSelectionRepository.saveSelectedWordBookId(
      childId: child.id,
      wordBookId: profile.wordBook.id,
    );
    final adventure = _loadPlannedAdventure(
      childId: child.id,
      referenceDate: createdAt,
    );
    final adoptedAdventure = _adoptPet(
      adventure: adventure,
      petName: profile.petName,
    );
    _adventureRepository.saveAdventure(adoptedAdventure);

    setState(() {
      _dashboard = _loadDashboard(createdAt);
      _selectedChildId = child.id;
      _adventure = adoptedAdventure;
      _selectedTab = _HomeTab.today;
    });
  }

  AdventureDashboardSnapshot _adoptPet({
    required AdventureDashboardSnapshot adventure,
    required String petName,
  }) {
    return AdventureDashboardSnapshot(
      childId: adventure.childId,
      themeTitle: adventure.themeTitle,
      currentNodeTitle: adventure.currentNodeTitle,
      starsEarned: adventure.starsEarned,
      starsTarget: adventure.starsTarget,
      chestProgress: adventure.chestProgress,
      levels: adventure.levels,
      pet: PetProfile(
        childId: adventure.pet.childId,
        petId: adventure.pet.petId,
        name: petName,
        level: adventure.pet.level,
        growthPoints: adventure.pet.growthPoints,
        growthTarget: adventure.pet.growthTarget,
        satiety: adventure.pet.satiety,
        mood: adventure.pet.mood,
        equippedDecorationIds: adventure.pet.equippedDecorationIds,
        unlockedDecorationIds: adventure.pet.unlockedDecorationIds,
        lastFedAt: adventure.pet.lastFedAt,
      ),
    );
  }

  Widget _buildParentTodayTab() {
    final summaries = _parentChildSummaries();
    _ParentChildSummary? selectedSummary;
    for (final summary in summaries) {
      if (summary.child.id == _selectedParentDetailChildId) {
        selectedSummary = summary;
        break;
      }
    }
    if (selectedSummary != null) {
      return _ParentChildDetailView(
        summary: selectedSummary,
        onReviewMistakes: () => _startParentMistakeReview(selectedSummary!),
        onBack: () {
          setState(() {
            _selectedParentDetailChildId = null;
          });
        },
      );
    }

    return _ParentDashboardTabView(
      children: _dashboard.children,
      summaries: summaries,
      onSelectChild: (summary) {
        setState(() {
          _selectedParentDetailChildId = summary.child.id;
        });
      },
      onManageData: _openDataManagement,
    );
  }

  void _startParentMistakeReview(_ParentChildSummary summary) {
    if (summary.mistakeWords.isEmpty) {
      return;
    }
    setState(() {
      _selectedParentDetailChildId = summary.child.id;
      _activeLevel = AdventureLevel(
        id: '${summary.child.id}-parent-mistake-review',
        childId: summary.child.id,
        date: DateTime.now(),
        type: AdventureLevelType.mistakeBoss,
        title: '${summary.child.name}错词复习',
        subtitle: '${summary.mistakeWords.length} 题 · 专属错词',
        status: AdventureLevelStatus.current,
        questionCount: summary.mistakeWords.length,
        reward: const AdventureReward(),
      );
      _activeStudyChildId = summary.child.id;
      _activeStudySelectedWordBookId =
          _selectedWordBookForChild(summary.child.id)?.id;
      _activeStudyCompletesAdventure = false;
      _isStudying = true;
      _isComplete = false;
      _isPetFedInCompletion = false;
      _completionSummary = null;
    });
  }

  void _clearActiveStudyOverride() {
    _activeStudyChildId = null;
    _activeStudySelectedWordBookId = null;
    _activeStudyCompletesAdventure = true;
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
      _isPetFedInCompletion = false;
      _completionSummary = null;
      _selectedParentDetailChildId = null;
      _clearActiveStudyOverride();
      _adventure = _loadPlannedAdventure(
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
          setState(() {
            _adventure = _loadPlannedAdventure(
              childId: _selectedChildId,
              referenceDate: DateTime.now(),
            );
          });
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
          childProfileRepository: _childProfileRepository,
          children: _childProfileRepository.loadChildren(),
        ),
        onDataChanged: () {
          if (mounted) {
            setState(() {
              _adventure = _loadPlannedAdventure(
                childId: _selectedChildId,
                referenceDate: DateTime.now(),
              );
            });
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
    setState(() {
      _adventure = _loadPlannedAdventure(
        childId: _selectedChildId,
        referenceDate: DateTime.now(),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已导入 ${result.wordBook!.wordCount} 个单词')),
    );
  }

  AdventureDashboardSnapshot _loadPlannedAdventure({
    required String childId,
    required DateTime referenceDate,
  }) {
    final baseAdventure = _adventureRepository.loadAdventure(
      childId: childId,
      referenceDate: referenceDate,
    );
    return _planAdventureSnapshot(baseAdventure);
  }

  AdventureDashboardSnapshot _planAdventureSnapshot(
    AdventureDashboardSnapshot baseAdventure,
  ) {
    return _dailyPlanner.plan(
      snapshot: baseAdventure,
      wordBooks: _wordBookRepository.loadWordBooks(),
      learningProgresses: _wordLearningProgressRepository.loadProgresses(
        childId: baseAdventure.childId,
      ),
      selectedWordBookId: _selectedWordBookForChild(baseAdventure.childId)?.id,
    );
  }

  WordBook? _selectedWordBookForChild(String childId) {
    final wordBooks = _wordBookRepository.loadWordBooks();
    if (wordBooks.isEmpty) {
      return null;
    }

    final savedWordBookId = _learningWordBookSelectionRepository
        .loadSelectedWordBookId(childId: childId);
    for (final wordBook in wordBooks) {
      if (wordBook.id == savedWordBookId) {
        return wordBook;
      }
    }

    final child = _dashboard.children.firstWhere(
      (child) => child.id == childId,
      orElse: () => _dashboard.children.first,
    );
    for (final wordBook in wordBooks) {
      if (wordBook.stageLabel == child.gradeLabel) {
        return wordBook;
      }
    }

    return wordBooks.first;
  }

  List<_ParentChildSummary> _parentChildSummaries() {
    final referenceDate = DateTime.now();
    return [
      for (final child in _dashboard.children)
        _ParentChildSummary.from(
          child: child,
          adventure: _loadPlannedAdventure(
            childId: child.id,
            referenceDate: referenceDate,
          ),
          answerRecords: _answerRecordRepository.loadRecords(childId: child.id),
          learningProgresses:
              _wordLearningProgressRepository.loadProgresses(childId: child.id),
          wordBook: _selectedWordBookForChild(child.id),
          referenceDate: referenceDate,
        ),
    ];
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

class _OnboardingProfile {
  const _OnboardingProfile({
    required this.childName,
    required this.petName,
    required this.wordBook,
  });

  final String childName;
  final String petName;
  final WordBook wordBook;
}

class _OnboardingScreen extends StatefulWidget {
  const _OnboardingScreen({
    required this.wordBooks,
    required this.onComplete,
  });

  final List<WordBook> wordBooks;
  final ValueChanged<_OnboardingProfile> onComplete;

  @override
  State<_OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<_OnboardingScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _petNameController;
  String? _selectedWordBookId;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _petNameController = TextEditingController(text: '豆豆');
    _selectedWordBookId =
        widget.wordBooks.isEmpty ? null : widget.wordBooks.first.id;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _petNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedWordBook = _selectedWordBook;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
      children: [
        const _Header(
          title: '欢迎来到词途',
          eyebrow: '先设置学习资料',
          trailing: SizedBox.shrink(),
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '孩子资料',
                style: TextStyle(
                  color: Color(0xFF111114),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const ValueKey('onboarding_child_name_input'),
                controller: _nameController,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: '孩子昵称',
                  hintText: '例如：小明',
                  errorText: _errorText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onChanged: (_) {
                  if (_errorText != null) {
                    setState(() {
                      _errorText = null;
                    });
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '领养学习伙伴',
                style: TextStyle(
                  color: Color(0xFF111114),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '默认：豆豆',
                style: TextStyle(
                  color: Color(0xFF70727A),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const ValueKey('onboarding_pet_name_input'),
                controller: _petNameController,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: '宠物名字',
                  hintText: '不填则使用豆豆',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const _SectionTitle('选择学习词表'),
        const SizedBox(height: 14),
        for (final wordBook in widget.wordBooks) ...[
          _OnboardingWordBookCard(
            wordBook: wordBook,
            isSelected: wordBook.id == _selectedWordBookId,
            onTap: () {
              setState(() {
                _selectedWordBookId = wordBook.id;
              });
            },
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 16),
        SizedBox(
          height: 58,
          child: FilledButton.icon(
            key: const ValueKey('onboarding_start_button'),
            onPressed: selectedWordBook == null ? null : _submit,
            icon: const Icon(Icons.check_rounded),
            label: const Text('开始使用'),
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
    );
  }

  WordBook? get _selectedWordBook {
    for (final wordBook in widget.wordBooks) {
      if (wordBook.id == _selectedWordBookId) {
        return wordBook;
      }
    }
    return null;
  }

  void _submit() {
    final childName = _nameController.text.trim();
    if (childName.isEmpty) {
      setState(() {
        _errorText = '请输入孩子昵称';
      });
      return;
    }

    final wordBook = _selectedWordBook;
    if (wordBook == null) {
      return;
    }

    widget.onComplete(
      _OnboardingProfile(
        childName: childName,
        petName: _normalizedPetName,
        wordBook: wordBook,
      ),
    );
  }

  String get _normalizedPetName {
    final petName = _petNameController.text.trim();
    return petName.isEmpty ? '豆豆' : petName;
  }
}

class _OnboardingWordBookCard extends StatelessWidget {
  const _OnboardingWordBookCard({
    required this.wordBook,
    required this.isSelected,
    required this.onTap,
  });

  final WordBook wordBook;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: ValueKey('onboarding_word_book_${wordBook.id}'),
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(
                wordBook.isBuiltIn
                    ? Icons.school_rounded
                    : Icons.upload_file_rounded,
                color: const Color(0xFF2F856F),
                size: 30,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wordBook.name,
                      style: const TextStyle(
                        color: Color(0xFF111114),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${wordBook.wordCount} 个单词 · ${wordBook.stageLabel}',
                      style: const TextStyle(
                        color: Color(0xFF70727A),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isSelected
                    ? const Color(0xFF2F856F)
                    : const Color(0xFF9B9BA3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParentDashboardTabView extends StatelessWidget {
  const _ParentDashboardTabView({
    required this.children,
    required this.summaries,
    required this.onSelectChild,
    required this.onManageData,
  });

  final List<ChildDashboardSnapshot> children;
  final List<_ParentChildSummary> summaries;
  final ValueChanged<_ParentChildSummary> onSelectChild;
  final VoidCallback onManageData;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: _tabContentPadding,
      children: [
        const _Header(
          title: '家长看板',
          eyebrow: '孩子总览',
          trailing: _LearnerPill(name: '家长'),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                value: '${children.length}',
                label: '孩子档案',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                value: '${summaries.fold<int>(
                  0,
                  (sum, summary) => sum + summary.dueReviewCount,
                )}',
                label: '到期复习',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _BackupEntryCard(onTap: onManageData),
        const SizedBox(height: 24),
        const _SectionTitle('孩子总览'),
        const SizedBox(height: 14),
        for (final summary in summaries) ...[
          _ParentChildSummaryCard(
            summary: summary,
            onTap: () => onSelectChild(summary),
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _BackupEntryCard extends StatelessWidget {
  const _BackupEntryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F8EC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.backup_rounded,
                  color: Color(0xFF2F856F),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '导出 / 导入备份',
                      style: TextStyle(
                        color: Color(0xFF111114),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '迁移设备或保存本地学习数据',
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
        ),
      ),
    );
  }
}

class _ParentChildSummaryCard extends StatelessWidget {
  const _ParentChildSummaryCard({
    required this.summary,
    required this.onTap,
  });

  final _ParentChildSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: ValueKey('parent_child_card_${summary.child.id}'),
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2F856F),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _firstCharacter(summary.child.name),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.child.name,
                          style: const TextStyle(
                            color: Color(0xFF111114),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          summary.child.gradeLabel,
                          style: const TextStyle(
                            color: Color(0xFF70727A),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _ProgressBubble(label: '${summary.completionPercent}%'),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: summary.completion,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE2E2E8),
                  color: const Color(0xFF2F856F),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _CompactBadge(
                    label: '今日完成 ${summary.completionPercent}%',
                    icon: Icons.flag_rounded,
                    color: const Color(0xFF2F856F),
                    backgroundColor: const Color(0xFFE5F8EC),
                  ),
                  _CompactBadge(
                    label: '近 7 日正确率 ${summary.accuracyPercent}%',
                    icon: Icons.check_circle_rounded,
                    color: const Color(0xFF5856D6),
                    backgroundColor: const Color(0xFFECEBFF),
                  ),
                  _CompactBadge(
                    label: '到期复习 ${summary.dueReviewCount} 个',
                    icon: Icons.schedule_rounded,
                    color: const Color(0xFFFF9500),
                    backgroundColor: const Color(0xFFFFF2D9),
                  ),
                  _CompactBadge(
                    label: '高频错词 ${summary.frequentMistakeLabel}',
                    icon: Icons.warning_amber_rounded,
                    color: const Color(0xFFFF3B30),
                    backgroundColor: const Color(0xFFFFE9E7),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParentChildDetailView extends StatelessWidget {
  const _ParentChildDetailView({
    required this.summary,
    required this.onReviewMistakes,
    required this.onBack,
  });

  final _ParentChildSummary summary;
  final VoidCallback onReviewMistakes;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: _tabContentPadding,
      children: [
        _Header(
          title: '${summary.child.name}详情',
          eyebrow: summary.child.gradeLabel,
          trailing: IconButton.filledTonal(
            key: const ValueKey('parent_child_detail_back'),
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: '返回总览',
          ),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                value: '${summary.completionPercent}%',
                label: '今日完成',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                value: '${summary.accuracyPercent}%',
                label: '近 7 日正确率',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _TrendCard(points: summary.trendPoints),
        const SizedBox(height: 24),
        _MistakeWordCard(
          mistakeWords: summary.mistakeWords,
          onReviewMistakes: onReviewMistakes,
        ),
        const SizedBox(height: 24),
        _ReviewAdviceCard(advice: summary.reviewAdvice),
        const SizedBox(height: 24),
        _WordBookCompletionCard(summary: summary),
      ],
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.points});

  final List<_DailyAccuracyPoint> points;

  @override
  Widget build(BuildContext context) {
    return _InsightCard(
      title: '近 7 日趋势',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final point in points) ...[
            Expanded(child: _TrendColumn(point: point)),
            if (point != points.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _TrendColumn extends StatelessWidget {
  const _TrendColumn({required this.point});

  final _DailyAccuracyPoint point;

  @override
  Widget build(BuildContext context) {
    final barHeight = point.hasRecords ? 28 + point.accuracy * 54 : 12.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          point.accuracyLabel,
          style: const TextStyle(
            color: Color(0xFF70727A),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: barHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: point.hasRecords
                ? const Color(0xFF2F856F)
                : const Color(0xFFE2E2E8),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          point.dateLabel,
          style: const TextStyle(
            color: Color(0xFF111114),
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _MistakeWordCard extends StatelessWidget {
  const _MistakeWordCard({
    required this.mistakeWords,
    required this.onReviewMistakes,
  });

  final List<_MistakeWordSummary> mistakeWords;
  final VoidCallback onReviewMistakes;

  @override
  Widget build(BuildContext context) {
    return _InsightCard(
      title: '高频错词',
      child: mistakeWords.isEmpty
          ? const Text(
              '暂无错词',
              style: TextStyle(
                color: Color(0xFF70727A),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            )
          : Column(
              children: [
                for (final mistakeWord in mistakeWords) ...[
                  Material(
                    key: ValueKey('parent_mistake_word_${mistakeWord.wordId}'),
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: onReviewMistakes,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: _DetailRow(
                          icon: Icons.warning_amber_rounded,
                          iconColor: const Color(0xFFFF3B30),
                          label:
                              '${mistakeWord.spelling} · ${mistakeWord.count} 次',
                          trailing: const Icon(
                            Icons.play_arrow_rounded,
                            color: Color(0xFF2F856F),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (mistakeWord != mistakeWords.last)
                    const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}

class _ReviewAdviceCard extends StatelessWidget {
  const _ReviewAdviceCard({required this.advice});

  final String advice;

  @override
  Widget build(BuildContext context) {
    return _InsightCard(
      title: '复习建议',
      child: _DetailRow(
        icon: Icons.tips_and_updates_rounded,
        iconColor: const Color(0xFFFF9500),
        label: advice,
      ),
    );
  }
}

class _WordBookCompletionCard extends StatelessWidget {
  const _WordBookCompletionCard({required this.summary});

  final _ParentChildSummary summary;

  @override
  Widget build(BuildContext context) {
    return _InsightCard(
      title: '词表完成情况',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  summary.wordBookName,
                  style: const TextStyle(
                    color: Color(0xFF111114),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${summary.wordBookCompletionPercent}%',
                style: const TextStyle(
                  color: Color(0xFF2F856F),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: summary.wordBookCompletion,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E2E8),
              color: const Color(0xFF2F856F),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '已掌握 ${summary.masteredWordCount} / ${summary.wordBookWordCount}',
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

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF111114),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF111114),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 10),
          trailing!,
        ],
      ],
    );
  }
}

class _DailyAccuracyPoint {
  const _DailyAccuracyPoint({
    required this.date,
    required this.totalCount,
    required this.correctCount,
  });

  final DateTime date;
  final int totalCount;
  final int correctCount;

  bool get hasRecords {
    return totalCount > 0;
  }

  double get accuracy {
    if (!hasRecords) {
      return 0;
    }
    return correctCount / totalCount;
  }

  String get accuracyLabel {
    return hasRecords ? '${(accuracy * 100).round()}%' : '--';
  }

  String get dateLabel {
    return '${date.month}/${date.day}';
  }

  static _DailyAccuracyPoint fromRecords({
    required DateTime date,
    required List<AnswerRecord> records,
  }) {
    final recordsOfDay = [
      for (final record in records)
        if (_isSameDay(record.answeredAt, date)) record,
    ];
    return _DailyAccuracyPoint(
      date: date,
      totalCount: recordsOfDay.length,
      correctCount: recordsOfDay.where((record) => record.isCorrect).length,
    );
  }

  static bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}

class _MistakeWordSummary {
  const _MistakeWordSummary({
    required this.wordId,
    required this.spelling,
    required this.count,
  });

  final String wordId;
  final String spelling;
  final int count;
}

class _ParentChildSummary {
  const _ParentChildSummary({
    required this.child,
    required this.completion,
    required this.accuracyPercent,
    required this.dueReviewCount,
    required this.frequentMistakeLabel,
    required this.trendPoints,
    required this.mistakeWords,
    required this.reviewAdvice,
    required this.wordBookName,
    required this.wordBookWordCount,
    required this.masteredWordCount,
  });

  final ChildDashboardSnapshot child;
  final double completion;
  final int accuracyPercent;
  final int dueReviewCount;
  final String frequentMistakeLabel;
  final List<_DailyAccuracyPoint> trendPoints;
  final List<_MistakeWordSummary> mistakeWords;
  final String reviewAdvice;
  final String wordBookName;
  final int wordBookWordCount;
  final int masteredWordCount;

  int get completionPercent {
    return (completion * 100).round();
  }

  double get wordBookCompletion {
    if (wordBookWordCount <= 0) {
      return 0;
    }
    return masteredWordCount / wordBookWordCount;
  }

  int get wordBookCompletionPercent {
    return (wordBookCompletion * 100).round();
  }

  static _ParentChildSummary from({
    required ChildDashboardSnapshot child,
    required AdventureDashboardSnapshot adventure,
    required List<AnswerRecord> answerRecords,
    required List<WordLearningProgress> learningProgresses,
    required WordBook? wordBook,
    required DateTime referenceDate,
  }) {
    final studyMetrics = _TodayStudyMetrics.from(adventure);
    final recentRecords = _recentRecords(answerRecords, referenceDate);

    return _ParentChildSummary(
      child: child,
      completion: studyMetrics.progress,
      accuracyPercent: _accuracyPercent(recentRecords),
      dueReviewCount: _dueReviewCount(
        learningProgresses: learningProgresses,
        wordBook: wordBook,
        referenceDate: referenceDate,
      ),
      frequentMistakeLabel: _frequentMistakeLabel(
        answerRecords: recentRecords,
        wordBook: wordBook,
      ),
      trendPoints: _trendPoints(
        answerRecords: recentRecords,
        referenceDate: referenceDate,
      ),
      mistakeWords: _mistakeWords(
        answerRecords: recentRecords,
        wordBook: wordBook,
      ),
      reviewAdvice: _reviewAdvice(
        learningProgresses: learningProgresses,
        wordBook: wordBook,
        referenceDate: referenceDate,
      ),
      wordBookName: wordBook?.name ?? '尚未选择词表',
      wordBookWordCount: wordBook?.wordCount ?? 0,
      masteredWordCount: _masteredWordCount(
        learningProgresses: learningProgresses,
        wordBook: wordBook,
      ),
    );
  }

  static List<AnswerRecord> _recentRecords(
    List<AnswerRecord> answerRecords,
    DateTime referenceDate,
  ) {
    final start = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
    ).subtract(const Duration(days: 6));
    return [
      for (final record in answerRecords)
        if (!record.answeredAt.isBefore(start)) record,
    ];
  }

  static int _accuracyPercent(List<AnswerRecord> answerRecords) {
    if (answerRecords.isEmpty) {
      return 0;
    }
    final correctCount =
        answerRecords.where((record) => record.isCorrect).length;
    return ((correctCount / answerRecords.length) * 100).round();
  }

  static int _dueReviewCount({
    required List<WordLearningProgress> learningProgresses,
    required WordBook? wordBook,
    required DateTime referenceDate,
  }) {
    if (wordBook == null) {
      return 0;
    }
    final wordIds = {for (final word in wordBook.words) word.id};
    final referenceDay = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
    );
    return learningProgresses.where((progress) {
      if (!wordIds.contains(progress.wordId) ||
          progress.consecutiveMistakes > 0) {
        return false;
      }
      final nextReviewDay = DateTime(
        progress.nextReviewAt.year,
        progress.nextReviewAt.month,
        progress.nextReviewAt.day,
      );
      return !nextReviewDay.isAfter(referenceDay);
    }).length;
  }

  static int _mistakeReviewCount({
    required List<WordLearningProgress> learningProgresses,
    required WordBook? wordBook,
  }) {
    if (wordBook == null) {
      return 0;
    }
    final wordIds = {for (final word in wordBook.words) word.id};
    return learningProgresses.where((progress) {
      return wordIds.contains(progress.wordId) &&
          progress.consecutiveMistakes > 0;
    }).length;
  }

  static int _masteredWordCount({
    required List<WordLearningProgress> learningProgresses,
    required WordBook? wordBook,
  }) {
    if (wordBook == null) {
      return 0;
    }
    final wordIds = {for (final word in wordBook.words) word.id};
    return learningProgresses.where((progress) {
      return wordIds.contains(progress.wordId) && progress.isMastered;
    }).length;
  }

  static List<_DailyAccuracyPoint> _trendPoints({
    required List<AnswerRecord> answerRecords,
    required DateTime referenceDate,
  }) {
    final referenceDay = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
    );
    return [
      for (var offset = 6; offset >= 0; offset -= 1)
        _DailyAccuracyPoint.fromRecords(
          date: referenceDay.subtract(Duration(days: offset)),
          records: answerRecords,
        ),
    ];
  }

  static List<_MistakeWordSummary> _mistakeWords({
    required List<AnswerRecord> answerRecords,
    required WordBook? wordBook,
  }) {
    final mistakeCounts = <String, int>{};
    for (final record in answerRecords) {
      if (record.isCorrect) {
        continue;
      }
      mistakeCounts[record.wordId] = (mistakeCounts[record.wordId] ?? 0) + 1;
    }
    final summaries = [
      for (final entry in mistakeCounts.entries)
        _MistakeWordSummary(
          wordId: entry.key,
          spelling: _wordSpelling(wordId: entry.key, wordBook: wordBook),
          count: entry.value,
        ),
    ]..sort((a, b) {
        final countCompare = b.count.compareTo(a.count);
        if (countCompare != 0) {
          return countCompare;
        }
        return a.spelling.compareTo(b.spelling);
      });
    return summaries.take(5).toList();
  }

  static String _reviewAdvice({
    required List<WordLearningProgress> learningProgresses,
    required WordBook? wordBook,
    required DateTime referenceDate,
  }) {
    final mistakeCount = _mistakeReviewCount(
      learningProgresses: learningProgresses,
      wordBook: wordBook,
    );
    final dueCount = _dueReviewCount(
      learningProgresses: learningProgresses,
      wordBook: wordBook,
      referenceDate: referenceDate,
    );
    if (mistakeCount > 0 && dueCount > 0) {
      return '先修复 $mistakeCount 个错词，再复习 $dueCount 个到期词';
    }
    if (mistakeCount > 0) {
      return '先修复 $mistakeCount 个错词，降低连续错误';
    }
    if (dueCount > 0) {
      return '今天优先复习 $dueCount 个到期词';
    }
    return '今天适合学习新词，保持稳定节奏';
  }

  static String _frequentMistakeLabel({
    required List<AnswerRecord> answerRecords,
    required WordBook? wordBook,
  }) {
    final mistakeCounts = <String, int>{};
    for (final record in answerRecords) {
      if (record.isCorrect) {
        continue;
      }
      mistakeCounts[record.wordId] = (mistakeCounts[record.wordId] ?? 0) + 1;
    }
    if (mistakeCounts.isEmpty) {
      return '暂无';
    }

    final sortedEntries = mistakeCounts.entries.toList()
      ..sort((a, b) {
        final countCompare = b.value.compareTo(a.value);
        if (countCompare != 0) {
          return countCompare;
        }
        return a.key.compareTo(b.key);
      });
    final wordId = sortedEntries.first.key;
    return _wordSpelling(wordId: wordId, wordBook: wordBook);
  }

  static String _wordSpelling({
    required String wordId,
    required WordBook? wordBook,
  }) {
    if (wordBook == null) {
      return wordId;
    }
    for (final word in wordBook.words) {
      if (word.id == wordId) {
        return word.spelling;
      }
    }
    return wordId;
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
    final studyMetrics = _TodayStudyMetrics.from(adventure);
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
                    const SizedBox(height: 8),
                    Text(
                      '预计 ${studyMetrics.remainingMinutes} 分钟 · 今日完成 ${studyMetrics.progressPercent}%',
                      style: const TextStyle(
                        color: Color(0xFF70727A),
                        fontSize: 15,
                        height: 1.35,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              _ProgressBubble(label: '${studyMetrics.progressPercent}%'),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: studyMetrics.progress,
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

class _TodayStudyMetrics {
  const _TodayStudyMetrics({
    required this.totalQuestions,
    required this.completedQuestions,
  });

  final int totalQuestions;
  final int completedQuestions;

  int get remainingQuestions {
    return (totalQuestions - completedQuestions).clamp(0, totalQuestions);
  }

  int get remainingMinutes {
    return remainingQuestions <= 0 ? 0 : remainingQuestions;
  }

  double get progress {
    if (totalQuestions <= 0) {
      return 1;
    }
    return completedQuestions / totalQuestions;
  }

  int get progressPercent {
    return (progress * 100).round();
  }

  static _TodayStudyMetrics from(AdventureDashboardSnapshot adventure) {
    final studyLevels = [
      for (final level in adventure.levels)
        if (level.type != AdventureLevelType.chestSettlement) level,
    ];
    final totalQuestions = studyLevels.fold<int>(
      0,
      (sum, level) => sum + _questionCountFor(level),
    );
    final completedQuestions = studyLevels.fold<int>(
      0,
      (sum, level) => level.status == AdventureLevelStatus.completed
          ? sum + _questionCountFor(level)
          : sum,
    );

    return _TodayStudyMetrics(
      totalQuestions: totalQuestions,
      completedQuestions: completedQuestions,
    );
  }

  static int _questionCountFor(AdventureLevel level) {
    return level.questionCount <= 0 ? 0 : level.questionCount;
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
            _RouteRow(
              icon: Icons.download_rounded,
              iconColor: const Color(0xFFFF9500),
              iconBackground: const Color(0xFFFFF2D9),
              title: '导入学习备份',
              subtitle: 'JSON',
              onTap: onManageData,
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
  final ValueChanged<_StudySessionSummary> onComplete;

  @override
  State<_StudyQuizScreen> createState() => _StudyQuizScreenState();
}

class _StudyQuizScreenState extends State<_StudyQuizScreen> {
  static const _answerEvaluator = StudyAnswerEvaluator();
  static const _progressUpdater = StudyProgressUpdater();

  late final List<AnswerRecord> _answerRecordsSnapshot;
  late final List<WordLearningProgress> _learningProgressSnapshot;
  final List<_StudySessionAnswer> _sessionAnswers = [];
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
              _sessionAnswers.add(
                _StudySessionAnswer(
                  record: record,
                  wordLabel: quiz.prompt,
                ),
              );
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
                      widget.onComplete(
                        _StudySessionSummary.fromAnswers(
                          level: widget.level,
                          answers: _sessionAnswers,
                        ),
                      );
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
    required this.summary,
    required this.isPetFed,
    required this.onFeedPet,
  });

  final AdventureDashboardSnapshot adventure;
  final _StudySessionSummary summary;
  final bool isPetFed;
  final VoidCallback onFeedPet;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6F1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        child: isPetFed
            ? Row(
                key: const ValueKey('pet-fed-strip'),
                children: [
                  const Icon(
                    Icons.favorite_rounded,
                    color: Color(0xFF2F856F),
                    size: 26,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${adventure.pet.name}吃饱啦，${summary.petRewardLabel}，饱腹 ${adventure.pet.satiety}%',
                      style: const TextStyle(
                        color: Color(0xFF2F856F),
                        fontSize: 15,
                        height: 1.3,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                key: const ValueKey('pet-ready-strip'),
                children: [
                  const Icon(
                    Icons.pets_rounded,
                    color: Color(0xFF2F856F),
                    size: 26,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${adventure.pet.name}获得${summary.petRewardLabel}，喂食后饱腹会提升。',
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
      ),
    );
  }
}

class _FedPetCelebration extends StatelessWidget {
  const _FedPetCelebration({
    required this.pet,
    required this.petRewardLabel,
    required this.onReturnHome,
  });

  final PetProfile pet;
  final String petRewardLabel;
  final VoidCallback onReturnHome;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        key: const ValueKey('pet-fed-celebration'),
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF6DF),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFFC766), width: 2),
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 108,
                  height: 108,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE7AE),
                    shape: BoxShape.circle,
                  ),
                ),
                const Positioned(
                  top: 8,
                  right: 18,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFFFF9500),
                    size: 26,
                  ),
                ),
                const Positioned(
                  bottom: 12,
                  left: 18,
                  child: Icon(
                    Icons.favorite_rounded,
                    color: Color(0xFFFF6B6B),
                    size: 24,
                  ),
                ),
                const Icon(
                  Icons.pets_rounded,
                  color: Color(0xFF2F856F),
                  size: 58,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '${pet.name}吃饱啦',
              style: const TextStyle(
                color: Color(0xFF111114),
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              petRewardLabel,
              style: const TextStyle(
                color: Color(0xFF2F856F),
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: pet.satiety / 100,
                minHeight: 12,
                color: const Color(0xFF2F856F),
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '饱腹 ${pet.satiety}%',
              style: const TextStyle(
                color: Color(0xFF70727A),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: onReturnHome,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2F856F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                child: const Text('回到首页'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardSummaryGrid extends StatelessWidget {
  const _RewardSummaryGrid({required this.summary});

  final _StudySessionSummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RewardChip(
            icon: Icons.star_rounded,
            label: '获得 ${summary.reward.stars} 颗星',
            color: const Color(0xFFFF9500),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _RewardChip(
            icon: Icons.restaurant_rounded,
            label: summary.rewardItemLabel,
            color: const Color(0xFF2F856F),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _RewardChip(
            icon: Icons.pets_rounded,
            label: summary.petRewardLabel,
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

class _CompletionReviewList extends StatelessWidget {
  const _CompletionReviewList({required this.reviewItems});

  final List<_StudyReviewItem> reviewItems;

  @override
  Widget build(BuildContext context) {
    if (reviewItems.isEmpty) {
      return const _GroupedList(
        children: [
          _RouteRow(
            icon: Icons.check_circle_rounded,
            iconColor: Color(0xFF2F856F),
            iconBackground: Color(0xFFEAF6F1),
            title: '今天没有新增错词',
            subtitle: '明天会按间隔复习继续巩固',
          ),
        ],
      );
    }

    return _GroupedList(
      children: [
        for (final item in reviewItems)
          _RouteRow(
            icon: item.icon,
            iconColor: const Color(0xFFFF9500),
            iconBackground: const Color(0xFFFFF2D9),
            title: item.wordLabel,
            subtitle: item.subtitle,
          ),
      ],
    );
  }
}

class _StudyCompleteScreen extends StatelessWidget {
  const _StudyCompleteScreen({
    required this.childName,
    required this.adventure,
    required this.summary,
    required this.isPetFed,
    required this.onFeedPet,
    required this.onReturnHome,
    required this.onReview,
  });

  final String childName;
  final AdventureDashboardSnapshot adventure;
  final _StudySessionSummary summary;
  final bool isPetFed;
  final VoidCallback onFeedPet;
  final VoidCallback onReturnHome;
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
              Text(
                '$childName完成 ${summary.completedQuestionCount} 题，点亮${summary.levelTitle}。',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF70727A),
                  fontSize: 18,
                  height: 1.35,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              if (isPetFed) ...[
                _FedPetCelebration(
                  pet: adventure.pet,
                  petRewardLabel: summary.petRewardLabel,
                  onReturnHome: onReturnHome,
                ),
                const SizedBox(height: 18),
              ],
              _PetRewardStrip(
                adventure: adventure,
                summary: summary,
                isPetFed: isPetFed,
                onFeedPet: onFeedPet,
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                value: '${summary.completedQuestionCount}',
                label: '完成',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                value: summary.accuracyLabel,
                label: '正确率',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                value: '${summary.pendingReviewCount}',
                label: '待复习',
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        const _SectionTitle('今日奖励'),
        const SizedBox(height: 14),
        _RewardSummaryGrid(summary: summary),
        const SizedBox(height: 28),
        const _SectionTitle('明天优先复习'),
        const SizedBox(height: 14),
        _CompletionReviewList(reviewItems: summary.reviewItems),
        const SizedBox(height: 120),
        SizedBox(
          height: 58,
          child: FilledButton(
            onPressed: isPetFed ? onReturnHome : onFeedPet,
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
            child: Text(isPetFed ? '回到首页' : '喂食${adventure.pet.name}'),
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

class _StudySessionAnswer {
  const _StudySessionAnswer({
    required this.record,
    required this.wordLabel,
  });

  final AnswerRecord record;
  final String wordLabel;
}

class _StudyReviewItem {
  const _StudyReviewItem({
    required this.wordLabel,
    required this.weaknessType,
  });

  final String wordLabel;
  final AnswerWeaknessType? weaknessType;

  String get subtitle {
    return switch (weaknessType) {
      AnswerWeaknessType.meaning => '释义待复习',
      AnswerWeaknessType.spelling => '拼写待复习',
      AnswerWeaknessType.listening => '听音待复习',
      null => '稍后再巩固',
    };
  }

  IconData get icon {
    return switch (weaknessType) {
      AnswerWeaknessType.meaning => Icons.translate_rounded,
      AnswerWeaknessType.spelling => Icons.edit_outlined,
      AnswerWeaknessType.listening => Icons.volume_up_rounded,
      null => Icons.refresh_rounded,
    };
  }
}

class _StudySessionSummary {
  const _StudySessionSummary({
    required this.levelTitle,
    required this.reward,
    required this.completedQuestionCount,
    required this.attemptCount,
    required this.correctCount,
    required this.reviewItems,
  });

  factory _StudySessionSummary.empty({required AdventureLevel level}) {
    return _StudySessionSummary(
      levelTitle: level.title,
      reward: level.reward,
      completedQuestionCount: 0,
      attemptCount: 0,
      correctCount: 0,
      reviewItems: const [],
    );
  }

  factory _StudySessionSummary.fromAnswers({
    required AdventureLevel level,
    required List<_StudySessionAnswer> answers,
  }) {
    final reviewItems = <_StudyReviewItem>[];
    final seenReviewWords = <String>{};
    for (final answer in answers) {
      if (answer.record.isCorrect ||
          seenReviewWords.contains(answer.wordLabel)) {
        continue;
      }
      seenReviewWords.add(answer.wordLabel);
      reviewItems.add(
        _StudyReviewItem(
          wordLabel: answer.wordLabel,
          weaknessType: answer.record.weaknessType,
        ),
      );
    }

    return _StudySessionSummary(
      levelTitle: level.title,
      reward: level.reward,
      completedQuestionCount:
          answers.where((answer) => answer.record.isCorrect).length,
      attemptCount: answers.length,
      correctCount: answers.where((answer) => answer.record.isCorrect).length,
      reviewItems: reviewItems,
    );
  }

  final String levelTitle;
  final AdventureReward reward;
  final int completedQuestionCount;
  final int attemptCount;
  final int correctCount;
  final List<_StudyReviewItem> reviewItems;

  int get accuracyPercent {
    if (attemptCount == 0) {
      return 0;
    }
    return (correctCount / attemptCount * 100).round();
  }

  int get pendingReviewCount => reviewItems.length;

  String get accuracyLabel => '$accuracyPercent%';

  String get rewardItemLabel {
    if (reward.foodName != null && reward.foodCount > 0) {
      return '${reward.foodName} +${reward.foodCount}';
    }
    if (reward.energy > 0) {
      return '能量 +${reward.energy}';
    }
    if (reward.chestProgress > 0) {
      return '宝箱 +${reward.chestProgress}%';
    }
    return '奖励已领取';
  }

  String get petRewardLabel {
    if (reward.growthPoints > 0) {
      return '成长值 +${reward.growthPoints}';
    }
    if (reward.energy > 0) {
      return '能量 +${reward.energy}';
    }
    if (reward.foodName != null && reward.foodCount > 0) {
      return '${reward.foodName} +${reward.foodCount}';
    }
    return '陪伴奖励已记录';
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
