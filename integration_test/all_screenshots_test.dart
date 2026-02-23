import 'package:flutter/material.dart' hide Actions;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aj_assistant/core/database/app_database.dart';
import 'package:aj_assistant/core/models/module.dart';
import 'package:aj_assistant/core/repositories/marketplace_repository.dart';
import 'package:aj_assistant/core/repositories/module_repository.dart';
import 'package:aj_assistant/core/theme/app_theme.dart';
import 'package:aj_assistant/features/auth/bloc/auth_bloc.dart';
import 'package:aj_assistant/features/auth/bloc/auth_state.dart';
import 'package:aj_assistant/features/auth/widgets/seal_logo.dart';
import 'package:aj_assistant/features/blueprint/navigation/module_navigation.dart';
import 'package:aj_assistant/features/blueprint/renderer/blueprint_renderer.dart';
import 'package:aj_assistant/features/blueprint/renderer/render_context.dart';
import 'package:aj_assistant/features/blueprint/renderer/widget_registry.dart';
import 'package:aj_assistant/features/blueprint/utils/icon_resolver.dart';
import 'package:aj_assistant/features/blueprint/dsl/blueprint_dsl.dart';
import 'package:aj_assistant/core/ai/api_key_service.dart';
import 'package:aj_assistant/features/capabilities/repositories/capability_repository.dart';
import 'package:aj_assistant/features/marketplace/screens/marketplace_screen.dart';
import 'package:aj_assistant/features/shell/screens/home_screen.dart';
import 'package:aj_assistant/features/shell/screens/shell_screen.dart';

