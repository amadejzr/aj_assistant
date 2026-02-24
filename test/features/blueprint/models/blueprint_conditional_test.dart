import 'package:bowerlab/features/blueprint/models/blueprint.dart';
import 'package:bowerlab/features/blueprint/models/blueprint_action.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BpConditional', () {
    test('toJson with then only', () {
      const node = BpConditional(
        condition: 'count() > 0',
        thenChildren: [BpTextDisplay(text: 'Has entries')],
      );
      expect(node.toJson(), {
        'type': 'conditional',
        'condition': 'count() > 0',
        'then': [
          {'type': 'text_display', 'text': 'Has entries'},
        ],
      });
    });

    test('toJson with then and else', () {
      const node = BpConditional(
        condition: 'count() > 0',
        thenChildren: [BpTextDisplay(text: 'Has entries')],
        elseChildren: [
          BpEmptyState(title: 'No entries', subtitle: 'Add one'),
        ],
      );
      expect(node.toJson(), {
        'type': 'conditional',
        'condition': 'count() > 0',
        'then': [
          {'type': 'text_display', 'text': 'Has entries'},
        ],
        'else': [
          {
            'type': 'empty_state',
            'title': 'No entries',
            'subtitle': 'Add one',
          },
        ],
      });
    });

    test('omits else when empty', () {
      const node = BpConditional(
        condition: true,
        thenChildren: [BpDivider()],
      );
      final json = node.toJson();
      expect(json.containsKey('else'), isFalse);
    });

    test('supports map condition', () {
      const node = BpConditional(
        condition: {'field': 'status', 'op': '==', 'value': 'active'},
        thenChildren: [BpTextDisplay(text: 'Active')],
      );
      expect(node.toJson()['condition'], {
        'field': 'status',
        'op': '==',
        'value': 'active',
      });
    });

    test('equality', () {
      const a = BpConditional(
        condition: 'count() > 0',
        thenChildren: [BpTextDisplay(text: 'yes')],
      );
      const b = BpConditional(
        condition: 'count() > 0',
        thenChildren: [BpTextDisplay(text: 'yes')],
      );
      expect(a, equals(b));
    });
  });

  group('ConfirmAction', () {
    test('toJson with all fields', () {
      const action = ConfirmAction(
        title: 'Delete?',
        message: 'This cannot be undone',
        onConfirm: DeleteEntryAction(confirm: false),
      );
      expect(action.toJson(), {
        'type': 'confirm',
        'title': 'Delete?',
        'message': 'This cannot be undone',
        'onConfirm': {'type': 'delete_entry'},
      });
    });

    test('toJson omits optional fields', () {
      const action = ConfirmAction(
        onConfirm: NavigateBackAction(),
      );
      expect(action.toJson(), {
        'type': 'confirm',
        'onConfirm': {'type': 'navigate_back'},
      });
    });

    test('fromJson roundtrip', () {
      const original = ConfirmAction(
        title: 'Sure?',
        message: 'Really?',
        onConfirm: DeleteEntryAction(confirm: true),
      );
      final restored = BlueprintAction.fromJson(original.toJson());
      expect(restored, isA<ConfirmAction>());
      final confirm = restored as ConfirmAction;
      expect(confirm.title, 'Sure?');
      expect(confirm.message, 'Really?');
      expect(confirm.onConfirm, isA<DeleteEntryAction>());
    });

    test('equality', () {
      const a = ConfirmAction(
        title: 'X',
        onConfirm: SubmitAction(),
      );
      const b = ConfirmAction(
        title: 'X',
        onConfirm: SubmitAction(),
      );
      expect(a, equals(b));
    });
  });

  group('ToastAction', () {
    test('toJson', () {
      const action = ToastAction(message: 'Saved!');
      expect(action.toJson(), {
        'type': 'toast',
        'message': 'Saved!',
      });
    });

    test('fromJson roundtrip', () {
      const original = ToastAction(message: 'Done');
      final restored = BlueprintAction.fromJson(original.toJson());
      expect(restored, isA<ToastAction>());
      expect((restored as ToastAction).message, 'Done');
    });

    test('equality', () {
      const a = ToastAction(message: 'hi');
      const b = ToastAction(message: 'hi');
      expect(a, equals(b));
    });
  });

  group('UpdateEntryAction', () {
    test('fromJson roundtrip', () {
      const original = UpdateEntryAction(
        data: {'status': 'done'},
        label: 'Mark done',
      );
      final restored = BlueprintAction.fromJson(original.toJson());
      expect(restored, isA<UpdateEntryAction>());
      final ue = restored as UpdateEntryAction;
      expect(ue.data, {'status': 'done'});
      expect(ue.label, 'Mark done');
    });
  });
}
