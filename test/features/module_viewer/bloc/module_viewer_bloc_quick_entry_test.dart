import 'package:aj_assistant/core/models/entry.dart';
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

class FakeEntry extends Fake implements Entry {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeEntry());
  });

  late MockModuleRepository moduleRepository;
  late MockEntryRepository entryRepository;

  const testModule = Module(
    id: 'mod1',
    name: 'Finances',
    schemas: {
      'default': ModuleSchema(
        label: 'Default',
        fields: {},
      ),
      'category': ModuleSchema(
        version: 2,
        label: 'Category',
        fields: {
          'name': FieldDefinition(
            key: 'name',
            type: FieldType.text,
            label: 'Name',
          ),
        },
      ),
      'expense': ModuleSchema(
        label: 'Expense',
        fields: {
          'amount': FieldDefinition(
            key: 'amount',
            type: FieldType.currency,
            label: 'Amount',
          ),
          'category': FieldDefinition(
            key: 'category',
            type: FieldType.reference,
            label: 'Category',
            constraints: {'schemaKey': 'category'},
          ),
        },
      ),
    },
  );

  setUp(() {
    moduleRepository = MockModuleRepository();
    entryRepository = MockEntryRepository();

    when(() => entryRepository.watchEntries(any(), any()))
        .thenAnswer((_) => const Stream.empty());
    when(() => entryRepository.createEntry(any(), any(), any()))
        .thenAnswer((_) async => 'new-entry-id');
    when(() => entryRepository.updateEntry(any(), any(), any()))
        .thenAnswer((_) async {});
  });

  ModuleViewerBloc createBloc() => ModuleViewerBloc(
        moduleRepository: moduleRepository,
        entryRepository: entryRepository,
        userId: 'user1',
      );

  group('ModuleViewerQuickEntryCreated', () {
    blocTest<ModuleViewerBloc, ModuleViewerState>(
      'calls createEntry with correct schemaKey',
      build: createBloc,
      seed: () => ModuleViewerLoaded(module: testModule),
      act: (bloc) => bloc.add(const ModuleViewerQuickEntryCreated(
        schemaKey: 'category',
        data: {'name': 'Food'},
      )),
      verify: (_) {
        final captured = verify(
          () => entryRepository.createEntry('user1', 'mod1', captureAny()),
        ).captured;
        final entry = captured.first as Entry;
        expect(entry.schemaKey, 'category');
        expect(entry.data, {'name': 'Food'});
        expect(entry.schemaVersion, 2);
      },
    );

    blocTest<ModuleViewerBloc, ModuleViewerState>(
      'sets pendingAutoSelect when autoSelectFieldKey provided',
      build: createBloc,
      seed: () => ModuleViewerLoaded(module: testModule),
      act: (bloc) => bloc.add(const ModuleViewerQuickEntryCreated(
        schemaKey: 'category',
        data: {'name': 'Food'},
        autoSelectFieldKey: 'category',
      )),
      expect: () => [
        isA<ModuleViewerLoaded>().having(
          (s) => s.pendingAutoSelect,
          'pendingAutoSelect',
          (fieldKey: 'category', entryId: 'new-entry-id'),
        ),
      ],
    );

    blocTest<ModuleViewerBloc, ModuleViewerState>(
      'does not set pendingAutoSelect when autoSelectFieldKey is null',
      build: createBloc,
      seed: () => ModuleViewerLoaded(module: testModule),
      act: (bloc) => bloc.add(const ModuleViewerQuickEntryCreated(
        schemaKey: 'category',
        data: {'name': 'Food'},
      )),
      expect: () => [],
    );
  });

  group('ModuleViewerQuickEntryUpdated', () {
    blocTest<ModuleViewerBloc, ModuleViewerState>(
      'calls updateEntry with merged data',
      build: createBloc,
      seed: () => ModuleViewerLoaded(
        module: testModule,
        entries: const [
          Entry(
            id: 'cat1',
            data: {'name': 'Food', 'color': 'red'},
            schemaKey: 'category',
          ),
        ],
      ),
      act: (bloc) => bloc.add(const ModuleViewerQuickEntryUpdated(
        entryId: 'cat1',
        schemaKey: 'category',
        data: {'name': 'Groceries'},
      )),
      verify: (_) {
        final captured = verify(
          () => entryRepository.updateEntry('user1', 'mod1', captureAny()),
        ).captured;
        final entry = captured.first as Entry;
        expect(entry.id, 'cat1');
        expect(entry.data['name'], 'Groceries');
        expect(entry.data['color'], 'red'); // preserved from existing
      },
    );

    blocTest<ModuleViewerBloc, ModuleViewerState>(
      'preserves schemaKey on update',
      build: createBloc,
      seed: () => ModuleViewerLoaded(
        module: testModule,
        entries: const [
          Entry(
            id: 'cat1',
            data: {'name': 'Food'},
            schemaKey: 'category',
          ),
        ],
      ),
      act: (bloc) => bloc.add(const ModuleViewerQuickEntryUpdated(
        entryId: 'cat1',
        schemaKey: 'category',
        data: {'name': 'Updated'},
      )),
      verify: (_) {
        final captured = verify(
          () => entryRepository.updateEntry('user1', 'mod1', captureAny()),
        ).captured;
        final entry = captured.first as Entry;
        expect(entry.schemaKey, 'category');
      },
    );
  });

  group('ModuleViewerFormSubmitted — schemaKey', () {
    blocTest<ModuleViewerBloc, ModuleViewerState>(
      'uses schemaKey from screenParams when present',
      build: createBloc,
      seed: () => ModuleViewerLoaded(
        module: testModule,
        formValues: const {'amount': 50},
        screenParams: const {'_schemaKey': 'expense'},
        screenStack: const [ScreenEntry('main')],
      ),
      act: (bloc) => bloc.add(const ModuleViewerFormSubmitted()),
      verify: (_) {
        final captured = verify(
          () => entryRepository.createEntry('user1', 'mod1', captureAny()),
        ).captured;
        final entry = captured.first as Entry;
        expect(entry.schemaKey, 'expense');
      },
    );

    blocTest<ModuleViewerBloc, ModuleViewerState>(
      'defaults to "default" when no schemaKey in screenParams',
      build: createBloc,
      seed: () => ModuleViewerLoaded(
        module: testModule,
        formValues: const {'name': 'Test'},
        screenStack: const [ScreenEntry('main')],
      ),
      act: (bloc) => bloc.add(const ModuleViewerFormSubmitted()),
      verify: (_) {
        final captured = verify(
          () => entryRepository.createEntry('user1', 'mod1', captureAny()),
        ).captured;
        final entry = captured.first as Entry;
        expect(entry.schemaKey, 'default');
      },
    );
  });
}
