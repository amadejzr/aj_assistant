import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aj_assistant/core/database/app_database.dart';
import 'package:aj_assistant/core/models/module.dart';
import 'package:aj_assistant/core/models/module_template.dart';
import 'package:aj_assistant/core/repositories/marketplace_repository.dart';
import 'package:aj_assistant/core/repositories/module_repository.dart';
import 'package:aj_assistant/features/auth/bloc/auth_bloc.dart';
import 'package:aj_assistant/features/auth/bloc/auth_event.dart';
import 'package:aj_assistant/features/auth/bloc/auth_state.dart';
import 'package:aj_assistant/features/auth/models/app_user.dart';
import 'package:aj_assistant/features/capabilities/repositories/capability_repository.dart';
import 'package:aj_assistant/features/chat/models/message.dart';
import 'package:aj_assistant/features/chat/repositories/chat_repository.dart';

// ── Mocks ────────────────────────────────────────────────────────────────

class MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class MockMarketplaceRepository extends Mock
    implements MarketplaceRepository {}

class MockModuleRepository extends Mock implements ModuleRepository {}

class MockChatRepository extends Mock implements ChatRepository {}

class MockAppDatabase extends Mock implements AppDatabase {}

class MockCapabilityRepository extends Mock implements CapabilityRepository {}

// ── Test user ────────────────────────────────────────────────────────────

const testUser = AppUser(
  uid: 'test_user',
  email: 'amadej@test.com',
  displayName: 'Amadej',
);

// ── Test modules (installed) ─────────────────────────────────────────────

const testModules = [
  Module(
    id: 'expenses',
    name: 'Expenses',
    description: 'Track daily spending',
    icon: 'wallet',
    color: '#D94E33',
  ),
  Module(
    id: 'fitness',
    name: 'Fitness',
    description: 'Log workouts & progress',
    icon: 'barbell',
    color: '#6B9E6B',
  ),
];

// ── Test messages (chat) ─────────────────────────────────────────────────

const testMessages = [
  Message(
    id: '1',
    role: MessageRole.user,
    content: 'I spent \$45 on groceries today',
  ),
  Message(
    id: '2',
    role: MessageRole.assistant,
    content: "I'll add that to your expenses.",
  ),
  Message(
    id: '3',
    role: MessageRole.assistant,
    content: '',
    pendingActions: [
      PendingAction(
        toolUseId: 'tool1',
        name: 'createEntry',
        input: {
          'schemaKey': 'expenses',
          'data': {
            'category': 'Groceries',
            'amount': '\$45.00',
            'date': 'Feb 22, 2026',
          },
        },
        description: 'Create expense entry',
      ),
    ],
    approvalStatus: ApprovalStatus.approved,
  ),
  Message(
    id: '4',
    role: MessageRole.assistant,
    content: 'Done! Your grocery expense has been recorded.',
  ),
];

// ── Test templates (marketplace) ─────────────────────────────────────────

const testTemplates = [
  ModuleTemplate(
    id: 'expenses',
    name: 'Expenses',
    description: 'Track daily spending and budgets',
    icon: 'wallet',
    color: '#D94E33',
    category: 'Finance',
    featured: true,
    installCount: 142,
  ),
  ModuleTemplate(
    id: 'fitness',
    name: 'Fitness Log',
    description: 'Log workouts, sets, and progress',
    icon: 'barbell',
    color: '#6B9E6B',
    category: 'Health',
    featured: true,
    installCount: 98,
  ),
  ModuleTemplate(
    id: 'habits',
    name: 'Habit Tracker',
    description: 'Build streaks and daily habits',
    icon: 'list',
    color: '#5B8FB9',
    category: 'Productivity',
    featured: false,
    installCount: 76,
  ),
  ModuleTemplate(
    id: 'reading',
    name: 'Reading List',
    description: 'Books to read and notes',
    icon: 'book',
    color: '#9B7B5B',
    category: 'Personal',
    featured: false,
    installCount: 53,
  ),
  ModuleTemplate(
    id: 'budget',
    name: 'Budget Planner',
    description: 'Monthly income and expenses',
    icon: 'chart',
    color: '#E8913A',
    category: 'Finance',
    featured: false,
    installCount: 64,
  ),
  ModuleTemplate(
    id: 'hiking',
    name: 'Hiking Log',
    description: 'Track trails and adventures',
    icon: 'mountains',
    color: '#4A8B6F',
    category: 'Health',
    featured: false,
    installCount: 31,
  ),
];
