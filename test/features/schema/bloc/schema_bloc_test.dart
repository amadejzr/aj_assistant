import 'package:aj_assistant/core/models/module.dart';
import 'package:aj_assistant/core/repositories/module_repository.dart';
import 'package:aj_assistant/features/schema/bloc/schema_bloc.dart';
import 'package:aj_assistant/features/schema/bloc/schema_event.dart';
import 'package:aj_assistant/features/schema/bloc/schema_state.dart';
import 'package:aj_assistant/features/schema/models/field_definition.dart';
import 'package:aj_assistant/features/schema/models/field_type.dart';
import 'package:aj_assistant/features/schema/models/module_schema.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockModuleRepository extends Mock implements ModuleRepository {}

class FakeModule extends Fake implements Module {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeModule());
  });

  late MockModuleRepository moduleRepository;

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

    when(() => moduleRepository.getModule(any(), any()))
        .thenAnswer((_) async => testModule);
    when(() => moduleRepository.updateModule(any(), any()))
        .thenAnswer((_) async {});
  });

  SchemaBloc createBloc() => SchemaBloc(
        moduleRepository: moduleRepository,
        userId: 'user1',
        moduleId: 'mod1',
      );

  group('SchemaStarted', () {
    blocTest<SchemaBloc, SchemaState>(
      'loads module and emits SchemaLoaded with schemas',
      build: createBloc,
      act: (bloc) => bloc.add(const SchemaStarted('mod1')),
      expect: () => [
        isA<SchemaLoading>(),
        isA<SchemaLoaded>()
            .having((s) => s.moduleId, 'moduleId', 'mod1')
            .having((s) => s.schemas.length, 'schemas count', 2)
            .having(
                (s) => s.schemas.containsKey('expense'), 'has expense', true),
      ],
    );

    blocTest<SchemaBloc, SchemaState>(
      'emits error when module not found',
      build: () {
        when(() => moduleRepository.getModule(any(), any()))
            .thenAnswer((_) async => null);
        return createBloc();
      },
      act: (bloc) => bloc.add(const SchemaStarted('mod1')),
      expect: () => [
        isA<SchemaLoading>(),
        isA<SchemaError>(),
      ],
    );
  });

  group('SchemaScreenChanged', () {
    blocTest<SchemaBloc, SchemaState>(
      'pushes current screen to stack and navigates to new screen',
      build: createBloc,
      seed: () => const SchemaLoaded(
        moduleId: 'mod1',
        schemas: {'expense': ModuleSchema(label: 'Expense')},
        currentScreen: 'list',
      ),
      act: (bloc) => bloc.add(
        const SchemaScreenChanged('editor',
            params: {'schemaKey': 'expense'}),
      ),
      expect: () => [
        isA<SchemaLoaded>()
            .having((s) => s.currentScreen, 'currentScreen', 'editor')
            .having((s) => s.screenParams['schemaKey'], 'schemaKey', 'expense')
            .having((s) => s.screenStack.length, 'stack length', 1)
            .having(
                (s) => s.screenStack.first.screen, 'prev screen', 'list'),
      ],
    );
  });

  group('SchemaNavigateBack', () {
    blocTest<SchemaBloc, SchemaState>(
      'pops screen stack and restores previous screen',
      build: createBloc,
      seed: () => const SchemaLoaded(
        moduleId: 'mod1',
        schemas: {'expense': ModuleSchema(label: 'Expense')},
        currentScreen: 'editor',
        screenParams: {'schemaKey': 'expense'},
        screenStack: [SchemaScreenEntry('list')],
      ),
      act: (bloc) => bloc.add(const SchemaNavigateBack()),
      expect: () => [
        isA<SchemaLoaded>()
            .having((s) => s.currentScreen, 'currentScreen', 'list')
            .having((s) => s.screenStack.length, 'stack length', 0),
      ],
    );

    blocTest<SchemaBloc, SchemaState>(
      'does nothing when stack is empty',
      build: createBloc,
      seed: () => const SchemaLoaded(
        moduleId: 'mod1',
        schemas: {},
        currentScreen: 'list',
      ),
      act: (bloc) => bloc.add(const SchemaNavigateBack()),
      expect: () => [],
    );
  });

  group('SchemaUpdated', () {
    blocTest<SchemaBloc, SchemaState>(
      'updates schema label, persists, state reflects change',
      build: createBloc,
      seed: () => SchemaLoaded(
        moduleId: 'mod1',
        schemas: Map.of(testModule.schemas),
      ),
      act: (bloc) => bloc.add(
        const SchemaUpdated(
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
        isA<SchemaLoaded>().having(
          (s) => s.schemas['expense']!.label,
          'updated schema label',
          'Updated Expense',
        ),
      ],
      verify: (_) {
        verify(() => moduleRepository.updateModule('user1', any())).called(1);
      },
    );

    blocTest<SchemaBloc, SchemaState>(
      'unknown schema key — no-op',
      build: createBloc,
      seed: () => SchemaLoaded(
        moduleId: 'mod1',
        schemas: Map.of(testModule.schemas),
      ),
      act: (bloc) => bloc.add(
        const SchemaUpdated('nonexistent', ModuleSchema(label: 'Ghost')),
      ),
      expect: () => [],
    );
  });

  group('SchemaAdded', () {
    blocTest<SchemaBloc, SchemaState>(
      'adds new schema, persists, state reflects change',
      build: createBloc,
      seed: () => SchemaLoaded(
        moduleId: 'mod1',
        schemas: Map.of(testModule.schemas),
      ),
      act: (bloc) => bloc.add(
        const SchemaAdded('budget', ModuleSchema(label: 'Budget')),
      ),
      expect: () => [
        isA<SchemaLoaded>()
            .having(
              (s) => s.schemas.containsKey('budget'),
              'has budget',
              true,
            )
            .having(
              (s) => s.schemas['budget']!.label,
              'budget label',
              'Budget',
            )
            .having((s) => s.schemas.length, 'total schemas', 3),
      ],
      verify: (_) {
        verify(() => moduleRepository.updateModule('user1', any())).called(1);
      },
    );
  });

  group('SchemaDeleted', () {
    blocTest<SchemaBloc, SchemaState>(
      'removes schema, persists, state reflects change',
      build: createBloc,
      seed: () => SchemaLoaded(
        moduleId: 'mod1',
        schemas: Map.of(testModule.schemas),
      ),
      act: (bloc) => bloc.add(const SchemaDeleted('category')),
      expect: () => [
        isA<SchemaLoaded>()
            .having(
              (s) => s.schemas.containsKey('category'),
              'category removed',
              false,
            )
            .having((s) => s.schemas.length, 'total schemas', 1),
      ],
      verify: (_) {
        verify(() => moduleRepository.updateModule('user1', any())).called(1);
      },
    );
  });

  group('FieldUpdated', () {
    blocTest<SchemaBloc, SchemaState>(
      'updates a field in a schema, persists',
      build: createBloc,
      seed: () => SchemaLoaded(
        moduleId: 'mod1',
        schemas: Map.of(testModule.schemas),
      ),
      act: (bloc) => bloc.add(
        const FieldUpdated(
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
        isA<SchemaLoaded>().having(
          (s) => s.schemas['expense']!.fields['amount']!.label,
          'updated field label',
          'Total Amount',
        ),
      ],
      verify: (_) {
        verify(() => moduleRepository.updateModule('user1', any())).called(1);
      },
    );

    blocTest<SchemaBloc, SchemaState>(
      'unknown schema key — no-op',
      build: createBloc,
      seed: () => SchemaLoaded(
        moduleId: 'mod1',
        schemas: Map.of(testModule.schemas),
      ),
      act: (bloc) => bloc.add(
        const FieldUpdated(
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
    );
  });

  group('FieldAdded', () {
    blocTest<SchemaBloc, SchemaState>(
      'adds new field to schema, persists',
      build: createBloc,
      seed: () => SchemaLoaded(
        moduleId: 'mod1',
        schemas: Map.of(testModule.schemas),
      ),
      act: (bloc) => bloc.add(
        const FieldAdded(
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
        isA<SchemaLoaded>()
            .having(
              (s) => s.schemas['expense']!.fields.containsKey('date'),
              'has date field',
              true,
            )
            .having(
              (s) => s.schemas['expense']!.fields['date']!.label,
              'date label',
              'Date',
            )
            .having(
              (s) => s.schemas['expense']!.fields.length,
              'field count',
              3,
            ),
      ],
      verify: (_) {
        verify(() => moduleRepository.updateModule('user1', any())).called(1);
      },
    );
  });

  group('FieldDeleted', () {
    blocTest<SchemaBloc, SchemaState>(
      'removes field from schema, persists',
      build: createBloc,
      seed: () => SchemaLoaded(
        moduleId: 'mod1',
        schemas: Map.of(testModule.schemas),
      ),
      act: (bloc) => bloc.add(const FieldDeleted('expense', 'note')),
      expect: () => [
        isA<SchemaLoaded>()
            .having(
              (s) => s.schemas['expense']!.fields.containsKey('note'),
              'note removed',
              false,
            )
            .having(
              (s) => s.schemas['expense']!.fields.length,
              'field count',
              1,
            ),
      ],
      verify: (_) {
        verify(() => moduleRepository.updateModule('user1', any())).called(1);
      },
    );
  });
}
