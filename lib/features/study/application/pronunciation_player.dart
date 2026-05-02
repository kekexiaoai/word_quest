import 'pronunciation_player_base.dart';
import 'pronunciation_player_factory_stub.dart'
    if (dart.library.html) 'pronunciation_player_factory_web.dart'
    if (dart.library.io) 'pronunciation_player_factory_io.dart' as platform;

export 'pronunciation_player_base.dart';

PronunciationPlayer createDefaultPronunciationPlayer() {
  return platform.createPlatformPronunciationPlayer();
}
