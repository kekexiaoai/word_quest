import 'local_key_value_store_base.dart';
import 'local_key_value_store_factory_stub.dart'
    if (dart.library.html) 'local_key_value_store_factory_web.dart'
    if (dart.library.io) 'local_key_value_store_factory_io.dart' as platform;

export 'local_key_value_store_base.dart';

LocalKeyValueStore createDefaultLocalKeyValueStore() {
  return platform.createPlatformLocalKeyValueStore();
}
