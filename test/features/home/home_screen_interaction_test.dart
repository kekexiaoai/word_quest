import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_quest/features/home/presentation/home_screen.dart';

void main() {
  testWidgets('点击继续学习进入做题页', (tester) async {
    await _pumpHome(tester);

    await tester
        .tap(find.byKey(const ValueKey('home_continue_learning_button')));
    await tester.pumpAndSettle();

    expect(find.text('听音训练'), findsOneWidget);
    expect(find.text('6 / 18'), findsOneWidget);
    expect(find.text('听发音，选择对应单词'), findsOneWidget);
    expect(find.text('neighbor'), findsOneWidget);
    expect(find.text('library'), findsOneWidget);
    expect(find.text('through'), findsOneWidget);

    await tester.tap(find.text('through'));
    await tester.pumpAndSettle();

    expect(find.text('答对了'), findsOneWidget);
    expect(find.text('through 表示穿过，也可表示从头到尾完成。'), findsOneWidget);

    await tester.tap(find.text('下一题'));
    await tester.pumpAndSettle();

    expect(find.text('今天完成了'), findsOneWidget);
    expect(find.text('安安获得 3 颗星，森林书屋第 4 站已点亮。'), findsOneWidget);
  });

  testWidgets('首页采用新版词途今日学习结构', (tester) async {
    await _pumpHome(tester);

    expect(find.text('词途'), findsOneWidget);
    expect(find.text('每天一小步，单词走得稳'), findsOneWidget);
    expect(find.text('安安'), findsOneWidget);
    expect(find.text('今日任务'), findsOneWidget);
    expect(find.text('12 分钟完成剩余练习'), findsOneWidget);
    expect(find.text('继续学习'), findsOneWidget);
    expect(find.text('接下来'), findsOneWidget);
    expect(find.text('听音训练'), findsOneWidget);
    expect(find.text('需要留意'), findsOneWidget);
    expect(find.text('through 拼写仍不稳'), findsOneWidget);

    expect(find.text('宁宁'), findsNothing);
    expect(find.text('内置词表'), findsNothing);
    expect(find.text('家长提醒'), findsNothing);
  });

  testWidgets('底部导航可以切换到新版词表和设置页', (tester) async {
    await _pumpHome(tester);

    await tester.tap(find.byKey(const ValueKey('home_tab_word_book')));
    await tester.pumpAndSettle();

    expect(find.text('小学高年级基础词表'), findsOneWidget);
    expect(find.text('词表'), findsWidgets);
    expect(find.text('搜索单词、释义或标签'), findsOneWidget);
    expect(find.text('240'), findsOneWidget);
    expect(find.text('待复习错词'), findsOneWidget);
    expect(find.text('当前词表'), findsOneWidget);
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
}

Future<void> _pumpHome(WidgetTester tester) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
}
