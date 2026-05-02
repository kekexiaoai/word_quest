import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_quest/features/home/presentation/home_screen.dart';

void main() {
  testWidgets('点击继续学习进入做题页', (tester) async {
    await _pumpHome(tester);
    await tester.drag(find.byType(ListView).first, const Offset(0, -220));
    await tester.pumpAndSettle();

    await tester
        .tap(find.byKey(const ValueKey('home_continue_learning_button')));
    await tester.pumpAndSettle();

    expect(find.text('基础选择题'), findsWidgets);
    expect(find.text('第 1 / 18 题'), findsOneWidget);
    expect(find.text('请选择中文释义'), findsOneWidget);
    expect(find.text('neighbor'), findsOneWidget);
  });

  testWidgets('底部导航可以切换到词表和家庭页', (tester) async {
    await _pumpHome(tester);

    await tester.tap(find.byKey(const ValueKey('home_tab_word_book')));
    await tester.pumpAndSettle();

    expect(find.text('错词与词表'), findsOneWidget);
    expect(find.text('高频错词'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('home_tab_family')));
    await tester.pumpAndSettle();

    expect(find.text('家庭'), findsWidgets);
    expect(find.text('本地优先'), findsOneWidget);
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
