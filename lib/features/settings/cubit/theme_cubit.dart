import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _key = 'theme_mode';

class ThemeCubit extends Cubit<ThemeMode> {
  final FlutterSecureStorage _storage;

  ThemeCubit({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(),
        super(ThemeMode.system);

  Future<void> init() async {
    final saved = await _storage.read(key: _key);
    if (saved != null) {
      final mode = ThemeMode.values.firstWhere(
        (m) => m.name == saved,
        orElse: () => ThemeMode.system,
      );
      emit(mode);
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    emit(mode);
    await _storage.write(key: _key, value: mode.name);
  }
}
