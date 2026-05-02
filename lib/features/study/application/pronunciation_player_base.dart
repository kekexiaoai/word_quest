abstract class PronunciationPlayer {
  void speak(String text);
}

class NoopPronunciationPlayer implements PronunciationPlayer {
  const NoopPronunciationPlayer();

  @override
  void speak(String text) {}
}
