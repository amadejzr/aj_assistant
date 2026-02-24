import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app.dart';
import 'core/logging/app_bloc_observer.dart';
import 'core/logging/console_log_backend.dart';
import 'core/logging/log.dart';
import 'core/repositories/marketplace_repository.dart';
import 'core/database/app_database.dart';
import 'core/database/schema_manager.dart';
import 'core/repositories/drift_module_repository.dart';
import 'core/repositories/module_repository.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/services/user_service.dart';
import 'features/blueprint/renderer/widget_registry.dart';
import 'features/capabilities/repositories/capability_repository.dart';
import 'features/capabilities/repositories/drift_capability_repository.dart';
import 'features/capabilities/services/notification_scheduler.dart';
import 'core/ai/api_key_service.dart';
import 'features/chat/cubit/model_cubit.dart';
import 'features/chat/repositories/chat_repository.dart';
import 'features/chat/repositories/drift_chat_repository.dart';
import 'features/settings/cubit/theme_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Logging — add backends before anything else.
  Log.addBackend(const ConsoleLogBackend());
  Bloc.observer = const AppBlocObserver();

  Log.i('App initialized', tag: 'App');

  WidgetRegistry.instance.registerDefaults();

  final authService = AuthService();
  final userService = UserService();
  final db = AppDatabase();
  final moduleRepository = DriftModuleRepository(db);

  // Ensure all dynamic module tables exist — Drift only manages its own
  // static tables, so m_* tables need explicit recreation on startup.
  final schemaManager = SchemaManager(db: db);
  for (final module in await moduleRepository.getModules('')) {
    await schemaManager.installModule(module);
  }

  final capabilityRepository = DriftCapabilityRepository(db);
  final apiKeyService = ApiKeyService();
  final themeCubit = ThemeCubit()..init();
  final modelCubit = ModelCubit()..init();
  final chatRepository = DriftChatRepository(db);
  final marketplaceRepository = BundledMarketplaceRepository();

  // Initialize notification scheduler
  final notificationScheduler = NotificationScheduler(capabilityRepository);
  await notificationScheduler.initialize();
  await notificationScheduler.requestPermissions();
  await notificationScheduler.rescheduleAll();

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AppDatabase>.value(value: db),
        RepositoryProvider<ModuleRepository>.value(value: moduleRepository),

        RepositoryProvider<CapabilityRepository>.value(
          value: capabilityRepository,
        ),
        RepositoryProvider<ApiKeyService>.value(value: apiKeyService),
        RepositoryProvider<ChatRepository>.value(value: chatRepository),
        RepositoryProvider<MarketplaceRepository>.value(
          value: marketplaceRepository,
        ),
        RepositoryProvider<NotificationScheduler>.value(
          value: notificationScheduler,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) =>
                AuthBloc(authService: authService, userService: userService)
                  ..add(const AuthCheckRequested()),
          ),
          BlocProvider.value(value: themeCubit),
          BlocProvider.value(value: modelCubit),
        ],
        child: const AJAssistantApp(),
      ),
    ),
  );
}
