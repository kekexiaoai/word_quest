import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_quest/features/study/application/pronunciation_player.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('word_quest/pronunciation');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('Android 和桌面端发音播放器通过原生通道播放单词', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });

    createDefaultPronunciationPlayer().speak(' library ');
    await Future<void>.delayed(Duration.zero);

    expect(calls, hasLength(1));
    expect(calls.single.method, 'speak');
    expect(calls.single.arguments, {'text': 'library'});
  });

  test('发音播放器忽略空文本', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });

    createDefaultPronunciationPlayer().speak('  ');
    await Future<void>.delayed(Duration.zero);

    expect(calls, isEmpty);
  });
}
