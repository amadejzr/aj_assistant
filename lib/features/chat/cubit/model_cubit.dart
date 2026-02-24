import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/ai/claude_model.dart';

const _key = 'claude_model';

class ModelCubit extends Cubit<ClaudeModel> {
  final FlutterSecureStorage _storage;

  ModelCubit({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(),
        super(ClaudeModel.sonnet);

  Future<void> init() async {
    final saved = await _storage.read(key: _key);
    if (saved != null) {
      final model = ClaudeModel.values.firstWhere(
        (m) => m.name == saved,
        orElse: () => ClaudeModel.sonnet,
      );
      emit(model);
    }
  }

  Future<void> setModel(ClaudeModel model) async {
    emit(model);
    await _storage.write(key: _key, value: model.name);
  }
}
