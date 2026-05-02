import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_quest/features/adventure/application/in_memory_adventure_repository.dart';
import 'package:word_quest/features/adventure/domain/adventure_dashboard_snapshot.dart';
import 'package:word_quest/features/home/presentation/home_screen.dart';
import 'package:word_quest/features/study/application/in_memory_answer_record_repository.dart';
import 'package:word_quest/features/study/domain/answer_record.dart';
import 'package:word_quest/features/study/domain/study_task.dart';
import 'package:word_quest/features/word_book/application/in_memory_word_book_repository.dart';
import 'package:word_quest/features/word_book/domain/word_book.dart';
import 'package:word_quest/features/word_book/domain/word_entry.dart';

void main() {
  testWidgets('点击继续学习进入做题页', (tester) async {
    await _pumpHome(tester);

    await tester
        .tap(find.byKey(const ValueKey('home_continue_learning_button')));
    await tester.pumpAndSettle();

    expect(find.text('听音训练'), findsOneWidget);
    expect(find.text('1 / 6'), findsOneWidget);
    expect(find.text('听发音，选择对应单词'), findsOneWidget);
    expect(find.text('neighbor'), findsOneWidget);
    expect(find.text('library'), findsWidgets);
    expect(find.text('through'), findsOneWidget);

    await tester.tap(find.text('through'));
    await tester.pumpAndSettle();

    expect(find.text('答对了'), findsOneWidget);
    expect(find.text('through 表示穿过，也可表示从头到尾完成。'), findsOneWidget);

    await tester.ensureVisible(find.text('下一题', skipOffstage: false));
    await tester.pumpAndSettle();
    await tester.tap(find.text('下一题'));
    await tester.pumpAndSettle();

    expect(find.text('2 / 6'), findsOneWidget);
    expect(find.text('今天完成了'), findsNothing);
  });

  testWidgets('答完当前关卡最后一题后才进入结算', (tester) async {
    await _pumpHome(tester);

    await tester
        .tap(find.byKey(const ValueKey('home_continue_learning_button')));
    await tester.pumpAndSettle();
    await _completeVisibleQuiz(tester, answers: const [
      'through',
      'neighbor',
      'library',
      'through',
      'neighbor',
      'library',
    ]);

    expect(find.text('今天完成了'), findsOneWidget);
    expect(find.text('安安获得 3 颗星，森林书屋第 4 站已点亮。'), findsOneWidget);
    expect(find.text('普通食物 +1'), findsOneWidget);
    expect(find.text('宠物成长 +24'), findsOneWidget);
    expect(find.text('喂食豆豆'), findsOneWidget);
  });

  testWidgets('答错会进入稍后重试，答对重试题后才结算', (tester) async {
    await _pumpHome(tester);

    await tester
        .tap(find.byKey(const ValueKey('home_continue_learning_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('library').last);
    await tester.pumpAndSettle();

    expect(find.text('再试一次'), findsOneWidget);
    expect(find.text('这题会放到本关稍后再试。'), findsOneWidget);

    await tester.ensureVisible(find.text('下一题', skipOffstage: false));
    await tester.pumpAndSettle();
    await tester.tap(find.text('下一题'));
    await tester.pumpAndSettle();

    expect(find.text('2 / 6'), findsOneWidget);
    expect(find.text('今天完成了'), findsNothing);

    await _completeVisibleQuiz(tester, answers: const [
      'neighbor',
      'library',
      'through',
      'neighbor',
      'library',
    ]);

    expect(find.text('今天完成了'), findsNothing);
    expect(find.text('1 / 6'), findsOneWidget);

    await tester.tap(find.text('through'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('下一题', skipOffstage: false));
    await tester.pumpAndSettle();
    await tester.tap(find.text('下一题'));
    await tester.pumpAndSettle();

    expect(find.text('今天完成了'), findsOneWidget);
  });

  testWidgets('答题会写入学习记录并标记薄弱类型', (tester) async {
    final storage = <AnswerRecord>[];
    final recordRepository = InMemoryAnswerRecordRepository(storage: storage);
    await _pumpHome(tester, answerRecordRepository: recordRepository);

    await tester
        .tap(find.byKey(const ValueKey('home_continue_learning_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('library').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('下一题', skipOffstage: false));
    await tester.pumpAndSettle();
    await tester.tap(find.text('下一题'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('neighbor'));
    await tester.pumpAndSettle();

    expect(storage, hasLength(2));
    expect(storage.first.childId, 'child-brother');
    expect(storage.first.wordId, 'through');
    expect(storage.first.practiceMode, PracticeMode.listeningChoice);
    expect(storage.first.isCorrect, isFalse);
    expect(storage.first.weaknessType, AnswerWeaknessType.listening);
    expect(storage.first.elapsedMilliseconds, greaterThan(0));
    expect(storage.last.wordId, 'neighbor');
    expect(storage.last.isCorrect, isTrue);
    expect(storage.last.weaknessType, isNull);
  });

  testWidgets('继续学习会根据学习记录进入薄弱点复习', (tester) async {
    final recordRepository = InMemoryAnswerRecordRepository(storage: [
      AnswerRecord(
        childId: 'child-brother',
        wordId: 'library',
        practiceMode: PracticeMode.listeningChoice,
        isCorrect: false,
        answeredAt: DateTime(2026, 5, 2, 8),
        elapsedMilliseconds: 1200,
        weaknessType: AnswerWeaknessType.listening,
      ),
    ]);
    await _pumpHome(tester, answerRecordRepository: recordRepository);

    await tester
        .tap(find.byKey(const ValueKey('home_continue_learning_button')));
    await tester.pumpAndSettle();

    expect(find.text('薄弱点复习'), findsOneWidget);
    expect(find.text('听发音，选择对应单词'), findsOneWidget);

    await tester.tap(find.text('library').last);
    await tester.pumpAndSettle();

    expect(find.text('薄弱点修复'), findsOneWidget);
  });

  testWidgets('导入词表中的错词会进入首页动态复习', (tester) async {
    final recordRepository = InMemoryAnswerRecordRepository(storage: [
      AnswerRecord(
        childId: 'child-brother',
        wordId: 'custom-ocean',
        practiceMode: PracticeMode.listeningChoice,
        isCorrect: false,
        answeredAt: DateTime(2026, 5, 2, 8),
        elapsedMilliseconds: 1200,
        weaknessType: AnswerWeaknessType.listening,
      ),
    ]);
    const wordBookRepository = InMemoryWordBookRepository(
      importedWordBooks: [
        WordBook(
          id: 'custom',
          name: '我的导入词表',
          stageLabel: '自定义',
          words: [
            WordEntry(id: 'custom-ocean', spelling: 'ocean', meanings: ['海洋']),
            WordEntry(id: 'custom-river', spelling: 'river', meanings: ['河流']),
            WordEntry(
                id: 'custom-mountain', spelling: 'mountain', meanings: ['高山']),
          ],
        ),
      ],
    );
    await _pumpHome(
      tester,
      answerRecordRepository: recordRepository,
      wordBookRepository: wordBookRepository,
    );

    await tester
        .tap(find.byKey(const ValueKey('home_continue_learning_button')));
    await tester.pumpAndSettle();

    expect(find.text('薄弱点复习'), findsOneWidget);
    expect(find.text('ocean'), findsWidgets);
    expect(find.text('river'), findsOneWidget);
  });

  testWidgets('词表页导入 CSV 后关卡可以立即使用导入词', (tester) async {
    final importedStorage = <WordBook>[];
    final wordBookRepository = InMemoryWordBookRepository(
      importedWordBooks: importedStorage,
    );
    final answerRecordRepository = InMemoryAnswerRecordRepository(storage: [
      AnswerRecord(
        childId: 'child-brother',
        wordId: 'csv-import-1-1',
        practiceMode: PracticeMode.listeningChoice,
        isCorrect: false,
        answeredAt: DateTime(2026, 5, 2, 8),
        elapsedMilliseconds: 1200,
        weaknessType: AnswerWeaknessType.listening,
      ),
    ]);
    await _pumpHome(
      tester,
      answerRecordRepository: answerRecordRepository,
      wordBookRepository: wordBookRepository,
    );

    await tester.tap(find.byKey(const ValueKey('home_tab_word_book')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('word_book_import_button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('word_book_import_name_input')),
      '海洋主题词表',
    );
    await tester.enterText(
      find.byKey(const ValueKey('word_book_import_csv_input')),
      '''
单词,中文释义
ocean,海洋
river,河流
mountain,高山
''',
    );
    await tester.tap(find.byKey(const ValueKey('word_book_import_submit')));
    await tester.pumpAndSettle();

    expect(importedStorage, hasLength(1));
    expect(find.text('海洋主题词表'), findsOneWidget);
    expect(find.text('3 个单词 · 自定义'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('home_tab_today')));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('home_continue_learning_button')));
    await tester.pumpAndSettle();

    expect(find.text('薄弱点复习'), findsOneWidget);
    expect(find.text('ocean'), findsWidgets);
    expect(find.text('river'), findsOneWidget);
  });

  testWidgets('首页采用新版词途今日学习结构', (tester) async {
    await _pumpHome(tester);

    expect(find.text('词途'), findsOneWidget);
    expect(find.text('每天一小步，单词走得稳'), findsOneWidget);
    expect(find.text('安安'), findsOneWidget);
    expect(find.text('今日任务'), findsOneWidget);
    expect(find.text('12 分钟完成剩余练习'), findsOneWidget);
    expect(find.text('继续学习'), findsOneWidget);
    expect(find.text('今日冒险'), findsOneWidget);
    expect(find.text('森林冒险'), findsOneWidget);
    expect(find.text('复习探索关'), findsOneWidget);
    expect(find.text('豆豆 Lv.2'), findsOneWidget);
    expect(find.text('饱腹 68%'), findsOneWidget);
    expect(find.text('喂食'), findsOneWidget);

    expect(find.text('宁宁'), findsNothing);
    expect(find.text('内置词表'), findsNothing);
    expect(find.text('家长提醒'), findsNothing);
  });

  testWidgets('底部导航可以切换到新版词表和设置页', (tester) async {
    await _pumpHome(tester);

    await tester.tap(find.byKey(const ValueKey('home_tab_quest')));
    await tester.pumpAndSettle();

    expect(find.text('森林冒险'), findsWidgets);
    expect(find.text('今日路线'), findsOneWidget);
    expect(find.text('新词热身关'), findsOneWidget);
    expect(find.text('复习探索关'), findsOneWidget);
    expect(find.text('错词 Boss 关'), findsOneWidget);
    expect(find.text('宝箱结算关'), findsOneWidget);
    expect(find.text('豆豆 Lv.2'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('home_tab_word_book')));
    await tester.pumpAndSettle();

    expect(find.text('小学高年级基础词表'), findsWidgets);
    expect(find.text('词表'), findsWidgets);
    expect(find.text('搜索单词、释义或标签'), findsOneWidget);
    expect(find.text('18'), findsOneWidget);
    expect(find.text('导入词表'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('word_book_import_button')), findsOneWidget);
    expect(find.text('最近练过'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('home_tab_settings')));
    await tester.pumpAndSettle();

    expect(find.text('设置'), findsWidgets);
    expect(find.text('Word Quest'), findsOneWidget);
    expect(find.text('孩子模式 · 五年级'), findsOneWidget);
    expect(find.text('身份与档案'), findsOneWidget);
    expect(find.text('切换孩子 / 家长'), findsOneWidget);
    expect(find.text('家长管理'), findsOneWidget);
    expect(find.text('导入学习备份'), findsOneWidget);
    expect(find.text('内部代号：Word Quest'), findsOneWidget);
  });

  testWidgets('设置页数据管理支持导出导入和清空学习记录', (tester) async {
    final answerStorage = <AnswerRecord>[
      AnswerRecord(
        childId: 'child-brother',
        wordId: 'library',
        practiceMode: PracticeMode.listeningChoice,
        isCorrect: false,
        answeredAt: DateTime(2026, 5, 2, 8),
        elapsedMilliseconds: 1200,
        weaknessType: AnswerWeaknessType.listening,
      ),
    ];
    final importedWordBooks = <WordBook>[
      const WordBook(
        id: 'custom',
        name: '我的导入词表',
        stageLabel: '自定义',
        words: [
          WordEntry(id: 'custom-ocean', spelling: 'ocean', meanings: ['海洋']),
        ],
      ),
    ];
    await _pumpHome(
      tester,
      answerRecordRepository:
          InMemoryAnswerRecordRepository(storage: answerStorage),
      wordBookRepository:
          InMemoryWordBookRepository(importedWordBooks: importedWordBooks),
    );

    await tester.tap(find.byKey(const ValueKey('home_tab_settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('settings_data_management')));
    await tester.pumpAndSettle();

    expect(find.text('数据管理'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('data_export_button')));
    await tester.pumpAndSettle();
    expect(find.textContaining('"answerRecords"'), findsOneWidget);
    expect(find.textContaining('我的导入词表'), findsOneWidget);

    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('settings_data_management')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('data_clear_records_button')));
    await tester.pumpAndSettle();

    expect(answerStorage, isEmpty);

    await tester.tap(find.byKey(const ValueKey('data_import_button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('data_import_json_input')),
      '''
{"schemaVersion":1,"exportedAt":"2026-05-02T21:00:00.000","children":[],"wordBooks":[{"id":"restored","name":"恢复词表","stageLabel":"自定义","isBuiltIn":false,"words":[{"id":"restored-1","spelling":"river","meanings":["河流"],"tags":[]}]}],"answerRecords":[{"childId":"child-brother","wordId":"restored-1","practiceMode":"listeningChoice","isCorrect":false,"answeredAt":"2026-05-02T20:00:00.000","elapsedMilliseconds":1000,"weaknessType":"listening"}]}
''',
    );
    await tester.tap(find.byKey(const ValueKey('data_import_submit')));
    await tester.pumpAndSettle();

    expect(importedWordBooks.single.name, '恢复词表');
    expect(answerStorage.single.wordId, 'restored-1');
  });

  testWidgets('闯关页当前关卡可以进入，锁定关卡不能进入', (tester) async {
    await _pumpHome(tester);

    await tester.tap(find.byKey(const ValueKey('home_tab_quest')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('错词 Boss 关'));
    await tester.pumpAndSettle();

    expect(find.text('听发音，选择对应单词'), findsNothing);
    expect(find.text('错词 Boss 关'), findsOneWidget);

    await tester.tap(find.text('复习探索关'));
    await tester.pumpAndSettle();

    expect(find.text('复习探索关'), findsOneWidget);
    expect(find.text('6 题 · 选择 / 拼写 / 听音'), findsOneWidget);
    expect(find.text('听发音，选择对应单词'), findsOneWidget);
  });

  testWidgets('不同关卡进入后显示对应题组', (tester) async {
    await _pumpHome(tester);

    await tester.tap(find.byKey(const ValueKey('home_tab_quest')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('新词热身关'));
    await tester.pumpAndSettle();

    expect(find.text('新词热身关'), findsOneWidget);
    expect(find.text('新词热身'), findsOneWidget);
    expect(find.text('1 / 8'), findsOneWidget);
    expect(find.text('看单词，选择中文意思'), findsOneWidget);
    expect(find.text('library'), findsWidgets);
    expect(find.text('图书馆'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('home_tab_quest')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('复习探索关'));
    await tester.pumpAndSettle();

    expect(find.text('复习探索关'), findsOneWidget);
    expect(find.text('听音训练'), findsOneWidget);
    expect(find.text('1 / 6'), findsOneWidget);
    expect(find.text('听发音，选择对应单词'), findsOneWidget);
    expect(find.text('through'), findsWidgets);
  });

  testWidgets('完成当前关卡后可以喂食宠物并更新首页状态', (tester) async {
    await _pumpHome(tester);

    await tester
        .tap(find.byKey(const ValueKey('home_continue_learning_button')));
    await tester.pumpAndSettle();
    await _completeVisibleQuiz(tester, answers: const [
      'through',
      'neighbor',
      'library',
      'through',
      'neighbor',
      'library',
    ]);
    await tester.tap(find.text('喂食豆豆'));
    await tester.pumpAndSettle();

    expect(find.text('豆豆 Lv.3'), findsOneWidget);
    expect(find.text('饱腹 88%'), findsOneWidget);
    expect(find.text('错词 Boss 关'), findsOneWidget);
  });

  testWidgets('冒险进度会保存到仓库并在首页重建后恢复', (tester) async {
    final storage = <String, AdventureDashboardSnapshot>{};
    final adventureRepository = InMemoryAdventureRepository(storage: storage);
    await _pumpHome(tester, adventureRepository: adventureRepository);

    await tester
        .tap(find.byKey(const ValueKey('home_continue_learning_button')));
    await tester.pumpAndSettle();
    await _completeVisibleQuiz(tester, answers: const [
      'through',
      'neighbor',
      'library',
      'through',
      'neighbor',
      'library',
    ]);
    await tester.tap(find.text('喂食豆豆'));
    await tester.pumpAndSettle();

    final restoredAnswerStorage = <AnswerRecord>[];
    await tester.pumpWidget(MaterialApp(
      home: HomeScreen(
        adventureRepository: adventureRepository,
        answerRecordRepository:
            InMemoryAnswerRecordRepository(storage: restoredAnswerStorage),
        wordBookRepository: const InMemoryWordBookRepository(),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('豆豆 Lv.3'), findsOneWidget);
    expect(find.text('饱腹 88%'), findsOneWidget);
    expect(find.text('错词 Boss 关'), findsOneWidget);
  });

  testWidgets('词表页滚动到底部时内容不会被底部导航遮挡', (tester) async {
    await _pumpHome(tester);

    await tester.tap(find.byKey(const ValueKey('home_tab_word_book')));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -420));
    await tester.pumpAndSettle();

    final libraryBottom = tester.getBottomLeft(find.text('library')).dy;
    final tabBarTop =
        tester.getTopLeft(find.byKey(const ValueKey('home_tab_bar'))).dy;

    expect(libraryBottom, lessThan(tabBarTop - 12));
  });

  testWidgets('底部导航栏圆角外侧保持透明露出正文', (tester) async {
    await _pumpHome(tester);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    final bodySafeArea = tester.widget<SafeArea>(
      find.byWidgetPredicate(
        (widget) => widget is SafeArea && widget.child is Center,
      ),
    );

    expect(scaffold.extendBody, isTrue);
    expect(bodySafeArea.bottom, isFalse);
  });
}

Future<void> _completeVisibleQuiz(
  WidgetTester tester, {
  required List<String> answers,
}) async {
  for (final answer in answers) {
    await tester.ensureVisible(find.text(answer, skipOffstage: false).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(answer).last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('下一题', skipOffstage: false));
    await tester.pumpAndSettle();
    await tester.tap(find.text('下一题'));
    await tester.pumpAndSettle();
  }
}

Future<void> _pumpHome(
  WidgetTester tester, {
  InMemoryAdventureRepository? adventureRepository,
  InMemoryAnswerRecordRepository? answerRecordRepository,
  InMemoryWordBookRepository? wordBookRepository,
}) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final storage = <String, AdventureDashboardSnapshot>{};
  final answerStorage = <AnswerRecord>[];
  await tester.pumpWidget(MaterialApp(
    home: HomeScreen(
      adventureRepository:
          adventureRepository ?? InMemoryAdventureRepository(storage: storage),
      answerRecordRepository: answerRecordRepository ??
          InMemoryAnswerRecordRepository(storage: answerStorage),
      wordBookRepository:
          wordBookRepository ?? const InMemoryWordBookRepository(),
    ),
  ));
}
