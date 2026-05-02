import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_quest/features/home/presentation/home_screen.dart';

void main() {
  testWidgets('点击继续学习进入做题页', (tester) async {
    await _pumpHome(tester);

    await tester
        .tap(find.byKey(const ValueKey('home_continue_learning_button')));
    await tester.pumpAndSettle();

    expect(find.text('基础选择题'), findsWidgets);
    expect(find.text('第 1 / 18 题'), findsOneWidget);
    expect(find.text('请选择中文释义'), findsOneWidget);
    expect(find.text('neighbor'), findsOneWidget);
  });

  testWidgets('首页只展示今日学习入口和学习路线', (tester) async {
    await _pumpHome(tester);

    expect(find.text('今天'), findsWidgets);
    expect(find.text('今日任务'), findsOneWidget);
    expect(find.text('继续学习'), findsOneWidget);
    expect(find.text('学习路线'), findsOneWidget);

    expect(find.text('安安'), findsNothing);
    expect(find.text('宁宁'), findsNothing);
    expect(find.text('内置词表'), findsNothing);
    expect(find.text('家长提醒'), findsNothing);
  });

  testWidgets('底部导航可以切换到词表和设置页', (tester) async {
    await _pumpHome(tester);

    await tester.tap(find.byKey(const ValueKey('home_tab_word_book')));
    await tester.pumpAndSettle();

    expect(find.text('错词与词表'), findsOneWidget);
    expect(find.text('高频错词'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('home_tab_settings')));
    await tester.pumpAndSettle();

    expect(find.text('设置'), findsWidgets);
    expect(find.text('账号与角色'), findsOneWidget);
    expect(find.text('当前学习者'), findsOneWidget);
    expect(find.text('角色切换'), findsOneWidget);
    expect(find.text('导入 CSV 词表'), findsOneWidget);
  });
}

Future<void> _pumpHome(WidgetTester tester) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
}
