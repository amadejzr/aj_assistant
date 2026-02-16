import 'package:aj_assistant/core/models/module.dart';
import 'package:aj_assistant/features/schema/models/field_definition.dart';
import 'package:aj_assistant/features/schema/models/field_type.dart';
import 'package:aj_assistant/features/schema/models/module_schema.dart';
import 'package:aj_assistant/core/repositories/entry_repository.dart';
import 'package:aj_assistant/core/repositories/module_repository.dart';
import 'package:aj_assistant/features/module_viewer/bloc/module_viewer_bloc.dart';
import 'package:aj_assistant/features/module_viewer/bloc/module_viewer_event.dart';
import 'package:aj_assistant/features/module_viewer/bloc/module_viewer_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockModuleRepository extends Mock implements ModuleRepository {}

class MockEntryRepository extends Mock implements EntryRepository {}

class FakeModule extends Fake implements Module {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeModule());
  });

  late MockModuleRepository moduleRepository;
  late MockEntryRepository entryRepository;

  const testModule = Module(
    id: 'mod1',
    name: 'Test Module',
    schemas: {
      'expense': ModuleSchema(
        label: 'Expense',
        fields: {
          'amount': FieldDefinition(
            key: 'amount',
            type: FieldType.currency,
            label: 'Amount',
            required: true,
          ),
          'note': FieldDefinition(
            key: 'note',
            type: FieldType.text,
            label: 'Note',
          ),
        },
      ),
      'category': ModuleSchema(
        label: 'Category',
        fields: {
          'name': FieldDefinition(
            key: 'name',
            type: FieldType.text,
            label: 'Name',
          ),
        },
      ),
    },
  );

  setUp(() {
    moduleRepository = MockModuleRepository();
    entryRepository = MockEntryRepository();

    when(() => moduleRepository.updateModule(any(), any()))
        .thenAnswer((_) async {});
    when(() => entryRepository.watchEntries(any(), any()))
        .thenAnswer((_) => const Stream.empty());
  });

  ModuleViewerBloc createBloc() => ModuleViewerBloc(
        moduleRepository: moduleRepository,
        entryRepository: entryRepository,
        userId: 'user1',
      );

  group('ModuleViewerSchemaUpdated', () {
    blocTest<ModuleViewerBloc, ModuleViewerState>(
      'updates a schema label, persists module, state reflects change',
      build: createBloc,
      seed: () => ModuleViewerLoaded(module: testModule),
      act: (bloc) => bloc.add(
        const ModuleViewerSchemaUpdated(
          'expense',
          ModuleSchema(
            label: 'Updated Expense',
            fields: {
              'amount': FieldDefinition(
                key: 'amount',
                type: FieldType.currency,
                label: 'Amount',
                required: true,
              ),
              'note': FieldDefinition(
                key: 'note',
                type: FieldType.text,
                label: 'Note',
              ),
            },
          ),
        ),
      ),
      expect: () => [
        isA<ModuleViewerLoaded>().having(
          (s) => s.module.schemas['expense']!.label,
          'updated schema label',
          'Updated Expense',
        ),
      ],
      verify: (_) {
        final captured =
            verify(() => moduleRepository.updateModule('user1', captureAny()))
                .captured;
        final updatedModule = captured.first as Module;
        expect(updatedModule.schemas['expense']!.label, 'Updated Expense');
        // Other schema unchanged
        expect(updatedModule.schemas['category']!.label, 'Category');
      },
    );

    blocTest<ModuleViewerBloc, ModuleViewerState>(
      'unknown schema key — no-op, state unchanged',
      build: createBloc,
      seed: () => ModuleViewerLoaded(module: testModule),
      act: (bloc) => bloc.add(
        const ModuleViewerSchemaUpdated(
          'nonexistent',
          ModuleSchema(label: 'Ghost'),
        ),
      ),
      expect: () => [],
      verify: (_) {
        verifyNever(() => moduleRepository.updateModule(any(), any()));
      },
    );
  });

  group('ModuleViewerSchemaAdded', () {
    blocTest<ModuleViewerBloc, ModuleViewerState>(
      'adds new schema key, persists module, state reflects change',
      build: createBloc,
      seed: () => ModuleViewerLoaded(module: testModule),
      act: (bloc) => bloc.add(
        const ModuleViewerSchemaAdded(
          'budget',
          ModuleSchema(label: 'Budget'),
        ),
      ),
      expect: () => [
        isA<ModuleViewerLoaded>()
            .having(
              (s) => s.module.schemas.containsKey('budget'),
              'has budget schema',
              true,
            )
            .having(
              (s) => s.module.schemas['budget']!.label,
              'budget label',
              'Budget',
            )
            .having(
              (s) => s.module.schemas.length,
              'total schemas',
              3,
            ),
      ],
      verify: (_) {
        final captured =
            verify(() => moduleRepository.updateModule('user1', captureAny()))
                .captured;
        final updatedModule = captured.first as Module;
        expect(updatedModule.schemas.containsKey('budget'), true);
        expect(updatedModule.schemas.length, 3);
      },
    );
  });

  group('ModuleViewerSchemaDeleted', () {
    blocTest<ModuleViewerBloc, ModuleViewerState>(
      'removes schema key, persists module, state reflects change',
      build: createBloc,
      seed: () => ModuleViewerLoaded(module: testModule),
      act: (bloc) => bloc.add(
        const ModuleViewerSchemaDeleted('category'),
      ),
      expect: () => [
        isA<ModuleViewerLoaded>()
            .having(
              (s) => s.module.schemas.containsKey('category'),
              'category removed',
              false,
            )
            .having(
              (s) => s.module.schemas.length,
              'total schemas',
              1,
            ),
      ],
      verify: (_) {
        final captured =
            verify(() => moduleRepository.updateModule('user1', captureAny()))
                .captured;
        final updatedModule = captured.first as Module;
        expect(updatedModule.schemas.containsKey('category'), false);
      },
    );
  });

  group('ModuleViewerFieldUpdated', () {
    blocTest<ModuleViewerBloc, ModuleViewerState>(
      'updates a field in a schema, persists',
      build: createBloc,
      seed: () => ModuleViewerLoaded(module: testModule),
      act: (bloc) => bloc.add(
        const ModuleViewerFieldUpdated(
          'expense',
          'amount',
          FieldDefinition(
            key: 'amount',
            type: FieldType.currency,
            label: 'Total Amount',
            required: true,
          ),
        ),
      ),
      expect: () => [
        isA<ModuleViewerLoaded>().having(
          (s) => s.module.schemas['expense']!.fields['amount']!.label,
          'updated field label',
          'Total Amount',
        ),
      ],
      verify: (_) {
        final captured =
            verify(() => moduleRepository.updateModule('user1', captureAny()))
                .captured;
        final updatedModule = captured.first as Module;
        expect(
          updatedModule.schemas['expense']!.fields['amount']!.label,
          'Total Amount',
        );
        // Other fields unchanged
        expect(
          updatedModule.schemas['expense']!.fields['note']!.label,
          'Note',
        );
      },
    );

    blocTest<ModuleViewerBloc, ModuleViewerState>(
      'unknown schema key — no-op, state unchanged',
      build: createBloc,
      seed: () => ModuleViewerLoaded(module: testModule),
      act: (bloc) => bloc.add(
        const ModuleViewerFieldUpdated(
          'nonexistent',
          'amount',
          FieldDefinition(
            key: 'amount',
            type: FieldType.currency,
            label: 'Amount',
          ),
        ),
      ),
      expect: () => [],
      verify: (_) {
        verifyNever(() => moduleRepository.updateModule(any(), any()));
      },
    );
  });

  group('ModuleViewerFieldAdded', () {
    blocTest<ModuleViewerBloc, ModuleViewerState>(
      'adds new field to schema, persists',
      build: createBloc,
      seed: () => ModuleViewerLoaded(module: testModule),
      act: (bloc) => bloc.add(
        const ModuleViewerFieldAdded(
          'expense',
          'date',
          FieldDefinition(
            key: 'date',
            type: FieldType.datetime,
            label: 'Date',
            required: true,
          ),
        ),
      ),
      expect: () => [
        isA<ModuleViewerLoaded>()
            .having(
              (s) => s.module.schemas['expense']!.fields.containsKey('date'),
              'has date field',
              true,
            )
            .having(
              (s) => s.module.schemas['expense']!.fields['date']!.label,
              'date label',
              'Date',
            )
            .having(
              (s) => s.module.schemas['expense']!.fields.length,
              'field count',
              3,
            ),
      ],
      verify: (_) {
        final captured =
            verify(() => moduleRepository.updateModule('user1', captureAny()))
                .captured;
        final updatedModule = captured.first as Module;
        expect(
          updatedModule.schemas['expense']!.fields.containsKey('date'),
          true,
        );
      },
    );
  });

  group('ModuleViewerFieldDeleted', () {
    blocTest<ModuleViewerBloc, ModuleViewerState>(
      'removes field from schema, persists',
      build: createBloc,
      seed: () => ModuleViewerLoaded(module: testModule),
      act: (bloc) => bloc.add(
        const ModuleViewerFieldDeleted('expense', 'note'),
      ),
      expect: () => [
        isA<ModuleViewerLoaded>()
            .having(
              (s) => s.module.schemas['expense']!.fields.containsKey('note'),
              'note removed',
              false,
            )
            .having(
              (s) => s.module.schemas['expense']!.fields.length,
              'field count',
              1,
            ),
      ],
      verify: (_) {
        final captured =
            verify(() => moduleRepository.updateModule('user1', captureAny()))
                .captured;
        final updatedModule = captured.first as Module;
        expect(
          updatedModule.schemas['expense']!.fields.containsKey('note'),
          false,
        );
        // Other field still there
        expect(
          updatedModule.schemas['expense']!.fields.containsKey('amount'),
          true,
        );
      },
    );
  });
}
