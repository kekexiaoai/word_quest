import 'dart:async';

import 'package:flutter/services.dart';

import 'pronunciation_player_base.dart';

PronunciationPlayer createPlatformPronunciationPlayer() {
  return const MethodChannelPronunciationPlayer();
}

class MethodChannelPronunciationPlayer implements PronunciationPlayer {
  const MethodChannelPronunciationPlayer();

  static const _channel = MethodChannel('word_quest/pronunciation');

  @override
  void speak(String text) {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      return;
    }

    unawaited(
      _channel.invokeMethod<void>('speak', {'text': trimmedText}).catchError(
        (_) {
          return null;
        },
      ),
    );
  }
}
