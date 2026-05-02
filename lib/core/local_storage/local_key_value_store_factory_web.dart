// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

import 'local_key_value_store_base.dart';

LocalKeyValueStore createPlatformLocalKeyValueStore() {
  return _WebLocalKeyValueStore();
}

class _WebLocalKeyValueStore implements LocalKeyValueStore {
  @override
  String? read(String key) {
    return html.window.localStorage[key];
  }

  @override
  void write(String key, String value) {
    html.window.localStorage[key] = value;
  }

  @override
  void remove(String key) {
    html.window.localStorage.remove(key);
  }
}
