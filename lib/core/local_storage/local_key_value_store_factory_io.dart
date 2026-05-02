import 'dart:io';

import 'local_key_value_store_base.dart';

LocalKeyValueStore createPlatformLocalKeyValueStore() {
  final home = Platform.environment['HOME'];
  final baseDirectory = home == null || home.isEmpty
      ? Directory.systemTemp
      : Directory('$home/.word_quest');
  return _FileLocalKeyValueStore(baseDirectory);
}

class _FileLocalKeyValueStore implements LocalKeyValueStore {
  _FileLocalKeyValueStore(this.directory);

  final Directory directory;

  @override
  String? read(String key) {
    final file = _fileFor(key);
    if (!file.existsSync()) {
      return null;
    }
    return file.readAsStringSync();
  }

  @override
  void write(String key, String value) {
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    _fileFor(key).writeAsStringSync(value);
  }

  @override
  void remove(String key) {
    final file = _fileFor(key);
    if (file.existsSync()) {
      file.deleteSync();
    }
  }

  File _fileFor(String key) {
    final safeKey = key.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');
    return File('${directory.path}/$safeKey.json');
  }
}