import 'helpers/test_helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetRegistry.instance.registerDefaults();

  late MockAuthBloc authBloc;
  late MockModuleRepository moduleRepo;
  late MockCapabilityRepository capabilityRepo;

  setUp(() {
    authBloc = MockAuthBloc();
    when(() => authBloc.state)
        .thenReturn(const AuthAuthenticated(testUser));
    when(() => authBloc.stream)
        .thenAnswer((_) => Stream.value(const AuthAuthenticated(testUser)));

    moduleRepo = MockModuleRepository();
    when(() => moduleRepo.watchModules(any()))
        .thenAnswer((_) => Stream.value(testModules));
    when(() => moduleRepo.getModules(any()))
        .thenAnswer((_) async => testModules);

    capabilityRepo = MockCapabilityRepository();
    when(() => capabilityRepo.watchEnabledCapabilities(
            limit: any(named: 'limit')))
        .thenAnswer((_) => Stream.value([]));
  });

  // ── Home ───────────────────────────────────────────────────────────────

  testWidgets('home', (tester) async {
    debugPrint('📸 [home] setting up mocks...');
    final apiKeyService = MockApiKeyService();
    final appDatabase = MockAppDatabase();

    debugPrint('📸 [home] pumping widget...');
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ModuleRepository>.value(value: moduleRepo),
          RepositoryProvider<CapabilityRepository>.value(
              value: capabilityRepo),
          RepositoryProvider<ApiKeyService>.value(value: apiKeyService),
          RepositoryProvider<AppDatabase>.value(value: appDatabase),
        ],
        child: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            home: const ShellScreen(child: HomeScreen()),
          ),
        ),
      ),
    );

    debugPrint('📸 [home] waiting for animations...');
    // Multiple pumps: let the BLoC stream emit and rebuild,
    // then advance past the 900ms entry animation.
    // Can't use pumpAndSettle — BreathingFab has an infinite animation.
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    debugPrint('📸 [home] taking screenshot...');
    await binding.takeScreenshot('home');
    debugPrint('📸 [home] done.');
  });

  // ── Chat ───────────────────────────────────────────────────────────────

  testWidgets('chat', (tester) async {
    debugPrint('📸 [chat] setting up mocks...');
    final apiKeyService = MockApiKeyService();
    when(() => apiKeyService.getKey())
        .thenAnswer((_) async => 'test-api-key');

    final appDatabase = MockAppDatabase();

    debugPrint('📸 [chat] pumping widget...');
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ModuleRepository>.value(value: moduleRepo),
          RepositoryProvider<ApiKeyService>.value(value: apiKeyService),
          RepositoryProvider<AppDatabase>.value(value: appDatabase),
          RepositoryProvider<CapabilityRepository>.value(
              value: capabilityRepo),
        ],
        child: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            home: const ShellScreen(child: HomeScreen()),
          ),
        ),
      ),
    );

    debugPrint('📸 [chat] waiting for animations...');
    // pump with duration — BreathingFab has an infinite animation
    await tester.pump(const Duration(seconds: 2));

    // Tap the BreathingFab to open the chat sheet
    debugPrint('📸 [chat] tapping FAB...');
    await tester.tap(find.byType(SealLogo));
    debugPrint('📸 [chat] waiting for chat sheet...');
    await tester.pump(const Duration(seconds: 2));

    debugPrint('📸 [chat] taking screenshot...');
    await binding.takeScreenshot('chat');
    debugPrint('📸 [chat] done.');
  });

  // ── Marketplace ────────────────────────────────────────────────────────

  testWidgets('marketplace', (tester) async {
    debugPrint('📸 [marketplace] setting up mocks...');
    final marketplaceRepo = MockMarketplaceRepository();
    when(() => marketplaceRepo.getTemplates())
        .thenAnswer((_) async => testTemplates);

    debugPrint('📸 [marketplace] pumping widget...');
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<MarketplaceRepository>.value(
              value: marketplaceRepo),
          RepositoryProvider<ModuleRepository>.value(value: moduleRepo),
        ],
        child: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            home: const MarketplaceScreen(),
          ),
        ),
      ),
    );

    debugPrint('📸 [marketplace] waiting for settle...');
    await tester.pumpAndSettle();
    debugPrint('📸 [marketplace] taking screenshot...');
    await binding.takeScreenshot('marketplace');
    debugPrint('📸 [marketplace] done.');
  });

  // ── Expense Tracker ────────────────────────────────────────────────────

  testWidgets('expense_tracker', (tester) async {
    debugPrint('📸 [expense_tracker] building template...');
    final template = _expenseTrackerTemplate();
    final screens = (template['screens'] as Map).map(
      (k, v) => MapEntry(k as String, Map<String, dynamic>.from(v as Map)),
    );
    final navJson = template['navigation'] as Map<String, dynamic>;
    final navigation = ModuleNavigation.fromJson(navJson);

    final module = Module(
      id: 'expense_tracker_test',
      name: template['name'] as String,
      description: template['description'] as String,
      icon: template['icon'] as String,
      color: template['color'] as String,
      screens: screens,
      navigation: navigation,
    );

    final screenJson = module.screens['main']!;
    debugPrint('📸 [expense_tracker] setting up render context...');

    final ctx = RenderContext(
      module: module,
      onFormValueChanged: (_, _) {},
      onNavigateToScreen: (_, {params = const {}}) {},
      queryResults: {
        'month_total': [
          {'total': 1247.50},
        ],
        'expense_count': [
          {'total': 23},
        ],
        'by_category': [
          {'category': 'Bills', 'total': 407.80},
          {'category': 'Food', 'total': 312.40},
          {'category': 'Shopping', 'total': 245.80},
          {'category': 'Transport', 'total': 187.50},
          {'category': 'Entertainment', 'total': 94.00},
        ],
        'recent': [
          {
            'id': '1',
            'amount': 45.20,
            'date': 1740200000000,
            'note': 'Groceries at Mercator',
            'category_name': 'Food',
          },
          {
            'id': '2',
            'amount': 23.50,
            'date': 1740190000000,
            'note': 'Uber to airport',
            'category_name': 'Transport',
          },
          {
            'id': '3',
            'amount': 18.00,
            'date': 1740180000000,
            'note': 'Cinema tickets',
            'category_name': 'Entertainment',
          },
          {
            'id': '4',
            'amount': 89.99,
            'date': 1740170000000,
            'note': 'New headphones',
            'category_name': 'Shopping',
          },
          {
            'id': '5',
            'amount': 67.40,
            'date': 1740160000000,
            'note': 'Electric bill',
            'category_name': 'Bills',
          },
        ],
      },
    );

    final bottomNav = navigation.bottomNav!;

    debugPrint('📸 [expense_tracker] pumping widget...');
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: Column(
          children: [
            Expanded(
              child: BlueprintRenderer(
                blueprintJson: screenJson,
                context_: ctx,
              ),
            ),
            BottomNavigationBar(
              currentIndex: 0,
              onTap: (_) {},
              type: BottomNavigationBarType.fixed,
              backgroundColor: const Color(0xFFFFFCF7),
              selectedItemColor: const Color(0xFFC44230),
              unselectedItemColor: const Color(0xFF8A847A),
              selectedLabelStyle:
                  const TextStyle(fontFamily: 'Karla', fontSize: 12),
              unselectedLabelStyle:
                  const TextStyle(fontFamily: 'Karla', fontSize: 12),
              items: bottomNav.items.map((item) {
                final icon = resolveIcon(item.icon);
                return BottomNavigationBarItem(
                  icon: Icon(icon ?? Icons.circle, size: 22),
                  label: item.label,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );

    debugPrint('📸 [expense_tracker] waiting for settle...');
    await tester.pumpAndSettle();
    debugPrint('📸 [expense_tracker] taking screenshot...');
    await binding.takeScreenshot('expense_tracker');
    debugPrint('📸 [expense_tracker] done.');
  });
}

// ── Expense tracker template ─────────────────────────────────────────────

Map<String, dynamic> _expenseTrackerTemplate() => TemplateDef.build(
      name: 'Expense Tracker',
      description:
          'Log expenses, manage categories, and see where your money goes',
      icon: 'receipt',
      color: '#E65100',
      category: 'Finance',
      navigation: Nav.bottomNav(items: [
        Nav.item(label: 'Dashboard', icon: 'chart-pie', screenId: 'main'),
        Nav.item(label: 'Expenses', icon: 'list', screenId: 'expenses'),
        Nav.item(
            label: 'Categories', icon: 'tag', screenId: 'categories'),
      ]),
      screens: {
        'main': Layout.screen(
          appBar: Layout.appBar(title: 'Expense Tracker', showBack: false),
          queries: {
            'month_total': Query.def(
              'SELECT COALESCE(SUM(amount), 0) as total '
              'FROM "m_expenses" '
              "WHERE date >= strftime('%s', date('now', 'start of month')) * 1000",
            ),
            'expense_count': Query.def(
              'SELECT COUNT(*) as total FROM "m_expenses" '
              "WHERE date >= strftime('%s', date('now', 'start of month')) * 1000",
            ),
            'by_category': Query.def(
              'SELECT c.name as category, COALESCE(SUM(e.amount), 0) as total '
              'FROM "m_expenses" e '
              'JOIN "m_expense_categories" c ON e.category_id = c.id '
              "WHERE e.date >= strftime('%s', date('now', 'start of month')) * 1000 "
              'GROUP BY c.name ORDER BY total DESC',
            ),
            'recent': Query.def(
              'SELECT e.id, e.amount, e.date, e.note, c.name as category_name '
              'FROM "m_expenses" e '
              'JOIN "m_expense_categories" c ON e.category_id = c.id '
              'ORDER BY e.date DESC LIMIT 5',
            ),
          },
          children: [
            Layout.scrollColumn(children: [
              Layout.row(children: [
                Display.statCard(
                  label: 'This Month',
                  format: 'currency',
                  accent: true,
                  source: 'month_total',
                  valueKey: 'total',
                ),
                Display.statCard(
                  label: 'Transactions',
                  source: 'expense_count',
                  valueKey: 'total',
                ),
              ]),
              Display.chart(
                chartType: 'pie',
                title: 'Spending by Category',
                source: 'by_category',
                groupBy: 'category',
                valueField: 'total',
              ),
              Display.entryList(
                title: 'Recent Expenses',
                source: 'recent',
                emptyState: Display.emptyState(
                  message: 'No expenses logged yet',
                  icon: 'receipt',
                  action: Act.navigate('add_expense',
                      label: 'Add your first expense'),
                ),
                itemLayout: Display.entryCard(
                  title: '{{category_name}}',
                  subtitle: '{{note}}',
                  trailing: '{{amount}}',
                  trailingFormat: 'currency',
                  onTap: Act.navigate(
                    'edit_expense',
                    forwardFields: [
                      'amount',
                      'category_id',
                      'date',
                      'note'
                    ],
                    params: {},
                  ),
                ),
              ),
            ]),
          ],
          fab: Actions.fab(
            icon: 'add',
            action: Act.navigate('add_expense', params: {}),
          ),
        ),
      },
    );
