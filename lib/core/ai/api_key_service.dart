import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _key = 'anthropic_api_key';

class ApiKeyService {
  final FlutterSecureStorage _storage;

  ApiKeyService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<String?> getKey() => _storage.read(key: _key);

  Future<void> setKey(String apiKey) =>
      _storage.write(key: _key, value: apiKey);

  Future<void> deleteKey() => _storage.delete(key: _key);

  Future<bool> hasKey() async => (await getKey()) != null;
}
