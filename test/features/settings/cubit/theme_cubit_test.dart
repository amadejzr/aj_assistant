import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:aj_assistant/features/settings/cubit/theme_cubit.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
  });

  group('ThemeCubit', () {
    test('initial state is ThemeMode.system', () {
      when(() => mockStorage.read(key: 'theme_mode'))
          .thenAnswer((_) async => null);
      final cubit = ThemeCubit(storage: mockStorage);
      expect(cubit.state, ThemeMode.system);
    });

    blocTest<ThemeCubit, ThemeMode>(
      'init loads saved theme from storage',
      setUp: () {
        when(() => mockStorage.read(key: 'theme_mode'))
            .thenAnswer((_) async => 'dark');
      },
      build: () => ThemeCubit(storage: mockStorage),
      act: (cubit) => cubit.init(),
      expect: () => [ThemeMode.dark],
    );

    blocTest<ThemeCubit, ThemeMode>(
      'init does nothing when storage is empty',
      setUp: () {
        when(() => mockStorage.read(key: 'theme_mode'))
            .thenAnswer((_) async => null);
      },
      build: () => ThemeCubit(storage: mockStorage),
      act: (cubit) => cubit.init(),
      expect: () => <ThemeMode>[],
    );

    blocTest<ThemeCubit, ThemeMode>(
      'setTheme emits new mode and persists it',
      setUp: () {
        when(() => mockStorage.read(key: 'theme_mode'))
            .thenAnswer((_) async => null);
        when(() => mockStorage.write(key: 'theme_mode', value: 'light'))
            .thenAnswer((_) async {});
      },
      build: () => ThemeCubit(storage: mockStorage),
      act: (cubit) => cubit.setTheme(ThemeMode.light),
      expect: () => [ThemeMode.light],
      verify: (_) {
        verify(() => mockStorage.write(key: 'theme_mode', value: 'light'))
            .called(1);
      },
    );
  });
}
