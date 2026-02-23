import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:aj_assistant/core/ai/api_key_service.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockSecureStorage mockStorage;
  late ApiKeyService service;

  setUp(() {
    mockStorage = MockSecureStorage();
    service = ApiKeyService(storage: mockStorage);
  });

  group('ApiKeyService', () {
    test('getKey returns stored key', () async {
      when(() => mockStorage.read(key: 'anthropic_api_key'))
          .thenAnswer((_) async => 'sk-ant-test123');
      final key = await service.getKey();
      expect(key, 'sk-ant-test123');
    });

    test('getKey returns null when no key stored', () async {
      when(() => mockStorage.read(key: 'anthropic_api_key'))
          .thenAnswer((_) async => null);
      final key = await service.getKey();
      expect(key, isNull);
    });

    test('setKey writes to storage', () async {
      when(() => mockStorage.write(
              key: 'anthropic_api_key', value: 'sk-ant-new'))
          .thenAnswer((_) async {});
      await service.setKey('sk-ant-new');
      verify(() => mockStorage.write(
          key: 'anthropic_api_key', value: 'sk-ant-new')).called(1);
    });

    test('deleteKey removes from storage', () async {
      when(() => mockStorage.delete(key: 'anthropic_api_key'))
          .thenAnswer((_) async {});
      await service.deleteKey();
      verify(() => mockStorage.delete(key: 'anthropic_api_key')).called(1);
    });

    test('hasKey returns true when key exists', () async {
      when(() => mockStorage.read(key: 'anthropic_api_key'))
          .thenAnswer((_) async => 'sk-ant-test');
      expect(await service.hasKey(), isTrue);
    });

    test('hasKey returns false when no key', () async {
      when(() => mockStorage.read(key: 'anthropic_api_key'))
          .thenAnswer((_) async => null);
      expect(await service.hasKey(), isFalse);
    });
  });
}
