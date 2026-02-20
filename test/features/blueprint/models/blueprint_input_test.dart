import 'package:aj_assistant/features/blueprint/models/blueprint.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BpTextInput', () {
    test('minimal', () {
      const input = BpTextInput(fieldKey: 'title');
      expect(input.toJson(), {'type': 'text_input', 'fieldKey': 'title'});
    });

    test('multiline', () {
      const input = BpTextInput(fieldKey: 'description', multiline: true);
      expect(input.toJson(), {
        'type': 'text_input',
        'fieldKey': 'description',
        'multiline': true,
      });
    });

    test('multiline false omits key', () {
      const input = BpTextInput(fieldKey: 'name');
      expect(input.toJson().containsKey('multiline'), false);
    });
  });

  group('BpNumberInput', () {
    test('toJson', () {
      const input = BpNumberInput(fieldKey: 'amount');
      expect(input.toJson(), {'type': 'number_input', 'fieldKey': 'amount'});
    });
  });

  group('BpCurrencyInput', () {
    test('defaults', () {
      const input = BpCurrencyInput(fieldKey: 'price');
      expect(input.toJson(), {'type': 'currency_input', 'fieldKey': 'price'});
    });

    test('custom symbol and decimals', () {
      const input = BpCurrencyInput(
        fieldKey: 'price',
        currencySymbol: '€',
        decimalPlaces: 0,
      );
      expect(input.toJson(), {
        'type': 'currency_input',
        'fieldKey': 'price',
        'currencySymbol': '€',
        'decimalPlaces': 0,
      });
    });
  });

  group('BpDatePicker', () {
    test('toJson', () {
      const input = BpDatePicker(fieldKey: 'due_date');
      expect(input.toJson(), {'type': 'date_picker', 'fieldKey': 'due_date'});
    });
  });

  group('BpTimePicker', () {
    test('toJson', () {
      const input = BpTimePicker(fieldKey: 'alarm_time');
      expect(
          input.toJson(), {'type': 'time_picker', 'fieldKey': 'alarm_time'});
    });
  });

  group('BpEnumSelector', () {
    test('toJson', () {
      const input = BpEnumSelector(fieldKey: 'priority');
      expect(
          input.toJson(), {'type': 'enum_selector', 'fieldKey': 'priority'});
    });
  });

  group('BpMultiEnumSelector', () {
    test('toJson', () {
      const input = BpMultiEnumSelector(fieldKey: 'tags');
      expect(input.toJson(),
          {'type': 'multi_enum_selector', 'fieldKey': 'tags'});
    });
  });

  group('BpToggle', () {
    test('toJson', () {
      const input = BpToggle(fieldKey: 'completed');
      expect(input.toJson(), {'type': 'toggle', 'fieldKey': 'completed'});
    });
  });

  group('BpSlider', () {
    test('toJson', () {
      const input = BpSlider(fieldKey: 'intensity');
      expect(input.toJson(), {'type': 'slider', 'fieldKey': 'intensity'});
    });
  });

  group('BpRatingInput', () {
    test('toJson', () {
      const input = BpRatingInput(fieldKey: 'score');
      expect(input.toJson(), {'type': 'rating_input', 'fieldKey': 'score'});
    });
  });

  group('BpReferencePicker', () {
    test('defaults', () {
      const input = BpReferencePicker(
        fieldKey: 'category',
        schemaKey: 'category',
      );
      expect(input.toJson(), {
        'type': 'reference_picker',
        'fieldKey': 'category',
        'schemaKey': 'category',
      });
    });

    test('custom displayField', () {
      const input = BpReferencePicker(
        fieldKey: 'account',
        schemaKey: 'account',
        displayField: 'title',
      );
      expect(input.toJson(), {
        'type': 'reference_picker',
        'fieldKey': 'account',
        'schemaKey': 'account',
        'displayField': 'title',
      });
    });

    test('default displayField omits key', () {
      const input = BpReferencePicker(
        fieldKey: 'ref',
        schemaKey: 'target',
      );
      expect(input.toJson().containsKey('displayField'), false);
    });
  });

  group('equality', () {
    test('same inputs are equal', () {
      const a = BpTextInput(fieldKey: 'x', multiline: true);
      const b = BpTextInput(fieldKey: 'x', multiline: true);
      expect(a, equals(b));
    });

    test('different fieldKeys are not equal', () {
      const a = BpTextInput(fieldKey: 'x');
      const b = BpTextInput(fieldKey: 'y');
      expect(a, isNot(equals(b)));
    });
  });

  group('inputs in form_screen', () {
    test('form with typed inputs produces correct JSON', () {
      const form = BpFormScreen(
        title: 'New Expense',
        submitLabel: 'Save',
        defaults: {'currency': 'USD'},
        children: [
          BpTextInput(fieldKey: 'note'),
          BpCurrencyInput(fieldKey: 'amount'),
          BpDatePicker(fieldKey: 'date'),
          BpEnumSelector(fieldKey: 'category'),
          BpReferencePicker(fieldKey: 'account', schemaKey: 'account'),
          BpToggle(fieldKey: 'recurring'),
        ],
      );

      final json = form.toJson();
      final children = json['children'] as List;
      expect(children.length, 6);
      expect(children[0]['type'], 'text_input');
      expect(children[1]['type'], 'currency_input');
      expect(children[2]['type'], 'date_picker');
      expect(children[3]['type'], 'enum_selector');
      expect(children[4]['type'], 'reference_picker');
      expect(children[4]['schemaKey'], 'account');
      expect(children[5]['type'], 'toggle');
    });
  });
}
