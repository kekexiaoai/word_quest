abstract class LocalKeyValueStore {
  String? read(String key);

  void write(String key, String value);

  void remove(String key);
}

class MemoryLocalKeyValueStore implements LocalKeyValueStore {
  MemoryLocalKeyValueStore({Map<String, String>? storage})
      : _storage = storage ?? {};

  final Map<String, String> _storage;

  @override
  String? read(String key) {
    return _storage[key];
  }

  @override
  void write(String key, String value) {
    _storage[key] = value;
  }

  @override
  void remove(String key) {
    _storage.remove(key);
  }
}
