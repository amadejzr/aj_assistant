import 'package:flutter_test/flutter_test.dart';
import 'package:bowerlab/features/capabilities/models/capability.dart';

void main() {
  group('Capability sealed class', () {
    group('ScheduledReminder', () {
      test('serializes to JSON correctly', () {
        final cap = ScheduledReminder(
          id: 'cap_1', moduleId: 'mod_1', title: 'Log expenses',
          message: 'Time to log!', enabled: true,
          frequency: ReminderFrequency.daily, hour: 20, minute: 0,
          createdAt: DateTime.utc(2026, 1, 1), updatedAt: DateTime.utc(2026, 1, 1),
        );
        expect(cap.type, 'scheduled');
        final json = cap.toJson();
        expect(json['type'], 'scheduled');
        expect(json['config']['frequency'], 'daily');
        expect(json['config']['hour'], 20);
      });

      test('deserializes from JSON correctly', () {
        final json = {
          'moduleId': 'mod_1', 'type': 'scheduled',
          'title': 'Log expenses', 'message': 'Time to log!', 'enabled': true,
          'config': {'frequency': 'daily', 'hour': 20, 'minute': 0},
          'createdAt': 1704067200000, 'updatedAt': 1704067200000,
        };
        final cap = Capability.fromJson('cap_1', json);
        expect(cap, isA<ScheduledReminder>());
        expect((cap as ScheduledReminder).frequency, ReminderFrequency.daily);
      });
    });

    group('DeadlineReminder', () {
      test('round-trips through JSON', () {
        final cap = DeadlineReminder(
          id: 'cap_2', moduleId: 'mod_1', title: 'Due tomorrow',
          message: '{{title}} is due', enabled: true,
          schemaKey: 'default', dateField: 'dueDate', offsetMinutes: -1440,
          createdAt: DateTime.utc(2026, 1, 1), updatedAt: DateTime.utc(2026, 1, 1),
        );
        final json = cap.toJson();
        final restored = Capability.fromJson('cap_2', json);
        expect(restored, isA<DeadlineReminder>());
        expect((restored as DeadlineReminder).offsetMinutes, -1440);
      });
    });

    group('StreakNudge', () {
      test('round-trips through JSON', () {
        final cap = StreakNudge(
          id: 'cap_3', moduleId: 'mod_1', title: 'Keep tracking',
          message: 'No entries', enabled: true,
          inactivityDays: 3, checkHour: 19, checkMinute: 0,
          createdAt: DateTime.utc(2026, 1, 1), updatedAt: DateTime.utc(2026, 1, 1),
        );
        final json = cap.toJson();
        final restored = Capability.fromJson('cap_3', json);
        expect(restored, isA<StreakNudge>());
        expect((restored as StreakNudge).inactivityDays, 3);
      });
    });

    test('supports null moduleId', () {
      final json = {
        'type': 'scheduled',
        'title': 'Drink water', 'message': 'Stay hydrated',
        'enabled': true,
        'config': {'frequency': 'daily', 'hour': 10, 'minute': 0},
        'createdAt': 1704067200000, 'updatedAt': 1704067200000,
      };
      final cap = Capability.fromJson('cap_null', json);
      expect(cap.moduleId, isNull);
      expect(cap.toJson().containsKey('moduleId'), isFalse);
    });

    test('fromJson throws for unknown type', () {
      final json = {
        'moduleId': 'mod_1', 'type': 'unknown', 'title': 'X', 'message': 'X',
        'enabled': true, 'config': {},
        'createdAt': 1704067200000, 'updatedAt': 1704067200000,
      };
      expect(() => Capability.fromJson('id', json), throwsArgumentError);
    });
  });
}
