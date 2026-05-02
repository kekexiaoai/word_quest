// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

import 'pronunciation_player_base.dart';

PronunciationPlayer createPlatformPronunciationPlayer() {
  return const WebSpeechPronunciationPlayer();
}

class WebSpeechPronunciationPlayer implements PronunciationPlayer {
  const WebSpeechPronunciationPlayer();

  @override
  void speak(String text) {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      return;
    }

    final speechSynthesis = html.window.speechSynthesis;
    if (speechSynthesis == null) {
      return;
    }

    final utterance = html.SpeechSynthesisUtterance(trimmedText)
      ..lang = 'en-US'
      ..rate = 0.82
      ..pitch = 1
      ..volume = 1;
    final voices = speechSynthesis.getVoices();
    for (final voice in voices) {
      if ((voice.lang ?? '').toLowerCase().startsWith('en')) {
        utterance.voice = voice;
        break;
      }
    }

    speechSynthesis.cancel();
    speechSynthesis.speak(utterance);
  }
}
