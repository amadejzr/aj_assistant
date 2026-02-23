import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app.dart';
import 'core/logging/app_bloc_observer.dart';
import 'core/logging/console_log_backend.dart';
import 'core/logging/log.dart';
import 'core/repositories/marketplace_repository.dart';
import 'core/database/app_database.dart';
import 'core/repositories/drift_module_repository.dart';
import 'core/repositories/module_repository.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/services/user_service.dart';
import 'features/blueprint/renderer/widget_registry.dart';
import 'features/capabilities/repositories/capability_repository.dart';
import 'features/capabilities/repositories/drift_capability_repository.dart';
import 'features/capabilities/services/notification_scheduler.dart';
import 'core/ai/api_key_service.dart';
import 'features/settings/cubit/theme_cubit.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Logging — add backends before anything else.
  Log.addBackend(const ConsoleLogBackend());
  Bloc.observer = const AppBlocObserver();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
  );

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  Log.i('Firebase initialized', tag: 'App');

  // Register all blueprint widget builders
  WidgetRegistry.instance.registerDefaults();

  final authService = AuthService();
  final userService = UserService();
  final db = AppDatabase();
  final moduleRepository = DriftModuleRepository(db);
  final capabilityRepository = DriftCapabilityRepository(db);
  final apiKeyService = ApiKeyService();
  final themeCubit = ThemeCubit()..init();
  final marketplaceRepository = FirestoreMarketplaceRepository();

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
                  ..startListening(),
          ),
          BlocProvider.value(value: themeCubit),
        ],
        child: const AJAssistantApp(),
      ),
    ),
  );
}
