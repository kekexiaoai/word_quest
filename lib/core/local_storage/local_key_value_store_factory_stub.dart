import 'local_key_value_store_base.dart';

LocalKeyValueStore createPlatformLocalKeyValueStore() {
  return MemoryLocalKeyValueStore();
}
