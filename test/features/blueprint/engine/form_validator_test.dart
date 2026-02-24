import 'package:bowerlab/features/blueprint/engine/form_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FormValidator.validate', () {
    // ═══════════════════════════════════════════════
    //  Required
    // ═══════════════════════════════════════════════
    test('required field empty returns error', () {
      final result = FormValidator.validate(
        value: '',
        validation: {'required': true},
        label: 'Name',
      );

      expect(result, 'Name is required');
    });

    test('required field with null value returns error', () {
      final result = FormValidator.validate(
        value: null,
        validation: {'required': true},
        label: 'Name',
      );

      expect(result, 'Name is required');
    });

    test('required field with whitespace-only value returns error', () {
      final result = FormValidator.validate(
        value: '   ',
        validation: {'required': true},
        label: 'Name',
      );

      expect(result, 'Name is required');
    });

    test('required field with value passes', () {
      final result = FormValidator.validate(
        value: 'John',
        validation: {'required': true},
        label: 'Name',
      );

      expect(result, isNull);
    });

    // ═══════════════════════════════════════════════
    //  Min / Max value
    // ═══════════════════════════════════════════════
    test('min value violation returns error', () {
      final result = FormValidator.validate(
        value: '5',
        validation: {'min': 10},
        label: 'Amount',
      );

      expect(result, 'Amount must be at least 10');
    });

    test('max value violation returns error', () {
      final result = FormValidator.validate(
        value: '150',
        validation: {'max': 100},
        label: 'Amount',
      );

      expect(result, 'Amount must be at most 100');
    });

    test('value at min boundary passes', () {
      final result = FormValidator.validate(
        value: '10',
        validation: {'min': 10},
        label: 'Amount',
      );

      expect(result, isNull);
    });

    test('value at max boundary passes', () {
      final result = FormValidator.validate(
        value: '100',
        validation: {'max': 100},
        label: 'Amount',
      );

      expect(result, isNull);
    });

    // ═══════════════════════════════════════════════
    //  MinLength / MaxLength
    // ═══════════════════════════════════════════════
    test('minLength violation returns error', () {
      final result = FormValidator.validate(
        value: 'ab',
        validation: {'minLength': 3},
        label: 'Username',
      );

      expect(result, 'Username must be at least 3 characters');
    });

    test('maxLength violation returns error', () {
      final result = FormValidator.validate(
        value: 'abcdefghijk',
        validation: {'maxLength': 10},
        label: 'Username',
      );

      expect(result, 'Username must be at most 10 characters');
    });

    test('value at minLength boundary passes', () {
      final result = FormValidator.validate(
        value: 'abc',
        validation: {'minLength': 3},
        label: 'Username',
      );

      expect(result, isNull);
    });

    test('value at maxLength boundary passes', () {
      final result = FormValidator.validate(
        value: 'abcdefghij',
        validation: {'maxLength': 10},
        label: 'Username',
      );

      expect(result, isNull);
    });

    // ═══════════════════════════════════════════════
    //  Pattern
    // ═══════════════════════════════════════════════
    test('pattern mismatch returns error', () {
      final result = FormValidator.validate(
        value: 'not-an-email',
        validation: {'pattern': r'^[\w.]+@[\w.]+\.\w+$'},
        label: 'Email',
      );

      expect(result, 'Email format is invalid');
    });

    test('pattern match passes', () {
      final result = FormValidator.validate(
        value: 'user@example.com',
        validation: {'pattern': r'^[\w.]+@[\w.]+\.\w+$'},
        label: 'Email',
      );

      expect(result, isNull);
    });

    test('invalid regex pattern is silently skipped', () {
      final result = FormValidator.validate(
        value: 'anything',
        validation: {'pattern': '[invalid('},
        label: 'Field',
      );

      // Invalid regex is skipped, no error
      expect(result, isNull);
    });

    // ═══════════════════════════════════════════════
    //  Custom message
    // ═══════════════════════════════════════════════
    test('custom message overrides default for required', () {
      final result = FormValidator.validate(
        value: '',
        validation: {
          'required': true,
          'message': 'Please enter your name',
        },
        label: 'Name',
      );

      expect(result, 'Please enter your name');
    });

    test('custom message overrides default for min', () {
      final result = FormValidator.validate(
        value: '5',
        validation: {
          'min': 10,
          'message': 'Too small!',
        },
        label: 'Amount',
      );

      expect(result, 'Too small!');
    });

    test('custom message overrides default for pattern', () {
      final result = FormValidator.validate(
        value: 'bad',
        validation: {
          'pattern': r'^\d+$',
          'message': 'Numbers only please',
        },
        label: 'Code',
      );

      expect(result, 'Numbers only please');
    });

    // ═══════════════════════════════════════════════
    //  Valid input / no rules
    // ═══════════════════════════════════════════════
    test('valid input passes all rules', () {
      final result = FormValidator.validate(
        value: 'hello123',
        validation: {
          'required': true,
          'minLength': 3,
          'maxLength': 20,
          'pattern': r'^[a-z0-9]+$',
        },
        label: 'Input',
      );

      expect(result, isNull);
    });

    test('null validation returns null', () {
      final result = FormValidator.validate(
        value: 'anything',
        validation: null,
        label: 'Field',
      );

      expect(result, isNull);
    });

    test('empty validation map returns null', () {
      final result = FormValidator.validate(
        value: 'anything',
        validation: {},
        label: 'Field',
      );

      expect(result, isNull);
    });

    // ═══════════════════════════════════════════════
    //  Non-required empty values skip remaining checks
    // ═══════════════════════════════════════════════
    test('non-required empty value skips min/max checks', () {
      final result = FormValidator.validate(
        value: '',
        validation: {'min': 10, 'max': 100},
        label: 'Amount',
      );

      expect(result, isNull);
    });

    test('non-required null value skips pattern check', () {
      final result = FormValidator.validate(
        value: null,
        validation: {'pattern': r'^\d+$'},
        label: 'Code',
      );

      expect(result, isNull);
    });
  });
}
