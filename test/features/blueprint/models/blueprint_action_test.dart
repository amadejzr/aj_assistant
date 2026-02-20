import 'package:aj_assistant/features/blueprint/models/blueprint_action.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NavigateAction', () {
    test('toJson with screen only', () {
      const action = NavigateAction(screen: 'add_entry');
      expect(action.toJson(), {'type': 'navigate', 'screen': 'add_entry'});
    });

    test('toJson with params and forwardFields', () {
      const action = NavigateAction(
        screen: 'edit_entry',
        params: {'_entryId': '123'},
        forwardFields: ['title', 'note'],
      );
      expect(action.toJson(), {
        'type': 'navigate',
        'screen': 'edit_entry',
        'params': {'_entryId': '123'},
        'forwardFields': ['title', 'note'],
      });
    });

    test('fromJson roundtrip', () {
      const original = NavigateAction(screen: 'main', params: {'tab': 0});
      final restored = BlueprintAction.fromJson(original.toJson());
      expect(restored, equals(original));
    });
  });

  group('NavigateBackAction', () {
    test('toJson', () {
      const action = NavigateBackAction();
      expect(action.toJson(), {'type': 'navigate_back'});
    });
  });

  group('SubmitAction', () {
    test('toJson', () {
      const action = SubmitAction();
      expect(action.toJson(), {'type': 'submit'});
    });
  });

  group('DeleteEntryAction', () {
    test('toJson with confirm', () {
      const action =
          DeleteEntryAction(confirm: true, confirmMessage: 'Delete this?');
      expect(action.toJson(), {
        'type': 'delete_entry',
        'confirm': true,
        'confirmMessage': 'Delete this?',
      });
    });

    test('toJson without confirm omits keys', () {
      const action = DeleteEntryAction();
      expect(action.toJson(), {'type': 'delete_entry'});
    });
  });

  group('ShowFormSheetAction', () {
    test('toJson', () {
      const action =
          ShowFormSheetAction(screen: 'quick_add', title: 'Quick Add');
      expect(action.toJson(), {
        'type': 'show_form_sheet',
        'screen': 'quick_add',
        'title': 'Quick Add',
      });
    });
  });

  group('RawAction', () {
    test('passes through unknown action JSON', () {
      const action = RawAction({'type': 'toast', 'message': 'hello'});
      expect(action.toJson(), {'type': 'toast', 'message': 'hello'});
    });
  });

  group('BlueprintAction.fromJson', () {
    test('unknown type becomes RawAction', () {
      final action =
          BlueprintAction.fromJson({'type': 'future_action', 'data': 1});
      expect(action, isA<RawAction>());
    });
  });
}
