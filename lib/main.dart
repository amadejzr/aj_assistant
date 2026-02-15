import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app.dart';
import 'core/logging/app_bloc_observer.dart';
import 'core/logging/console_log_backend.dart';
import 'core/logging/log.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/services/user_service.dart';
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

  final authService = AuthService();
  final userService = UserService();

  runApp(
    BlocProvider(
      create: (_) => AuthBloc(
        authService: authService,
        userService: userService,
      )..startListening(),
      child: const AJAssistantApp(),
    ),
  );
}
