import 'package:aj_assistant/core/models/entry.dart';
import 'package:aj_assistant/core/models/module.dart';
import 'package:aj_assistant/core/repositories/entry_repository.dart';
import 'package:aj_assistant/core/repositories/module_repository.dart';
import 'package:aj_assistant/features/module_viewer/bloc/module_viewer_bloc.dart';
import 'package:aj_assistant/features/module_viewer/bloc/module_viewer_event.dart';
import 'package:aj_assistant/features/module_viewer/bloc/module_viewer_state.dart';
import 'package:aj_assistant/features/schema/models/field_definition.dart';
import 'package:aj_assistant/features/schema/models/field_type.dart';
import 'package:aj_assistant/features/schema/models/module_schema.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockModuleRepository extends Mock implements ModuleRepository {}

class MockEntryRepository extends Mock implements EntryRepository {}

class FakeEntry extends Fake implements Entry {}

class FakeModule extends Fake implements Module {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeEntry());
    registerFallbackValue(FakeModule());
  });

  late MockModuleRepository moduleRepository;
  late MockEntryRepository entryRepository;

  // ── Module with onSubmit effects on add_expense ──
  const financeModule = Module(
    id: 'finance',
    name: 'Finance',
    schemas: {
      'account': ModuleSchema(
        label: 'Account',
        fields: {
          'name': FieldDefinition(
            key: 'name',
            type: FieldType.text,
            label: 'Name',
          ),
          'balance': FieldDefinition(
            key: 'balance',
            type: FieldType.number,
            label: 'Balance',
          ),
        },
      ),
      'expense': ModuleSchema(
        label: 'Expense',
        fields: {
          'amount': FieldDefinition(
            key: 'amount',
            type: FieldType.number,
            label: 'Amount',
          ),
          'account': FieldDefinition(
            key: 'account',
            type: FieldType.reference,
            label: 'Account',
            constraints: {'schemaKey': 'account'},
          ),
          'note': FieldDefinition(
            key: 'note',
            type: FieldType.text,
            label: 'Note',
          ),
        },
      ),
      'income': ModuleSchema(
        label: 'Income',
        fields: {
          'amount': FieldDefinition(
            key: 'amount',
            type: FieldType.number,
            label: 'Amount',
          ),
          'account': FieldDefinition(
            key: 'account',
            type: FieldType.reference,
            label: 'Deposit To',
            constraints: {'schemaKey': 'account'},
          ),
        },
      ),
    },
    screens: {
      'main': {
        'id': 'main',
        'type': 'screen',
        'title': 'Finance',
      },
      'add_expense': {
        'id': 'add_expense',
        'type': 'form_screen',
        'title': 'Add Expense',
        'submitLabel': 'Save',
        'onSubmit': [
          {
            'type': 'adjust_reference',
            'referenceField': 'account',
            'targetField': 'balance',
            'amountField': 'amount',
            'operation': 'subtract',
          },
        ],
        'children': [
          {'type': 'number_input', 'fieldKey': 'amount'},
          {'type': 'text_input', 'fieldKey': 'note'},
        ],
      },
      'edit_expense': {
        'id': 'edit_expense',
        'type': 'form_screen',
        'title': 'Edit Expense',
        // No onSubmit — editing doesn't re-adjust balance
        'children': [
          {'type': 'number_input', 'fieldKey': 'amount'},
          {'type': 'text_input', 'fieldKey': 'note'},
        ],
      },
      'add_income': {
        'id': 'add_income',
        'type': 'form_screen',
        'title': 'Add Income',
        'submitLabel': 'Save',
        'onSubmit': [
          {
            'type': 'adjust_reference',
            'referenceField': 'account',
            'targetField': 'balance',
            'amountField': 'amount',
            'operation': 'add',
          },
        ],
        'children': [
          {'type': 'number_input', 'fieldKey': 'amount'},
        ],
      },
      'no_effects_form': {
        'id': 'no_effects_form',
        'type': 'form_screen',
        'title': 'Simple Form',
        'submitLabel': 'Save',
        'children': [
          {'type': 'text_input', 'fieldKey': 'name'},
        ],
      },
      'multi_effect_form': {
        'id': 'multi_effect_form',
        'type': 'form_screen',
        'title': 'Transfer',
        'submitLabel': 'Transfer',
        'onSubmit': [
          {
            'type': 'adjust_reference',
            'referenceField': 'fromAccount',
            'targetField': 'balance',
            'amountField': 'amount',
            'operation': 'subtract',
          },
          {
            'type': 'adjust_reference',
            'referenceField': 'toAccount',
            'targetField': 'balance',
            'amountField': 'amount',
            'operation': 'add',
          },
        ],
        'children': [],
      },
      'set_effect_form': {
        'id': 'set_effect_form',
        'type': 'form_screen',
        'title': 'Complete Goal',
        'submitLabel': 'Done',
        'onSubmit': [
          {
            'type': 'set_reference',
            'referenceField': 'goal',
            'targetField': 'status',
            'value': 'completed',
          },
        ],
        'children': [],
      },
      'literal_amount_form': {
        'id': 'literal_amount_form',
        'type': 'form_screen',
        'title': 'Log Session',
        'submitLabel': 'Log',
        'onSubmit': [
          {
            'type': 'adjust_reference',
            'referenceField': 'program',
            'targetField': 'sessions',
            'amount': 1,
            'operation': 'add',
          },
        ],
        'children': [],
      },
      'edit_budget': {
        'id': 'edit_budget',
        'type': 'form_screen',
        'title': 'Budget',
        'submitLabel': 'Save',
        'onSubmit': [
          {
            'type': 'adjust_reference',
            'referenceField': 'account',
            'targetField': 'balance',
            'amountField': 'amount',
            'operation': 'subtract',
          },
        ],
        'children': [
          {'type': 'number_input', 'fieldKey': 'needsTarget'},
        ],
      },
    },
  );

  const walletEntry = Entry(
    id: 'acc-wallet',
    data: {'name': 'Wallet', 'balance': 1000},
    schemaKey: 'account',
  );
  const savingsEntry = Entry(
    id: 'acc-savings',
    data: {'name': 'Savings', 'balance': 5000},
    schemaKey: 'account',
  );
  const goalEntry = Entry(
    id: 'goal-1',
    data: {'name': 'Vacation', 'status': 'active', 'sessions': 3},
    schemaKey: 'goal',
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
    when(() => moduleRepository.updateModule(any(), any()))
        .thenAnswer((_) async {});
  });

  ModuleViewerBloc createBloc() => ModuleViewerBloc(
        moduleRepository: moduleRepository,
        entryRepository: entryRepository,
        userId: 'user1',
      );

  // ═══════════════════════════════════════════════════════
  //  onSubmit: adjust_reference — expense subtracts balance
  // ═══════════════════════════════════════════════════════
  group('onSubmit effects — adjust_reference', () {
    blocTest<ModuleViewerBloc, ModuleViewerState>(
      'creates expense entry AND adjusts account balance',
      build: createBloc,
      seed: () => ModuleViewerLoaded(
        module: financeModule,
        currentScreenId: 'add_expense',
        screenParams: const {'_schemaKey': 'expense'},
        screenStack: const [ScreenEntry('main')],
        entries: const [walletEntry, savingsEntry],
        formValues: const {
          'amount': 150,
          'account': 'acc-wallet',
          'note': 'Groceries',
        },
      ),
      act: (bloc) => bloc.add(const ModuleViewerFormSubmitted()),
      verify: (_) {
        // 1. Entry was created
        final createCalls = verify(
          () => entryRepository.createEntry('user1', 'finance', captureAny()),
        ).captured;
        final created = createCalls.first as Entry;
        expect(created.schemaKey, 'expense');
        expect(created.data['amount'], 150);
        expect(created.data['note'], 'Groceries');

        // 2. Account was updated (balance: 1000 - 150 = 850)
        final updateCalls = verify(
          () => entryRepository.updateEntry('user1', 'finance', captureAny()),
        ).captured;
        final updated = updateCalls.first as Entry;
        expect(updated.id, 'acc-wallet');
        expect(updated.schemaKey, 'account');
        expect(updated.data['balance'], 850);
        expect(updated.data['name'], 'Wallet'); // other fields preserved
      },
    );

    blocTest<ModuleViewerBloc, ModuleViewerState>(
      'income adds to account balance',
      build: createBloc,
      seed: () => ModuleViewerLoaded(
        module: financeModule,
        currentScreenId: 'add_income',
        screenParams: const {'_schemaKey': 'income'},
        screenStack: const [ScreenEntry('main')],
        entries: const [walletEntry, savingsEntry],
        formValues: const {
          'amount': 3000,
          'account': 'acc-savings',
        },
      ),
      act: (bloc) => bloc.add(const ModuleViewerFormSubmitted()),
      verify: (_) {
        // Account updated (balance: 5000 + 3000 = 8000)
        final updateCalls = verify(
          () => entryRepository.updateEntry('user1', 'finance', captureAny()),
        ).captured;
        final updated = updateCalls.first as Entry;
        expect(updated.id, 'acc-savings');
        expect(updated.data['balance'], 8000);
      },
    );

    blocTest<ModuleViewerBloc, ModuleViewerState>(
      'navigates back after submit + effects',
      build: createBloc,
      seed: () => ModuleViewerLoaded(
        module: financeModule,
        currentScreenId: 'add_expense',
        screenParams: const {'_schemaKey': 'expense'},
        screenStack: const [ScreenEntry('main')],
        entries: const [walletEntry],
        formValues: const {
          'amount': 50,
          'account': 'acc-wallet',
          'note': 'Coffee',
        },
      ),
      act: (bloc) => bloc.add(const ModuleViewerFormSubmitted()),
      expect: () => [
        // isSubmitting: true
        isA<ModuleViewerLoaded>().having(
          (s) => s.isSubmitting,
          'isSubmitting',
          true,
        ),
        // Back on main, form cleared
        isA<ModuleViewerLoaded>()
            .having((s) => s.currentScreenId, 'screenId', 'main')
            .having((s) => s.formValues, 'formValues', isEmpty)
            .having((s) => s.isSubmitting, 'isSubmitting', false),
      ],
    );
  });

  // ═══════════════════════════════════════════════════════
  //  No effects — form without onSubmit
  // ═══════════════════════════════════════════════════════
  group('form without onSubmit', () {
    blocTest<ModuleViewerBloc, ModuleViewerState>(
      'creates entry without calling updateEntry',
      build: createBloc,
      seed: () => ModuleViewerLoaded(
        module: financeModule,
        currentScreenId: 'no_effects_form',
        screenParams: const {'_schemaKey': 'account'},
        screenStack: const [ScreenEntry('main')],
        entries: const [walletEntry],
        formValues: const {'name': 'New Account'},
      ),
      act: (bloc) => bloc.add(const ModuleViewerFormSubmitted()),
      verify: (_) {
        verify(
          () => entryRepository.createEntry('user1', 'finance', any()),
        ).called(1);

        // No updateEntry call — no effects to apply
        verifyNever(
          () => entryRepository.updateEntry(any(), any(), any()),
        );
      },
    );
  });

  // ═══════════════════════════════════════════════════════
  //  Edit form — no effects on edit screen
  // ═══════════════════════════════════════════════════════
  group('edit form without onSubmit', () {
    blocTest<ModuleViewerBloc, ModuleViewerState>(
      'updates entry without triggering effects',
      build: createBloc,
      seed: () => ModuleViewerLoaded(
        module: financeModule,
        currentScreenId: 'edit_expense',
        screenParams: const {
          '_schemaKey': 'expense',
          '_entryId': 'exp-1',
        },
        screenStack: const [ScreenEntry('main')],
        entries: const [
          walletEntry,
          Entry(
            id: 'exp-1',
            data: {'amount': 100, 'note': 'Old note', 'account': 'acc-wallet'},
            schemaKey: 'expense',
          ),
        ],
        formValues: const {'amount': 120, 'note': 'Updated note'},
      ),
      act: (bloc) => bloc.add(const ModuleViewerFormSubmitted()),
      verify: (_) {
        // Only one updateEntry call — for the edited expense, not for account
        final calls = verify(
          () => entryRepository.updateEntry('user1', 'finance', captureAny()),
        ).captured;
        expect(calls, hasLength(1));
        final updated = calls.first as Entry;
        expect(updated.id, 'exp-1');
        expect(updated.data['amount'], 120);
        expect(updated.data['note'], 'Updated note');
        expect(updated.data['account'], 'acc-wallet'); // merged from existing

        // No createEntry call
        verifyNever(
          () => entryRepository.createEntry(any(), any(), any()),
        );
      },
    );
  });

  // ═══════════════════════════════════════════════════════
  //  Settings mode — skips onSubmit effects entirely
  // ═══════════════════════════════════════════════════════
  group('settings mode', () {
    blocTest<ModuleViewerBloc, ModuleViewerState>(
      'updates module settings without running onSubmit effects',
      build: createBloc,
      seed: () => ModuleViewerLoaded(
        module: financeModule,
        currentScreenId: 'edit_budget',
        screenParams: const {'_settingsMode': true},
        screenStack: const [ScreenEntry('main')],
        entries: const [walletEntry],
        formValues: const {'needsTarget': 60},
      ),
      act: (bloc) => bloc.add(const ModuleViewerFormSubmitted()),
      verify: (_) {
        // Module settings updated
        verify(
          () => moduleRepository.updateModule('user1', any()),
        ).called(1);

        // No entry operations at all
        verifyNever(
          () => entryRepository.createEntry(any(), any(), any()),
        );
        verifyNever(
          () => entryRepository.updateEntry(any(), any(), any()),
        );
      },
    );
  });

  // ═══════════════════════════════════════════════════════
  //  Multiple effects — transfer between accounts
  // ═══════════════════════════════════════════════════════
  group('multiple onSubmit effects', () {
    blocTest<ModuleViewerBloc, ModuleViewerState>(
      'applies both effects (transfer: subtract + add)',
      build: createBloc,
      seed: () => ModuleViewerLoaded(
        module: financeModule,
        currentScreenId: 'multi_effect_form',
        screenParams: const {'_schemaKey': 'expense'},
        screenStack: const [ScreenEntry('main')],
        entries: const [walletEntry, savingsEntry],
        formValues: const {
          'amount': 500,
          'fromAccount': 'acc-wallet',
          'toAccount': 'acc-savings',
        },
      ),
      act: (bloc) => bloc.add(const ModuleViewerFormSubmitted()),
      verify: (_) {
        // 1 createEntry + 2 updateEntry calls
        verify(
          () => entryRepository.createEntry('user1', 'finance', any()),
        ).called(1);

        final updateCalls = verify(
          () => entryRepository.updateEntry('user1', 'finance', captureAny()),
        ).captured;
        expect(updateCalls, hasLength(2));

        final walletUpdate = updateCalls
            .cast<Entry>()
            .firstWhere((e) => e.id == 'acc-wallet');
        final savingsUpdate = updateCalls
            .cast<Entry>()
            .firstWhere((e) => e.id == 'acc-savings');

        expect(walletUpdate.data['balance'], 500); // 1000 - 500
        expect(savingsUpdate.data['balance'], 5500); // 5000 + 500
      },
    );
  });

  // ═══════════════════════════════════════════════════════
  //  set_reference effect
  // ═══════════════════════════════════════════════════════
  group('onSubmit effects — set_reference', () {
    blocTest<ModuleViewerBloc, ModuleViewerState>(
      'sets field on referenced entry to literal value',
      build: createBloc,
      seed: () => ModuleViewerLoaded(
        module: financeModule,
        currentScreenId: 'set_effect_form',
        screenParams: const {'_schemaKey': 'expense'},
        screenStack: const [ScreenEntry('main')],
        entries: const [goalEntry],
        formValues: const {'goal': 'goal-1'},
      ),
      act: (bloc) => bloc.add(const ModuleViewerFormSubmitted()),
      verify: (_) {
        final updateCalls = verify(
          () => entryRepository.updateEntry('user1', 'finance', captureAny()),
        ).captured;
        final updated = updateCalls.first as Entry;
        expect(updated.id, 'goal-1');
        expect(updated.data['status'], 'completed');
        expect(updated.data['name'], 'Vacation'); // preserved
      },
    );
  });

  // ═══════════════════════════════════════════════════════
  //  Literal amount
  // ═══════════════════════════════════════════════════════
  group('onSubmit effects — literal amount', () {
    blocTest<ModuleViewerBloc, ModuleViewerState>(
      'increments field by literal 1',
      build: createBloc,
      seed: () => ModuleViewerLoaded(
        module: financeModule,
        currentScreenId: 'literal_amount_form',
        screenParams: const {'_schemaKey': 'expense'},
        screenStack: const [ScreenEntry('main')],
        entries: const [goalEntry],
        formValues: const {'program': 'goal-1'},
      ),
      act: (bloc) => bloc.add(const ModuleViewerFormSubmitted()),
      verify: (_) {
        final updateCalls = verify(
          () => entryRepository.updateEntry('user1', 'finance', captureAny()),
        ).captured;
        final updated = updateCalls.first as Entry;
        expect(updated.id, 'goal-1');
        expect(updated.data['sessions'], 4); // 3 + 1
      },
    );
  });

  // ═══════════════════════════════════════════════════════
  //  Edge cases
  // ═══════════════════════════════════════════════════════
  group('edge cases', () {
    blocTest<ModuleViewerBloc, ModuleViewerState>(
      'effect with missing account ref silently skips',
      build: createBloc,
      seed: () => ModuleViewerLoaded(
        module: financeModule,
        currentScreenId: 'add_expense',
        screenParams: const {'_schemaKey': 'expense'},
        screenStack: const [ScreenEntry('main')],
        entries: const [walletEntry],
        formValues: const {
          'amount': 100,
          'note': 'No account selected',
          // No 'account' field
        },
      ),
      act: (bloc) => bloc.add(const ModuleViewerFormSubmitted()),
      verify: (_) {
        // Entry created
        verify(
          () => entryRepository.createEntry('user1', 'finance', any()),
        ).called(1);

        // No updateEntry — effect skipped because no account reference
        verifyNever(
          () => entryRepository.updateEntry(any(), any(), any()),
        );
      },
    );

    blocTest<ModuleViewerBloc, ModuleViewerState>(
      'effect failure does not prevent navigation back',
      build: createBloc,
      seed: () => ModuleViewerLoaded(
        module: financeModule,
        currentScreenId: 'add_expense',
        screenParams: const {'_schemaKey': 'expense'},
        screenStack: const [ScreenEntry('main')],
        entries: const [walletEntry],
        formValues: const {
          'amount': 100,
          'account': 'acc-wallet',
          'note': 'Test',
        },
      ),
      setUp: () {
        // Make updateEntry fail
        when(() => entryRepository.updateEntry(any(), any(), any()))
            .thenThrow(Exception('Network error'));
      },
      act: (bloc) => bloc.add(const ModuleViewerFormSubmitted()),
      expect: () => [
        isA<ModuleViewerLoaded>().having(
          (s) => s.isSubmitting,
          'isSubmitting',
          true,
        ),
        // Still navigates back despite effect failure
        isA<ModuleViewerLoaded>()
            .having((s) => s.currentScreenId, 'screenId', 'main')
            .having((s) => s.isSubmitting, 'isSubmitting', false),
      ],
    );

    blocTest<ModuleViewerBloc, ModuleViewerState>(
      'meta keys (_prefixed) are stripped from form data before effects',
      build: createBloc,
      seed: () => ModuleViewerLoaded(
        module: financeModule,
        currentScreenId: 'add_expense',
        screenParams: const {'_schemaKey': 'expense'},
        screenStack: const [ScreenEntry('main')],
        entries: const [walletEntry],
        formValues: const {
          '_internalFlag': true,
          'amount': 200,
          'account': 'acc-wallet',
          'note': 'Test',
        },
      ),
      act: (bloc) => bloc.add(const ModuleViewerFormSubmitted()),
      verify: (_) {
        // Entry created without meta keys
        final createCalls = verify(
          () => entryRepository.createEntry('user1', 'finance', captureAny()),
        ).captured;
        final created = createCalls.first as Entry;
        expect(created.data.containsKey('_internalFlag'), isFalse);
        expect(created.data['amount'], 200);
      },
    );
  });
}
